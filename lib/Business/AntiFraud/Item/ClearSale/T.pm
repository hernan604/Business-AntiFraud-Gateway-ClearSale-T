package Business::AntiFraud::Item::ClearSale::T;
use Moo;

extends qw/Business::AntiFraud::Item/;

has category_id => (
    is => 'rw',
);

has gift_type_id => (
    is => 'rw',
);

has generic => (
    is => 'rw',
);

1;
