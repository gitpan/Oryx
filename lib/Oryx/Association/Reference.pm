package Oryx::Association::Reference;

use base qw(Oryx::Association);

sub new {
    my ($class, $proto) = @_;
    return bless $proto, $class;
}

#=============================================================================
# TIE MAGIC
sub id { $_[0]->{oid} }

# meta in this case is a reference to the owning Association instance
sub TIESCALAR {
    my $class = shift;
    my ($meta, $idOrObject) = @_;

    my $self = bless {
        meta    => $meta,
        oid     => ref($idOrObject) ? $idOrObject->id : $idOrObject,
        changed => 0,
    }, $class;

    eval "use ".$meta->class; $self->_croak($@) if $@;
    return $self;
}

sub STORE {
    my ($self, $object) = @_;
    return unless $object;
    $self->{oid} = $object->id;
    $self->{changed}++;
    $self->{TARGET} = $object;
}

sub FETCH {
    my $self = shift;
    if (defined $self->{oid}) {
	unless (defined $self->{TARGET}) {
	    $self->{TARGET} = $self->{meta}->class->retrieve($self->{oid});
	}
    } else {
	return undef;
    }
    $self->{TARGET};
}

sub changed {$_[0]->{changed} = $_[1] if $_[1]; $_[0]->{changed}}

1;
