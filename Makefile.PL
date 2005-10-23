use inc::Module::Install;

name('Oryx');
author('Richard Hundt <richard NO SPAM AT protea-systems.com>');
abstract('Object Persistence with Multiple Inheritance');
license('artistic');
version_from('lib/Oryx.pm');
build_requires(qw(
    YAML
    Class::Data::Inheritable
    Class::Date
    DBM::Deep
    Test::More
    Data::Types
    File::Spec
    Module::Pluggable
));

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
    File::Spec
    Module::Pluggable
));

check_nmake();
&WriteAll();
