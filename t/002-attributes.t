#!/usr/bin/perl -w

use strict;
use warnings;
use MooseX::AutoDoc;
use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More tests => 7;
use AutoDocTest1;

my $autodoc = MooseX::AutoDoc->new;
my $meta = AutoDocTest1->meta;
my %attributes = map { $_ => $meta->get_attribute($_) }
  $meta->get_attribute_list;

#attr 1
{
  my $target =
    {
     name => 'attr1',
     info => {},
     description => 'Optional read-only value'
    };

  my $spec = $autodoc->_attribute_info($attributes{attr1});

  is_deeply($spec, $target);
}

#attr 2
{
  my $target =
    {
     name => 'attr2',
     info => {},
     description => 'Optional read-write value of type L<HashRef|Moose::Util::TypeConstraints>'
    };

  my $spec = $autodoc->_attribute_info($attributes{attr2});

  is_deeply($spec, $target);
}

#attr 3
{
  my $target =
    {
     'info' => {},
     'name' => 'attr3',
     'description' => 'Optional read-write value of type L<ArrayRef[Str]|Moose::Util::TypeConstraints>'
    };

  my $spec = $autodoc->_attribute_info($attributes{attr3});

  is_deeply($spec, $target);
}

#attr 4
{
  my $target =
    {
     'info' => {},
     'name' => 'attr4',
     'description' => 'Required read-write value of type L<ArrayRef[Str]|Moose::Util::TypeConstraints>'
    };

  my $spec = $autodoc->_attribute_info($attributes{attr4});

  is_deeply($spec, $target);
}

#attr 5
{
  my $target =
    {
     'info' => {},
     'name' => 'attr5',
     'description' => 'Required read-write value of type L<ArrayRef[Str]|Moose::Util::TypeConstraints> that will be automatically dereferenced by the reader / accessor'
    };

  my $spec = $autodoc->_attribute_info($attributes{attr5});

  is_deeply($spec, $target);
}

#attr 6
{
  my $target =
    {
     'info' => {
                'predicate' => 'has_attr6',
                'builder' => '_build_attr6',
                'clearer' => 'clear_attr6'
               },
     'name' => 'attr6',
     'description' => 'Optional read-write lazy-building value'
    };

  my $spec = $autodoc->_attribute_info($attributes{attr6});

  is_deeply($spec, $target);
}

#attr 7
{
  my $target =
  {
   'info' => {
              'reader' => 'attr7',
              'writer' => '_attr7',
              'constructor key' => '-attr7',
             },
   'name' => 'attr7',
   'description' => 'Optional value'
  };

  my $spec = $autodoc->_attribute_info($attributes{attr7});

  is_deeply($spec, $target);
}
