use inc::Module::Install;

name('Oryx');
author('Richard Hundt <richard@protea-systems.com>');
abstract('Orthogonal Object Persistence');
license('artistic');
version_from('lib/Oryx.pm');
build_requires('Test::More');

requires(qw(
    perl 5.6.1
    DBI
    YAML
    Class::Data::Inheritable
    Class::Date
    SQL::Abstract
    Ima::DBI
    DBM::Deep
    Data::Types
));

check_nmake();
&WriteAll();
