use strict;
use warnings;
use utf8;
no warnings 'utf8';

use Test::More tests => 46;

use Biber;
use Biber::Utils;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);
my $biber;
my $bibfile;
my $bibentries;
chdir("t/tdata") ;

# Set up Biber
$biber = Biber->new( unicodebbl => 1, fastsort => 1, noconf => 1 );
$biber->parse_auxfile('uniqueness1.aux');
$bibfile = Biber::Config->getoption('bibdata')->[0] . ".bib";
Biber::Config->setblxoption('maxnames', 1);
Biber::Config->setblxoption('uniquename', 1);
Biber::Config->setblxoption('uniquelist', 0);
$biber->parse_bibtex($bibfile);
$biber->prepare;
$bibentries = $biber->bib;

# Basic uniquename and hash testing
is($bibentries->entry('un1')->get_field($bibentries->entry('un1')->get_field('labelnamename'))->nth_element(1)->get_uniquename, '2', 'Uniquename requiring full name expansion - 1');
is($bibentries->entry('un2')->get_field($bibentries->entry('un2')->get_field('labelnamename'))->nth_element(1)->get_uniquename, '2', 'Uniquename requiring full name expansion - 2');
is($bibentries->entry('un5')->get_field($bibentries->entry('un5')->get_field('labelnamename'))->nth_element(1)->get_uniquename, '2', 'Uniquename requiring full name expansion - 3');
is($bibentries->entry('un3')->get_field($bibentries->entry('un2')->get_field('labelnamename'))->nth_element(1)->get_uniquename, '1', 'Uniquename requiring initials name expansion - 1');
is($bibentries->entry('un4')->get_field($bibentries->entry('un4')->get_field('labelnamename'))->nth_element(1)->get_uniquename, '1', 'Uniquename requiring initials name expansion - 2');
is($bibentries->entry('un6')->get_field('namehash'), 'AJ+1', 'Namehash and fullhash different due to maxnames setting - 1');
is($bibentries->entry('un6')->get_field('fullhash'), 'AJBM1', 'Namehash and fullhash different due to maxnames setting - 2');
is($bibentries->entry('un7')->get_field('namehash'), 'C1', 'Fullnamshash ignores SHORT* names - 1');
is($bibentries->entry('un7')->get_field('fullhash'), 'AJBM1', 'Fullnamshash ignores SHORT* names - 2');

$biber = Biber->new( unicodebbl => 1, fastsort => 1, noconf => 1 );
$biber->parse_auxfile('uniqueness2.aux');
$bibfile = Biber::Config->getoption('bibdata')->[0] . ".bib";
Biber::Config->setblxoption('maxnames', 2);
Biber::Config->setblxoption('uniquename', 2);
Biber::Config->setblxoption('uniquelist', 1);
$biber->parse_bibtex($bibfile);
$biber->prepare;
$bibentries = $biber->bib;

is($bibentries->entry('un8')->get_field($bibentries->entry('un8')->get_field('labelnamename'))->nth_element(1)->get_uniquename, '0', 'Uniquename - 1');
is($bibentries->entry('un8')->get_field($bibentries->entry('un8')->get_field('labelnamename'))->nth_element(2)->get_uniquename, '0', 'Uniquename - 2');
is($bibentries->entry('un8')->get_field($bibentries->entry('un8')->get_field('labelnamename'))->nth_element(3)->get_uniquename, '1', 'Uniquename - 3');
is($bibentries->entry('un9')->get_field($bibentries->entry('un9')->get_field('labelnamename'))->nth_element(1)->get_uniquename, '0', 'Uniquename - 4');
is($bibentries->entry('un9')->get_field($bibentries->entry('un9')->get_field('labelnamename'))->nth_element(2)->get_uniquename, '0', 'Uniquename - 5');
is($bibentries->entry('un9')->get_field($bibentries->entry('un9')->get_field('labelnamename'))->nth_element(3)->get_uniquename, '1', 'Uniquename - 6');
is($bibentries->entry('un9')->get_field($bibentries->entry('un9')->get_field('labelnamename'))->nth_element(4)->get_uniquename, '0', 'Uniquename - 7');
is($bibentries->entry('un10')->get_field($bibentries->entry('un10')->get_field('labelnamename'))->nth_element(1)->get_uniquename, '0', 'Uniquename - 8');

is($bibentries->entry('un8')->get_field($bibentries->entry('un8')->get_field('labelnamename'))->get_uniquelist, '3', 'Uniquelist - 1');
is($bibentries->entry('un9')->get_field($bibentries->entry('un9')->get_field('labelnamename'))->get_uniquelist, '3', 'Uniquelist - 2');
is($bibentries->entry('un10')->get_field($bibentries->entry('un10')->get_field('labelnamename'))->get_uniquelist, '1', 'Uniquelist - 3');


$biber = Biber->new( unicodebbl => 1, fastsort => 1, noconf => 1 );
$biber->parse_auxfile('uniqueness3.aux');
$bibfile = Biber::Config->getoption('bibdata')->[0] . ".bib";
Biber::Config->setblxoption('maxnames', 3);
Biber::Config->setblxoption('uniquename', 2);
Biber::Config->setblxoption('uniquelist', 0);
Biber::Config->setblxoption('singletitle', 1);
Biber::Config->setblxoption('labelyear', [ 'year' ]);
$biber->parse_bibtex($bibfile);
$biber->prepare;
$bibentries = $biber->bib;
is($bibentries->entry('ey1')->get_field('extrayear'), '1', 'Extrayear - 1');
is($bibentries->entry('ey2')->get_field('extrayear'), '2', 'Extrayear - 2');
is($bibentries->entry('ey3')->get_field('extrayear'), '1', 'Extrayear - 3');
is($bibentries->entry('ey4')->get_field('extrayear'), '2', 'Extrayear - 4');
is($bibentries->entry('ey5')->get_field('extrayear'), '1', 'Extrayear - 5');
is($bibentries->entry('ey6')->get_field('extrayear'), '2', 'Extrayear - 6');
ok(is_undef($bibentries->entry('ey1')->get_field('singletitle')), 'Singletitle - 1');
ok(is_undef($bibentries->entry('ey2')->get_field('singletitle')), 'Singletitle - 2');
ok(is_undef($bibentries->entry('ey5')->get_field('singletitle')), 'Singletitle - 3');


$biber = Biber->new( unicodebbl => 1, fastsort => 1, noconf => 1 );
$biber->parse_auxfile('uniqueness3.aux');
$bibfile = Biber::Config->getoption('bibdata')->[0] . ".bib";
Biber::Config->setblxoption('maxnames', 3);
Biber::Config->setblxoption('uniquename', 1);
Biber::Config->setblxoption('uniquelist', 1);
Biber::Config->setblxoption('singletitle', 1);
Biber::Config->setblxoption('labelyear', [ 'year' ]);
$biber->parse_bibtex($bibfile);
$biber->prepare;
$bibentries = $biber->bib;

ok(is_undef($bibentries->entry('ey1')->get_field('extrayear')), 'Extrayear - 7');
ok(is_undef($bibentries->entry('ey2')->get_field('extrayear')), 'Extrayear - 8');
is($bibentries->entry('ey3')->get_field('extrayear'), '1', 'Extrayear - 9');
is($bibentries->entry('ey4')->get_field('extrayear'), '2', 'Extrayear - 10');
ok(is_undef($bibentries->entry('ey5')->get_field('extrayear')), 'Extrayear - 11');
ok(is_undef($bibentries->entry('ey6')->get_field('extrayear')), 'Extrayear - 12');
is($bibentries->entry('ey1')->get_field('singletitle'), '1', 'Singletitle - 4');
is($bibentries->entry('ey2')->get_field('singletitle'), '1', 'Singletitle - 5');
is($bibentries->entry('ey5')->get_field('singletitle'), '1', 'Singletitle - 6');

$biber = Biber->new( unicodebbl => 1, fastsort => 1, noconf => 1 );
$biber->parse_auxfile('uniqueness3.aux');
$bibfile = Biber::Config->getoption('bibdata')->[0] . ".bib";
Biber::Config->setblxoption('maxnames', 3);
Biber::Config->setblxoption('uniquename', 0);
Biber::Config->setblxoption('uniquelist', 0);
Biber::Config->setblxoption('singletitle', 1);
Biber::Config->setblxoption('labelyear', [ 'year' ]);
$biber->parse_bibtex($bibfile);
$biber->prepare;
$bibentries = $biber->bib;

is($bibentries->entry('ey1')->get_field('extrayear'), '1', 'Extrayear - 13');
is($bibentries->entry('ey2')->get_field('extrayear'), '2', 'Extrayear - 14');
is($bibentries->entry('ey3')->get_field('extrayear'), '1', 'Extrayear - 15');
is($bibentries->entry('ey4')->get_field('extrayear'), '2', 'Extrayear - 16');
is($bibentries->entry('ey5')->get_field('extrayear'), '1', 'Extrayear - 17');
is($bibentries->entry('ey6')->get_field('extrayear'), '2', 'Extrayear - 18');
ok(is_undef($bibentries->entry('ey1')->get_field('singletitle')), 'Singletitle - 7');
ok(is_undef($bibentries->entry('ey2')->get_field('singletitle')), 'Singletitle - 8');

unlink "$bibfile.utf8";