package Business::AntiFraud::Gateway::ClearSale::T;
use Moo;
use Carp 'croak';
use bareword::filehandles;
use indirect;
use multidimensional;
use HTTP::Tiny;
use Data::Dumper;
use HTTP::Request::Common;
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

