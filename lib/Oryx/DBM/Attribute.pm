package Oryx::DBM::Attribute;

use Oryx::Value;

use base qw(Oryx::Attribute);

sub update {
    my ($self, $proto, $object) = @_;
    my $attr_name = $self->name;
    if (ref tied($object->{$attr_name})
    eq 'Oryx::Value::Complex') {
	$proto->{$attr_name} =
            tied($object->{$attr_name})->dump;
    } else {
	$proto->{$attr_name} = $object->$attr_name;
    }
}

1;
