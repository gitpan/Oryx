package Oryx::Value::Integer;
use base qw(Oryx::Value);

use Data::Types qw(is_int to_int);

sub check_type {
    my ($self, $value) = @_;
    return is_int($value);
}

sub check_size {
    my ($self, $value) = @_;
    if (defined $self->meta->size) {
	return $value <= $self->meta->size;
    }
    return 1;
}

sub inflate {
    my ($self, $value) = @_;
    return to_int($value);
}

sub deflate {
    my ($self, $value) = @_;
    return to_int($value);
}

1;
