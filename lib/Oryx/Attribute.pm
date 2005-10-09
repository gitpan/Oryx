package Oryx::Attribute;

use base qw(Oryx::MetaClass);

sub new {
    my ($class, $meta, $owner) = @_;
    my $self = bless {
	owner => $owner,
	meta  => $meta,
    }, $class;

    eval 'use '.$self->typeClass;
    $self->_croak($@) if $@;

    no strict 'refs';
    *{$owner.'::'.$self->name} = $self->_mk_accessor;

    return $self;

}

sub create    { }
sub retrieve  { }
sub update    { }
sub delete    { }
sub search    { }

sub construct {
    my ($self, $obj) = @_;

    my $attr_name = $self->name;
    $obj->{$attr_name} = $self->typeClass->inflate($obj->{$attr_name});

    my @args = ($self, $obj);
    tie $obj->{$attr_name}, $self->typeClass, @args;

    return $obj;
}

sub name {
    my $self = shift;
    return $self->getMetaAttribute("name");
}

sub type {
    my $self = shift;
    $self->getMetaAttribute("type") || 'String';
}

sub size {
    my $self = shift;
    return $self->getMetaAttribute("size");
}

sub required {
    my $self = shift;
    return $self->getMetaAttribute('required');
}

sub primitive {
    my $self = shift;
    return $self->typeClass->primitive;
}

sub typeClass {
    my $self = shift;
    return 'Oryx::Value::'.$self->type;
}

sub _mk_accessor {
    my $attrib = shift;
    my $attrib_name = $attrib->name;
    return sub {
	my $self = shift;
	$self->{$attrib_name} = shift if @_;
	$self->{$attrib_name};
    };
}

1;
