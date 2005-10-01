package Oryx::DBI::Util::Pg;

use base qw(Oryx::DBI::Util);

our %SQL_TYPES = (
    'Oid'       => 'integer PRIMARY KEY',
    'Integer'   => 'integer',
    'Reference' => 'integer',
    'String'    => 'varchar',
    'Text'      => 'text',
    'Complex'   => 'text',
    'Binary'    => 'bytea',
    'Float'     => 'numeric',
    'Boolean'   => 'boolean',
    'DateTime'  => 'timestamp',
);

sub new { return bless { }, $_[0] };

sub type2sql {
    my ($self, $type, $size) = @_;
    my $sql_type = $SQL_TYPES{$type};
    $sql_type .= "($size)" if defined $size;
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
    my $sth = $dbh->table_info('%', '%', $table);
    my $esc = $dbh->get_info( 14 );
    $table  =~ s/([_%])/$esc$1/g;
    $sth->execute();
    my @rv = @{$sth->fetchall_arrayref};
    $sth->finish;
    return @rv;
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
    my $sql = "CREATE SEQUENCE ".$self->_seq_name($table);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub sequenceDrop {
    my ($self, $dbh, $table) = @_;
    my $sql = "DROP SEQUENCE ".$self->_seq_name($table);
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub indexCreate {
    my ($self, $dbh, $table, $field) = @_;
    my $sql = "CREATE INDEX ".$field."_index ON $table";
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    $sth->finish;
}

sub indexDrop {

}

sub nextval {
    my ($self, $dbh, $table) = @_;
    my $sth = $dbh->prepare_cached("SELECT nextval(?)");
    $sth->execute($self->_seq_name($table)) unless $sth->{Active};
    my $id = $sth->fetch->[0];
    $sth->finish;
    return $id;
}

sub _seq_name {
    my ($self, $table) = @_;
    return $table."_id_seq";
}

1;
