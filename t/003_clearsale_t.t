# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use warnings;
use strict;
use Test::More;

BEGIN { use_ok('Business::AntiFraud'); }

use Business::AntiFraud;
use DateTime;

my $antifraud = eval {
    Business::AntiFraud->new(
        codigo_integracao   => '856AD362-740C-4372-8C94-1EDFCDB9C25D',
        sandbox             => 1,
        gateway             => 'ClearSale::T',
        receiver_email      => 'hernanlopes@gmail.com',
        currency            => 'BRL',
    );
};

ok( $antifraud, 'the object was defined' );
ok( !$@,        'no error' );

if ($@) {
    diag $@;
}

isa_ok( $antifraud, 'Business::AntiFraud::Gateway::ClearSale::T' );

my $pedido_num = 'P3D1D0-ID-'.int rand(999999).int rand(999999);
my $data = DateTime->new(
    year   => 2012,
    month  => 04,
    day    => 20,
    hour   => 04,
    minute => 20,
    second => 00,
);

my $cart = $antifraud->new_cart(
    {
        business_type       => 'B2C', #B2C ou B2B
        sequential          => int rand(9), #sequential da clear sale.
        status              => 0, #0=novo, 9=aprovado, 41=canceldado,45=reprovado
        reanalise           => 0,
        origin              => 'origem do pedido',
        pedido_id           => $pedido_num,
        data                => $data,#ou $data
        data_pagamento      => '2012-10-29T20:21:22', #ou $data
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

{
    my $item = eval { $cart->get_item(1) };

    ok( $item, 'item is defined' );
    ok( !$@,   'no error' );

    if ($@) {
        diag $@;
    }

    isa_ok( $item           , 'Business::AntiFraud::Item' );
    is(     $item->id       , '1'       , 'item id is correct' );
    isnt(   $item->price    , 200.5     , 'item price is not numeric' );
    is(     $item->price    , '200.50'  , 'item price is correct' );
    is(     $item->quantity , 10        , 'item quantity is correct' );
}

{
    my $item = eval { $cart->get_item('02') };

    ok( $item, 'item is defined' );
    ok( !$@,   'no error' );

    if ($@) {
        diag $@;
    }

    isa_ok( $item, 'Business::AntiFraud::Item' );
    is( $item->id,       '02',   'item id is correct' );
    is( $item->price,    '0.56', 'item price is correct' );
    is( $item->quantity, 5,      'item quantity is correct' );
}

{
    my $item = eval { $cart->get_item('03') };

    ok( $item, 'item is defined' );
    ok( !$@,   'no error' );

    if ($@) {
        diag $@;
    }

    isa_ok( $item, 'Business::AntiFraud::Item' );

    is( $item->id, '03', 'item id is correct' );
    isnt( $item->price, 10, 'item price is not numeric' );
    is( $item->price,    '10.00', 'item price is correct' );
    is( $item->quantity, 1,       'item quantity is correct' );
}

{
    my $item = eval { $cart->get_item('my-id') };

    ok( $item, 'item is defined' );
    ok( !$@,   'no error' );

    if ($@) {
        diag $@;
    }

    isa_ok( $item, 'Business::AntiFraud::Item' );

    is( $item->id, 'my-id', 'item id is correct' );
    isnt( $item->price, 10, 'item price is not numeric' );
    is( $item->price,    '10.00', 'item price is correct' );
    is( $item->quantity, 1,       'item quantity is correct' );
}

sub has_node {
    my ( $content, $node_str ) = @_;
    return 0 if
           ! defined $content
        or ! defined $node_str
        or $content !~ m/$node_str/gim;
    return 1;
}

sub validate_nodes {
    my ( $content, $nodes ) = @_;
    foreach my $node ( @$nodes ) {
        is( &has_node( $content, "<$node>"), 1, 'expected node found: ' . $node );
    }
}

my $transaction_id = '';

{
    my $methods_expected = [ qw/define_ambiente homologacao producao create_xml_send_orders send_order update_order_status get_package_status get_order_status get_orders_status get_analyst_comments/ ];
    foreach my $method ( @$methods_expected ) {
        is( ref $antifraud->can( $method ), ref sub{}, 'method found in object' );
    }
}

{
    my $res = $antifraud->send_order( $cart );
    is( exists $res->{ content }    , 1, 'content received' );
    &validate_nodes( $res->{ content }, [ qw/TransactionID Status Message ID Score/ ] );
    ($transaction_id) = $res->{ content } =~ m/TransactionID>([^<]+)</gm;
}

{
    my $args = {
        pedido_id       => $pedido_num,
        status_pedido   => 'Aprovado', #Aprovado ou #Reprovado
    };
    my $res = $antifraud->update_order_status( $args );
    is( $res->{ url } =~ m#paymentintegration.asmx/UpdateOrderStatusID#gm, 1 , 'url UpdateOrderStatusID' );
    &validate_nodes( $res->{ content },[ qw/StatusCode Message TransactionStatus/ ] );
}

{
    # getPackageStatus
    my $res = $antifraud->get_package_status( $transaction_id );
    is( $res->{ url } =~ m#service.asmx/GetPackageStatus#gm, 1, 'expected url'  );
    &validate_nodes( $res->{ content }, [ qw/Order ID Status Score/ ] );
    is( $res->{ content } =~ m/$pedido_num/gm, 1, ' trouxe o numero do pedido ' );
}

{
    # getOrderStatus
    my $res = $antifraud->get_order_status( $pedido_num );
    is( $res->{ url } =~ m#service.asmx/GetOrderStatus#gm, 1, 'expected url'  );
    &validate_nodes( $res->{ content }, [ qw/Status Score ID/ ] );
}

{
    # getOrdersStatus
    my $res = $antifraud->get_orders_status( [$pedido_num,$pedido_num] );
    is( $res->{ url } =~ m#service.asmx/GetOrdersStatus#, 1, 'expected url' );
    &validate_nodes( $res->{ content } , [ qw/Status Score ID/ ] );
}

{
    # getAnalystComments
    my $res = $antifraud->get_analyst_comments( $pedido_num, 1 );
}


done_testing;
