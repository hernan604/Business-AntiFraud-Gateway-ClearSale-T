package Business::AntiFraud::Gateway::ClearSale::T;
use Moo;
use Carp 'croak';
use bareword::filehandles;
use indirect;
use multidimensional;
use HTTP::Tiny;
use HTTP::Request::Common;
use XML::LibXML;
use HTML::Entities;
extends qw/Business::AntiFraud::Gateway::Base/;

our    $VERSION     = '0.01';

=head1 NAME

=encoding utf-8

Business::AntiFraud::Gateway::ClearSale::T - Interface perl T-ClearSale & A-ClearSale

=head1 SYNOPSIS

    use Business::AntiFraud;
    use DateTime;

    my $data = DateTime->new(
        year   => 2012,
        month  => 04,
        day    => 20,
        hour   => 04,
        minute => 20,
        second => 00,
    );

    my $antifraud = eval {
        Business::AntiFraud->new(
            codigo_integracao   => '856AD362-740C-4372-8C94-1EDFCDB9C25D',
            sandbox             => 1,
            gateway             => 'ClearSale::T',
            receiver_email      => 'hernanlopes@gmail.com',
            currency            => 'BRL',
        );
    };
    my $cart = $antifraud->new_cart(
        {
            business_type       => 'B2C', #B2C ou B2B
            sequential          => int rand(9), #sequential da clear sale.
            status              => 0, #0=novo, 9=aprovado, 41=canceldado,45=reprovado
            reanalise           => 0,
            origin              => 'origem do pedido',
            pedido_id           => $pedido_num,
            data                => $data,
            data_pagamento      => $data,
            total_items         => 50,
            parcelas            => 2,
            tipo_de_pagamento   => 1,
            tipo_cartao         => 2,
            total               => 12.90,
            total_paid          => 7.90,
            juros_taxa          => 12,
            juros_valor         => 1000.00,
            shipping_price      => 98.21,
            delivery_time       => 'cinco dias',
            qty_payment_types   => '1',
            gift_message        => 'Enjoy your gift!',
            observations        => '.......obs......',
            qty_items           => 10,
            buyer       => {
                email   => 'comprador@email.com',
                ip      => '200.232.107.100',
            },
            shipping => {
                client_id          => 'XXX-YYY-010',
                person_type        => 'PJ', #PJ ou PF. juridica/fisica
                document_id        => '999222111222',
                rg_ie              => '98.765.432-1',
                name               => 'Nome Shipping',
                birthdate          => '2012-10-29T20:21:22', #or, yyyy-mm-ddThh:mm:ss
                email              => 'email@shipping.com',
                genre              => 'M', #1=masc/male, 0=feminino/female
                document_id        => '999222111555',
                address_street     => 'Rua shipping',
                address_number     => '334',
                address_district   => 'Ships',
                address_city       => 'Shipping City',
                address_state      => 'Vila Shipping',
                address_zip_code   => '99900-099',
                address_country    => 'Espanha',
                address_complement => 'apto 40',
                address_reference  => 'Prox ao shopping XYZ',
                phone              => '7770-0201',
                phone_prefix       => '13',
                phone_type         => 0, #0=not defined,1=residential,2=comercial,3=recado,4=cobranca,5=temporario,6=cel
                phone_ddi          => 12,
            },
            billing => {
                client_id          => 'XXX-YYY-010',
                person_type        => 'PJ', #PJ ou PF. juridica/fisica
                document_id        => '999222111222',
                rg_ie              => '98.765.432-1',
                name               => 'Nome Billing',
                birthdate          => $data, #or, yyyy-mm-ddThh:mm:ss
                email              => 'email@billing.com',
                genre              => 'M', #1=masc/male, 0=feminino/female
                address_street     => 'Rua billing',
                address_number     => '333',
                address_district   => 'Bills',
                address_city       => 'Bill City',
                address_state      => 'Vila Bill',
                address_zip_code   => '99900-022',
                address_country    => 'Brazil',
                address_complement => 'apto 50',
                address_reference  => 'Prox ao shopping XYZ',
                phone              => '5670-0201',
                phone_prefix       => '11',
                phone_type         => 0, #0=not defined,1=residential,2=comercial,3=recado,4=cobranca,5=temporario,6=cel
                phone_ddi          => 12,
                card_number        => '31321323123213',
                card_bin           => '321',
                card_type          => 1, #1=diners,2=mastercard,3=visa,4=outros,5=american express,6=hipercard,7=aura
                card_expiration_date => '05/13', #igual ao que consta no cartão
                nsu                => 'xxx-nsu-xxx'.int rand(9292929),
            },
        }
    );
    $cart->add_item(
        {
            id              => 1,
            name            => 'Produto NOME1',
            category        => 'Informática',
            price           => 200.5,
            quantity        => 10,
            gift_type_id    => 1,
            category_id     => 2,
            generic         => 'bla bla bla',
        }
    );

    $cart->add_item(
        {
            id       => '02',
            name     => 'Produto NOME2',
            price    => 0.56,
            quantity => 5,
        }
    );

    $cart->add_item(
        {
            id       => '03',
            name     => 'Produto NOME3',
            price    => 10,
            quantity => 1,
        }
    );

    $cart->add_item(
        {
            id       => 'my-id',
            name     => 'Produto NOME4',
            price    => 10,
            quantity => 1,
        }
    );

    # Enviar pedido para o clear sale

    my $res = $antifraud->send_order( $cart );
    use Data::Printer; warn p $res;

    # Atualizar status de um pedido
    my $args = {
        pedido_id       => $pedido_num,
        status_pedido   => 'Aprovado', #Aprovado ou #Reprovado
    };
    my $res = $antifraud->update_order_status( $args );

    # getPackageStatus ( transaction id vem após send_order )
    my $res = $antifraud->get_package_status( $transaction_id );

    # getOrderStatus
    my $res = $antifraud->get_order_status( $pedido_num );

    # getOrdersStatus (varios pedidos)
    my $res = $antifraud->get_orders_status( [$pedido_num,$pedido_num] );

    # getAnalystComments
    my $res = $antifraud->get_analyst_comments( $pedido_num, 1 );

=head1 OBS

See the source of this file to find the fields relationship

=head1 ATTRIBUTES

=head2 ua

Uses HTTP::Tiny as useragent

=cut

has ua => (
    is => 'rw',
    default => sub { HTTP::Tiny->new() },
);

=head2 sandbox

Boolean

=cut

has sandbox                     => ( is => 'rw' );

=head2 url_pagamento
=cut

has url_pagamento               => ( is => 'rw', );

=head2 url_integracao_webservice
=cut

has url_integracao_webservice   => ( is => 'rw', );

=head2 url_integracao_aplicacao
=cut

has url_integracao_aplicacao    => ( is => 'rw', );

=head2 codigo_integracao

Seu código de integração

=cut

has codigo_integracao           => ( is => 'rw', );

has xml                         => ( is => 'rw' );


=head1 METHODS

=head2 BUILD

Define the urls (dev or prod) according to $self->sandbox

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

=head2 homologacao

Define urls for: homologacao

=cut

sub homologacao {
    my ( $self ) = @_;
    $self->url_pagamento( 'http://homologacao.clearsale.com.br/integracaov2/paymentintegration.asmx' );
    $self->url_integracao_webservice( 'http://homologacao.clearsale.com.br/integracaov2/service.asmx' );
    $self->url_integracao_aplicacao( 'http://homologacao.clearsale.com.br/aplicacao/Login.aspx' );
}

=head2 producao

Define urls for: producao

=cut

sub producao {
    my ( $self ) = @_;
    $self->url_pagamento( 'http://www.clearsale.com.br/integracaov2/paymentintegration.asmx' );
    $self->url_integracao_webservice( 'http://www.clearsale.com.br/integracaov2/service.asmx' );
    $self->url_integracao_aplicacao( 'http://www.clearsale.com.br/aplicacao/Login.aspx' );
}

=head2 create_xml_send_orders

Receives: $cart

generates the XML based on $cart contents.

Returns: XML

=cut

sub create_xml_send_orders {
    my ( $self, $cart ) = @_;

    $self->xml(XML::LibXML::Document->new('1.0','utf-8'));
    my $node_clearsale = $self->xml->createElement('ClearSale');
    $self->xml->addChild( $node_clearsale );

    my $orders = $self->xml->createElement('Orders');
    $node_clearsale->addChild( $orders );

    # node: Orders
    my $node_order = $self->xml->createElement( 'Order' );
    $orders->addChild( $node_order );
    $self->_add_xml_nodes_order( $node_order, $cart );

    #node: Collection Data / Billing
    my $node_collection = $self->xml->createElement( 'CollectionData' );
    $node_order->addChild( $node_collection );
    $self->_add_xml_nodes_collection( $node_collection, $cart );

    #node: Shipping
    my $node_shipping = $self->xml->createElement( 'ShippingData' );
    $node_order->addChild( $node_shipping );
    $self->_add_xml_nodes_shipping( $node_shipping, $cart );

    #node: Payments
    my $node_payments = $self->xml->createElement( 'Payments' );
    my $node_payment = $self->xml->createElement( 'Payment' );
    $node_order->addChild( $node_payments );
    $node_payments->addChild( $node_payment );
    $self->_add_xml_node_payment( $node_payment, $cart );

    #node: Items
    my $node_items = $self->xml->createElement( 'Items' );
    $node_order->addChild( $node_items );
    $self->_add_xml_node_items( $node_items , $cart );


    my $id = $self->xml->createElement( 'ID' );
    $id->appendText( $cart->pedido_id );

    return $self->xml->toString();

}

=head2 send_order

Equivalent for SendOrders

receives: $xml and posts to /SendOrders

returns $response;

=cut

sub send_order {
    my ( $self , $cart ) = @_;
    my $xml = $self->create_xml_send_orders( $cart );
    my $ws_method = '/SendOrders';
    my $ws_url = $self->url_integracao_webservice . $ws_method;
    my $content = [
        entityCode  => $self->codigo_integracao,
        xml         => $self->xml,
    ];
    my $res = $self->ua->request( 'POST', $ws_url, {
        headers => {
            'Content-Type' => 'application/x-www-form-urlencoded',
        },
        content => POST( $ws_url, [], Content => $content )->content,
    } );
    $res = $self->_decode_response( $res );
    return $res;
}

=head2 update_order_status

Will work only for orders with status APA or APM

The documentation says:

A atualização somente ocorrerá para pedidos aprovados no ClearSale (APA ou APM), status diferentes de aprovação não serão permitidos para atualizar o status de pagamento.

usage:

    my $content = [
        entityCode      => '',
        orderID         => '', *** eh o pedido_id / $pedido_num
        strStatusPedido => '',#26=Aprovado  27=Reprovado
    ];
    update_order_status( $content );

=cut

sub update_order_status {
    my ( $self, $args ) = @_;
    {
        return 'erro, $content must be a HashRef: { pedido_id => "", status_pedido => "" }'
            if           ref $args ne ref {} ||
                !exists $args->{ pedido_id } ||
            !exists $args->{ status_pedido }   ;
    }
    my $ws_url = $self->url_pagamento . '/UpdateOrderStatusID';
    my $content = [
        entityCode      => $self->codigo_integracao,
        orderId         => $args->{ pedido_id },
        StatusPedido    => $args->{ status_pedido }, #Aprovado ou #Reprovado
    ];
    my $res = $self->ua->request(
        'POST',
        $ws_url,
        {
            headers => {
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => POST( $ws_url, [], Content => $content )->content,
        }
    );

    $res = $self->_decode_response( $res );

    return $res;
}

=head2 get_package_satus

recebe: TransactionID que é retornado após executar o send_order

retorno:

    \ {
        content    "<?xml version="1.0" encoding="utf-8"?>
    <ClearSale>
      <Orders>
        <Order>
          <ID>P3D1D0-ID-347749</ID>
          <Status>AMA</Status>
          <Score>30.2400</Score>
        </Order>
      </Orders>
    </ClearSale>",
        headers    {
            cache-control      "private, max-age=0",
            connection         "close",
            content-length     392,
            content-type       "text/xml; charset=utf-8",
            date               "Thu, 14 Feb 2013 12:47:02 GMT",
            server             "Microsoft-IIS/6.0",
            x-aspnet-version   "2.0.50727",
            x-powered-by       "ASP.NET"
        },
        protocol   "HTTP/1.1",
        reason     "OK",
        status     200,
        success    1,
        url        "http://homologacao.clearsale.com.br/integracaov2/service.asmx/GetPackageStatus"
    }


=cut

sub get_package_status {
    my ( $self, $transaction_id ) = @_;
    my $content = [
        entityCode => $self->codigo_integracao,
        packageId  => $transaction_id,
    ];
    my $ws_url = $self->url_integracao_webservice . '/GetPackageStatus';
    my $res = $self->ua->request(
        'POST',
        $ws_url,
        {
            headers => {
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => POST( $ws_url, [], Content => $content )->content,
        }
    );
    $res = $self->_decode_response( $res );
    return $res;
}

=head2 get_order_status

Recupera o status atual dos pedidos na Clear Sale

recebe: $pedido_id

retorno:

    \ {
        content    "<?xml version="1.0" encoding="utf-8"?>
    <ClearSale>
      <Orders>
        <Order>
          <ID>P3D1D0-ID-300244</ID>
          <Status>AMA</Status>
          <Score>30.2400</Score>
        </Order>
      </Orders>
    </ClearSale>",
        headers    {
            cache-control      "private, max-age=0",
            connection         "close",
            content-length     392,
            content-type       "text/xml; charset=utf-8",
            date               "Thu, 14 Feb 2013 13:01:01 GMT",
            server             "Microsoft-IIS/6.0",
            x-aspnet-version   "2.0.50727",
            x-powered-by       "ASP.NET"
        },
        protocol   "HTTP/1.1",
        reason     "OK",
        status     200,
        success    1,
        url        "http://homologacao.clearsale.com.br/integracaov2/service.asmx/GetOrderStatus"
    }


=cut

sub get_order_status {
    my ( $self, $pedido_id ) = @_;
    my $content = [
        entityCode => $self->codigo_integracao,
        orderID  => $pedido_id,
    ];
    my $ws_url = $self->url_integracao_webservice . '/GetOrderStatus';
    my $res = $self->ua->request(
        'POST',
        $ws_url,
        {
            headers => {
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => POST( $ws_url, [], Content => $content )->content,
        }
    );
    $res = $self->_decode_response( $res );
    return $res;
}

=head2 get_orders_status

Recupera o status atual dos pedidos (utilize para obter informações de mais de 1 pedido)

recebe: ArrayRef [$pedido1,$pedido2]

retorna:

    \ {
        content    "<?xml version="1.0" encoding="utf-8"?>
    <ClearSale>
      <Orders>
        <Order>
          <ID>P3D1D0-ID-889443</ID>
          <Status>AMA</Status>
          <Score>30.2400</Score>
        </Order>
        <Order>
          <ID>P3D1D0-ID-889443</ID>
          <Status>AMA</Status>
          <Score>30.2400</Score>
        </Order>
      </Orders>
    </ClearSale>",
        headers    {
            cache-control      "private, max-age=0",
            connection         "close",
            content-length     558,
            content-type       "text/xml; charset=utf-8",
            date               "Thu, 14 Feb 2013 13:31:54 GMT",
            server             "Microsoft-IIS/6.0",
            x-aspnet-version   "2.0.50727",
            x-powered-by       "ASP.NET"
        },
        protocol   "HTTP/1.1",
        reason     "OK",
        status     200,
        success    1,
        url        "http://homologacao.clearsale.com.br/integracaov2/service.asmx/GetOrdersStatus"
    } at t/003_clearsale_t.t line 277.

=cut

sub get_orders_status {
    my ( $self, $pedidos ) = @_;
    next unless ref $pedidos eq ref [];
    my $xml = XML::LibXML::Document->new('1.0','utf-8');
    my $node_clearsale = $xml->createElement('ClearSale');
    $xml->addChild( $node_clearsale );

    my $node_orders = $xml->createElement('Orders');
    $node_clearsale->addChild( $node_orders );

    foreach my $pedido_id ( @$pedidos ) {
        my $node_order    = $xml->createElement('Order');
        my $node_order_id = $xml->createElement('ID');
        $node_order->addChild( $node_order_id );
        $node_order_id->appendText( $pedido_id );
        $node_orders->addChild( $node_order );
    }

    my $content = [
        entityCode => $self->codigo_integracao,
        xml        => $xml->toString(),
    ];
    my $ws_url = $self->url_integracao_webservice . '/GetOrdersStatus';
    my $res = $self->ua->request(
        'POST',
        $ws_url,
        {
            headers => {
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => POST( $ws_url, [], Content => $content )->content,
        }
    );
    $res = $self->_decode_response( $res );
    return $res;

}

=head2 get_analyst_comments

WS: http://homologacao.clearsale.com.br/integracaov2/service.asmx?op=GetAnalystComments

recebe: $pedido_num, $get_all

$get_all é um booleano indica se traz todos ou apenas ultimo comentario

retorna:

    \ {
        content    "<?xml version="1.0" encoding="utf-8"?>
    <Order>
      <ID>P3D1D0-ID-680045</ID>
      <Date d2p1:nil="true" xmlns:d2p1="http://www.w3.org/2001/XMLSchema-instance" />
      <QtyInstallments d2p1:nil="true" xmlns:d2p1="http://www.w3.org/2001/XMLSchema-instance" />
      <ShippingPrice d2p1:nil="true" xmlns:d2p1="http://www.w3.org/2001/XMLSchema-instance" />
      <ShippingTypeID>0</ShippingTypeID>
      <ManualOrder>
        <ManualQuery d3p1:nil="true" xmlns:d3p1="http://www.w3.org/2001/XMLSchema-instance" />
        <UserID>0</UserID>
      </ManualOrder>
      <TotalItens>0</TotalItens>
      <TotalOrder>0</TotalOrder>
      <Gift>0</Gift>
      <Status>-1</Status>
      <Reanalise>0</Reanalise>
      <WeddingList d2p1:nil="true" xmlns:d2p1="http://www.w3.org/2001/XMLSchema-instance" />
      <ReservationDate d2p1:nil="true" xmlns:d2p1="http://www.w3.org/2001/XMLSchema-instance" />
      <Product d2p1:nil="true" xmlns:d2p1="http://www.w3.org/2001/XMLSchema-instance" />
      <ListTypeID d2p1:nil="true" xmlns:d2p1="http://www.w3.org/2001/XMLSchema-instance" />
      <ShippingData>
        <Type d3p1:nil="true" xmlns:d3p1="http://www.w3.org/2001/XMLSchema-instance" />
        <BirthDate d3p1:nil="true" xmlns:d3p1="http://www.w3.org/2001/XMLSchema-instance" />
        <Phones />
        <Address />
      </ShippingData>
      <CollectionData>
        <Type d3p1:nil="true" xmlns:d3p1="http://www.w3.org/2001/XMLSchema-instance" />
        <BirthDate d3p1:nil="true" xmlns:d3p1="http://www.w3.org/2001/XMLSchema-instance" />
        <Phones />
        <Address />
      </CollectionData>
      <Payments />
      <Items />
      <Passangers />
      <Connections />
      <AnalystComments />
      <CategoryValueID>0</CategoryValueID>
    </Order>",
        headers    {
            cache-control      "private, max-age=0",
            connection         "close",
            content-length     2049,
            content-type       "text/xml; charset=utf-8",
            date               "Thu, 14 Feb 2013 14:05:46 GMT",
            server             "Microsoft-IIS/6.0",
            x-aspnet-version   "2.0.50727",
            x-powered-by       "ASP.NET"
        },
        protocol   "HTTP/1.1",
        reason     "OK",
        status     200,
        success    1,
        url        "http://homologacao.clearsale.com.br/integracaov2/service.asmx/GetAnalystComments"
    }

=cut

sub get_analyst_comments {
    my ( $self, $pedido_num, $get_all ) = @_;
    my $content = [
        entityCode => $self->codigo_integracao,
        orderID    => $pedido_num,
        getAll     => ( defined $get_all ) ? ( $get_all == 1 ) ? 'True' : 'False' : 'False',
    ];
    my $ws_url = $self->url_integracao_webservice . '/GetAnalystComments';
    my $res = $self->ua->request(
        'POST',
        $ws_url,
        {
            headers => {
                'Content-Type' => 'application/x-www-form-urlencoded',
            },
            content => POST( $ws_url, [], Content => $content )->content,
        }
    );
    $res = $self->_decode_response( $res );
    return $res;
}

sub _add_xml_node_items {
    my ( $self, $node, $cart ) = @_;
    my $fields_list  = [
        {ID           => 'id',              },
        {Name         => 'name',            },
        {ItemValue    => 'price',           },
        {Generic      => 'generic',         },
        {Qty          => 'quantity',        },
        {GiftTypeID   => 'gift_type_id',    },
        {CategoryID   => 'category_id',     },
        {CategoryName => 'category',        },
    ];
    foreach my $item ( @{ $cart->_items } ) {
        my $node_item = $self->xml->createElement( 'Item' );
        foreach my $fields_item ( @$fields_list ) {
            foreach my $field ( keys $fields_item ) {
                my $attr = $fields_item->{ $field };
                if ( my $val = $item->$attr ) {
                    my $new_node = $self->xml->createElement( $field );
                    $new_node->appendText( $val );
                    $node_item->addChild( $new_node );
                }
            }
        }
        $node->addChild( $node_item );
    }
}

sub _add_xml_node_payment {
    my ( $self, $node, $cart ) = @_;
    #xml fields order matters... :/
    my $fields_payment = [
       {Sequential          => 'sequential',                                            },
       {Date                => 'data_pagamento',                                        },
       {Amount              => 'total',                                                 },
       {PaymentTypeID       => 'tipo_de_pagamento',                                     },
       {QtyInstallments     => 'parcelas',                                              },
       {Interest            => 'juros_taxa',                                            },
       {InterestValue       => 'juros_valor',                                           },
       {CardNumber          => { object => 'billing', attr => 'card_number',           }},
       {CardBin             => { object => 'billing', attr => 'card_bin',              }},
       {CardType            => { object => 'billing', attr => 'card_type',             }},
       {CardExpirationDate  => { object => 'billing', attr => 'card_expiration_date',  }},
       {Name                => { object => 'billing', attr => 'name',                  }},
       {LegalDocument       => { object => 'billing', attr => 'document_id',           }},
    ];
    $self->_add_xml_values( $node, $cart, $fields_payment );

    my $node_payment_address = $self->xml->createElement( 'Address' );
    $node->addChild( $node_payment_address );

    my $fields_address = [
      { Street      => { object => 'billing', attr => 'address_street',     }},
      { Number      => { object => 'billing', attr => 'address_number',     }},
      { Comp        => { object => 'billing', attr => 'address_complement', }},
      { County      => { object => 'billing', attr => 'address_district',   }},
      { City        => { object => 'billing', attr => 'address_city',       }},
      { State       => { object => 'billing', attr => 'address_state',      }},
      { Country     => { object => 'billing', attr => 'address_country',    }},
      { ZipCode     => { object => 'billing', attr => 'address_zip_code',   }},
    ];
    $self->_add_xml_values( $node_payment_address, $cart, $fields_address );

    my $fields_payment_part2 = [
       {Nsu                 => { object => 'billing', attr => 'nsu',        }},
    ];
    $self->_add_xml_values( $node, $cart, $fields_payment_part2 );
}

sub _add_xml_nodes_shipping {
    my ( $self, $node, $cart ) = @_;

    my $fields_collection = [
       { ID              => { object => 'shipping', attr => 'client_id'   }},
       { Type            => { object => 'shipping', attr => 'person_type' }},
       { LegalDocument1  => { object => 'shipping', attr => 'document_id' }},
       { LegalDocument2  => { object => 'shipping', attr => 'rg_ie'       }},
       { Name            => { object => 'shipping', attr => 'name'        }},
       { BirthDate       => { object => 'shipping', attr => 'birthdate'   }},
       { Email           => { object => 'shipping', attr => 'email'       }},
       { Genre           => { object => 'shipping', attr => 'genre'       }},
    ];
    $self->_add_xml_values( $node, $cart, $fields_collection );


    #now, append the address information
    my $fields_collection_address = [
       {Street      => { object => 'shipping', attr => 'address_street'     }},
       {Number      => { object => 'shipping', attr => 'address_number'     }},
       {Comp        => { object => 'shipping', attr => 'address_complement' }},
       {County      => { object => 'shipping', attr => 'address_district'   }},
       {City        => { object => 'shipping', attr => 'address_city'       }},
       {State       => { object => 'shipping', attr => 'address_state'      }},
       {Country     => { object => 'shipping', attr => 'address_country',   }},
       {ZipCode     => { object => 'shipping', attr => 'address_zip_code'   }},
       {Reference   => { object => 'shipping', attr => 'address_reference'  }},
    ];
    my $node_address = $self->xml->createElement( 'Address' );
    $node->addChild( $node_address );
    $self->_add_xml_values( $node_address, $cart, $fields_collection_address );

    #now, append the phone information
    my $fields_collection_phone = [
       {Type        => { object => 'shipping', attr => 'phone_type'     }},
       {DDI         => { object => 'shipping', attr => 'phone_ddi'      }},
       {DDD         => { object => 'shipping', attr => 'phone_prefix'   }},
       {Number      => { object => 'shipping', attr => 'phone'          }},
    ];
    my $node_phones = $self->xml->createElement( 'Phones' );
    $node->addChild( $node_phones );
    my $node_phone = $self->xml->createElement( 'Phone' );
    $node_phones->addChild( $node_phone );
    $self->_add_xml_values( $node_phone, $cart, $fields_collection_phone );
}

=head2 _add_xml_nodes_collection

builds the <CollectionData> node

=cut

sub _add_xml_nodes_collection {
    my ( $self, $node, $cart ) = @_;

    #append CollectionData node information
    my $fields_collection = [
       {ID              => { object => 'billing', attr => 'client_id'   }},
       {Type            => { object => 'billing', attr => 'person_type' }},
       {LegalDocument1  => { object => 'billing', attr => 'document_id' }},
       {LegalDocument2  => { object => 'billing', attr => 'rg_ie'       }},
       {Name            => { object => 'billing', attr => 'name'        }},
       {BirthDate       => { object => 'billing', attr => 'birthdate'   }},
       {Email           => { object => 'billing', attr => 'email'       }},
       {Genre           => { object => 'billing', attr => 'genre'       }},
    ];
    $self->_add_xml_values( $node, $cart, $fields_collection );

    #now, append the address information
    my $fields_collection_address = [
       {Street      => { object => 'billing', attr => 'address_street'      }},
       {Number      => { object => 'billing', attr => 'address_number'      }},
       {Comp        => { object => 'billing', attr => 'address_complement'  }},
       {County      => { object => 'billing', attr => 'address_district'    }},
       {City        => { object => 'billing', attr => 'address_city'        }},
       {State       => { object => 'billing', attr => 'address_state'       }},
       {Country     => { object => 'billing', attr => 'address_country',    }},
       {ZipCode     => { object => 'billing', attr => 'address_zip_code'    }},
       {Reference   => { object => 'billing', attr => 'address_reference'   }},
    ];
    my $node_address = $self->xml->createElement( 'Address' );
    $node->addChild( $node_address );
    $self->_add_xml_values( $node_address, $cart, $fields_collection_address );

    #now, append the phone information
    my $fields_collection_phone = [
       {Type        => { object => 'billing', attr => 'phone_type'      }},
       {DDI         => { object => 'billing', attr => 'phone_ddi'       }},
       {DDD         => { object => 'billing', attr => 'phone_prefix'    }},
       {Number      => { object => 'billing', attr => 'phone'           }},
    ];
    my $node_phones = $self->xml->createElement( 'Phones' );
    $node->addChild( $node_phones );
    my $node_phone = $self->xml->createElement( 'Phone' );
    $node_phones->addChild( $node_phone );
    $self->_add_xml_values( $node_phone, $cart, $fields_collection_phone );
}

sub _add_xml_nodes_order { #order means your cart order... the stuff you bought
    my ( $self, $node, $cart ) = @_;
    my $fields_pedido = [
      { ID                  => 'pedido_id',                         },
      { Date                => 'data',                              },
      { Email               => { object => 'buyer',attr => 'email'} },
      { B2B_B2C             => 'business_type',                     },
      { ShippingPrice       => 'shipping_price',                    },
      { TotalItens          => 'total_items',                       },
      { TotalOrder          => 'total',                             },
      { QtyInstallments     => 'parcelas',                          },
      { DeliveryTimeCD      => 'delivery_time',                     },
      { QtyItems            => 'qty_items',                         },
      { QtyPaymentTypes     => 'qty_payment_types',                 },
      { IP                  => { object => 'buyer', attr => 'ip', } },
      { GiftMessage         => 'gift_message',                      },
      { Obs                 => 'observations',                      },
      { Status              => 'status',                            },
      { Reanalise           => 'reanalise',                         },
      { Origin              => 'origin',                            },
    ];
    $self->_add_xml_values( $node, $cart, $fields_pedido );
}

sub _add_xml_values {
    my ( $self, $node, $cart, $fields_obj ) = @_;
    foreach my $fields ( @$fields_obj ) {
        foreach my $field ( keys $fields ) {
            if ( ref $fields->{ $field } ne ref {} ) {
                my $attr = $fields->{ $field };
                if ( defined $cart->$attr ) {
                    my $val = $cart->$attr;
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
                    if ( defined $cart->$obj and defined $cart->$obj->$attr ) {
                        my $val = $cart->$obj->$attr;
                        my $elem = $self->xml->createElement( $field );
                        $elem->appendText( $val );
                        $node->addChild( $elem );
                    }
                }
            }
        }
    }
}

=head2 _decode_response

strip out wsdl tags and decode the content into XML which is then returned

=cut

sub _decode_response {
    my ( $self, $res ) = @_;
    #TODO parse this in a better way and return a perl object
    $res->{ content } =~ s#<\?xml([^\>]+)\>##g;
    $res->{ content } =~ s#<string([^\>]+)\>##igmx;
    $res->{ content } =~ s#</string>##igmx;
    $res->{ content } =~ s#utf-16#utf-8#g;
    $res->{ content } = decode_entities( $res->{ content } );
    $res->{ content } =~ s/\n|\r//igm;
    $res->{ content } =~ s/\?\>/\?\>\n/;
    return $res;
}

=head1 AUTHOR

    Hernan Lopes
    CPAN ID: HERNAN
    movimentoperl
    hernan@cpan.org
    http://github.com/hernan604

=head1 SPONSORED BY

http://www.nixus.com.br

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;

