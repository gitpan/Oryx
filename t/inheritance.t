use lib 't', 'lib';

use Test::More tests => 7;
use Oryx;
use YAML;
use Data::Dumper;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);
#my $storage = Oryx->connect([ "dbi:Pg:dbname=test", 'test', 'test' ]);
#my $storage = Oryx->connect([ "dbm:Deep:datapath=/tmp" ]);

use Child1;

#####################################################################
### SET UP

$storage->deploySchema();
$storage->dbh->commit;

ok($storage->ping);
my $id;

#####################################################################
### TEST

my $child = Child1->create({
    child_attrib1 => 'child attribute',
    parent1_attrib => 'from parent 1',
    parent2_attrib => 'from parent 2',
});

$child->update;
$child->dbh->commit;
$id = $child->id;
$child->remove_from_cache;

my $retrieved = Child1->retrieve($id);

ok($retrieved->parent1_attrib eq 'from parent 1');
ok($retrieved->parent2_attrib eq 'from parent 2');

ok($retrieved->child_attrib1 eq 'child attribute');
ok($retrieved->isa('Parent1'));
ok($retrieved->isa('Parent2'));
ok($retrieved->isa('Child1'));

#####################################################################
### TEAR DOWN

my $dbh = $storage->dbh;
$storage->util->tableDrop($dbh, 'parent1s');
$storage->util->tableDrop($dbh, 'parent2s');
$storage->util->tableDrop($dbh, 'child1s');
$storage->util->tableDrop($dbh, 'child1_parents');
$storage->util->sequenceDrop($dbh, 'parent1s');
$storage->util->sequenceDrop($dbh, 'parent2s');
$storage->util->sequenceDrop($dbh, 'child1s');
$dbh->commit;
