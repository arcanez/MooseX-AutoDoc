package AutoDocTest7;

use Moose;
use AutoDocTestTypes qw( TestType );

has typed_attr => (isa => TestType, is => 'bare');

1;
