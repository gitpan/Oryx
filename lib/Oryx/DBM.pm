package Oryx::DBM;

use DBM::Deep;
use Oryx::DBM::Class;
use Oryx::DBM::Util;
use Oryx::Class;

use base qw(Oryx Oryx::MetaClass);

__PACKAGE__->mk_classdata("datapath");

sub new {
    my $class = shift;
    return bless { }, $class;
}

sub dbh { $_[0] }
sub commit {  }

# $conn looks like this : ["dbm:Deep:datapath=/path/to/data"]
sub connect {
    my ($self, $conn, $schema) = @_;

    $self->init('Oryx::DBM::Class', $conn, $schema);

    if ($conn->[0] =~ /^dbm:Deep:datapath=(.+)$/) {
        $self->_croak('ERROR: connect called without a datapath')
            unless $1;
        $self->datapath($1);
    } else {
        $self->_croak("ERROR: bad dsn $conn->[0]");
    }

    $self->catalog(DBM::Deep->new($self->datapath.'/oryx_catalog'));

    return $self;
}

sub catalog { $_[0]->{catalog} = $_[1] if $_[1]; $_[0]->{catalog} }

sub ping {
    my $self = shift;
    return UNIVERSAL::isa($self->catalog, 'DBM::Deep');
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
    my $self = shift;
    $self->util( Oryx::DBM::Util->new );
}

sub deploySchema {
    my ($self, $schema) = @_;
    $schema = $self->schema unless defined $schema;

    $DEBUG && $self->_carp(
	"deploySchema $schema : classes => ".join(",\n", $schema->classes)
    );
    unless (-d $self->datapath) {
	mkdir $self->datapath;
    }
    foreach my $class ($schema->classes) {
	$self->deployClass($class);
    }
}

sub deployClass {
    my ($self, $class) = @_;
    $DEBUG && $self->_carp("DEPLOYING $class");
    $self->util->tableCreate($self, $class);
}

1;
