package Oryx::DBI::Util;
use Carp qw(carp croak);

sub _carp {
    my $class = ref($_[0]) ? ref($_[0]) : $_[0];
    carp("[$class] $_[1]");
}

sub _croak {
    my $class = ref($_[0]) ? ref($_[0]) : $_[0];
    croak("[$class] $_[1]");
}

1;
__END__

=head1 NAME

Oryx::DBI::Util - abstract base class for Oryx DBI utilities

=head1 DESCRIPTION

Oryx::DBI::Util represents an interface to be implemented in order
to add support for additional RDBMS'. The following methods must
be implemented:

=head1 METHODS

=over

=item B<columnExists( $dbh, $table, $column )>

=item B<columnCreate( $dbh, $table, $colname, $coltype )>

=item B<columnDrop( $dbh, $table, $colname )>

=item B<tableExists( $dbh, $table )>

=item B<tableCreate( $dbh, $table, \@columns, $type )>

=item B<tableDrop( $dbh, $table )>

=item B<sequenceCreate( $dbh, $table )>

=item B<sequenceDrop( $dbh, $table )>

=item B<indexCreate( $dbh, $table, $field )>

=item B<indexDrop( $dbh, $table, $field )>

=item B<type2sql( $type, $size )>

=item B<nextval( $dbh, $table )>

=back

=head1 AUTHOR

Copyright (C) 2005 Richard Hundt <richard NO SPAM AT protea-systems.com>

=head1 LICENCE

This library is free software and may be used under the same terms as Perl itself.

=cut
