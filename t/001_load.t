# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Business::AntiFraud::Gateway::ClearSale::T' ); }

my $object = Business::AntiFraud::Gateway::ClearSale::T->new ();
isa_ok ($object, 'Business::AntiFraud::Gateway::ClearSale::T');


