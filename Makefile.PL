

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::AntiFraud::Gateway::ClearSale::T',
    VERSION_FROM => 'lib/Business/AntiFraud/Gateway/ClearSale/T.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernan@cpan.org)',
    ABSTRACT     => 'Interface perl T-ClearSale & A-ClearSale',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Test::More' => 0,
                     'Moo' => 0,
                     'Carp' => 0,
                     'bareword::filehandles'  => 0,
                     'indirect' => 0,
                     'multidimensional' => 0,
                     'HTTP::Tiny' => 0,
                     'HTTP::Request::Common' => 0,
                     'XML::LibXML' => 0,
                     'HTML::Entities' => 0,
                    },
);
