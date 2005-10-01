package Oryx::Association::Hash;

use base qw(Oryx::Association);

our $DEBUG = 0;

sub new {
    my ($class, $proto) = @_;
    return bless $proto, $class;
}

sub load  { $_[0]->_croak('abstract') }
sub fetch { $_[0]->_croak('abstract') }
sub store { $_[0]->_croak('abstract') }

#=============================================================================
# TIE MAGIC
sub TIEHASH {
    my ($class, $meta, $owner) = @_;

    my $self = bless {
	meta    => $meta,  # first Association instance via 'new'
	owner   => $owner, # the object instance which owns this Value
        created => { },
        deleted => { },
        updated => { },
    }, $class;

    return $self;
}

sub HASH {
    my $self = shift;
    unless (defined $self->{HASH}) {
	$self->{HASH} = $self->{meta}->load($self->{owner});
    }
    $self->{HASH};
}

sub FETCH {
    my ($self, $key) = @_;
    my $retval = $self->{meta}->fetch($self->HASH->{$key}, $self->{owner});
    return $retval;
}

sub STORE {
    my ($self, $key, $thing) = @_;
    unless (exists $self->HASH->{$key}) {
	$self->_set_created($key, $thing);
    } else {
	$self->_set_updated($key, $thing);
    }
    $self->HASH->{$key} = $self->{meta}->store($thing, $self->{owner});
}

sub DELETE {
    my ($self, $key) = @_;
    my $thing = delete $self->HASH->{$key};
    $self->_set_deleted($key, $thing);
    return $thing;
}

sub CLEAR {
    my $self = shift;
    while (my ($key, $thing) = each %{$self->HASH}) {
	$self->DELETE($key);
    }
}

sub EXISTS {
    my ($self, $key) = @_;
    return exists $self->HASH->{$key};
}

sub FIRSTKEY {
    my $self = shift;
    my $a = keys %{$self->HASH};          # reset each() iterator
    each %{$self->HASH};
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    return each %{$self->HASH};
}

sub SCALAR {
    my $self = shift;
    return scalar(%{$self->HASH});
}

sub created { $_[0]->{created} = $_[1] if $_[1]; $_[0]->{created} };
sub updated { $_[0]->{updated} = $_[1] if $_[1]; $_[0]->{updated} };
sub deleted { $_[0]->{deleted} = $_[1] if $_[1]; $_[0]->{deleted} };

# try to keep the database operations to a minimum...
sub _set_deleted {
    my ($self, $key, $thing) = @_;
    delete $self->updated->{$key} if $self->updated->{$key};
    if ($self->created->{$key}) {
	delete $self->created->{$key};
    } else {
	$self->deleted->{$key} = $thing;
    }
}

sub _set_created {
    my ($self, $key, $thing) = @_;
    if ($self->deleted->{$key}) {
	$self->updated->{$key} = $thing;
	delete $self->deleted->{$key};
    } else {
	$self->created->{$key} = $thing;
    }
}

sub _set_updated {
    my ($self, $key, $thing) = @_;
    delete $self->deleted->{$key} if $self->deleted->{$key};
    if ($self->created->{$key}) {
	$self->created->{$key} = $thing;
    } else {
	$self->updated->{$key} = $thing;
    }
}

1;
