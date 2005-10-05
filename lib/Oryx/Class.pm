package Oryx::Class;

use Carp qw(carp croak);
use UNIVERSAL qw(isa can);
use Scalar::Util qw(weaken);

use base qw(Class::Data::Inheritable);

BEGIN {
    __PACKAGE__->mk_classdata("auto_deploy");

    $XML_DOM_Lite_Is_Available = 1;
    eval "use XML::DOM::Lite qw(Parser Node :constants);";
    $XML_DOM_Lite_Is_Available = 0 if $@;
}

our $DEBUG = 0;
our $PARSER;

sub parser {
    $PARSER = Parser->new unless defined $PARSER;
    $PARSER;
}

our %Orphans;

# Object Cache
our %Live_Objects;

sub init {
    my $class = shift;

    # set up class data accessors :
    $class->mk_classdata("_meta");
    $class->mk_classdata("attributes");
    $class->mk_classdata("associations");
    $class->mk_classdata("methods");
    $class->mk_classdata("parents");

    # DATA section cache
    $class->mk_classdata('dataNode');

    $class->meta({});
    $class->attributes({});
    $class->associations({});
    $class->methods({});
    $class->parents([]);
}

# ... hooks in you, hooks in me, hooks in the ceiling for that
# well-hung feeling... no big deal, no big sin... strung up on love I
# got the hooks screwed in... man, you gotta love Perl (whereas loving
# Iron Maiden is optional, of course).
sub import {
    my $class = shift;
    my %param = @_;

    $DEBUG>1 && $class->_carp("importing...");

    return if $class eq __PACKAGE__
        or $class eq 'Oryx::MetaClass'
        or $class =~ /Oryx::[^:]+::Class/;

    return if $class->can('_meta') and %{$class->attributes};

    if (can($class, 'storage') and $class->storage) {
	if (%Orphans) {
	    $class->storage->schema->addClass($_)
                foreach keys %Orphans;
	    %Orphans = ();
	}
	$class->storage->schema->addClass($class);
    } else {
        $DEBUG && $class->_carp("no storage available Orphaning");
	$Orphans{$class}++;
        return;
    }

    # initialise class data
    $class->init;
    $DEBUG && $class->_carp("setting up...");

    # first set up parent relationships (this doesn't *have* to be
    # done first, but I believe that the chicken came before the
    # egg... the are, as always, good semantic and performance reasons
    # behind this belief... if not behind this particular fragment of
    # code being here instead of at the bottom of this function).
    foreach (@{$class.'::ISA'}) {
	# only if the superclass is a subclass of Oryx::DBx::Class
	if (isa($_, __PACKAGE__)
        and $_ ne __PACKAGE__
        and $_ !~ /Oryx::[^:]+::Class/) {
	    $class->addParent($_);
	}
    }

    my $schema;
    if ($schema = ${$class.'::schema'}) {
	foreach (@{$schema->{attributes}}) {
	    $class->addAttribute($_);
	}
	foreach (@{$schema->{associations}}) {
	    $class->addAssociation($_);
	}
	foreach (@{$schema->{methods}}) {
	    $class->addMethod($_);
	}
    }
    elsif ($schema = $class->parseDataIO) {
	foreach (@{$schema->childNodes}) {
	    if ($_->nodeType & 1) { # ELEMENT_NODE
		if ($_->tagName eq "Class") {
		    $class->generate($_);
		}
	    }
	}
    }
    else {
	# assume that we're adding members explicitly
    }

    if ($class->auto_deploy) {
	unless ($class->storage->util->tableExists(
        $class->dbh, $class->table)) {
	    $class->storage->deployClass($class);
	}
    }
}

sub meta {
    my $class = shift;
    $class->_meta(shift) if @_;
    $class->_meta;
}

# this is used when you've got your schema in the DATA section of the
# module. XML::DOM::Lite needs to be present.
sub generate {
    my ($class, $nclass) = @_;

    $class->meta($nclass->attributes);

    foreach my $member (@{$nclass->childNodes}) {
	if ($member->nodeType & 1) { # ELEMENT_NODE
	    if ($member->tagName eq "Attribute") {
		$class->addAttribute($member->attributes);
	    }
	    elsif ($member->tagName eq "Association") {
		$class->addAssociation($member->attributes);
	    }
	    elsif ($member->tagName eq "Method") {
		$class->addMethod($member->attributes);
	    }
	}
    }

    return $class;
}

sub construct {
    my ($class, $proto) = @_;

    my $object;
    my $key = $class->_mk_cache_key($proto->{id});
    return $object if ($object = $Live_Objects{$key});

    $object = bless $proto, $class;
    $_->construct($object) foreach $class->members;

    weaken($Live_Objects{$key} = $object);
    return $object;
}

sub addAttribute {
    my ($class, $meta) = @_;
    my $attrib =
        (ref($class->storage).'::Attribute')->new($meta, $class);
    $class->attributes->{$attrib->name} = $attrib;
}

sub addAssociation {
    my ($class, $meta) = @_;
    my $assoc =
        (ref($class->storage).'::Association')->new($meta, $class);
    $class->associations->{$assoc->role} = $assoc;
}

sub addMethod {
    my ($class, $meta) = @_;
    my $methd =
        (ref($class->storage).'::Method')->new($meta, $class);
    $class->methods->{$methd->name} = $methd;
}

sub addParent {
    my ($class, $super) = @_;
    push @{$class->parents},
        (ref($class->storage).'::Parent')->new($super, $class);
}

sub id { $_[0]->{id} }

sub is_abstract {
    my $class = shift;
    return not %{$class->attributes};
}

sub table {
    my $class = shift;

    unless (defined $class->meta->{table}) {
	$class->meta->{table} = $class->schema->prefix.$class->name;
	# this is getting out of hand...
	if ($class->meta->{table} =~ /s$/) {
	    $class->meta->{table} .= 'es';
	} elsif ($class->meta->{table} =~ /[^p]h$/) {
	    $class->meta->{table} .= 'es';
	} elsif ($class->meta->{table} =~ /y$/) {
	    $class->meta->{table} =~ s/([^aeiou])y$/$1ies/;
	} else {
	    $class->meta->{table} .= 's';
	}
    }
    $class->meta->{table};
}

sub name {
    my $class = shift;
    unless (defined $class->getMetaAttribute("name")) {
	$class =~ /([^:]+)$/;
	$class->setMetaAttribute("name", lc("$1"));
    }
    $class->getMetaAttribute("name");
}

sub members {
    my $class = shift;
    return (
        values %{$class->attributes},
	values %{$class->associations},
	values %{$class->methods},
        # not really members, but we'll treat the same
	@{$class->parents},
    );
}

sub commit { $_[0]->dbh->commit }

sub schema { $_[0]->storage->schema }

sub parseDataIO {
    my ($class) = @_;
    unless ($XML_DOM_Lite_Is_Available) {
	$class->_carp('XML DATA schemas are not supported unless'
		      .' you have XML::DOM::Lite installed');
	return undef;
    }
    return $class->dataNode if $class->dataNode;
    my $stream = $class->loadDataIO;
    if ($stream) {
	$class->parser->rootNode(my $stub = Node->new({
	    tagName => 'stub',
	    nodeType => ELEMENT_NODE,
        }));
        $class->parser->parseNamespace($stream, "");
	$class->dataNode($stub);
        return $stub;
    } else {
	return undef;
    }
}

sub loadDataIO {
    my $class = shift;
    my $fh = *{"$class\::DATA"}{IO};
    return undef unless $fh;
    local $/ = undef;
    my $stream = <$fh>;
    return $stream;
}

sub remove_from_cache {
    my $self = shift;
    my $key = $self->_mk_cache_key($self->id);
    CORE::delete( $Live_Objects{$key} );
}

sub _mk_cache_key {
    my $class = ref($_[0]) || $_[0];
    my $id = $_[1];
    return join('|', ( $class, $id ));
}

sub _carp {
    my $thing = ref($_[0]) ? ref($_[0]) : $_[0];
    carp("[$thing] $_[1]");
}

sub _croak {
    my $thing = ref($_[0]) ? ref($_[0]) : $_[0];
    croak("[$thing] $_[1]");
}

sub DESTROY { $_[0]->remove_from_cache }

1;
__END__

=head1 NAME

Oryx::Class - abstract base class for Oryx classes

=head1 SYNOPSIS
 
 see Oryx for details on creating classes and defining meta data
 
=head1 METHODS

=over

=item B<create>

=item B<retrieve>

=item B<update>

=item B<delete>

=item B<search>

=item B<commit>

=back

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENCE

This library is free software and may be used under the same terms as Perl itself.

=cut
