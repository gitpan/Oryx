package Oryx::Value::Complex;

use YAML;

use base qw(Oryx::Value);

sub TIESCALAR {
    my $class = shift;
    my ($meta, $owner) = @_;

    my $self = bless {
	meta  => $meta, # the Attribute instance
	owner => $owner,
    }, $class;

    return $self;
}

sub FETCH {
    my ($self) = @_;
    return $self->VALUE;
}

sub STORE {
    my ($self, $value) = @_;
    $self->{VALUE} = $value;
}

sub VALUE {
    my $self = shift;
    unless (defined $self->{VALUE}) {
	eval { $self->{VALUE} = YAML::Load($self->{owner}->{$self->{meta}->name}) };
    }
    $self->{VALUE};
}

sub dump {
    my $self = shift;
    return YAML::Dump($self->{VALUE});
}

1;
