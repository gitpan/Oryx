package Oryx::Schema;

use base qw(Class::Data::Inheritable);

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
    return defined $_[0]->_classes->{$_[1]};
}

sub getClass {
    return $_[0]->_classes->{$_[1]};
}

1;
