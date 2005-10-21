package Oryx::Attribute;

use base qw(Oryx::MetaClass);

=head1 NAME

Oryx::Attribute - Attribute meta-type for Oryx persistent classes

=head1 SYNOPSIS

 my $attrib = Oryx::Attribute->new( \%meta, $owner );

=head1 DESCRIPTION

=head1 METHODS

=over

=item new( $meta, $owner )

=cut

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

=item create

Abstract (see implementing subclasses)

=item retrieve

Abstract (see implementing subclasses)

=item update

Abstract (see implementing subclasses)

=item delete

Abstract (see implementing subclasses)

=item search

Abstract (see implementing subclasses)

=cut

sub create    { }
sub retrieve  { }
sub update    { }
sub delete    { }
sub search    { }

=item construct( $self, $obj )

Inflate the attribute value and C<tie> it to the implementing
Value class, eg: L<Oryx::Value::String>, L<Oryx::Value::Complex>
etc. (see L<perltie>)

=cut

sub construct {
    my ($self, $obj) = @_;

    my $attr_name = $self->name;
    $obj->{$attr_name} = $self->typeClass->inflate($obj->{$attr_name});

    my @args = ($self, $obj);
    tie $obj->{$attr_name}, $self->typeClass, @args;

    return $obj;
}

=item name

returns the C<name> meta-attribute for this attribute. This
is the same as the accessor and the field in the table in which
the value for this attribute is stored.

=cut

sub name {
    my $self = shift;
    return $self->getMetaAttribute("name");
}

=item type

returns the C<type> meta-attribute for this attribute. Defaults
to 'String'.

=cut

sub type {
    my $self = shift;
    $self->getMetaAttribute("type") || 'String';
}

=item size

returns the C<size> meta-attribute for this attribute. This is
the allowed length for the 'String' or size of 'Number' etc. and
is used for input checking by the Value type. No default.

=cut

sub size {
    my $self = shift;
    return $self->getMetaAttribute("size");
}

=item required

returns the value of the C<required> meta-attribute. This has
the effect of raising an error if an instance of the owning
class is constructed without a value for this field defined
in the prototype hash reference which is passed to
C<< Oryx::Class->create( \%proto ) >>. Equivalent to a NOT NULL
constraint.

=cut

sub required {
    my $self = shift;
    return $self->getMetaAttribute('required');
}

=item primitive

returns a string: 'SCALAR', 'ARRAY', or 'HASH' which is defined
in the implementing L<Oryx::Value> meta-type.

=cut

sub primitive {
    my $self = shift;
    return $self->typeClass->primitive;
}

=item typeClass

returns the canonical package name of the implementing
L<Oryx::Value> meta-type for this attribute.

=cut

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

=back

=head1 AUTHOR

Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 THANKS TO

Andrew Sterling Hanencamp

=head1 LICENCE

This module is free software and may be used under the same terms as
Perl itself.

=cut

