package Oryx::MetaClass;

# okay, so it's not really a meta-class in the true sense since it
# doesn't get instantiated. Instead, it gets subclassed, but we use
# inheritable class data to achieve the same effect. This is 
# because we're not trying to create our own meta-model so much as
# trying to squeeze a relational data model into Perl's in-built
# meta-model.  Subclassing this via Perl's inheritance mechanism
# preserves class state as if the sub class were a Class instance of a
# MetaClass (which it is, just not this one... Perl's). There is
# meta-data associated with the class which is in the form of a DOM
# Node which was used to define the schema in the first place (and
# which is passed into the constructor of whichever entity derives
# from this class).

use Carp qw(carp croak cluck);
use base qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata("storage");
__PACKAGE__->mk_classdata("schema");

sub create    { }
sub retrieve  { }
sub update    { }
sub delete    { }
sub search    { }
sub construct { }

sub meta {
    my $class = shift;
    $class->{meta} = shift if @_;
    $class->{meta};
}

sub setMetaAttribute {
    my ($class, $key, $value) = @_;
    $class->meta->{$key} = $value;
}

sub getMetaAttribute {
    my ($class, $key) = @_;
    unless ($class->meta) {
	cluck("$class has no meta");
    }
    return $class->meta->{$key};
}

sub _carp {
    my $thing = ref($_[0]) ? ref($_[0]) : $_[0];
    carp("[$thing] $_[1]");
}

sub _croak {
    my $thing = ref($_[0]) ? ref($_[0]) : $_[0];
    croak("[$thing] $_[1]");
}

1;
