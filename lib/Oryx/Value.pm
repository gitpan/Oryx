package Oryx::Value;

use Oryx::Value::Binary;
use Oryx::Value::Boolean;
use Oryx::Value::Complex;
use Oryx::Value::DateTime;
use Oryx::Value::Float;
use Oryx::Value::Integer;
use Oryx::Value::String;
use Oryx::Value::Text;

# These Value types are here to do the getting, setting and validation
# so that the Attribute doesn't need to worry about what type it
# is... the Attribute should be no more than a symbol (name)
# associated with a Value instance.

# The constructor is passed the associated Attribute (or Association)
# instance which can be accessed via the `owner' mutator

sub primitive { 'SCALAR' }

sub TIESCALAR {
    my $class = shift;
    my ($meta, $owner) = @_;
    my $self = bless {
	meta  => $meta,  # Oryx::Attribute instance
	owner => $owner, # Oryx::Class instance
    }, $class;

    return $self;
}

sub FETCH {
    my $self = shift;
    return $self->{VALUE};
}

sub STORE {
    my ($self, $value) = @_;
    $self->{VALUE} = $value;
}

sub _croak {
    my ($self, $msg) = @_;
    $self->{owner}->_croak("<".$self->{meta}->name."> $msg");
}

sub _carp {
    my ($self, $msg) = @_;
    $self->{owner}->_carp("<".$self->{meta}->name."> $msg");
}

1;
