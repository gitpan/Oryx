package Oryx::DBM::Class;

use DBM::Deep;
use Oryx::DBM::Association;
use Oryx::DBM::Attribute;
use Oryx::DBM::Method;
use Oryx::DBM::Parent;

use base qw(Oryx::MetaClass);

our $DEBUG = 2;

__PACKAGE__->mk_classdata('_dbm');

sub dbh { $_[0]->storage }

sub dbm {
    my $class = ref $_[0] || $_[0];
    unless ($class->_dbm) {
	$class->_dbm(
	    DBM::Deep->new(%{ $class->dbh->catalog->get($class->table) })
        );
    }
    $class->_dbm;
}

sub create {
    my ($class, $param) = @_;

    $param->{id} = $class->nextId();
    $param->{_isa} ||= $class;

    $_->create($param) foreach $class->members;

    # grab out the attributes that this class knows about
    my @keys = ('id', keys %{$class->attributes});
    push @keys, '_isa' if $class->is_abstract;
    push @keys, '_parent_ids' if @{ $class->parents };

    my $proto = { };
    @$proto{@keys} = @$param{@keys};

    $class->dbm->push( $proto );

    return $class->construct($proto);
}

sub retrieve {
    my ($class, $id) = @_;

    # fetch the object from the cache if it exists
    my $key = $class->_mk_cache_key($id);
    my $object;
    return $object if ($object = $Live_Objects{$key});

    $DEBUG && $class->_carp("retrieve : id => $id");
    my $proto = $class->dbm->get( $id );

    $_->retrieve($proto, $id) foreach $class->members;

    if ($proto) {
	if ($class->is_abstract and $proto->{_isa} ne $class) {
	    # abstract classes are never instantiated directly, so we
	    # need to retrieve the decendant instead. The descendant's
	    # ID is the same as the abstract class' ID because we used
	    # the abstract class' sequence when the decendant instance
	    # was created...
	    $DEBUG>1 && $class->_carp("RETRIEVE subclass : "
                .$proto->{_isa}." for abstract class : $class");
	    eval "use ".$proto->{_isa};
	    $class->_croak($@) if $@;
	    return $proto->{_isa}->retrieve($proto->{id});
	}
	return $class->construct($proto);
    } else {
	return undef;
    }
}

sub update {
    my ($self) = @_;
    return if $self->is_abstract;

    $self->dbm->lock;

    my $proto = $self->dbm->get( $self->id );
    $_->update($proto, $self) foreach $self->members;
    $self->dbm->put( $self->id, $proto );

    $self->dbm->unlock;

    return $self;
}

sub delete {
    my ($self) = @_;
    my $proto = $self->dbm->get($self->id);
    $_->delete($proto, $self) foreach $self->members;
    $self->dbm->delete($self->id);
    $self->remove_from_cache;
}

sub search {
    my ($class, $param) = @_;

    my ($found, @objs);
    SEARCH: foreach my $proto (@{ $class->dbm }) {
	$found = 1;
	foreach my $field (keys %$param) {
	    next SEARCH if ref $proto->{$field};

	    my $value = $param->{$field};
	    $value =~ /%?([^%]*)%?/;
	    unless ($proto->{$field} =~ /$1/) {
		$found = 0;
	    }
	}
	push @objs, $class->construct($proto) if $found;
    }

    return @objs;
}

# next id in sequence
sub nextId {
    my $nextId = $_[0]->dbm->length;
    $DEBUG && $_[0]->_carp("next id => $nextId");
    return $nextId;
}

1;
