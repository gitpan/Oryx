use lib 't', 'lib';

use Test::More tests => 12;
use Oryx;
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
warn "CONN =======> ".YAML::Dump($conn);
my $storage = Oryx->connect($conn);

use ArrayClass;
use Class1;
use Class2;

$storage->deploySchema();
$storage->dbh->commit;

ok($storage->ping);

my $arrayclass = ArrayClass->create({attrib =>'cheese' });
ok($arrayclass);

my $class1_1 = Class1->create({attrib1 => 'thing1_1'});
ok($class1_1);

my $class1_2 = Class1->create({attrib1 => 'thing1_2'});
ok($class1_2);

my $class2_1 = Class2->create({attrib1 => 'thing2_1'});
ok($class2_1);

my $class2_2 = Class2->create({attrib1 => 'thing2_2'});
ok($class2_2);

push @{$arrayclass->array1}, $class1_1, $class1_2;
is(scalar(@{$arrayclass->array1}), 2);
is($arrayclass->array1->[0]->id, $class1_1->id);
is($arrayclass->array1->[1]->id, $class1_2->id);

push @{$arrayclass->array2}, $class2_1, $class2_2;
is(scalar(@{$arrayclass->array1}), 2);
is($arrayclass->array1->[0]->id, $class2_1->id);
is($arrayclass->array1->[1]->id, $class2_2->id);

$arrayclass->update;
$arrayclass->commit;

my $retrieved = ArrayClass->retrieve($arrayclass->id);

my $dbh = $storage->dbh;
$storage->util->tableDrop($dbh, 'class1s');
$storage->util->tableDrop($dbh, 'class2s');
$storage->util->tableDrop($dbh, 'arrayclasses');
$storage->util->tableDrop($dbh, 'arrayclasses_array1_class1s');
$storage->util->tableDrop($dbh, 'arrayclasses_array2_class2s');
$storage->util->sequenceDrop($dbh, 'class1s');
$storage->util->sequenceDrop($dbh, 'class2s');
$storage->util->sequenceDrop($dbh, 'arrayclasses');
$dbh->commit;

