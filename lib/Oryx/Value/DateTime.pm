package Oryx::Value::DateTime;

use base qw(Oryx::Value);
use Class::Date qw(:errors date);

sub STORE {
    my ($self, $value) = @_;
    local $Class::Date::DATE_FORMAT = $self->format;

    my $date;
    unless (UNIVERSAL::isa($value, 'Class::Date')) {
	$date = date($value);
    } else {
	$date = $value;
    }
    if ($date->error == E_INVALID) {
	$self->_croak($date->errstr);
    }

    $self->{VALUE} = "$date";
}

sub FETCH {
    my $self = shift;
    local $Class::Date::DATE_FORMAT = $self->format;

    unless ($self->{VALUE}) {
	$self->STORE($self->{owner}->{$self->{meta}->name});
    }

    return date($self->{VALUE});
}

sub format {
    my $self = shift;
    unless (defined $self->{format}) {
	$self->{format} = $self->{meta}->getMetaAttribute('format')
	  || "%d-%m-%Y";
    }
    return $self->{format};
}

1;
