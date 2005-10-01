package Oryx::DBM::Association::Hash;

use Oryx::DBM::Association::Reference;

use base qw(Oryx::Association::Hash);

our $DEBUG = 0;

sub create {
    my ($self, $proto) = @_;
}

sub retrieve {
    my ($self, $proto, $id) = @_;
}

sub update {
    my ($self, $proto, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->$accessor || { };

    $proto->{$accessor} = { };
    @{ $proto->{$accessor} }{ keys %$value } = map { $_->id } values %$value;

    tied(%$value)->updated({});
    tied(%$value)->created({});
    tied(%$value)->deleted({});

    $self->update_backrefs($obj, values %$value);

    $obj->dbh->commit;
}

sub delete {
    my $self = shift;
    my ($query, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->$accessor;

    if ($self->constraint eq 'Composition') {
	# composition, so cascade the delete
	foreach my $thing (values %$value) {
	    $thing->delete;
	}
    } elsif ($self->constraint eq 'Aggregation') {
	# aggregation so just clear the Hash
	%$value = ();
    }

    $self->update(@_);
}

sub search {

}

sub construct {
    my ($self, $obj) = @_;
    my $assoc_name = $self->role;
    my @args = ($self, $obj);
    tie my %value, __PACKAGE__, @args;
    $obj->{$assoc_name} = \%value;
}

sub load {
    my ($self, $owner) = @_;

    $DEBUG && $self->_carp("load : OWNER => $owner, ID => ".$owner->id);

    my $Hash = $owner->dbm->get($owner->id)->{$self->role} || { };

    my @args;
    foreach (keys(%$Hash)) {
	@args = ($self, $Hash->{$_});
	tie $Hash->{$_}, 'Oryx::DBM::Association::Reference', @args;
    }

    return $Hash;

}

sub fetch {
    my ($self, $thing, $owner) = @_;
    return $thing;
}

sub store {
    my ($self, $thing, $owner) = @_;
    return $thing;
}

1;
