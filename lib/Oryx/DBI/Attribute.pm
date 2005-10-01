package Oryx::DBI::Attribute;

use Oryx::Value;

use base qw(Oryx::Attribute);

sub retrieve {
    my ($self, $query, $values) = @_;
    push @{$query->{fields}}, $self->name;
}

sub update {
    my ($self, $query, $object) = @_;
    my $attr_name = $self->name;
    if (ref tied($object->{$attr_name})
    eq 'Oryx::Value::Complex') {
	$query->{fieldvals}->{$attr_name} =
            tied($object->{$attr_name})->dump;
    } else {
	$query->{fieldvals}->{$attr_name} = $object->$attr_name;
    }
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
