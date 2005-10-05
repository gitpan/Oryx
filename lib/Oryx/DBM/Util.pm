package Oryx::DBM::Util;

use File::Spec;
use DBM::Deep;

sub new {
    my $class = shift;
    return bless { }, $class;
}

sub tableExists {
    my ($self, $dbm, $table) = @_;
    return -e File::Spec->catfile($dbm->datapath, $table);
}

sub tableCreate {
    my ($self, $dbm, $table) = @_;
    my $filename = File::Spec->catfile($dbm->datapath, $table);
    $dbm->catalog->put( $table, {
	file    => $filename,
	type    => DBM::Deep::TYPE_ARRAY,
	#locking => 1,
    });
}

sub tableDrop {
    my ($self, $dbm, $table) = @_;
    my $meta = $dbm->catalog->get( $table );
    return unless $meta; # not defined for link tables
    unlink $meta->{file};
    $dbm->catalog->delete( $table );
}

sub sequenceDrop {
    my ($self, $dbm, $table) = @_;
}

1;
