#vim:set ft=perl:

use lib 't', 'lib';

use Test::More qw(no_plan);
use Oryx;
use Oryx::Class (auto_deploy => 1);
use YAML;

my $conn = YAML::LoadFile('t/dsn.yml');
my $storage = Oryx->connect($conn);

use WeirdName;
use Security::Role;
use Security::Permission;

#####################################################################
### SET UP

ok($storage->ping);

my $weird = WeirdName->create({ attrib1 => 'foo' });
my $role = Security::Role->create({ rolename => 'foo' });
my $perm1 = Security::Permission->create({ permname => 'perm1' });
my $perm2 = Security::Permission->create({ permname => 'perm2' });

$role->my_perms->[0] = $perm1;
$role->my_perms->[1] = $perm2;


