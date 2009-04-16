use strict;
use warnings;
use utf8;
no warnings 'utf8' ;

use Test::More tests => 19;

use Biber::Utils;

is( normalize_string('"a, b–c: d" '),  'a bc d', 'normalize_string' );

is( normalize_string_underscore('\c Se\x{c}\"ok-\foo{a},  N\`i\~no
    $§+ :-)   '), 'Secoka_Nino', 'normalize_string_underscore 1' );

is( normalize_string_underscore('{Foo de Bar, Graf Ludwig}'), 'Foo_de_Bar_Graf_Ludwig', 'normalize_string_underscore 2');

my @names = ( 
    { namestring => '\"Askdjksdj, Bsadk Cklsjd', nameinitstring => '\"Askdjksdj, BC' },
    { namestring => 'von Üsakdjskd, Vsajd W\`asdjh', nameinitstring => 'v Üsakdjskd, VW'  },
    { namestring => 'Xaskldjdd, Yajs\x{d}ajks~Z.', nameinitstring => 'Xaskldjdd, YZ'  },
    { namestring => 'Maksjdakj, Nsjahdajsdhj', nameinitstring => 'Maksjdakj, N'  },
);

is( makenameid(@names), 'Askdjksdj_Bsadk_Cklsjd_von_Üsakdjskd_Vsajd_Wasdjh_Xaskldjdd_Yajsdajks_Z_Maksjdakj_Nsjahdajsdhj', 'makenameid' );

is( makenameinitid(@names), 'Askdjksdj_BC_v_Üsakdjskd_VW_Xaskldjdd_YZ_Maksjdakj_N', 
    'makenameinitid' );

is( latexescape('{5}: Joe & Sons: $3.01 + 5% of some_function()'), 
               '\{5\}: Joe \& Sons: \$3.01 + 5\% of some\_function()',
               'latexescape'); 

is( terseinitials(' Goldman-Sachs,  Antonio Ludwig '),  'GSAL', 'terseinitials');

my @arrayA = qw/ a b c d e f c /;
my @arrayB = qw/ c e /;
my @AminusB = array_minus(\@arrayA, \@arrayB);
my @AminusBexpected = qw/ a b d f /;

is_deeply(\@AminusB, \@AminusBexpected, 'array_minus') ;

is(remove_outer('{Some string}'), 'Some string', 'remove_outer') ;

my $nameA =  
    { firstname => 'John',
      lastname => 'Doe', 
      prefix => undef, 
      suffix => undef, 
      namestring => 'Doe, John',
      nameinitstring => 'Doe_J' } ;
my $nameAb =  
    { firstname => 'John',  
      lastname => 'Doe', 
      prefix => undef, 
      suffix => 'Jr', 
      namestring => 'Doe, Jr, John',
      nameinitstring => 'Doe_J_J' } ;

is_deeply(parsename('John Doe'), $nameA, 'parsename 1a');

is_deeply(parsename('Doe, Jr, John'), $nameAb, 'parsename 1b');

my $nameB = 
    { firstname => 'Johann Gottfried',  
      lastname => 'Berlichingen zu Hornberg', 
      prefix => 'von', 
      suffix => undef, 
      namestring => 'von Berlichingen zu Hornberg, Johann Gottfried',
      nameinitstring => 'v_Berlichingen_zu_Hornberg_JG' } ;
my $nameBb = 
    { firstname => 'Johann Gottfried',  
      lastname => 'Berlichingen zu Hornberg', 
      prefix => 'von', 
      suffix => undef, 
      namestring => 'Berlichingen zu Hornberg, Johann Gottfried',
      nameinitstring => 'Berlichingen_zu_Hornberg_JG' } ;

is_deeply(parsename('von Berlichingen zu Hornberg, Johann Gottfried', {useprefix => 1}), 
                    $nameB, 'parsename 2a') ;

is_deeply(parsename('von Berlichingen zu Hornberg, Johann Gottfried', {useprefix => 0}), 
                    $nameBb, 'parsename 2b') ;

my $nameC = 
   {  firstname => undef , 
      lastname => 'Robert and Sons, Inc.', 
      prefix => undef, 
      suffix => undef, 
      namestring => 'Robert and Sons, Inc.',
      nameinitstring => 'Robert_and_Sons,_Inc.' } ;

is_deeply(parsename('{Robert and Sons, Inc.}'), $nameC, 'parsename 3') ;

my $nameD = 
   {  firstname => 'ʿAbdallāh', 
       lastname => 'al-Ṣāliḥ', 
         prefix => undef, 
         suffix => undef, 
     namestring => 'Ṣāliḥ, Abdallāh',
 nameinitstring => 'Ṣāliḥ_A' } ;

is_deeply(parsename('al-Ṣāliḥ, ʿAbdallāh'), $nameD, 'parsename 4') ;

is( getinitials('{\"O}zt{\"u}rk'), '{\"O}.', 'getinitials 1' ) ;
is( getinitials('{\c{C}}ok {\OE}illet'), '{\c{C}}.~{\OE}.', 'getinitials 2' ) ;
is( getinitials('Ḥusayn ʿĪsā'), 'Ḥ.~Ī.', 'getinitials 3' ) ;

is( tersify('Ä.~{\c{C}}.~{\c S}.'), 'Ä{\c{C}}{\c S}', 'tersify' ) ;

# vim: set tabstop=4 shiftwidth=4: 
