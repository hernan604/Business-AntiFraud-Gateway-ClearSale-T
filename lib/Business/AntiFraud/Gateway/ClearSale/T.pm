package Business::AntiFraud::Gateway::ClearSale::T;
use Moo;
use Carp 'croak';
use bareword::filehandles;
use indirect;
use multidimensional;
use HTTP::Tiny;
use Data::Dumper;
use HTTP::Request::Common;
use XML::LibXML;
use HTML::Entities;
extends qw/Business::AntiFraud::Gateway::Base/;

our    $VERSION     = '0.01';

=head1 NAME

Business::AntiFraud::Gateway::ClearSale::T - Interface perl p/ T-ClearSale & A-ClearSale

=head1 SYNOPSIS

  use Business::AntiFraud::Gateway::ClearSale::T;

=head1 OBS

See the source of this file to find the fields relationship

=head1 DESCRIPTION

=head2 ua

Uses HTTP::Tiny as useragent

=cut

has ua => (
    is => 'rw',
    default => sub { HTTP::Tiny->new() },
);

=head2 sandbox

Boolean. Indica se homologação ou sandbox

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
    my ( $self, $xml ) = @_;
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
    $res->{ content } = decode_entities( $res->{ content } );
    return $res;
}

=head2 update_order_status

Equivalent for UpdateOrderStatus
TODO: Testar.. estou recebendo uma mensagem abaixo. Pessoal da clearsale está em recesso.
<Message>Status de origem não permite alteração de destino.</Message>

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
    return 'erro, $content must be a HashRef: { pedido_id => "", status_pedido => "" }'
        if           ref $args ne ref {} ||
            !exists $args->{ pedido_id } ||
        !exists $args->{ status_pedido }   ;
    my $ws_method = '/UpdateOrderStatusID';
    my $ws_url = $self->url_pagamento . $ws_method;
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
    $res->{ content } = decode_entities( $res->{ content } );
    return $res;
}

=head2 get_package_satus

recebe: TransactionID que é retornado após executar o send_order

retorno:

    \ {
        content    "<?xml version="1.0" encoding="utf-8"?>
    <string xmlns="http://www.clearsale.com.br/integration"><?xml version="1.0" encoding="utf-16"?>
    <ClearSale>
      <Orders>
        <Order>
          <ID>P3D1D0-ID-347749</ID>
          <Status>AMA</Status>
          <Score>30.2400</Score>
        </Order>
      </Orders>
    </ClearSale></string>",
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
    $res->{ content } = decode_entities( $res->{ content } );
    return $res;
}

=head2 get_order_status

Recupera o status atual dos pedidos na Clear Sale

recebe: $pedido_id

retorno:

    \ {
        content    "<?xml version="1.0" encoding="utf-8"?>
    <string xmlns="http://www.clearsale.com.br/integration"><?xml version="1.0" encoding="utf-16"?>
    <ClearSale>
      <Orders>
        <Order>
          <ID>P3D1D0-ID-300244</ID>
          <Status>AMA</Status>
          <Score>30.2400</Score>
        </Order>
      </Orders>
    </ClearSale></string>",
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
    $res->{ content } = decode_entities( $res->{ content } );
    return $res;
}

=head2 get_orders_status

Recupera o status atual dos pedidos (utilize para obter informações de mais de 1 pedido)

recebe: ArrayRef [$pedido1,$pedido2]

retorna:

    \ {
        content    "<?xml version="1.0" encoding="utf-8"?>
    <string xmlns="http://www.clearsale.com.br/integration"><?xml version="1.0" encoding="utf-16"?>
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
    </ClearSale></string>",
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
    $res->{ content } = decode_entities( $res->{ content } );
    return $res;

}

=head2 get_analyst_comments

WS: http://homologacao.clearsale.com.br/integracaov2/service.asmx?op=GetAnalystComments

recebe: $pedido_num, $get_all
$get_all é um booleano indica se traz todos ou apenas ultimo comentario

retorna:

    \ {
        content    "<?xml version="1.0" encoding="utf-8"?>
    <string xmlns="http://www.clearsale.com.br/integration"><?xml version="1.0" encoding="utf-16"?>
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
    </Order></string>",
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
    $res->{ content } = decode_entities( $res->{ content } );
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

1;

