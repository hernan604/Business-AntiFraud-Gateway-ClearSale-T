package Business::AntiFraud::Billing::ClearSale::T;
use Moo;

extends qw/Business::AntiFraud::Billing/;

has client_id           => ( is => 'rw', required => 1, );
has person_type         => ( is => 'rw', required => 1,
    coerce => sub {
        my $value = $_[0];
        if ( $value =~ m/pj/ig ) {
            return 2;
        }
        return 1;
    },
);
has phone_type          => ( is => 'rw', required => 1, );
has name                => ( is => 'rw', required => 1, );
has document_id         => ( is => 'rw', required => 1, ); #CPF ou CPNJ
has address_street      => ( is => 'rw', required => 1, );
has address_number      => ( is => 'rw', required => 1, );
has address_district    => ( is => 'rw', required => 1, );
has address_city        => ( is => 'rw', required => 1, );
has address_state       => ( is => 'rw', required => 1, );
has address_zip_code    => ( is => 'rw', required => 1, );
has phone               => ( is => 'rw', required => 1, );
has phone_prefix        => ( is => 'rw', required => 1, );
has rg_ie               => ( is => 'rw', required => 0, ); #LegalDocument2
has birthdate => (
    is => 'rw',
    required => 1,
    coerce => sub {
        my $data = $_[0];
        if ( ref $data && ref $data eq 'DateTime' ) {
            return $data->ymd('-').'T'.$data->hms(':');
        }
        return $data;
    },
);
has genre               => ( is => 'rw', required => 0, );
has address_reference   => ( is => 'rw', required => 0, );
has phone_ddi           => ( is => 'rw', required => 0, );
has nsu                 => ( is => 'rw', required => 0, );
has card_number => (
    is       => 'rw',
    required => 0,
);

has card_bin => (
    is       => 'rw',
    required => 0,
);

has card_type => (
    is       => 'rw',
    required => 0,
);

has card_expiration_date => (
    is       => 'rw',
    required => 0,
);

1;
