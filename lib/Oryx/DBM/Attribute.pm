package Oryx::DBM::Attribute;

use Oryx::Value;

use base qw(Oryx::Attribute);

sub create {
    my ($self, $proto) = @_;
    my $attr_name = $self->name;
    $proto->{$attr_name} = $self->typeClass->deflate($proto->{$attr_name});
}

sub update {
    my ($self, $proto, $object) = @_;
    my $attr_name = $self->name;
    my $value = $object->$attr_name;
    $proto->{$attr_name} = $self->typeClass->deflate($value);
}

1;
