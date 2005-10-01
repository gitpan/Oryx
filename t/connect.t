use lib 't', 'lib';
use Test::More tests => 1;
use Oryx;

#my $storage = Oryx->connect([ "dbi:Pg:dbname=test", 'test', 'test' ]);
my $storage = Oryx->connect([ "dbm:Deep:datapath=/tmp" ]);

ok($storage->ping);
