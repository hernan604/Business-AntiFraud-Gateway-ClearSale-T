package Business::AntiFraud::Buyer::ClearSale::T;
use Moo;

extends qw/Business::AntiFraud::Buyer/;

=head1 NAME

Business::AntiFraud::Buyer::ClearSale::T

=head1 DESCRIPTION

extends Business::AntiFraud::Buyer

=head1 ATTRIBUTES

=head2 ip
holds the buyers IP
=cut

has ip => (
    is => 'rw',
);

1;
