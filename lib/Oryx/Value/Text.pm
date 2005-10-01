package Oryx::Value::Text;
use base qw(Oryx::Value);

use Data::Types qw(is_string to_string);

sub STORE {
    my ($self, $value) = @_;
    $self->_croak("'$value' is not Text")
      unless is_string($value);
    $self->{VALUE} = to_string($value);
}

sub FETCH {
    my $self = shift;
    unless ($self->{VALUE}) {
	$self->STORE($self->{owner}->{$self->{meta}->name});
    }
    return to_string($self->{VALUE});
}

1;
