package AutoDocTestTypes;

use MooseX::Types -declare => [qw( TestType )];
use MooseX::Types::Moose 'Object';

# type definition
subtype TestType,
  as Object,
  where { 1 };

1;
