package Oryx::DBI::Association::Reference;

use base qw(Oryx::Association::Reference);

sub create {
    my ($self, $query, $proto) = @_;
}

sub retrieve {
    my ($self, $query, $id) = @_;
    push @{$query->{fields}}, $self->role
}

sub search {
    my ($self, $query) = @_;
    push @{$query->{fields}}, $self->role
}

sub update {
    my ($self, $query, $obj) = @_;
    my $accessor = $self->role;
    if (tied($obj->{$accessor})->changed) {
	my $sql = SQL::Abstract->new;

	my $s_table = $self->source->table;
	my $f_key = $self->role;
	my %fieldvals = ();
	my %where = (id => $obj->id);

	$fieldvals{$f_key} = $obj->$accessor->id;
	my ($stmnt, @bind) = $sql->update($s_table, \%fieldvals, \%where);

	my $sth = $obj->dbh->prepare($stmnt);
	$sth->execute(@bind);
	$sth->finish;
    }
}

sub delete {
    my $self = shift;
    my ($query, $obj) = @_;
    if ($self->constraint eq 'Composition') {
	my $accessor = $self->role;
	my $value = $obj->$accessor;
	$value->delete;
    }
    $self->update(@_);
}

sub search {

}

sub construct {
    my ($self, $obj) = @_;
    my $assoc_name = $self->role;
    my @args = ($self, $obj->{$self->role});
    tie $obj->{$assoc_name}, __PACKAGE__, @args;
}

1;
