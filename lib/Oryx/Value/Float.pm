package Oryx::Value::Float;
use base qw(Oryx::Value);

use Data::Types qw(is_float to_float);

sub FETCH {
    my $self = shift;
    return to_float($self->{VALUE});
}

sub STORE {
    my ($self, $value) = @_;
    $self->_croak("`$value' is not an floating point number")
      unless is_float($value);

    my $p = $self->{meta}->getMetaAttribute("precision");
    if (defined $p) {
	my $rx = '\d+\.\d{0,'.$p.'}';
	$self->_croak("precision mismatch for value '".$value."'")
	  unless $p =~ /$rx/;
    }

    $self->{VALUE} = $value;
}

1;
