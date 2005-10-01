package Oryx::DBI::Class;

use SQL::Abstract;

use Oryx::DBI::Association;
use Oryx::DBI::Attribute;
use Oryx::DBI::Method;
use Oryx::DBI::Parent;

use base qw(Oryx::MetaClass);

# Other MetaClass constructs are true instances and save their meta
# data as $self->{meta}. Class meta objects are different because
# their state is saved as class data instead of as instances of the
# MetaClass class.

# make some noise
our $DEBUG = 2;

sub dbh { $_[0]->storage->dbh }

sub create {
    my ($class, $param) = @_;
    my %query = ( table => $class->table );
    $param->{id} = $class->nextId();
    $param->{_isa} ||= $class;

    $_->create(\%query, $param) foreach $class->members;

    # grab out the attributes that this class knows about
    my @keys = ('id', keys %{$class->attributes});
    push @keys, '_isa' if $class->is_abstract;
    my $proto = { };
    @$proto{@keys} = @$param{@keys};

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->insert($query{table}, $proto);
    my $sth = $class->dbh->prepare_cached($stmnt);
    $sth->execute(@bind);
    $sth->finish;
    return $class->construct($proto);
}

sub retrieve {
    my ($class, $id) = @_;

    # fetch the object from the cache if it exists
    my $key = $class->_mk_cache_key($id);
    my $object;
    return $object if ($object = $Live_Objects{$key});

    my %query = (
        table  => $class->table,
	fields => [ 'id' ],
	where  => { id => $id },
    );

    if ($class->is_abstract) {
	$DEBUG && $class->_carp("ABSTRACT CLASS retrieve $class");
	push @{$query{fields}}, '_isa';
    }
    $DEBUG && $class->_carp("retrieve : id => $id");
    $_->retrieve(\%query, $id) foreach $class->members;

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->select(@query{
        qw(table fields where order)
    });
    my $sth = $class->dbh->prepare_cached($stmnt);

    eval { $sth->execute(@bind) };
    $self->_croak("execute failed [$stmnt], bind => "
        .join(", ", @bind)." $@") if $@;

    my $values = $sth->fetch;
    $sth->finish;

    if ($values and @$values) {
	my $proto = $class->row2proto($query{fields}, $values);

	if ($class->is_abstract and $proto->{_isa} ne $class) {
	    # abstract classes are never instantiated directly, so we
	    # need to retrieve the decendant instead. The descendant's
	    # ID is the same as the abstract class' ID because we used
	    # the abstract class' sequence when the decendant instance
	    # was created... so no need for a JOIN here
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
    my %query = (
	table => $self->table,
	fieldvals => { },
        where => { id => $self->id },
    );
    $_->update(\%query, $self) foreach $self->members;

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->update(@query{
        qw(table fieldvals where)
    });
    my $sth = $self->dbh->prepare_cached($stmnt);

    eval { $sth->execute(@bind) };
    $self->_croak("execute failed for $stmnt, bind => "
        .join(", ", @bind)." $@") if $@;

    $sth->finish;

    return $self;
}

sub delete {
    my ($self) = @_;
    my %query = (
	table => $self->table,
        where => { id => $self->id },
    );
    $_->delete(\%query, $self) foreach $self->members;

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->delete(@query{qw(table where)});
    my $sth = $self->dbh->prepare_cached($stmnt);

    $sth->execute(@bind);
    $sth->finish;

    $self->remove_from_cache;
}

sub search {
    my ($class, $param) = @_;
    my %query = (
	table  => $class->table,
	fields => [ 'id' ],
        where  => $param,
        order  => [ ],
    );

    push @{$query{fields}}, '_isa' if $class->is_abstract;

    $_->search(\%query) foreach $class->members;

    my $sql = SQL::Abstract->new(cmp => 'like');
    my ($stmnt, @bind) = $sql->select(@query{
        qw(table fields where order)
    });
    my $sth = $class->dbh->prepare_cached($stmnt);
    $sth->execute(@bind);

    my (@objs, @row);
    while (@row = $sth->fetch) {
	my $proto = $class->row2proto($query{fields}, \@row);
	push @objs, $class->construct($proto);
    }
    $sth->finish;
    return @objs;
}

sub row2proto {
    my ($class, $fields, $values) = @_;
    my $proto = { };
    @$proto{ @$fields } = @$values;
    return $proto;
}

# next id in sequence
sub nextId {
    my $class = shift;
    $class->storage->util->nextval($class->dbh, $class->table);
}

1;
