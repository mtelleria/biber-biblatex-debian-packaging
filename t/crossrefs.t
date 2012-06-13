# -*- cperl -*-
use strict;
use warnings;
use utf8;
no warnings 'utf8';

use Test::More tests => 31;

use Biber;
use Biber::Output::bbl;
use Log::Log4perl;
use Capture::Tiny qw(capture);
use Biber::Utils;

chdir("t/tdata");

# Set up Biber object
my $biber = Biber->new(noconf => 1);

# Note stderr is output here so we can capture it and do a cyclic crossref test
my $LEVEL = 'ERROR';
my $l4pconf = qq|
    log4perl.category.main                             = $LEVEL, Screen
    log4perl.category.screen                           = $LEVEL, Screen
    log4perl.appender.Screen                           = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.utf8                      = 1
    log4perl.appender.Screen.Threshold                 = $LEVEL
    log4perl.appender.Screen.stderr                    = 1
    log4perl.appender.Screen.layout                    = Log::Log4perl::Layout::SimpleLayout
|;

Log::Log4perl->init(\$l4pconf);

$biber->parse_ctrlfile('crossrefs.bcf');
$biber->set_output_obj(Biber::Output::bbl->new());

# Options - we could set these in the control file but it's nice to see what we're
# relying on here for tests

# Biber options
Biber::Config->setoption('fastsort', 1);
Biber::Config->setoption('sortlocale', 'C');
Biber::Config->setoption('nodieonerror', 1); # because there is a failing cyclic crossref check
Biber::Config->setoption('crossref_tree', 1);

# Now generate the information
my (undef, $stderr) = capture { $biber->prepare };
my $section0 = $biber->sections->get_section(0);
my $main0 = $biber->sortlists->get_list(0, 'entry', 'MAIN');
my $section1 = $biber->sections->get_section(1);
my $main1 = $biber->sortlists->get_list(1, 'entry', 'MAIN');
my $out = $biber->get_output_obj;

# crossref field is included as the parent is included by being crossrefed >= mincrossrefs times
my $cr1 = q|    \entry{cr1}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=121b6dc164b5b619c81c670fbd823f12}{Gullam}{G\bibinitperiod}{Graham}{G\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=121b6dc164b5b619c81c670fbd823f12}{Gullam}{G\bibinitperiod}{Graham}{G\bibinitperiod}{}{}{}{}}%
      }
      \name{editor}{1}{}{%
        {{hash=c129df5593fdaa7475548811bfbb227d}{Erbriss}{E\bibinitperiod}{Edgar}{E\bibinitperiod}{}{}{}{}}%
      }
      \list{publisher}{1}{%
        {Grimble}%
      }
      \strng{namehash}{121b6dc164b5b619c81c670fbd823f12}
      \strng{fullhash}{121b6dc164b5b619c81c670fbd823f12}
      \field{sortinit}{G}
      \field{labelyear}{1974}
      \field{booktitle}{Graphs of the Continent}
      \strng{crossref}{cr_m}
      \field{eprintclass}{SOMECLASS}
      \field{eprinttype}{SomEPrFiX}
      \field{origyear}{1955}
      \field{title}{Great and Good Graphs}
      \field{year}{1974}
    \endentry
|;

# crossref field is included as the parent is included by being crossrefed >= mincrossrefs times
my $cr2 = q|    \entry{cr2}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=2d51a96bc0a6804995b3a9ff350c3384}{Fumble}{F\bibinitperiod}{Frederick}{F\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=2d51a96bc0a6804995b3a9ff350c3384}{Fumble}{F\bibinitperiod}{Frederick}{F\bibinitperiod}{}{}{}{}}%
      }
      \name{editor}{1}{}{%
        {{hash=c129df5593fdaa7475548811bfbb227d}{Erbriss}{E\bibinitperiod}{Edgar}{E\bibinitperiod}{}{}{}{}}%
      }
      \list{institution}{1}{%
        {Institution}%
      }
      \list{publisher}{1}{%
        {Grimble}%
      }
      \strng{namehash}{2d51a96bc0a6804995b3a9ff350c3384}
      \strng{fullhash}{2d51a96bc0a6804995b3a9ff350c3384}
      \field{sortinit}{F}
      \field{labelyear}{1974}
      \field{booktitle}{Graphs of the Continent}
      \strng{crossref}{cr_m}
      \field{origyear}{1943}
      \field{title}{Fabulous Fourier Forms}
      \field{year}{1974}
      \warn{\item Field 'school' is aliased to field 'institution' but both are defined in entry with key 'cr2' - skipping alias}
    \endentry
|;

# This is included as it is crossrefed >= mincrossrefs times
# Notice lack of labelname and hashes because the only name is EDITOR and useeditor is false
my $cr_m = q|    \entry{cr_m}{book}{}
      \name{editor}{1}{}{%
        {{hash=c129df5593fdaa7475548811bfbb227d}{Erbriss}{E\bibinitperiod}{Edgar}{E\bibinitperiod}{}{}{}{}}%
      }
      \list{publisher}{1}{%
        {Grimble}%
      }
      \field{sortinit}{G}
      \field{labelyear}{1974}
      \field{title}{Graphs of the Continent}
      \field{year}{1974}
    \endentry
|;

# crossref field is included as the parent is cited
my $cr3 = q|    \entry{cr3}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=2baf676a220704f6914223aefccaaa88}{Aptitude}{A\bibinitperiod}{Arthur}{A\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=2baf676a220704f6914223aefccaaa88}{Aptitude}{A\bibinitperiod}{Arthur}{A\bibinitperiod}{}{}{}{}}%
      }
      \name{editor}{1}{}{%
        {{hash=a1f5c22413396d599ec766725b226735}{Monkley}{M\bibinitperiod}{Mark}{M\bibinitperiod}{}{}{}{}}%
      }
      \list{publisher}{1}{%
        {Rancour}%
      }
      \strng{namehash}{2baf676a220704f6914223aefccaaa88}
      \strng{fullhash}{2baf676a220704f6914223aefccaaa88}
      \field{sortinit}{A}
      \field{labelyear}{1996}
      \field{booktitle}{Beasts of the Burbling Burns}
      \strng{crossref}{crt}
      \field{eprinttype}{sometype}
      \field{origyear}{1934}
      \field{title}{Arrangements of All Articles}
      \field{year}{1996}
      \warn{\item Field 'archiveprefix' is aliased to field 'eprinttype' but both are defined in entry with key 'cr3' - skipping alias}
    \endentry
|;

# cited as normal
my $crt = q|    \entry{crt}{book}{}
      \name{editor}{1}{}{%
        {{hash=a1f5c22413396d599ec766725b226735}{Monkley}{M\bibinitperiod}{Mark}{M\bibinitperiod}{}{}{}{}}%
      }
      \list{publisher}{1}{%
        {Rancour}%
      }
      \field{sortinit}{B}
      \field{labelyear}{1996}
      \field{title}{Beasts of the Burbling Burns}
      \field{year}{1996}
    \endentry
|;

# various event fields inherited correctly
my $cr6 = q|    \entry{cr6}{inproceedings}{}
      \name{labelname}{1}{}{%
        {{hash=8ab39ee68c55046dc1f05d657fcefed9}{Author}{A\bibinitperiod}{Firstname}{F\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=8ab39ee68c55046dc1f05d657fcefed9}{Author}{A\bibinitperiod}{Firstname}{F\bibinitperiod}{}{}{}{}}%
      }
      \name{editor}{1}{}{%
        {{hash=344a7f427fb765610ef96eb7bce95257}{Editor}{E\bibinitperiod}{}{}{}{}{}{}}%
      }
      \list{location}{1}{%
        {Address}%
      }
      \strng{namehash}{8ab39ee68c55046dc1f05d657fcefed9}
      \strng{fullhash}{8ab39ee68c55046dc1f05d657fcefed9}
      \field{sortinit}{A}
      \field{labelyear}{2009}
      \field{booktitle}{Manual booktitle}
      \field{eventday}{21}
      \field{eventendday}{24}
      \field{eventendmonth}{08}
      \field{eventendyear}{2009}
      \field{eventmonth}{08}
      \field{eventtitle}{Title of the event}
      \field{eventyear}{2009}
      \field{title}{Title of inproceeding}
      \field{venue}{Location of event}
      \field{year}{2009}
      \field{pages}{123\bibrangedash}
    \endentry
|;

# Special fields inherited correctly
my $cr7 = q|    \entry{cr7}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=8ab39ee68c55046dc1f05d657fcefed9}{Author}{A\bibinitperiod}{Firstname}{F\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=8ab39ee68c55046dc1f05d657fcefed9}{Author}{A\bibinitperiod}{Firstname}{F\bibinitperiod}{}{}{}{}}%
      }
      \name{bookauthor}{1}{}{%
        {{hash=91a1dd4aeed3c4ec29ca74c4e778be5f}{Bookauthor}{B\bibinitperiod}{Brian}{B\bibinitperiod}{}{}{}{}}%
      }
      \list{publisher}{1}{%
        {Publisher of proceeding}%
      }
      \strng{namehash}{8ab39ee68c55046dc1f05d657fcefed9}
      \strng{fullhash}{8ab39ee68c55046dc1f05d657fcefed9}
      \field{sortinit}{A}
      \field{labelyear}{2010}
      \field{booksubtitle}{Book Subtitle}
      \field{booktitle}{Book Title}
      \field{booktitleaddon}{Book Titleaddon}
      \field{title}{Title of Book bit}
      \field{year}{2010}
      \field{pages}{123\bibrangedash 126}
      \verb{verbb}
      \verb String
      \endverb
    \endentry
|;

# Default inheritance supressed except for specified
my $cr8 = q|    \entry{cr8}{incollection}{}
      \name{labelname}{1}{}{%
        {{hash=3d449e56eb3ca1ae80dc99a18d689795}{Smith}{S\bibinitperiod}{Firstname}{F\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=3d449e56eb3ca1ae80dc99a18d689795}{Smith}{S\bibinitperiod}{Firstname}{F\bibinitperiod}{}{}{}{}}%
      }
      \strng{namehash}{3d449e56eb3ca1ae80dc99a18d689795}
      \strng{fullhash}{3d449e56eb3ca1ae80dc99a18d689795}
      \field{sortinit}{S}
      \field{labelyear}{2010}
      \field{booktitle}{Book Title}
      \field{title}{Title of Collection bit}
      \field{year}{2010}
      \field{pages}{1\bibrangedash 12}
    \endentry
|;

# xref field is included as the parent is included by being crossrefed >= mincrossrefs times
my $xr1 = q|    \entry{xr1}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=e0ecc4fc668ee499d1afba44e1ac064d}{Zentrum}{Z\bibinitperiod}{Zoe}{Z\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=e0ecc4fc668ee499d1afba44e1ac064d}{Zentrum}{Z\bibinitperiod}{Zoe}{Z\bibinitperiod}{}{}{}{}}%
      }
      \strng{namehash}{e0ecc4fc668ee499d1afba44e1ac064d}
      \strng{fullhash}{e0ecc4fc668ee499d1afba44e1ac064d}
      \field{sortinit}{Z}
      \field{origyear}{1921}
      \field{title}{Moods Mildly Modified}
      \strng{xref}{xrm}
    \endentry
|;

# xref field is included as the parent is included by being crossrefed >= mincrossrefs times
my $xr2 = q|    \entry{xr2}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=6afa09374ecfd6b394ce714d2d9709c7}{Instant}{I\bibinitperiod}{Ian}{I\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=6afa09374ecfd6b394ce714d2d9709c7}{Instant}{I\bibinitperiod}{Ian}{I\bibinitperiod}{}{}{}{}}%
      }
      \strng{namehash}{6afa09374ecfd6b394ce714d2d9709c7}
      \strng{fullhash}{6afa09374ecfd6b394ce714d2d9709c7}
      \field{sortinit}{I}
      \field{origyear}{1926}
      \field{title}{Migraines Multiplying Madly}
      \strng{xref}{xrm}
    \endentry
|;

# This is included as it is crossrefed >= mincrossrefs times
# Notice lack of labelname and hashes because the only name is EDITOR and useeditor is false
my $xrm = q|    \entry{xrm}{book}{}
      \name{editor}{1}{}{%
        {{hash=809950f9b59ae207092b909a19dcb27b}{Prendergast}{P\bibinitperiod}{Peter}{P\bibinitperiod}{}{}{}{}}%
      }
      \list{publisher}{1}{%
        {Mainstream}%
      }
      \field{sortinit}{C}
      \field{labelyear}{1970}
      \field{title}{Calligraphy, Calisthenics, Culture}
      \field{year}{1970}
    \endentry
|;

# xref field is included as the parent is cited
my $xr3 = q|    \entry{xr3}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=9788055665b9bb4b37c776c3f6b74f16}{Normal}{N\bibinitperiod}{Norman}{N\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=9788055665b9bb4b37c776c3f6b74f16}{Normal}{N\bibinitperiod}{Norman}{N\bibinitperiod}{}{}{}{}}%
      }
      \strng{namehash}{9788055665b9bb4b37c776c3f6b74f16}
      \strng{fullhash}{9788055665b9bb4b37c776c3f6b74f16}
      \field{sortinit}{N}
      \field{origyear}{1923}
      \field{title}{Russion Regalia Revisited}
      \strng{xref}{xrt}
    \endentry
|;

# cited as normal
my $xrt = q|    \entry{xrt}{book}{}
      \name{editor}{1}{}{%
        {{hash=bf7d6b02f3e073913e5bfe5059508dd5}{Lunders}{L\bibinitperiod}{Lucy}{L\bibinitperiod}{}{}{}{}}%
      }
      \list{publisher}{1}{%
        {Middling}%
      }
      \field{sortinit}{K}
      \field{labelyear}{1977}
      \field{title}{Kings, Cork and Calculation}
      \field{year}{1977}
    \endentry
|;

# No crossref field as parent is not cited (mincrossrefs < 2)
my $cr4 = q|    \entry{cr4}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=50ef7fd3a1be33bccc5de2768b013836}{Mumble}{M\bibinitperiod}{Morris}{M\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=50ef7fd3a1be33bccc5de2768b013836}{Mumble}{M\bibinitperiod}{Morris}{M\bibinitperiod}{}{}{}{}}%
      }
      \name{editor}{1}{}{%
        {{hash=6ea89bd4958743a20b70fe17647d6af5}{Jermain}{J\bibinitperiod}{Jeremy}{J\bibinitperiod}{}{}{}{}}%
      }
      \list{publisher}{1}{%
        {Pillsbury}%
      }
      \strng{namehash}{50ef7fd3a1be33bccc5de2768b013836}
      \strng{fullhash}{50ef7fd3a1be33bccc5de2768b013836}
      \field{sortinit}{M}
      \field{labelyear}{1945}
      \field{booktitle}{Vanquished, Victor, Vandal}
      \field{origyear}{1911}
      \field{title}{Enterprising Entities}
      \field{year}{1945}
    \endentry
|;

# No crossref field as parent is not cited (mincrossrefs < 2)
my $xr4 = q|    \entry{xr4}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=7804ffef086c0c4686c235807f5cb502}{Mistrel}{M\bibinitperiod}{Megan}{M\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=7804ffef086c0c4686c235807f5cb502}{Mistrel}{M\bibinitperiod}{Megan}{M\bibinitperiod}{}{}{}{}}%
      }
      \strng{namehash}{7804ffef086c0c4686c235807f5cb502}
      \strng{fullhash}{7804ffef086c0c4686c235807f5cb502}
      \field{sortinit}{M}
      \field{origyear}{1933}
      \field{title}{Lumbering Lunatics}
    \endentry
|;

# Missing keys in xref/crossref should be deleted during datasource parse
# So these two should have no xref/crossref data in them
my $mxr = q|    \entry{mxr}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=7804ffef086c0c4686c235807f5cb502}{Mistrel}{M\bibinitperiod}{Megan}{M\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=7804ffef086c0c4686c235807f5cb502}{Mistrel}{M\bibinitperiod}{Megan}{M\bibinitperiod}{}{}{}{}}%
      }
      \strng{namehash}{7804ffef086c0c4686c235807f5cb502}
      \strng{fullhash}{7804ffef086c0c4686c235807f5cb502}
      \field{sortinit}{M}
      \field{origyear}{1933}
      \field{title}{Lumbering Lunatics}
    \endentry
|;

my $mcr = q|    \entry{mcr}{inbook}{}
      \name{labelname}{1}{}{%
        {{hash=7804ffef086c0c4686c235807f5cb502}{Mistrel}{M\bibinitperiod}{Megan}{M\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=7804ffef086c0c4686c235807f5cb502}{Mistrel}{M\bibinitperiod}{Megan}{M\bibinitperiod}{}{}{}{}}%
      }
      \strng{namehash}{7804ffef086c0c4686c235807f5cb502}
      \strng{fullhash}{7804ffef086c0c4686c235807f5cb502}
      \field{sortinit}{M}
      \field{origyear}{1933}
      \field{title}{Lumbering Lunatics}
    \endentry
|;

my $ccr1 = q|    \entry{ccr2}{book}{}
      \name{labelname}{1}{}{%
        {{hash=6268941b408d3263bddb208a54899ea9}{Various}{V\bibinitperiod}{Vince}{V\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=6268941b408d3263bddb208a54899ea9}{Various}{V\bibinitperiod}{Vince}{V\bibinitperiod}{}{}{}{}}%
      }
      \name{editor}{1}{}{%
        {{hash=cfee758a1c82df2e26af1985e061bb0a}{Editor}{E\bibinitperiod}{Edward}{E\bibinitperiod}{}{}{}{}}%
      }
      \strng{namehash}{6268941b408d3263bddb208a54899ea9}
      \strng{fullhash}{6268941b408d3263bddb208a54899ea9}
      \field{sortinit}{V}
      \field{labelyear}{1923}
      \strng{crossref}{ccr1}
      \field{title}{Misc etc.}
      \field{year}{1923}
    \endentry
|;

my $ccr2 = q|    \entry{ccr3}{inbook}{}
      \name{bookauthor}{1}{}{%
        {{hash=6268941b408d3263bddb208a54899ea9}{Various}{V\bibinitperiod}{Vince}{V\bibinitperiod}{}{}{}{}}%
      }
      \name{editor}{1}{}{%
        {{hash=cfee758a1c82df2e26af1985e061bb0a}{Editor}{E\bibinitperiod}{Edward}{E\bibinitperiod}{}{}{}{}}%
      }
      \field{sortinit}{P}
      \field{labelyear}{1911}
      \field{booktitle}{Misc etc.}
      \strng{crossref}{ccr2}
      \field{title}{Perhaps, Perchance, Possibilities?}
      \field{year}{1911}
    \endentry
|;

# This is strange in what it gets from where but it shows information being inherited from two
# sources
my $ccr3 = q|    \entry{ccr4}{inbook}{}
      \name{bookauthor}{1}{}{%
        {{hash=6268941b408d3263bddb208a54899ea9}{Various}{V\bibinitperiod}{Vince}{V\bibinitperiod}{}{}{}{}}%
      }
      \name{editor}{1}{}{%
        {{hash=cfee758a1c82df2e26af1985e061bb0a}{Editor}{E\bibinitperiod}{Edward}{E\bibinitperiod}{}{}{}{}}%
      }
      \field{sortinit}{S}
      \field{labelyear}{1911}
      \field{booktitle}{Misc etc.}
      \field{title}{Stuff Concerning Varia}
      \field{year}{1911}
    \endentry
|;


is($out->get_output_entry($main0,'cr1'), $cr1, 'crossref test 1');
is($out->get_output_entry($main0,'cr2'), $cr2, 'crossref test 2');
is($out->get_output_entry($main0,'cr_m'), $cr_m, 'crossref test 3');
is($out->get_output_entry($main0,'cr3'), $cr3, 'crossref test 4');
is($out->get_output_entry($main0,'crt'), $crt, 'crossref test 5');
is($out->get_output_entry($main0,'cr4'), $cr4, 'crossref test 6');
is($section0->has_citekey('crn'), 0,'crossref test 7');
is($out->get_output_entry($main0,'cr6'), $cr6, 'crossref test (inheritance) 8');
is($out->get_output_entry($main0,'cr7'), $cr7, 'crossref test (inheritance) 9');
is($out->get_output_entry($main0,'cr8'), $cr8, 'crossref test (inheritance) 10');
is($out->get_output_entry($main0,'xr1'), $xr1, 'xref test 1');
is($out->get_output_entry($main0,'xr2'), $xr2, 'xref test 2');
is($out->get_output_entry($main0,'xrm'), $xrm, 'xref test 3');
is($out->get_output_entry($main0,'xr3'), $xr3, 'xref test 4');
is($out->get_output_entry($main0,'xrt'), $xrt, 'xref test 5');
is($out->get_output_entry($main0,'xr4'), $xr4, 'xref test 6');
is($section0->has_citekey('xrn'), 0,'xref test 7');
is($out->get_output_entry($main0,'mxr'), $mxr, 'missing xref test');
is($out->get_output_entry($main0,'mcr'), $mcr, 'missing crossef test');
is($section1->has_citekey('crn'), 0,'mincrossrefs reset between sections');
is($out->get_output_entry($main0,'ccr2'), $ccr1, 'cascading crossref test 1');
is($out->get_output_entry($main0,'ccr3'), $ccr2, 'cascading crossref test 2');
chomp $stderr;
is($stderr, "ERROR - Circular inheritance between 'circ1'<->'circ2'", 'Cyclic crossref error check');
is($section0->has_citekey('r1'), 1,'Recursive crossref test 1');
ok(defined($section0->bibentry('r1')),'Recursive crossref test 2');
is($section0->has_citekey('r2'), 0,'Recursive crossref test 3');
ok(defined($section0->bibentry('r2')),'Recursive crossref test 4');
is($section0->has_citekey('r3'), 0,'Recursive crossref test 5');
ok(defined($section0->bibentry('r3')),'Recursive crossref test 6');
is($section0->has_citekey('r4'), 0,'Recursive crossref test 7');
ok(defined($section0->bibentry('r4')),'Recursive crossref test 8');


