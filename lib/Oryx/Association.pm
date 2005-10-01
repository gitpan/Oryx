package Oryx::Association;

use base qw(Oryx::MetaClass);

sub new {
    my ($class, $meta, $source) = @_;

    my $type_class = $class.'::'.$meta->{type};
    eval "use $type_class"; $class->_croak($@) if $@;

    my $self = $type_class->new({
	meta   => $meta,
	source => $source,
    });

    eval 'use '.$self->class;
    $self->_croak($@) if $@;

    no strict 'refs';
    *{$source.'::'.$self->role} = $self->_mk_accessor;

    return $self;
}

sub create    { $_[0]->_croak("abstract") }
sub retrieve  { $_[0]->_croak("abstract") }
sub update    { $_[0]->_croak("abstract") }
sub delete    { $_[0]->_croak("abstract") }
sub search    { $_[0]->_croak("abstract") }
sub construct { $_[0]->_croak("abstract") }

sub _mk_accessor {
    my $assoc = shift;
    my $assoc_name = $assoc->role;
    return sub {
	my $self = shift;
	$self->{$assoc_name} = shift if @_;
	$self->{$assoc_name};
    };
}

sub source {
    my $self = shift;
    $self->{source};
}

sub class {
    my $self = shift;
    unless (defined $self->{class}) {
	$self->{class} = $self->getMetaAttribute("class");
    }
    $self->{class};
}
sub role {
    my $self = shift;
    unless (defined $self->{role}) {
	unless ($self->{role} = $self->getMetaAttribute("role")) {
	    # set some sensible defaults for creating the accessor
	    $self->{role} = $self->class->table;
	    if ($self->type eq 'Reference') {
		# singular, so drop the last 's' or 'es' (the latter
		# only if the penultimate 's' is not preceded by a
		# vowel)... so that a name like 'houses' does not
		# become 'hous' ... and so forth
		if ($self->{role} =~ /[^aeiou]ses$/) {
		    $self->{role} =~ s/es$//;
		} elsif ($self->{role} =~ /hes$/) {
		    $self->{role} =~ s/es$//;
		} else {
		    $self->{role} =~ s/s$//;
		}
	    }
	}
    }
    $self->{role};
}

# Reference, Array or Hash... defaults to Reference.
sub type {
    my $self = shift;
    unless (defined $self->{type}) {
	$self->{type} = $self->getMetaAttribute("type")
	  || 'Reference';
    }
    $self->{type};
}

# Aggregate, Composition ... Aggregate is the default,
# Composition does a cascading delete.
sub constraint {
    my $self = shift;
    unless (defined $self->{constraint}) {
	$self->{constraint} = $self->getMetaAttribute("constraint")
	  || 'Aggregate';
    }
    $self->{constraint};
}

sub update_backrefs {
    my ($self, $obj, @things) = @_;
    # update backrefs
    if ($self->class->can($self->source->name)) {
	my $backref = $self->source->name;
	foreach (@things) {
	    $_->$backref($obj);
	    $_->update;
	}
    }
}

sub link_table {
    my $self = shift;
    return $self->source->table.'_'.$self->role.'_'.$self->class->table;
}

1;

__END__

=head1 NAME

Association - 

=head1 SYNOPSIS

 <Schema name="CMS">
   <Class name="Page">
     <Attribute name="title" type="String" size="255" />
     <Association name="template" target="Template" type="Reference" />
     <Association target="Template" constraint="Inheritance" />
   </Class>
   <Class name="Template">
     <Association target="Section" type="Array" constraint="Composition" />
   </Class>
   <Class name="Section">
     <Association target="Template" type="Reference" />
   </Class>
 </Schema>

=head1 DESCRIPTION

The key difference between Attributes and Associations is that
Associations use Reference types. Associations with One multiplicity
have a single reference, otherwise you get an Array of Reference types
or a Hash of Reference types depending on the schema
definition. Reference types are distinguished by the fact that they
always point to instances of the same (target) class. The constraint
MetaAttribute (Aggregate, Composition or Inheritance) determines
whether updates and deletes cascade or not.

The 'name' meta-attribute is optional for Associations in general and
meaningless for Associations with Inheritance constraints. If not
present, an accessor is created with the name set to that of the
target Class' table name (which is a simple automatic pluralisation of
the Class' name by the 'table' accessor in the target Class). If the
Association is a 'Reference' type and the 'name' meta-attribute is not
present, then an accessor is created for the Association by
sigularising (stripping a trailing 's' off) the target Class's table
name.

=cut

