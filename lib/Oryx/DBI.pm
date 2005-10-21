package Oryx::DBI;

use Oryx::DBI::Class;

use base qw(Oryx Oryx::MetaClass Ima::DBI);

our $DEBUG = 1;

sub new {
    my $class = shift;
    return bless { }, $class;
}

sub connect {
    my ($self, $conn, $schema) = @_;

    eval "use $schema"; $self->_croak($@) if $@;

    my $db_name = $schema->name;

    ref($self)->set_db($db_name, @$conn)
        unless UNIVERSAL::can($self, "db_$db_name");

    $self->init('Oryx::DBI::Class', $conn, $schema);
    return $self;
}

sub dbh {
    my $class = shift;
    my $db_name = $class->db_name;
    eval { $class->$db_name };
    $class->_croak($@) if $@;
    return $class->$db_name();
}

sub db_name {
    my $self = shift;
    return "db_".$self->schema->name;
}

sub ping {
    my $self = shift;
    my $sth = $self->dbh->prepare('SELECT 1+1');
    $sth->execute;
    $sth->finish;
}

sub schema {
    my $self = shift;
    $self->{schema} = shift if @_;
    $self->{schema};
}

sub util {
    my $self = shift;
    $self->{util} = shift if @_;
    $self->{util};
}

sub set_util {
    my ($self, $dsn) = @_;
    $dsn =~ /^dbi:(\w+)/i;
    my $utilClass = __PACKAGE__."\::Util\::$1";

    eval "use $utilClass";
    $self->_croak($@) if $@;

    $self->util($utilClass->new);
}

sub deploySchema {
    my ($self, $schema) = @_;
    $schema = $self->schema unless defined $schema;

    $DEBUG && $self->_carp(
	"deploySchema $schema : classes => "
        .join(",\n", $schema->classes)
    );

    foreach my $class ($schema->classes) {
	$self->deployClass($class);
    }
}

sub deployClass {
    my $self = shift;
    my $class = shift;
    $DEBUG && $self->_carp("DEPLOYING $class");

    eval "use $class"; $self->_croak($@) if $@;

    my $dbh   = $class->dbh;
    my $table = $class->table;

    my $int = $self->util->type2sql('Integer');
    my $oid = $self->util->type2sql('Oid');

    my @columns = ('id');
    my @types   = ($oid);
    if ($class->is_abstract) {
	push @columns, '_isa';
	push @types, $self->util->type2sql('String');
    }

    foreach my $attrib (values %{$class->attributes}) {
	push @columns, $attrib->name;
	push @types, $attrib->as_sql;
    }

    foreach my $assoc (values %{$class->associations}) {
	my $targetClass = $assoc->class;
	eval "use $targetClass"; $self->_croak($@) if $@;
	if ($assoc->type ne 'Reference') {
	    # create a link table
	    my $lt_name = $assoc->link_table;
	    my @lt_cols = $assoc->link_fields;
	    my @lt_types = ($int) x 2;

	    # set up the meta column (3rd entry in @lt_cols) to store
	    # indicies or keys depeding on the type of Association
	    if (lc($assoc->type) eq 'array') {
		push @lt_types, $int;
	    }
	    elsif (lc($assoc->type) eq 'hash') {
		push @lt_types, $self->util->type2sql('String');
	    }

	    $self->util->tableCreate(
                $dbh, $lt_name, \@lt_cols, \@lt_types
            );
	}
        elsif (not $assoc->is_weak) {
	    push @types,   $int;
	    push @columns, $targetClass->table."_id";
	}
    }

    if (@{$class->parents}) {
	my @lt_cols  = (lc($class->name.'_id'));
	my @lt_types = ($int) x (scalar(@{$class->parents}) + 1);
	my $lt_name  = lc($class->name."_parents");
	push @lt_cols, map { lc($_->class->name) } @{$class->parents};

	$DEBUG && $self->_carp(
            "PARENT $_, lt_name => $lt_name, lt_cols => "
	    .join("|", @lt_cols).", lt_types => "
	    .join("|", @lt_types));

	# create the link table
	$self->util->tableCreate(
            $dbh, $lt_name, \@lt_cols, \@lt_types
        );
    }

    $self->util->tableCreate($dbh, $table, \@columns, \@types);
    $self->util->sequenceCreate($dbh, $table);

    $dbh->commit;
}

1;
