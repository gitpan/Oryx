package Oryx::DBI::Attribute;

use Oryx::Value;

use base qw(Oryx::Attribute);

sub create {
    my ($self, $query, $param) = @_;
    my $attr_name = $self->name;
    $param->{$attr_name} = $self->typeClass->deflate($param->{$attr_name});
}

sub retrieve {
    my ($self, $query, $values) = @_;
    push @{$query->{fields}}, $self->name;
}

sub update {
    my ($self, $query, $object) = @_;
    my $attr_name = $self->name;
    my $value = $object->$attr_name;
    $query->{fieldvals}->{$attr_name} = $self->typeClass->deflate($value);
}

sub search {
    my ($self, $query) = @_;
    push @{$query->{fields}}, $self->name;
}

sub as_sql {
    my $self = shift;
    return $self->{owner}->storage->util->type2sql(
        $self->type, $self->size
    );
}

1;
