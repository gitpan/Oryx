package Oryx::Value::Boolean;
use base qw(Oryx::Value);

sub STORE {
    my ($self, $value) = @_;
    $self->_croak("'$value' not a boolean") unless $value =~ /^[01]$/;
    $self->{VALUE} = $value;
}

sub FETCH {
    my ($self) = @_;
    return +($self->{VALUE});
}

1;
