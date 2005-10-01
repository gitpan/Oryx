package Oryx::DBM::Association::Array;

use Oryx::DBM::Association::Reference;

use base qw(Oryx::Association::Array);

sub create {
    my ($self, $proto) = @_;
}

sub retrieve {
    my ($self, $proto, $id) = @_;
}

sub update {
    my ($self, $proto, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->$accessor || [ ];

    $proto->{$accessor} = [ map { $_->id } @$value ];

    # were not interested in these (for now), so just clear them
    tied(@$value)->updated({});
    tied(@$value)->created({});
    tied(@$value)->deleted({});

    $self->update_backrefs($obj, @$value);

}

sub delete {
    my $self = shift;
    my ($proto, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->$accessor;

    if ($self->constraint eq 'Composition') {
	# cascade the delete
	while (my $thing = pop @$value) {
	    $thing->delete;
	}
    } elsif ($self->constraint eq 'Aggregation') {
	# just clear the Array
	@$value = ();
    }

    $self->update(@_);
}

sub search {
    my ($self, $query) = @_;
}

sub construct {
    my ($self, $obj) = @_;
    my $assoc_name = $self->role;
    my @args = ($self, $obj);
    tie my @value, __PACKAGE__, @args;
    $obj->{$assoc_name} = \@value;
}

sub load {
    my ($self, $owner) = @_;

    # take a copy of the DBM array
    my $Array = [ $owner->{$self->role} ? @{ $owner->{$self->role} } : () ];

    my @args;
    for (my $x = 0; $x < @$Array; $x++) {
	@args = ($self, $Array->[$x]);
	$Array->[$x] = Oryx::DBM::Association::Reference->TIESCALAR(@args);
    }

    return $Array;
}

sub fetch {
    my ($self, $thing, $owner) = @_;
    if (ref $thing eq 'Oryx::DBM::Association::Reference') {
	return $thing->FETCH();
    }
    return $thing;
}

sub store {
    my ($self, $thing, $owner) = @_;
    return $thing;
}

1;
