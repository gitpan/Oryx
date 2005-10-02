use lib 't', 'lib';

use Test::More tests => 25;
use Oryx;
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

#my $storage = Oryx->connect([ "dbi:Pg:dbname=test", 'test', 'test' ]);
#my $storage = Oryx->connect([ "dbm:Deep:datapath=/tmp" ]);

use AssocClass;
use HashClass;
use Class1;
use Class2;

#####################################################################
### SET UP

$storage->deploySchema();
$storage->dbh->commit;

ok($storage->ping);
my $id;

#####################################################################
### Reference

my $owner = AssocClass->create({attrib1 => 'foo'});
my $referree = Class2->create({attrib1 => 'referree'});
$owner->assoc2($referree);
$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;

my $retrieved = AssocClass->retrieve($id);
ok($retrieved->assoc2->attrib1 eq 'referree');

#####################################################################
### ARRAY BASIC

my $thing1 = Class1->create({attrib1 => 'foo'});
my $thing2 = Class1->create({attrib1 => 'bar'});
my $thing3 = Class1->create({attrib1 => 'baz'});

$owner = AssocClass->create({
    attrib1 => 'this class has an Array Assocition with TestClass'
});
push @{$owner->assoc1}, $thing1;
push @{$owner->assoc1}, $thing2;
push @{$owner->assoc1}, $thing3;

$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;
$retrieved = AssocClass->retrieve($id);

ok($retrieved->assoc1->[0]->attrib1 eq 'foo');
ok($retrieved->assoc1->[1]->attrib1 eq 'bar');
ok($retrieved->assoc1->[2]->attrib1 eq 'baz');

#####################################################################
### ARRAY POP

$thing1 = Class1->create({attrib1 => 'foo'});
$thing2 = Class1->create({attrib1 => 'bar'});
$thing3 = Class1->create({attrib1 => 'baz'});

$owner = AssocClass->create({
    attrib1 => 'this class has an Array Assocition with Class1'
});
push @{$owner->assoc1}, $thing1;
push @{$owner->assoc1}, $thing2;
push @{$owner->assoc1}, $thing3;

$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;
$retrieved = AssocClass->retrieve($id);

my $popped1 = pop @{$retrieved->assoc1};
my $popped2 = pop @{$retrieved->assoc1};
my $popped3 = pop @{$retrieved->assoc1};

ok(not scalar @{$retrieved->assoc1});

ok($popped1->id eq $thing3->id);
ok($popped2->id eq $thing2->id);
ok($popped3->id eq $thing1->id);

#####################################################################
### ARRAY SHIFT

$thing1 = Class1->create({attrib1 => 'foo'});
$thing2 = Class1->create({attrib1 => 'bar'});
$thing3 = Class1->create({attrib1 => 'baz'});

$owner = AssocClass->create({
    attrib1 => 'this class has an Array Assocition with Class1'
});
push @{$owner->assoc1}, $thing1;
push @{$owner->assoc1}, $thing2;
push @{$owner->assoc1}, $thing3;

$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;
$retrieved = AssocClass->retrieve($id);

my $shifted1 = shift @{$retrieved->assoc1};
my $shifted2 = shift @{$retrieved->assoc1};
my $shifted3 = shift @{$retrieved->assoc1};

ok(not scalar @{$retrieved->assoc1});

ok($shifted1->id eq $thing1->id);
ok($shifted2->id eq $thing2->id);
ok($shifted3->id eq $thing3->id);

#####################################################################
### ARRAY SPLICE

$thing1 = Class1->create({attrib1 => 'foo'});
$thing2 = Class1->create({attrib1 => 'bar'});
$thing3 = Class1->create({attrib1 => 'baz'});

$owner = AssocClass->create({
    attrib1 => 'this class has an Array Assocition with Class1'
});
push @{$owner->assoc1}, $thing1;
push @{$owner->assoc1}, $thing2;
push @{$owner->assoc1}, $thing3;

$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;

$retrieved = AssocClass->retrieve($id);
my $splice_in1 = Class1->create({attrib1 => 'in1'});
my $splice_in2 = Class1->create({attrib1 => 'in2'});

my ($splice_out) = splice @{$retrieved->assoc1}, 1, 1, ($splice_in1, $splice_in2);

ok($splice_out->id eq $thing2->id);
ok(scalar @{$retrieved->assoc1} eq 4);

ok($retrieved->assoc1->[0]->id eq $thing1->id);
ok($retrieved->assoc1->[1]->id eq $splice_in1->id);
ok($retrieved->assoc1->[2]->id eq $splice_in2->id);
ok($retrieved->assoc1->[3]->id eq $thing3->id);

#####################################################################
### ARRAY Delete Composition

$thing1 = Class1->create({attrib1 => 'foo'});
$thing2 = Class1->create({attrib1 => 'bar'});
$thing3 = Class1->create({attrib1 => 'baz'});

$owner = AssocClass->create({
    attrib1 => 'this class has an Array Assocition with Class1'
});
push @{$owner->assoc1}, $thing1;
push @{$owner->assoc1}, $thing2;
push @{$owner->assoc1}, $thing3;

$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;

$retrieved = AssocClass->retrieve($id);

my ($thing1_id, $thing2_id, $thing3_id) =
    ($thing1->id, $thing2->id, $thing3->id);

$retrieved->delete;
my $deleted1 = Class1->retrieve($thing1_id);
my $deleted2 = Class1->retrieve($thing2_id);
my $deleted3 = Class1->retrieve($thing3_id);

ok(not defined $deleted1);
ok(not defined $deleted2);
ok(not defined $deleted3);

#####################################################################
### HASH

$thing1 = Class1->create({attrib1 => 'foo'});
$thing2 = Class1->create({attrib1 => 'bar'});
$thing3 = Class1->create({attrib1 => 'baz'});

$owner = HashClass->create({
    attrib1 => 'this class has a Hash Assocition with Class1'
});

$owner->assoc2->{$thing1->attrib1} = $thing1;
$owner->assoc2->{$thing2->attrib1} = $thing2;
$owner->assoc2->{$thing3->attrib1} = $thing3;

$owner->update;
$owner->commit;
$id = $owner->id;
undef $owner;
$retrieved = HashClass->retrieve($id);

ok($retrieved->assoc2->{foo}->id eq $thing1->id);
ok($retrieved->assoc2->{bar}->id eq $thing2->id);
ok($retrieved->assoc2->{baz}->id eq $thing3->id);


#####################################################################
### TEAR DOWN

my $dbh = $storage->dbh;
$storage->util->tableDrop($dbh, 'assocclasses');
$storage->util->tableDrop($dbh, 'assocclasses_assoc1_class1s');
$storage->util->tableDrop($dbh, 'class1s');
$storage->util->tableDrop($dbh, 'class2s');
$storage->util->tableDrop($dbh, 'hashclasses');
$storage->util->tableDrop($dbh, 'hashclasses_assoc2_class1s');
$storage->util->sequenceDrop($dbh, 'assocclasses');
$storage->util->sequenceDrop($dbh, 'class1s');
$storage->util->sequenceDrop($dbh, 'class2s');
$storage->util->sequenceDrop($dbh, 'hashclasses');
$dbh->commit;

