package Oryx::Value::Text;
use base qw(Oryx::Value);

use Data::Types qw(is_string to_string);

sub check_type {
    my ($self, $value) = @_;
    return is_string($value);
}

1;
