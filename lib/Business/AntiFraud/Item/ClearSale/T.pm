package Business::AntiFraud::Item::ClearSale::T;
use Moo;

extends qw/Business::AntiFraud::Item/;

=head1 ATTRIBUTES
=head2 category_id
=cut

has category_id => (
    is => 'rw',
);

=head2 gift_type_id
=cut

has gift_type_id => (
    is => 'rw',
);

=head2 generic
=cut

has generic => (
    is => 'rw',
);

1;
