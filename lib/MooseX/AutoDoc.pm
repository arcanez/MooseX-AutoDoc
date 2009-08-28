package MooseX::AutoDoc;

use Moose;
use Carp;
use Class::MOP;
use Moose::Meta::Role;
use Moose::Meta::Class;
use Scalar::Util qw(blessed);
use List::MoreUtils qw(any);
use namespace::autoclean;

#  Create a special TypeConstraint for the View so you can just set it
# with a class name and it'll DWIM
{
  use Moose::Util::TypeConstraints;

  subtype 'AutoDocView'
    => as 'Object'
      => where { $_->isa('MooseX::AutoDoc::View') }
        => message { "Value should be a subclass of MooseX::AutoDoc::View" } ;

  coerce 'AutoDocView'
    => from  'Str'
      => via { Class::MOP::load_class($_); $_->new };

  no Moose::Util::TypeConstraints;
}

#view object
has view => (is => 'rw', isa => 'AutoDocView', coerce => 1, lazy_build => 1);

#type constraint library to name mapping to make nice links
has tc_to_lib_map => (is => 'rw', isa => 'HashRef', lazy_build => 1);

#method metaclasses to ignore to avoid documenting some methods
has ignored_method_metaclasses => (is => 'rw', isa => 'HashRef', lazy_build => 1);

#defaults to artistic...
has license_text => (is => 'rw', isa => 'Str', lazy_build => 1);

#how can i get the data about the current user?
has authors      => (is => 'rw', isa => 'ArrayRef[HashRef]',
                     predicate => 'has_authors');

sub _build_view { "MooseX::AutoDoc::View::TT" }

sub _build_tc_to_lib_map {
  my %types = map {$_ => 'Moose::Util::TypeConstraints'}
    qw/Any Item Bool Undef Defined Value Num Int Str Role Maybe ClassName Ref
       ScalarRef ArrayRef HashRef CodeRef RegexpRef GlobRef FileHandle Object/;
  return \ %types;
}

sub _build_ignored_method_metaclasses {
  return {
          'Moose::Meta::Method::Accessor'    => 1,
          'Moose::Meta::Method::Constructor' => 1,
          'Class::MOP::Method::Accessor'     => 1,
          'Class::MOP::Method::Generated'    => 1,
          'Class::MOP::Method::Constructor'  => 1,
         };

#          'Moose::Meta::Role::Method'        => 1,
#          'Moose::Meta::Method::Overridden'  => 1,
#          'Class::MOP::Method::Wrapped'      => 1,

}

sub _build_license_text {
  "This library is free software; you can redistribute it and/or modify it "
    ."under the same terms as Perl itself.";
}

#make the actual POD
sub generate_pod_for {
  my ($self, $package, $view_args) = @_;

  carp("${package} is already loaded. This will cause inacurate output.".
       "if ${package} is the consumer of any roles.")
    if Class::MOP::is_class_loaded( $package );

  my $spec = $self->_package_info($package);
  my $key = $package->meta->isa("Moose::Meta::Role") ? 'role' : 'class';
  my $vars = {
              $key    => $spec,
              license => $self->license_text,
              authors => $self->has_authors ? $self->authors : [],
             };
  my $render = "render_${key}";
  return $self->view->$render($vars, $view_args);
}

# *_info methods
sub _package_info {
  my($self, $package) = @_;

  #intercept role application so we can accurately generate
  #method and attribute information for the parent class.
  #this is fragile, but there is not better way that i am aware of
  my $rmeta = Moose::Meta::Role->meta;
  $rmeta->make_mutable if $rmeta->is_immutable;
  my $original_apply = $rmeta->get_method("apply")->body;
  $rmeta->remove_method("apply");
  my @roles_to_apply;
  $rmeta->add_method("apply", sub{push(@roles_to_apply, [@_])});
  #load the package with the hacked Moose::Meta::Role
  eval { Class::MOP::load_class($package); };
  confess "Failed to load package ${package} $@" if $@;

  #get on with analyzing the  package
  my $meta = $package->meta;
  my $spec = {};
  my ($class, $is_role);
  if($package->meta->isa('Moose::Meta::Role')){
    $is_role = 1;
    # we need to apply the role to a class to be able to properly introspect it
    $class = Moose::Meta::Class->create_anon_class;
    $original_apply->($meta, $class);
  } else {
    #roles don't have superclasses ...
    $class = $meta;
    my @superclasses = map{ $_->meta }
      grep { $_ ne 'Moose::Object' } $meta->superclasses;
    my @superclass_specs = map{ $self->_superclass_info($_) } @superclasses;
    $spec->{superclasses} = \@superclass_specs;
  }

  #these two are common to both roles and classes
  my @attributes = map{ $class->get_attribute($_) } sort $class->get_attribute_list;
  my @methods    =
    grep{ ! exists $self->ignored_method_metaclasses->{$_->meta->name} }
      map { $class->get_method($_) }
        grep { $_ ne 'meta' } sort $class->get_method_list;

  my @method_specs     = map{ $self->_method_info($_)    } @methods;
  my @attribute_specs  = map{ $self->_attribute_info($_) } @attributes;

  #fix Moose::Meta::Role and apply the roles that were delayed
  $rmeta->remove_method("apply");
  $rmeta->add_method("apply", $original_apply);
  $rmeta->make_immutable;
  #we apply roles to be able to figure out which ones we are using although I
  #could just cycle through $_->[0] for @roles_to_apply;
  shift(@$_)->apply(@$_) for @roles_to_apply;

  #Moose::Meta::Role and Class have different methods to get consumed roles..
  #make sure we break up composite roles as well to get better names and nicer
  #linking to packages.
  my @roles = sort{ $a->name cmp $b->name }
    map { $_->isa("Moose::Meta::Role::Composite") ? @{ $_->get_roles } : $_ }
      @{ $is_role ? $meta->get_roles : $meta->roles };
  my @role_specs = map{ $self->_consumed_role_info($_) } @roles;

  #fill up the spec
  $spec->{name}       = $meta->name;
  $spec->{roles}      = \ @role_specs;
  $spec->{methods}    = \ @method_specs;
  $spec->{attributes} = \ @attribute_specs;

  return $spec;
}

sub _attribute_info{
  my($self, $attr) = @_;;
  my $attr_name = $attr->name;
  my $spec = { name => $attr_name };
  my $info = $spec->{info} = {};

  $info->{clearer}   = $attr->clearer   if $attr->has_clearer;
  $info->{builder}   = $attr->builder   if $attr->has_builder;
  $info->{predicate} = $attr->predicate if $attr->has_predicate;


  my $description = $attr->is_required ? 'Required ' : 'Optional ';
  if( defined(my $is = $attr->_is_metadata) ){
    $description .= 'read-only '  if $is eq 'ro';
    $description .= 'read-write ' if $is eq 'rw';

    #If we have 'is' info only write out this info if it != attr_name
    $info->{writer} = $attr->writer
      if $attr->has_writer && $attr->writer ne $attr_name;
    $info->{reader} = $attr->reader
      if $attr->has_reader && $attr->reader ne $attr_name;
    $info->{accessor} = $attr->accessor
      if $attr->has_accessor && $attr->accessor ne $attr_name;
  } else {
    $info->{writer} = $attr->writer     if $attr->has_writer;
    $info->{reader} = $attr->reader     if $attr->has_reader;
    $info->{accessor} = $attr->accessor if $attr->has_accessor;
  }
  $info->{'constructor key'} = $attr->init_arg
    if $attr->has_init_arg && $attr->init_arg ne $attr_name;

  if( defined(my $lazy = $attr->is_lazy) ){
    $description .= 'lazy-building ';
  }
  $description .= 'value';
  if( defined(my $isa = $attr->_isa_metadata) ){
    my $link_to;
    if( blessed $isa ){
      my $from_type_lib;
      while( blessed $isa ){
        $isa = $isa->name;
      }
      my @parts = split '::', $isa;
      my $type_name = pop @parts;
      my $type_lib = join "::", @parts;
      if(eval{$type_lib->isa("MooseX::Types::Base")}){
        $link_to = $type_lib;
        $isa = $type_name;
      }
    } else {
      my ($isa_base) = ($isa =~ /^(.*?)(?:\[.*\])?$/);
      if (exists $self->tc_to_lib_map->{$isa_base}){
        $link_to = $self->tc_to_lib_map->{$isa_base};
      }
      my $isa = $isa_base;
    }
    if(defined $link_to){
      $isa = "L<${isa}|${link_to}>";
    }
    $description .= " of type ${isa}";
  }
  if( $attr->should_auto_deref){
    $description .=" that will be automatically dereferenced by ".
      "the reader / accessor";
  }
  if( $attr->has_documentation ){
    $description .= "\n\n" . $attr->documentation;
  }
  $spec->{description} = $description;

  return $spec;
}

sub _superclass_info {
  my($self, $superclass) = @_;
  my $spec = { name => $superclass->name };
  return $spec;
}

sub _method_info {
  my($self, $method) = @_;
  my $spec = { name => $method->name };
  return $spec;
}

sub _consumed_role_info {
  my($self, $role) = @_;;
  my $spec = { name => $role->name };
  return $spec;
}

1;

__END__;

=head1 NAME

MooseX::AutoDoc - Automatically generate documentation for Moose-based packages

=head1 SYNOPSIS

    use MooseX::AutoDoc;
    my $autodoc = MooseX::AutoDoc->new
      (
       authors =>
        [
         {
          name => "Guillermo Roditi",
          email => 'groditi@cpan.org',
          handle => "groditi",
         }
        ],
      );

    my $class_pod = $autodoc->generate_pod_for("MyClass");
    my $role_pod  = $autodoc->generate_pod_for("MyRole");

=head1 DESCRIPTION

MooseX::AutoDoc allows you to automatically generate POD documentation from
your Moose based objects by introspecting them and creating a POD skeleton
with extra information where it can be infered through the MOP.

=head1 NOTICE REGARDING ROLE CONSUMPTION

To accurantely detect which methods and attributes are part of the class / role
being examined and which are part of a consumed role the L</"generate_pod_for">
method need to delay role consumption. If your role or class has been loaded
prior to calling these methods you run a risk of recieving inacurate data and
a warning will be emitted. This is due to the fact that once a role is applied
there is no way to tell which attributes and methods came from the class and
which came from the role.

=head1 ATTRIBUTES

Unless noted otherwise, you may set any of these attributes at C<new> time by
passing key / value pairs to C<new> where the key is the name of the attribute
you wish to set. Unless noted otherwise accessor methods for attributes also
share the same name as the attribute.

=head2 authors

=over 4

=item B<predicate> - has_authors

=back

Optional read-write value of type
L<ArrayRef[HashRef]|Moose::Util::TypeConstraints> representing the authors of
the class / role being documented. These values are passed directly to the view
and the default TT view accepts entries in the following form
(all fields optional)

  {
   name   => 'Guillermo Roditi',
   handle => 'groditi',
   email  => '<groditi@gmail.com>',
  }

=head2 ignored_method_metaclasses

=over 4

=item B<builder> - _build_ignored_method_metaclasses

Default to the Moose and Class::MOP method metaclasses for generated methods,
accessors, and constructors.

=item B<clearer> - clear_ignored_method_metaclasses

=item B<predicate> - has_ignored_method_metaclasses

=back

Required read-write lazy-building value of type
L<HashRef|Moose::Util::TypeConstraints> where the keys are method metaclasses
MooseX::AutoDoc should ignore when creating a method list.

=head2 license_text

=over 4

=item B<builder> - _build_license_text

=item B<clearer> - clear_license_text

=item B<predicate> - has_license_text

=back

Required read-write lazy-building value of type
L<Str|Moose::Util::TypeConstraints>. By default it will use the following text:

    This library is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

=head2 tc_to_lib_map

=over 4

=item B<builder> - _build_tc_to_lib_map

=item B<clearer> - clear_tc_to_lib_map

=item B<predicate> - has_tc_to_lib_map

=back

Required read-write lazy-building value of type
L<HashRef|Moose::Util::TypeConstraints>. The keys refer to type constraint
names and the values to the module where the documentation available for that
type is. Please note that if you are using MooseX::Types libraries the links
will be automatically generated if the library class can be found (most cases).

=head2 view

=over 4

=item B<builder> - _build_view

Returns 'MooseX::AutoDoc::View::TT'

=item B<clearer> - clear_view

=item B<predicate> - has_view

=back

Required read-write lazy-building value of type AutoDocView. The AutoDocView
type will accept an Object that isa L<MooseX::AutoDoc::View>. This attribute
will attempt to coerce string values to instances by treating them as class
names and attempting to load and instantiate a class of the same name.

=head1 METHODS

=head2 new key => $value

Instantiate a new object. Please refer to L</"ATTRIBUTES"> for a list of valid
key options.

=head2 generate_pod_for $package_name, $view_args

Returns a string containing the Pod for the package. To make sure the data is
accurate please make sure the package has not been loaded prior to this step.
for more info see L</"NOTICE REGARDING ROLE CONSUMPTION">

=head2 _package_info $package_name

Will return a hashref representing the documentation components of the package
with the keys C<name>,  C<attributes>, C<methods>, C<attributes> and--if the
case the package is a class--C<superclasses>; the latter four are array refs
of the hashrefs returned by L</"_superclass_info">, L</"_attribute_info">,
L</"_method_info">, and L</"_consumed_role_info"> respectively.

=head2 _attribute_info $attr

Accepts one argument, an attribute metaclass instance.
Returns a hashref representing the documentation components of the
attribute with the keys C<name>, C<description>, and C<info>, a hashref
of additional information. If you have set the documentation attribute of
your attributes the documentation text will be appended to the auto-generated
description.

=head2 _consumed_role_info $role

Accepts one argument, a role metaclass instance. Returns a hashref representing
the documentation components of the role with the key C<name>.

=head2 _method_info $method

Accepts one argument, a method metaclass instance. Returns a hashref
representing the documentation components of the role with the key C<name>.

=head2 _superclass_info $class

Accepts one argument, the metaclass instance of a superclass. Returns a hashref
representing the documentation components of the role with the key C<name>.

=head2 meta

Retrieve the metaclass instance. Please see L<Moose::Meta::Class> and
L<Class::MOP::Class> for more information.

=head1 AUTHORS

Guillermo Roditi (Guillermo Roditi) <groditi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
