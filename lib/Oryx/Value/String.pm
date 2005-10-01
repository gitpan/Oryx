package Oryx::Value::String;
use base qw(Oryx::Value);

use Data::Types qw(is_string to_string);

sub FETCH {
    my $self = shift;
    unless ($self->{VALUE}) {
	$self->STORE($self->{owner}->{$self->{meta}->name});
    }
    return to_string($self->{VALUE});
}

sub STORE {
    my ($self, $value) = @_;

    $self->_croak("'$value' not a string")
      unless is_string($value);

    if (defined $self->{meta}->size) {
	$self->_croak("size limit exeeded for string: '$value'")
	  unless length($value) <= $self->{meta}->size;
    }

    $self->{VALUE} = $value;
}


1;
