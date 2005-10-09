package Oryx::Value::String;
use base qw(Oryx::Value);

use Data::Types qw(is_string to_string);

sub check_size {
    my ($self, $value) = @_;
    if (defined $self->meta->size) {
	return length($value) <= $self->meta->size;
    }
    return 1;
}

sub check_type {
    my ($self, $value) = @_;
    return is_string($value);
}

sub inflate {
    my ($self, $value) = @_;
    return to_string($value);
}

sub deflate {
    my ($self, $value) = @_;
    return to_string($value);
}

1;
