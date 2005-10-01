package Oryx::Value::Integer;
use base qw(Oryx::Value);

use Data::Types qw(is_int to_int);

sub FETCH {
    my $self = shift;
    return to_int($self->{VALUE});
}

sub STORE {
    my ($self, $value) = @_;
    $self->_croak("'$value' is not an integer") unless is_int($value);
    $self->{VALUE} = $value;
}

1;
