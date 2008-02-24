package MooseX::AutoDoc::View;

use Moose;

has args => (is => 'ro', predicate => 'has_args');

#twi different methods because it really does make more sense this way
sub render_role  { confess "Unimplemented Method"; }
sub render_class { confess "Unimplemented Method"; }

1;

__END__;

=head1 NAME

MooseX::AutoDoc::View

=head1 DESCRIPTION

This is an empty base class for MooseX::AutoDoc views.

=head1 ATTRIBUTES

=head2 args

=over 4

=item B<predicate> - has_args

=back

Optional read-only value. It's use is defined by the subclass.

=head1 METHODS

=head2 new key => $value

Instantiate a new object.

=head2 render_class \%vars, $options

Render the documentation for a class. By default, AutoDoc will pass three
variables, authors, class, license.

=head2 render_role \%vars, $options

Render the documentation for a role. By default, AutoDoc will pass three
variables, authors, class, license.

=head2 meta

Retrieve the metaclass instance. Please see L<Moose::Meta::Class> and
L<Class::MOP::Class> for more information.

=head1 AUTHORS

Guillermo Roditi (groditi) <groditi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
