package Biber::Entry::Names;

use Data::Dump;

=encoding utf-8

=head1 NAME

Biber::Entry::Names

=head2 new

    Initialize a Biber::Entry::Names object

=cut

sub new {
  my $class = shift;
  return bless [], $class;
}

=head2 names

    Return ref to array of all Biber::Entry::Names objects
    in object

=cut

sub names {
  my $self = shift;
  return $self;
}

=head2 add_element

    Add a Biber::Entry::Name object to the Biber::Entry::Names
    object

=cut

sub add_element {
  my $self = shift;
  my $name_obj = shift;
  push @$self, $name_obj;
  return;
}

=head2 count_elements

    Returns the number of Biber::Entry::Name objects in the object

=cut

sub count_elements {
  my $self = shift;
  return scalar @$self;
}

=head2 nth_element

    Returns the nth Biber::Entry::Name object in the object

=cut

sub nth_element {
  my $self = shift;
  my $n = shift;
  return @$self[$n-1];
}

=head2 first_n_elements

    Returns a new Biber::Entry::Names object containing only
    the first n entries of $self

=cut

sub first_n_elements {
  my $self = shift;
  my $n = shift;
  return bless [ splice(@$self, 0, $n) ], Biber::Entry::Names;
}

=head2 del_last_element

    Deletes the last Biber::Entry::Name object in the object

=cut

sub del_last_element {
  my $self = shift;
  $self = [ pop(@$self) ];
  return;
}

=head2 last_element

    Returns the last Biber::Entry::Name object in the object

=cut

sub last_element {
  my $self = shift;
  return @$self[-1];
}

=head2 dump

    Dump a Biber::Entry::Name object for debugging purposes

=cut

sub dump {
  my $self = shift;
  dd($self);
  return;
}

=head1 AUTHORS

François Charette, C<< <firmicus at gmx.net> >>
Philip Kime C<< <philip at kime.org.uk> >>

=head1 BUGS

Please report any bugs or feature requests on our sourceforge tracker at
L<https://sourceforge.net/tracker2/?func=browse&group_id=228270>.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 François Charette and Philip Kime, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=cut

1;

# vim: set tabstop=2 shiftwidth=2 expandtab: