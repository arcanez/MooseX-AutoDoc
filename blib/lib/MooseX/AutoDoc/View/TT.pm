package MooseX::AutoDoc::View::TT;

use Moose;
use Scalar::Util qw/blessed/;
use Template;

extends 'MooseX::AutoDoc::View';

has _tt     => (is => 'ro', isa => 'Template', lazy_build => 1);
has '+args' => (isa => 'HashRef');

sub _build__tt {
  my $self = shift;
  Template->new($self->has_args ? $self->args : {})
    || confess $Template::ERROR;
}

has role_template   => (is => 'rw', isa => 'Str', lazy_build => 1);
has class_template  => (is => 'rw', isa => 'Str', lazy_build => 1);

has role_template_blocks  => (is => 'rw', isa => 'HashRef', lazy_build => 1);
has class_template_blocks => (is => 'rw', isa => 'HashRef', lazy_build => 1);

sub _build_role_template  { "[% USE wrap; PROCESS role_block;  %]" }
sub _build_class_template { "[% USE wrap; PROCESS class_block; %]" }

sub render_role {
  my ($self, $vars, $options) = @_;
  my $tt = $self->_tt;
  my $output;
  my $template = $self->role_template. " ".$self->_role_blocks;
  $tt->process(\ $template, $vars, \ $output, %{ $options || {}})
    || confess $tt->error;
  return $output;
}

sub render_class {
  my ($self, $vars, $options) = @_;
  my $tt = $self->_tt;
  my $output;
  my $template = $self->class_template. " ".$self->_class_blocks;
  $tt->process(\ $template, $vars, \ $output, %{ $options || {}})
    || confess $tt->error;
  return $output;
}


sub _class_blocks {
  my $self= shift;
  my $blocks = $self->class_template_blocks;
  return join "",
    map { " [%- BLOCK ${_} %] ".$blocks->{$_}." [% END; -%] "}
      keys %$blocks;
}

sub _role_blocks {
  my $self= shift;
  my $blocks = $self->role_template_blocks;
  return join "",
    map { " [%- BLOCK ${_} %] ".$blocks->{$_}." [% END; -%] "}
      keys %$blocks;
}

1;

sub _build_class_template_blocks{
  my $blocks = {};
  $blocks->{name_block} = q^
=head1 NAME

[% class.name %]
^;

  $blocks->{synopsys_block} = q^
=head1 SYNOPSYS

    use [% class.name %];
    #TODO
    [% class.name %]->new();
^;

  $blocks->{description_block} = q^
=head1 DESCRIPTION

[%- IF class.superclasses.size == 1 %]
[% 'This class is a subclass of L<' _ class.superclasses.first.name _'>' _
' and inherits all it\'s methods and attributes.' FILTER wrap(80,'','') %]

[%- ELSIF class.superclasses.size > 1 %]
This class is a subclass of the following classes and inherits all their
methods and attributes;

=over 4
[%- FOREACH superclass = class.superclasses %]

=item L<[% superclass.name %]>
[%- END %]

=back

[%- END -%]
^;

  $blocks->{roles_consumed_block} = q^
[%- IF class.roles.size %]
=head1 ROLES CONSUMED

The following roles are consumed by this class. Unless otherwise indicated, all
methods, modifiers and attributes present in those roles are applied to this
class.

=over 4
[% FOREACH role_consumed = class.roles;
     PROCESS role_consumed_block;
   END %]
=back
[% END -%]
^;

  $blocks->{role_consumed_block} = q^
=item L<[% role_consumed.name %]>
^;

  $blocks->{attributes_block} = q^
[%- IF class.attributes.size %]
=head1 ATTRIBUTES

Unless noted otherwise, you may set any of these attributes at C<new> time by
passing key / value pairs to C<new> where the key is the name of the attribute
you wish to set. Unless noted otherwise accessor methods for attributes also
share the same name as the attribute.
[%
  FOREACH attribute = class.attributes;
    PROCESS attribute_block;
  END;
END;
-%]
^;

 $blocks->{attribute_block} = q^
=head2 [% attribute.name %]
[%- IF attribute.info.size %]

=over 4
[% FOREACH pair IN attribute.info.pairs %]
=item B<[% pair.key %]> - [% pair.value %]
[% END %]
=back
[%- END; %]

[% attribute.description FILTER wrap(80, '',''); %]
^;

 $blocks->{methods_block} = q^
=head1 METHODS

=head2 new $key => $value

Instantiate a new object. Please refer to L</"ATTRIBUTES"> for a list of valid
key options.
[%
  FOREACH method = class.methods;
    PROCESS method_block;
  END;
%]
=head2 meta

Retrieve the metaclass instance. Please see L<Moose::Meta::Class> and
L<Class::MOP::Class> for more information.
^;

  $blocks->{method_block} = q^
=head2 [% method.name %]

Description of [% method.name %]
^;

  $blocks->{authors_block} = q^
=head1 AUTHORS
[%
  FOREACH author = authors;
    PROCESS author_block;
  END;
-%]
^;

  $blocks->{author_block} = q^
[%
IF author.name.length;         author.name _ ' ';  END;
IF author.handle.length; '(' _ author.name _ ') '; END;
IF author.email.length;  '<' _ author.email _ '>'; END;
%]
^;

  $blocks->{license_block} = q^
=head1 COPYRIGHT AND LICENSE

[% license FILTER wrap(80, '', '') %]
^;

  $blocks->{class_block} = q^
[%
PROCESS name_block;
PROCESS synopsys_block;
PROCESS description_block;
PROCESS roles_consumed_block;
PROCESS attributes_block;
PROCESS methods_block;
PROCESS authors_block;
PROCESS license_block;
%]
=cut
^;

  return $blocks;
}

sub _build_role_template_blocks{
  my $blocks = {};

  $blocks->{name_block} = q^
=head1 NAME

[% role.name %]
^;

  $blocks->{synopsys_block} = q^
=head1 SYNOPSYS

    use Moose;
    with '[% role.name %]';
^;

  $blocks->{description_block} = q^
=head1 DESCRIPTION

When consumed, this role will apply to the consuming class all the methods,
method modifiers, and attributes it is composed of.
^;

  $blocks->{roles_consumed_block} = q^
[%- IF role.roles.size %]
=head1 ROLES CONSUMED

The following roles are consumed by this role. Unless otherwise indicated, all
methods, modifiers and attributes present in those roles will also be applied
to any class or role consuming this role.

=over 4
[% FOREACH role_consumed = role.roles;
     PROCESS role_consumed_block;
   END %]
=back
[% END -%]
^;

  $blocks->{role_consumed_block} = q^
=item L<[% role_consumed.name %]>
^;

  $blocks->{attributes_block} = q^
[%- IF role.attributes.size %]
=head1 ATTRIBUTES

Unless noted otherwise, you may set any of these attributes on consuming
classes at C<new()> time by passing key / value pairs to C<new> where the key
is the name of the attribute you wish to set. Unless noted otherwise accessor
methods for attributes also share the same name as the attribute.
[%
  FOREACH attribute = role.attributes;
    PROCESS attribute_block;
  END;
END;
-%]
^;

 $blocks->{attribute_block} = q^
=head2 [% attribute.name %]
[%- IF attribute.info.size %]

=over 4
[% FOREACH pair IN attribute.info.pairs %]
=item B<[% pair.key %]> -   [% pair.value %]
[% END %]
=back
[%- END; %]

[% attribute.description FILTER wrap(80, '',''); %]
^;

 $blocks->{methods_block} = q^
=head1 METHODS
[%
  FOREACH method = role.methods;
    PROCESS method_block;
  END;
%]
=head2 meta

Retrieve the role metaclass instance. Please see L<Moose::Meta::Role>;
^;

  $blocks->{method_block} = q^
=head2 [% method.name %]

Description of [% method.name %]
^;

  $blocks->{authors_block} = q^
=head1 AUTHORS
[%
  FOREACH author = authors;
    PROCESS author_block;
  END;
-%]
^;

  $blocks->{author_block} = q^
[%
IF author.name.length; author.name _ ' '; END;
IF author.handle.length; '(' _ author.name _ ') '; END;
IF author.email.length; '<' _ author.email _ '> '; END;
%]
^;

  $blocks->{license_block} = q^
=head1 COPYRIGHT AND LICENSE

[% license FILTER wrap(80, '', '') %]
^;

  $blocks->{role_block} = q^
[%
PROCESS name_block;
PROCESS synopsys_block;
PROCESS description_block;
PROCESS roles_consumed_block;
PROCESS attributes_block;
PROCESS methods_block;
PROCESS authors_block;
PROCESS license_block;
%]
=cut
^;

  return $blocks;
}

1;

__END__;
