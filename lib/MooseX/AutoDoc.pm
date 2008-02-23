package MooseX::AutoDoc;

use Moose;
use Carp;
use Class::MOP;
use Moose::Meta::Role;
use Moose::Meta::Class;
use Scalar::Util qw/blessed/;

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
          'Moose::Meta::Role::Method'        => 1,
          'Moose::Meta::Method::Accessor'    => 1,
          'Moose::Meta::Method::Constructor' => 1,
          'Class::MOP::Method::Accessor'     => 1,
          'Class::MOP::Method::Generated'    => 1,
          'Class::MOP::Method::Constructor'  => 1,
         };

#          'Moose::Meta::Method::Overridden'  => 1,
#          'Class::MOP::Method::Wrapped'      => 1,
}

sub _build_license_text {
  "This library is free software; you can redistribute it and/or modify it "
    ."under the same terms as Perl itself.";
}

#make the actual POD
sub generate_pod_for_role {
  my ($self, $role, $view_args) = @_;

  carp("${role} is already loaded. This will cause inacurate output.".
       "if ${role} is the consumer of any roles.")
    if Class::MOP::is_class_loaded( $role );

  my $spec = $self->role_info($role);
  my $vars = {
              role    => $spec,
              license => $self->license_text,
              authors => $self->has_authors ? $self->authors : [],
             };
  return $self->view->render_role($vars, $view_args);
}

#make the actual POD
sub generate_pod_for_class {
  my ($self, $class, $view_args) = @_;

  carp("${class} is already loaded. This will cause inacurate output.".
       "if ${class} is the consumer of any roles.")
    if Class::MOP::is_class_loaded( $class );

  my $spec = $self->class_info($class);
  my $vars = {
              class   => $spec,
              license => $self->license_text,
              authors => $self->has_authors ? $self->authors : [],
             };

  return $self->view->render_class($vars, $view_args);
}


# *_info methods
sub role_info {
  my ($self, $role) = @_;

  my (@roles_to_apply, $rmeta, $original_apply);
  {    #intercept role application so we can accurately generate
       #method and attribute information for the parent class.
       #this is fragile, but there is not better way that i am aware of

    $rmeta = Moose::Meta::Role->meta;
    $rmeta->make_mutable if $rmeta->is_immutable;
    $original_apply = $rmeta->get_method("apply")->body;
    $rmeta->remove_method("apply");
    $rmeta->add_method("apply", sub{push(@roles_to_apply, [@_])});

    eval { Class::MOP::load_class($role); };
    confess "Failed to load class ${role} $@" if $@;
  }

  my $meta =  $role->meta;
  my $anon = Moose::Meta::Class->create_anon_class;
  $original_apply->($meta, $anon);

  my @attributes = map{ $anon->get_attribute($_) } sort $anon->get_attribute_list;

  my %ignored_method_metaclasses = %{ $self->ignored_method_metaclasses };
  delete $ignored_method_metaclasses{'Moose::Meta::Role::Method'};
  my @methods =
    grep{ ! exists $ignored_method_metaclasses{$_->meta->name} }
      map { $anon->get_method($_) }
        grep { $_ ne 'meta' }    #it wasnt getting filtered on the anon class..
          sort $anon->get_method_list;
  my @method_specs     = map{ $self->method_info($_)        } @methods;
  my @attribute_specs  = map{ $self->attribute_info($_)     } @attributes;

  { #fix Moose::Meta::Role and apply the roles that were delayed
    $rmeta->remove_method("apply");
    $rmeta->add_method("apply", $original_apply);
    $rmeta->make_immutable;
    shift(@$_)->apply(@$_) for @roles_to_apply;
  }

  my @roles =
    sort{ $a->name cmp $b->name }
      map { $_->isa("Moose::Meta::Role::Composite") ? @{$_->get_roles} : $_ }
        @{ $meta->get_roles };

  my @role_specs = map{ $self->consumed_role_info($_) } @roles;

  my $spec = {
              name         => $meta->name,
              roles        => \ @role_specs,
              methods      => \ @method_specs,
              attributes   => \ @attribute_specs,
             };

  return $spec;
}


sub class_info {
  my ($self, $class) = @_;

  my (@roles_to_apply, $rmeta, $original_apply);
  {    #intercept role application so we can accurately generate
       #method and attribute information for the parent class.
       #this is fragile, but there is not better way that i am aware of

    $rmeta = Moose::Meta::Role->meta;
    $rmeta->make_mutable if $rmeta->is_immutable;
    $original_apply = $rmeta->get_method("apply")->body;
    $rmeta->remove_method("apply");
    $rmeta->add_method("apply", sub{push(@roles_to_apply, [@_])});

    eval { Class::MOP::load_class($class); };
    confess "Failed to load class ${class} $@" if $@;
  }

  my $meta = $class->meta;

  my @attributes   = map{ $meta->get_attribute($_) } sort $meta->get_attribute_list;
  my @superclasses = map{ $_->meta }
    grep { $_ ne 'Moose::Object' } $meta->superclasses;

  my @methods =
    grep{ ! exists $self->ignored_method_metaclasses->{$_->meta->name} }
      map { $meta->get_method($_) }
        grep { $_ ne 'meta' }    #it wasnt getting filtered on the anon class..
          sort $meta->get_method_list;

  my @method_specs     = map{ $self->method_info($_)        } @methods;
  my @attribute_specs  = map{ $self->attribute_info($_)     } @attributes;
  my @superclass_specs = map{ $self->superclass_info($_)    } @superclasses;

  { #fix Moose::Meta::Role and apply the roles that were delayed
    $rmeta->remove_method("apply");
    $rmeta->add_method("apply", $original_apply);
    $rmeta->make_immutable;
    shift(@$_)->apply(@$_) for @roles_to_apply;
  }

  my @roles = sort{ $a->name cmp $b->name }
    map { $_->isa("Moose::Meta::Role::Composite") ? @{$_->get_roles} : $_ }
      @{ $meta->roles };
  my @role_specs = map{ $self->consumed_role_info($_) } @roles;

  my $spec = {
              name         => $meta->name,
              roles        => \ @role_specs,
              methods      => \ @method_specs,
              attributes   => \ @attribute_specs,
              superclasses => \ @superclass_specs,
             };

  return $spec;
}

sub attribute_info{
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

sub superclass_info {
  my($self, $superclass) = @_;
  my $spec = { name => $superclass->name };
  return $spec;
}

sub method_info {
  my($self, $method) = @_;
  my $spec = { name => $method->name };
  return $spec;
}

sub consumed_role_info {
  my($self, $role) = @_;;
  my $spec = { name => $role->name };
  return $spec;
}

1;

__END__;



