

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Business::AntiFraud::Gateway::ClearSale::T',
    VERSION_FROM => 'lib/Business/AntiFraud/Gateway/ClearSale/T.pm', # finds \$VERSION
    AUTHOR       => 'Hernan Lopes (hernan@cpan.org)',
    ABSTRACT     => 'Interface perl p/ T-ClearSale & A-ClearSale',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
