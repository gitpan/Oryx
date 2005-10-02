package Oryx::DBI::Util::mysql;

use base qw(Oryx::DBI::Util);

our %SQL_TYPES = (
    'Oid'       => 'bigint PRIMARY KEY',
    'Integer'   => 'bigint',
    'Reference' => 'bigint',
    'String'    => 'varchar',
    'Text'      => 'text',
    'Complex'   => 'text',
    'Binary'    => 'blob',
    'Float'     => 'float',
    'Boolean'   => 'tinyint',
    'DateTime'  => 'datetime',
);

sub new { return bless { }, $_[0] };

sub type2sql {
    my ($self, $type, $size) = @_;
    my $sql_type = $SQL_TYPES{$type};
    if ($type eq 'String') {
	$size ||= '255';
	$sql_type .= "($size)";
    } elsif ($type eq 'Integer' and defined $size) {
	$sql_type .= "($size)";
    }
    return $sql_type;
}

sub columnExists {
    my ($self, $dbh, $table, $column) = @_;
    my $esc = $dbh->get_info( 14 );
    $table  =~ s/([_%])/$esc$1/g;
    $column =~ s/([_%])/$esc$1/g;
    my $sth = $dbh->column_info('%', '%', $table, $column);
    $sth->execute();
    my @rv = @{$sth->fetchall_arrayref};
    $sth->finish;
    return @rv;
}

sub columnCreate {
    my ($self, $dbh, $table, $colname, $coltype) = @_;
    my $sth = $dbh->prepare(<<"SQL");
ALTER TABLE $table ADD COLUMN $colname $coltype;
SQL
    $sth->execute;
    $sth->finish;
}

sub columnDrop {

}

sub tableExists {
    my ($self, $dbh, $table) = @_;
    my $esc = $dbh->get_info( 14 );
    my $_table  =~ s/([_%])/$esc$1/g;
    my $sth = $dbh->table_info('%', '%', $_table);
    $sth->execute();
    my @rv = @{$sth->fetchall_arrayref};
    $sth->finish;
    return grep { $_->[2] eq $table } @rv;
}

sub tableCreate {
    my ($self, $dbh, $table, $columns, $types) = @_;

    my $sql = <<"SQL";
CREATE TABLE $table (
SQL

    if (defined $columns and defined $types) {
	for (my $x = 0; $x < @$columns; $x++) {
	    $sql .= '  '.$columns->[$x].' '.$types->[$x];
	    $sql .= ($x != $#$columns) ? ",\n" : "\n";
	}
    }

    $sql .= <<SQL;
);
SQL

    my $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->finish;
}

sub tableDrop {
    my ($self, $dbh, $table) = @_;
    my $sql = "DROP TABLE $table";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

# hmm... will I ever get around to figuring this one out?
sub sequenceExists {

}

sub sequenceCreate {
    my ($self, $dbh, $table) = @_;

    unless ($self->tableExists($dbh, 'oryx_sequences')) {
	$self->tableCreate($dbh, 'oryx_sequences', ['name', 'value'], ['VARCHAR(255)', 'BIGINT']);
	$self->indexCreate($dbh, 'oryx_sequences', 'name');
    }

    my $sql = "INSERT INTO oryx_sequences VALUES ('".$self->_seq_name($table)."', 0)";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub sequenceDrop {
    my ($self, $dbh, $table) = @_;
    my $sql = "DELETE FROM oryx_sequences WHERE name='".$self->_seq_name($table)."'";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub indexCreate {
    my ($self, $dbh, $table, $field) = @_;
    my $sql = "CREATE INDEX ".$field."_index ON $table ($field)";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub indexDrop {

}

sub nextval {
    my ($self, $dbh, $table) = @_;
    my $sth = $dbh->prepare_cached("UPDATE oryx_sequences SET value=(value + 1) WHERE name=?");
    $sth->execute($self->_seq_name($table));
    $sth->finish;

    $sth = $dbh->prepare_cached("SELECT value FROM oryx_sequences WHERE name=?");
    $sth->execute($self->_seq_name($table));
    my $id = $sth->fetch->[0];
    $sth->finish;
    return $id;
}

sub _seq_name {
    my ($self, $table) = @_;
    return $table."_id_seq";
}

1;
