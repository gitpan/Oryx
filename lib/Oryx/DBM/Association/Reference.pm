package Oryx::DBM::Association::Reference;

use base qw(Oryx::Association::Reference);

sub create {
    my ($self, $proto) = @_;
}

sub retrieve {
    my ($self, $proto, $id) = @_;
    my $f_key = $self->class->table."_id";
    my $f_id  = $proto->{ $f_key };
    $proto->{ $f_key } = $self->class->dbm->get( $f_id )
      if defined $f_id;
}

sub update {
    my ($self, $proto, $obj) = @_;
    my $accessor = $self->role;
    if (tied($obj->{$accessor})->changed) {
	my $f_key = $self->class->table.'_id';
	$proto->{ $f_key } = $obj->$accessor->id;
    }
}

sub delete {
    my $self = shift;
    my ($proto, $obj) = @_;
    if ($self->constraint eq 'Composition') {
	# cascade the delete
	my $accessor = $self->role;
	$obj->$accessor->dbm->delete($obj->id);
    }
    $self->update(@_);
}

sub search {

}

sub construct {
    my ($self, $obj) = @_;
    my $assoc_name = $self->role;
    my @args = ($self, $obj->{$self->class->table.'_id'});
    tie $obj->{$assoc_name}, __PACKAGE__, @args;
}

1;
