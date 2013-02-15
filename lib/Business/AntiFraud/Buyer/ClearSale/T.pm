package Business::AntiFraud::Buyer::ClearSale::T;
use Moo;

extends qw/Business::AntiFraud::Buyer/;

has ip => (
    is => 'rw',
);

1;
