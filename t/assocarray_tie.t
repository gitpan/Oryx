use lib 't', 'lib';

use Test::More qw(no_plan);
use Oryx;
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use AssocClass (auto_deploy => 1);
use Class1 (auto_deploy => 1);

#####################################################################
### SET UP

ok($storage->ping);
my $id;
my $owner;
my $retrieved;


#####################################################################
### ARRAY TIE

$thing1 = Class1->create({attrib1 => 'foo'});
$thing2 = Class1->create({attrib1 => 'bar'});
$thing3 = Class1->create({attrib1 => 'baz'});

$owner = AssocClass->create({
    attrib1 => 'this class has an Array Assocition with Class1'
});

$owner->update;

push @{$owner->assoc1}, $thing1;
push @{$owner->assoc1}, $thing2;
push @{$owner->assoc1}, $thing3;

$owner->update;
$owner->commit;

$id = $owner->id;
$owner->remove_from_cache();
undef $owner;

$retrieved = AssocClass->retrieve($id);

unshift @{$retrieved->assoc1}, $thing2;
$retrieved->update();

is(scalar(@{$retrieved->assoc1}), 4);

my $popped1 = pop @{$retrieved->assoc1};
my $popped2 = pop @{$retrieved->assoc1};
my $popped3 = pop @{$retrieved->assoc1};
my $popped4 = pop @{$retrieved->assoc1};

ok(not scalar @{$retrieved->assoc1});

ok(defined($thing1));
ok(defined($thing2));
ok(defined($thing3));

ok($popped1->id eq $thing3->id);
ok($popped2->id eq $thing2->id);
ok($popped3->id eq $thing1->id);


#####################################################################
### TEAR DOWN

my $dbh = $storage->dbh;
$storage->util->tableDrop($dbh, 'assocclass');
$storage->util->tableDrop($dbh, 'assocclass_assoc1_class1');
$storage->util->tableDrop($dbh, 'class1');
$storage->util->sequenceDrop($dbh, 'assocclass');
$storage->util->sequenceDrop($dbh, 'class1');
$dbh->commit;

