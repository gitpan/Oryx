package Oryx::Schema;

use base qw(Class::Data::Inheritable);

=head1 NAME

Oryx::Schema - Schema class for Oryx

=head1 SYNOPSIS

  package CMS::Schema;
 
  # enable auto deploy for all classes 
  use Oryx::Class(auto_deploy => 1);
   
  # useful if you want to say $storage->deploySchema('CMS::Schema');
  use CMS::Page;
  use CMS::Paragraph;
  use CMS::Image;
  use CMS::Author;
   
  sub prefix { 'cms' }

  1;
   
  use CMS::Schema;
   
  my $cms_storage = Oryx->connect(\@conn, 'CMS::Schema'); 
  CMS::Schema->addClass('CMS::Revision');
  my @cms_classes = CMS::Schema->classes;
  $cms_storage->deploySchema();                 # deploys only classes seen by CMS::Schema
  $cms_storage->deploySchema('CMS::Schema')     # same thing, but `use's CMS::Schema first
  my $name = CMS::Schema->name;                 # returns CMS_Schema
  CMS::Schema->hasClass($classname);            # true if seen $classname
  

=head1 DESCRIPTION

Schema class for Oryx.

The use of this class is optional.

The intention is to allow arbitrary grouping of classes
into different namespaces to support simultaneous use of
different storage backends, or for having logically separate
groups of classes in the same database, but having table
names prefixed to provide namespace separation.

=cut

__PACKAGE__->mk_classdata('_classes');

sub new {
    my $class = shift;
    $class->_classes({ }) unless defined $class->_classes;
    return bless { }, $class;
}

sub name {
    my $name = ref $_[0] ? ref $_[0] : $_[0];
    $name =~ s/::/_/g;
    return $name;
}

sub prefix { '' }

sub classes {
    keys %{$_[0]->_classes};
}

sub addClass {
    my ($self, $class) = @_;
    $self->_classes->{$class}++;
}

sub hasClass {
    return $_[0]->_classes->{$_[1]};
}

1;

=head1 SEE ALSO

L<Oryx>, L<Oryx::Class>

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENSE

This library is free software and may be used under the same terms as Perl itself.

=cut
