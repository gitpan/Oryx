package Oryx::Value::Float;
use base qw(Oryx::Value);

use Data::Types qw(is_float to_float);

sub check_type {
    my ($self, $value) = @_;
    return is_float($value);
}

sub check_size {
    my ($self, $value) = @_;
    my $p = $self->meta->getMetaAttribute("precision");
    if (defined $p) {
	my $rx = '^\d+\.\d{0,'.$p.'}$';
	return $value =~ /$rx/;
    }
    return 1;
}

1;
