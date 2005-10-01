package Oryx::DBI::Association::Hash;

use Oryx::DBI::Association::Reference;

use base qw(Oryx::Association::Hash);

sub create {
    my ($self, $query, $proto) = @_;
}

sub retrieve {
    my ($self, $query, $id) = @_;
}

sub update {
    my ($self, $query, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->$accessor;

    my $sql = SQL::Abstract->new;

    my $lt_name = $self->link_table;
    my @lt_flds = $self->link_fields;

    my (@bind, %lt_fieldvals, %lt_where, $stmnt, $sth);
    if (%{tied(%$value)->deleted}) {
	%lt_where = ($lt_flds[0] => $obj->id, $lt_flds[2] => '');

	$stmnt = $sql->delete($lt_name, \%lt_where);
	$sth   = $obj->dbh->prepare($stmnt);

	while (my ($key, $thing) = each %{tied(%$value)->deleted}) {
	    $lt_where{$lt_flds[2]} = $key;
	    @bind = $sql->values(\%lt_where);
	    $sth->execute(@bind);
	}

	$sth->finish;
	tied(%$value)->deleted({});
    }

    if (%{tied(%$value)->created}) {
	@lt_fieldvals{@lt_flds} = ($obj->id, '', '');

	$stmnt = $sql->insert($lt_name, \%lt_fieldvals);
	$sth   = $obj->dbh->prepare($stmnt);

	while (my ($key, $thing) = each %{tied(%$value)->created}) {
	    $lt_fieldvals{$lt_flds[1]} = defined $thing ? $thing->id : undef;
	    $lt_fieldvals{$lt_flds[2]} = $key;
	    @bind = $sql->values(\%lt_fieldvals);
	    $sth->execute(@bind);
	}

	$sth->finish;
	tied(%$value)->created({});
    }

    if (%{tied(%$value)->updated}) {
	%lt_where = ( $lt_flds[0] => $obj->id, $lt_flds[2] => '' );
	%lt_fieldvals = ( $lt_flds[1] => '' );

	$stmnt = $sql->update($lt_name, \%lt_fieldvals, \%lt_where);
	$sth   = $obj->dbh->prepare($stmnt);

	while (my ($key, $thing) = each %{tied(%$value)->updated}) {
	    $lt_fieldvals{$lt_flds[1]} = defined $thing ? $thing->id : undef;
	    $lt_where{$lt_flds[2]} = $key;
	    @bind = $sql->values(\%lt_fieldvals);
	    push @bind, $sql->values(\%lt_where);
	    $sth->execute(@bind);
	}

	$sth->finish;
	tied(%$value)->updated({});
    }

    $self->update_backrefs($obj, values %$value);

    $obj->dbh->commit;
}

sub delete {
    my $self = shift;
    my ($query, $obj) = @_;
    my $accessor = $self->role;
    my $value = $obj->$accessor;

    if ($self->constraint eq 'Composition') {
	# composition, so cascade the delete
	foreach my $thing (values %$value) {
	    $thing->delete;
	}
    } elsif ($self->constraint eq 'Aggregation') {
	# aggregation so just clear the Hash
	%$value = ();
    }

    $self->update(@_);
}

sub search {

}

sub construct {
    my ($self, $obj) = @_;
    my $assoc_name = $self->role;
    my @args = ($self, $obj);
    tie my %value, __PACKAGE__, @args;
    $obj->{$assoc_name} = \%value;
}

sub load {
    my ($self, $owner) = @_;

    my $lt_name = $self->link_table;
    my ($source_id, $target_id, $_key) = $self->link_fields;

    my (@fields, %where);
    @fields = ($target_id, $_key);

    $DEBUG && $self->_carp("load : OWNER => $owner, ID => ".$owner->id);

    $where{$source_id} = $owner->id;

    my $sql = SQL::Abstract->new;
    my ($stmnt, @bind) = $sql->select($lt_name, \@fields, \%where);

    my $sth = $owner->dbh->prepare_cached($stmnt);
    $sth->execute(@bind);

    my $Hash = { }; my @args;
    my @ids_keys = $sth->fetchall;
    for (my $x = 0; $x < @ids_keys; $x++) {
	@args = ($self, $ids_keys[$x]->[0]);
	tie $Hash->{$ids_keys[$x]->[1]},
	  'Oryx::DBI::Association::Reference', @args;
    }
    $sth->finish;

    return $Hash;

}

sub fetch {
    my ($self, $thing, $owner) = @_;
    return $thing;
}

sub store {
    my ($self, $thing, $owner) = @_;
    return $thing;
}

sub link_fields {
    my $self = shift;
    return ("source_id", "target_id", '_key');
}

1;
