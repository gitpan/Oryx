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

    $self->STORE($self->owner->{$self->meta->name});
    return $self;
}

sub FETCH {
    my $self = shift;
    unless (defined $self->VALUE) {
	my $value = $self->owner->{$self->meta->name};
	$self->VALUE($self->inflate($value));
    }
    return $self->VALUE;
}

sub STORE {
    my ($self, $value) = @_;
    if ($self->check($value)) {
	$self->VALUE($value);
    } else {
	$self->_croak('check failed ['.$value.'] MESSAGE: '.$self->errstr);
    }
}

sub VALUE {
    my $self = shift;
    $self->{VALUE} = shift if @_;
    return $self->{VALUE};
}

# hook to modify the value before it is stored in the db
sub deflate {
    my ($self, $value) = @_;
    return $value
}

# hook to modify the value as it is loaded from the db
sub inflate {
    my ($self, $value) = @_;
    return $value;
}

# hook for checking the value before it is set
sub check {
    my ($self, $value) = @_;
    unless ($self->check_required($value)) {
	$self->errstr('value required');
	return 0;
    }
    if (defined $value) {
	unless ($self->check_type($value)) {
	    $self->errstr('type mismatch');
	    return 0;
	}
	unless ($self->check_size($value)) {
	    $self->errstr('size mismatch');
	    return 0;
	}
    }
    return 1;
}

sub check_type {
    my ($self, $value) = @_;
    return 1;
}

sub check_size {
    my ($self, $value) = @_;
    return 1;
}

sub check_required {
    my ($self, $value) = @_;
    if ($self->meta->required) {
	return defined $value;
    } else {
	return 1;
    }
}

sub errstr {
    my $self = shift;
    $self->{errstr} = shift if @_;
    return $self->{errstr};
}

sub meta  { $_[0]->{meta}  }

sub owner { $_[0]->{owner} }

sub _croak {
    my ($self, $msg) = @_;
    $self->{owner}->_croak("<".$self->{meta}->name."> $msg");
}

sub _carp {
    my ($self, $msg) = @_;
    $self->{owner}->_carp("<".$self->{meta}->name."> $msg");
}

1;
__END__

=head1 NAME

Oryx::Value - abstract base class for Oryx value types

=head1 SYNOPSIS

 see Oryx documentation for supported value types and what they do

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENCE

This library is free software and may be used under the same terms as Perl itself.

=cut
