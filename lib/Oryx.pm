package Oryx;

use Carp qw(carp croak);
use UNIVERSAL qw(isa can);
use Oryx::Class;

our $VERSION = '0.11';
our $DEBUG = 0;

sub new { croak("abstract") }

sub import {
    my $class = shift;
    my %param = @_;
    if (defined $param{auto_deploy}) {
	Oryx::Class->auto_deploy($param{auto_deploy});
    }
}

sub init {
    my ($self, $Class, $conn, $schema) = @_;

    $DEBUG && $self->_carp("SCHEMA => $schema, Class => $Class");
    unless (ref($schema) and isa($schema, 'Oryx::Schema')) {
        $schema = 'Oryx::Schema' unless $schema;
	eval "use $schema"; croak($@) if $@;
	$schema = $schema->new;
	$DEBUG && $self->_carp("new schema instance => $schema");
    }

    $self->schema($schema);
    $self->set_util($conn->[0]); # $dsname

    push @Oryx::Class::ISA, $Class;
    $self->Class($Class);
    $self->Class->storage($self);

    if (%Oryx::Class::Orphans) {
	foreach (keys %Oryx::Class::Orphans) {
	    eval { Oryx::Class::import($_) };
	    $_->_carp($@) if $@;
	    $schema->addClass($_);
	}
	%Oryx::Class::Orphans = ();
    }
}

sub connect {
    my ($class, $conn, $schema) = @_;
    $schema = 'Oryx::Schema' unless $schema;

    # determine the type of storage we're using from the dsn
    my $storage;
    if ($conn->[0] =~ /^dbm:/) {
        eval 'use Oryx::DBM'; $class->_croak($@) if $@;
	$storage = Oryx::DBM->new;
    } else {
        eval 'use Oryx::DBI'; $class->_croak($@) if $@;
	$storage = Oryx::DBI->new;
    }

    $storage->connect($conn, $schema);
    return $storage;
}

sub Class { $_[0]->{Class} = $_[1] if $_[1]; $_[0]->{Class} }

# delegate to the actual implementing storage class
sub deploySchema {
    my ($self, $schema) = @_;
    $self->Class->storage->deploySchema($schema);
}

sub _carp {
    my $class = ref $_[0] || $_[0];
    carp("[".$class."] $_[1]");
}

sub _croak {
    my $class = ref $_[0] || $_[0];
    croak("[".$class."] $_[1]");
}

1;

__END__

=head1 NAME

Oryx - Meta-Model Driven Object Persistance with Multiple Inheritance

=head1 SYNOPSIS

 #===========================================================================
 # connect to storage
 $storage = Oryx->connect(['dbi:Pg:dbname=cms', $usname, $passwd]);
 
 # or specify a schema
 $storage = Oryx->connect(
    ["dbi:Pg:dbname=cms", $usname, $passwd], 'CMS::Schema'
 );
 
 # for DBM::Deep back-end
 Oryx->connect(['dbm:Deep:datapath=/path/to/data'], 'CMS::Schema');

 #===========================================================================
 # deploy the schema
 $storage->deploySchema();              # for all known classes (via `use')
 $storage->deploySchema('CMS::Schema');
 $storage->deployClass('CMS::Page');
 
 # automatically deploy as needed
 use Oryx ( auto_deploy => 1 );           # for all classes
 CMS::Page->auto_deploy(1);             # only for this class
 
=head1 DESCRIPTION

Oryx is an Object Persistence framework which supports both object-relational
mapping as well as DMB style databases and as such is not coupled to any
particular storage back-end. In other words, you should be able to
swap out an RDMBS with a DBM style database (and vice versa) without
changing your persistent classes at all.

This is achieved with the use a meta model which fits in as closely
with Perl's own as possible - and due to Perl's excellent
introspection capabilities and enormous flexibility - this is very
close indeed. For this reason Hash, Array and Reference association
types are implemented with liberal use of `tie'. The use of a meta
model, albeit a very transparent one, conceptually supports the
de-coupling of storage back-end from persistent classes, and, for the
most part, beside a really small amout of meta-data, you would use
persistent classes in a way that is virtually indistinguishable from
ordinary perl classes.

=head1 INTRODUCTION

This documentation applies to classes persisted in L<DBM::Deep> style
storage as well except insofar as the implementation details are
concerned where tables and columns are mentioned - separate files are
used for L<DBM::Deep> based storage instead of tables (see
L<Oryx::DBM> for details).

This is still a very early release and only supports L<DBM::Deep>, MySQL
and Postgres back-ends at the moment. Having said this, however, Oryx is
already quite usable. It needs to be thrashed a lot more and support
for the rest of the popular RDBMS needs to be added. Things will
change (for the better, one hopes); if you're interested in helping to
precipitate that change... let me know, you'd be most welcome.

=head1 OVERVIEW

The documentation is in the process of being divided up between the
different components:

=over

=item L<Oryx::Class>

Contains the details for defining persistent classes and how to use them.
Read this first.

=item L<Oryx::Association>

Describes Associations meta-types in more detail.

=item L<Oryx::Attribute>

Explains Attribute meta-types.

=item L<Oryx::Parent>

All about Inheritance in Oryx.

=item L<Oryx::Value>

A description of our DB friendly primitive types.

=item L<Oryx::Manual::Guts>

Oryx meta-model and internals for developers.

=back

=head1 CONNECTING TO STORAGE

The call to Oryx->connect(...) specifies the dsn and connection
credentials to use when connecting where applicable. For DBM::Deep
style storage, the connection arguments look like this:

 Oryx->connect(['dbm:Deep:datapath=/path/to/data'], 'CMS::Schema');

For RDBMS (Postgres in this case) it may look like this:

 Oryx->connect(["dbi:Pg:dbname=cms", $usname, $passwd], 'CMS::Schema');

The Schema defaults to 'Oryx::Schema' and is therefore optional, so we
could say Oryx->connect([ ... dsn ... ]), and forget about passing in
a Schema.

One advantage to using separate Schema classes is that this gives you
namespace separation where you need to connect several sets of classes
to different storage back ends (especially where these are mixed in
such a way where the same classes exist in different stores). Another
advantage is that the Schema class may define a B<prefix> method which
simply returns a string to prefix table names with, for those of us
who only get a single database with our hosting package and need to
have some namespace separation.

Here's an example of a Schema class :

 package CMS::Schema;
 use base qw(Oryx::Schema);
 
 sub prefix { 'cms' }
 
 1;

=head1 TODO

=over

=item B<test test test>

Tests are a bit sparse at the moment.

=item B<Support for Oracle, etc.>

Only MySQL, PostgreSQL SQLite and DBM::Deep are supported currently.
It should be fairly trivial to add support for the other RDBMS'

=item B<More documentation>

=back

=head1 BUGS

I'm sure there are some... if I had more tests, I know I'd find 'em

=head1 ACKNOWLEDGEMENTS

Special thanks to:

=over 4

=item I<Sam Vilain>

For educating me about meta-models, feedback and for hosting the
subversion repository.

=item I<Andrew Sterling Hanenkamp>

For bug reports and patches, and his ongoing help with documentation,
tests and good suggestions.

=over

=head1 SEE ALSO

L<Class::DBI>, L<Tangram>, L<Class::Tangram>, L<SQL::Abstract>,
L<Class::Data::Inheritable>, L<Data::Types>, L<DBM::Deep>, L<DBI>,
L<ImA::DBI>

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENSE

Oryx may be used under the same terms as Perl itself.

=cut
