package Business::AntiFraud::Gateway::ClearSale::T;
use Moo;
use Carp 'croak';
use bareword::filehandles;
use indirect;
use multidimensional;
use HTTP::Tiny;
use Data::Dumper;
use HTTP::Request::Common;
#use SOAP::Lite;
use XML::LibXML;
extends qw/Business::AntiFraud::Gateway::Base/;

our    $VERSION     = '0.01';

=head1 NAME

Business::AntiFraud::Gateway::ClearSale::T - Interface perl p/ T-ClearSale & A-ClearSale

=head1 SYNOPSIS

  use Business::AntiFraud::Gateway::ClearSale::T;


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ToduleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.

=head2 ua
Uses HTTP::Tiny as useragent
=cut

has ua => (
    is => 'rw',
    default => sub { HTTP::Tiny->new() },
);

=head2 sandbox
Indica se homologação ou sandbox
=cut

has sandbox => ( is => 'rw' );

has url_pagamento               => ( is => 'rw', );
has url_integracao_webservice   => ( is => 'rw', );
has url_integracao_aplicacao    => ( is => 'rw', );

=head2 codigo_integracao
Seu código de integração
=cut

has codigo_integracao           => ( is => 'rw', );

has xml                         => ( is => 'rw' );

=head2 BUILD

=cut

sub BUILD {
    my $self    = shift;
    my $options = shift;
    $self->define_ambiente();
};

sub define_ambiente {
    my ( $self ) = @_;
    if ( $self->sandbox ) {
        $self->homologacao();
        return;
    }
    $self->producao();
}

sub homologacao {
    my ( $self ) = @_;
    $self->url_pagamento( 'http://homologacao.clearsale.com.br/integracaov2/paymentintegration.asmx' );
    $self->url_integracao_webservice( 'http://homologacao.clearsale.com.br/integracaov2/service.asmx' );
    $self->url_integracao_aplicacao( 'http://homologacao.clearsale.com.br/aplicacao/Login.aspx' );
}

sub producao {
    my ( $self ) = @_;
    $self->url_pagamento( 'http://www.clearsale.com.br/integracaov2/paymentintegration.asmx' );
    $self->url_integracao_webservice( 'http://www.clearsale.com.br/integracaov2/service.asmx' );
    $self->url_integracao_aplicacao( 'http://www.clearsale.com.br/aplicacao/Login.aspx' );
}

sub create_xml_send_orders {
    my ( $self, $cart ) = @_;
    use Data::Printer;
    warn p $cart;

    $self->xml(XML::LibXML::Document->new('1.0','utf-8'));
    my $node_clearsale = $self->xml->createElement('ClearSale');
    $self->xml->addChild( $node_clearsale );

    my $orders = $self->xml->createElement('Orders');
    $node_clearsale->addChild( $orders );

    # node: Orders
    my $node_order = $self->xml->createElement( 'Order' );
    $orders->addChild( $node_order );
    $self->add_xml_nodes_order( $node_order, $cart );

    #node: Collection Data / Billing
    my $node_collection = $self->xml->createElement( 'CollectionData' );
    $node_order->addChild( $node_collection );
    $self->add_xml_nodes_collection( $node_collection, $cart );

    #node: Shipping
    my $node_shipping = $self->xml->createElement( 'ShippingData' );
    $node_order->addChild( $node_shipping );
    $self->add_xml_nodes_shipping( $node_shipping, $cart );

    #node: Payments
    my $node_payments = $self->xml->createElement( 'Payments' );
    my $node_payment = $self->xml->createElement( 'Payment' );
    $node_order->addChild( $node_payments );
    $node_payments->addChild( $node_payment );
    $self->add_xml_node_payment( $node_payment, $cart );

    #node: Items
    my $node_items = $self->xml->createElement( 'Items' );
    $node_order->addChild( $node_items );
    $self->add_xml_node_items( $node_items , $cart );


    my $id = $self->xml->createElement( 'ID' );
    $id->appendText( $cart->pedido_id );

    warn p $self->xml;
    return $self->xml->toString();

}

sub ws_send_order {
    my ( $self, $xml ) = @_;
#   my $elem = SOAP::Data->type( 'xml' => $xml );
#   my $soap = SOAP::Lite->new(
#       uri     => $self->url_integracao_webservice,
#       proxy   => $self->url_integracao_webservice,
#   );
#   my $res = $soap->call( 'sendOrders' , $elem );
    my $ws_method = '/SendOrders';
    my $ws_url = $self->url_integracao_webservice . $ws_method;
    my $content = [
        entityCode  => $self->codigo_integracao,
        xml         => $xml,
    ];
    my $res = $self->ua->request( 'POST', $ws_url, {
        headers => {
            'Content-Type' => 'application/x-www-form-urlencoded',
        },
        content => POST( $ws_url, [], Content => $content )->content,
    } );
    warn p $content;
    return $res;
}

sub add_xml_node_items {
    my ( $self, $node, $cart ) = @_;
    my $fields_item  = {
        ID           => 'id',
        Name         => 'name',
        ItemValue    => 'price',
        Generic      => 'generic',
        Qty          => 'quantity',
        GiftTypeID   => 'gift_type_id',
        CategoryID   => 'category_id',
        CategoryName => 'category',
    };
    foreach my $item ( @{ $cart->_items } ) {
        my $node_item = $self->xml->createElement( 'Item' );
        foreach my $field ( keys $fields_item ) {
            my $attr = $fields_item->{ $field };
            if ( my $val = $item->$attr ) {
                my $new_node = $self->xml->createElement( $field );
                $new_node->appendText( $val );
                $node_item->addChild( $new_node );
            }
        }
        $node->addChild( $node_item );
    }
}

sub add_xml_node_payment {
    my ( $self, $node, $cart ) = @_;

    my $fields_payment = {
        Sequential          => 'sequential',
        Date                => 'data_pagamento',
        Amount              => 'total',
        PaymentTypeID       => 'tipo_de_pagamento',
        QtyInstallments     => 'parcelas',
        Intrest             => 'juros_taxa',
        IntrestValue        => 'juros_valor',
        Nsu                 => { object => 'billing', attr => 'nsu',                    },
        CardNumber          => { object => 'billing', attr => 'card_number',            },
        CardBin             => { object => 'billing', attr => 'card_bin',               },
        CardType            => { object => 'billing', attr => 'card_type',              },
        CardExpirationDate  => { object => 'billing', attr => 'card_expiration_date',   },
        Name                => { object => 'billing', attr => 'name',                   },
        LegalDocument       => { object => 'billing', attr => 'document_id',            },
    };
    $self->add_xml_values( $node, $cart, $fields_payment );

    my $node_payment_address = $self->xml->createElement( 'Address' );
    $node->addChild( $node_payment_address );

    my $fields_address = {
        Street      => { object => 'billing', attr => 'address_street',     },
        Number      => { object => 'billing', attr => 'address_number',     },
        Comp        => { object => 'billing', attr => 'address_complement', },
        County      => { object => 'billing', attr => 'address_district',   },
        City        => { object => 'billing', attr => 'address_city',       },
        State       => { object => 'billing', attr => 'address_state',      },
        Country     => { object => 'billing', attr => 'address_country',    },
        ZipCode     => { object => 'billing', attr => 'address_zip_code',   },
        Reference   => { object => 'billing', attr => 'address_reference',  },
    };
    $self->add_xml_values( $node_payment_address, $cart, $fields_address );
}

sub add_xml_nodes_shipping {
    my ( $self, $node, $cart ) = @_;

    #append CollectionData node information
    my $fields_collection = {
        ID              => { object => 'shipping', attr => 'client_id' },
        Type            => { object => 'shipping', attr => 'person_type' },
        LegalDocument1  => { object => 'shipping', attr => 'document_id' },
        LegalDocument2  => { object => 'shipping', attr => 'rg_ie' },
        Name            => { object => 'shipping', attr => 'name' },
        BirthDate       => { object => 'shipping', attr => 'birthdate' },
        Email           => { object => 'shipping', attr => 'email' },
        Genre           => { object => 'shipping', attr => 'genre' },
    };
    $self->add_xml_values( $node, $cart, $fields_collection );


    #now, append the address information
    my $fields_collection_address = {
        Street      => { object => 'shipping', attr => 'address_street' },
        Number      => { object => 'shipping', attr => 'address_number' },
        Comp        => { object => 'shipping', attr => 'address_complement' },
        County      => { object => 'shipping', attr => 'address_district' },
        City        => { object => 'shipping', attr => 'address_city' },
        State       => { object => 'shipping', attr => 'address_state' },
        ZipCode     => { object => 'shipping', attr => 'address_zip_code' },
        Reference   => { object => 'shipping', attr => 'address_reference' },
    };
    my $node_address = $self->xml->createElement( 'Address' );
    $node->addChild( $node_address );
    $self->add_xml_values( $node_address, $cart, $fields_collection_address );

    #now, append the phone information
    my $fields_collection_phone = {
        Type        => { object => 'shipping', attr => 'phone_type' },
        DDI         => { object => 'shipping', attr => 'phone_ddi' },
        DDD         => { object => 'shipping', attr => 'phone_prefix' },
        Number      => { object => 'shipping', attr => 'phone' },
    };
    my $node_phones = $self->xml->createElement( 'Phones' );
    $node->addChild( $node_phones );
    my $node_phone = $self->xml->createElement( 'Phone' );
    $node_phones->addChild( $node_phone );
    $self->add_xml_values( $node_phone, $cart, $fields_collection_phone );
}

sub add_xml_nodes_collection {
    my ( $self, $node, $cart ) = @_;

    #append CollectionData node information
    my $fields_collection = {
        ID              => { object => 'billing', attr => 'client_id' },
        Type            => { object => 'billing', attr => 'person_type' },
        LegalDocument1  => { object => 'billing', attr => 'document_id' },
        LegalDocument2  => { object => 'billing', attr => 'rg_ie' },
        Name            => { object => 'billing', attr => 'name' },
        BirthDate       => { object => 'billing', attr => 'birthdate' },
        Email           => { object => 'billing', attr => 'email' },
        Genre           => { object => 'billing', attr => 'genre' },
    };
    $self->add_xml_values( $node, $cart, $fields_collection );


    #now, append the address information
    my $fields_collection_address = {
        Street      => { object => 'billing', attr => 'address_street' },
        Number      => { object => 'billing', attr => 'address_number' },
        Comp        => { object => 'billing', attr => 'address_complement' },
        County      => { object => 'billing', attr => 'address_district' },
        City        => { object => 'billing', attr => 'address_city' },
        State       => { object => 'billing', attr => 'address_state' },
        ZipCode     => { object => 'billing', attr => 'address_zip_code' },
        Reference   => { object => 'billing', attr => 'address_reference' },
    };
    my $node_address = $self->xml->createElement( 'Address' );
    $node->addChild( $node_address );
    $self->add_xml_values( $node_address, $cart, $fields_collection_address );

    #now, append the phone information
    my $fields_collection_phone = {
        Type        => { object => 'billing', attr => 'phone_type' },
        DDI         => { object => 'billing', attr => 'phone_ddi' },
        DDD         => { object => 'billing', attr => 'phone_prefix' },
        Number      => { object => 'billing', attr => 'phone' },
    };
    my $node_phones = $self->xml->createElement( 'Phones' );
    $node->addChild( $node_phones );
    my $node_phone = $self->xml->createElement( 'Phone' );
    $node_phones->addChild( $node_phone );
    $self->add_xml_values( $node_phone, $cart, $fields_collection_phone );
}

sub add_xml_nodes_order {
    my ( $self, $node, $cart ) = @_;
    my $fields_pedido = {
        ID                  => 'pedido_id',
        Date                => 'data',
        Email               => {
            object      => 'buyer',
            attr        => 'email',
        },
        B2B_B2C             => 'business_type',
        ShippingPrice       => 'shipping_price',
        TotalItems          => 'total_items',
        TotalOrder          => 'total',
        QtyInstallments     => 'parcelas',
        DeliveryTimeCD      => 'delivery_time',
        QtyItems            => 'qty_items',
       #QtyPaymentTypes     => 'qty_payment_types',
        IP                  => {
            object      => 'buyer',
            attr        => 'ip',
        },
        GiftMessage         => 'gift_message',
        Obs                 => 'observations',
        Status              => 'status',
        Reanalise           => 'reanalise',
        Origin              => 'origin',
    };
    $self->add_xml_values( $node, $cart, $fields_pedido );
}

sub add_xml_values {
    my ( $self, $node, $cart, $fields ) = @_;
    foreach my $field ( keys $fields ) {
        warn $field;
        if ( ref $fields->{ $field } ne ref {} ) {
            my $attr = $fields->{ $field };
            if ( my $val = $cart->$attr ) {
                warn $field . ': '. $val;
                my $elem = $self->xml->createElement( $field );
                $elem->appendText( $val );
                $node->addChild( $elem );
            }
        } else {
            if ( exists $fields->{$field}->{object} and
                 exists $fields->{$field}->{attr} )
            {
                my $obj  = $fields->{$field}->{object};
                my $attr = $fields->{$field}->{ attr };
                if ( my $val = $cart->$obj->$attr ) {
                    warn $field . ': ' . $val;
                    my $elem = $self->xml->createElement( $field );
                    $elem->appendText( $val );
                    $node->addChild( $elem );
                }
            }
        }
    }
}

=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    movimentoperl
    hernan@cpan.org
    http://github.com/hernan604

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

