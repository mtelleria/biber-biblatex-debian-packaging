# -*- cperl -*-
use strict;
use warnings;
use utf8;
no warnings 'utf8';

use Test::More tests => 9;

use Biber;
use Biber::Output::bbl;
use Biber::Input::file::bibtex;
use Log::Log4perl;
chdir("t/tdata");

# Set up Biber object
my $biber = Biber->new(noconf => 1);
my $LEVEL = 'ERROR';
my $l4pconf = qq|
    log4perl.category.main                             = $LEVEL, Screen
    log4perl.category.screen                           = $LEVEL, Screen
    log4perl.appender.Screen                           = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.utf8                      = 1
    log4perl.appender.Screen.Threshold                 = $LEVEL
    log4perl.appender.Screen.stderr                    = 0
    log4perl.appender.Screen.layout                    = Log::Log4perl::Layout::SimpleLayout
|;
Log::Log4perl->init(\$l4pconf);

$biber->parse_ctrlfile('sort-complex.bcf');
$biber->set_output_obj(Biber::Output::bbl->new());

# Options - we could set these in the control file but it's nice to see what we're
# relying on here for tests

# Biber options
Biber::Config->setoption('fastsort', 1);
Biber::Config->setoption('sortlocale', 'C');
# Want to ignore SHORTHAND* fields for the first few tests
Biber::Config->setoption('sourcemap', [
  {
    datatype => "bibtex",
    map => [
      {
        map_step => [{ map_field_set => "SHORTHAND", map_null => 1 },
                     { map_field_set => "SORTSHORTHAND", map_null => 1 }]
      }]}]);

# Biblatex options
Biber::Config->setblxoption('labelyear', undef);

# Now generate the information
$biber->prepare;
my $section = $biber->sections->get_section(0);
my $bibentries = $section->bibentries;
my $main = $biber->sortlists->get_list(0, 'entry', 'MAIN');
my $shs = $biber->sortlists->get_list(0, 'shorthand', 'SHORTHANDS');
my $out = $biber->get_output_obj;

my $ss = [
           [
            {},
            {'presort'    => {}}
           ],
           [
            {'final' => 1},
            {'sortkey'    => {}}
           ],
           [
            {},
            {'labelalpha'    => {}},
           ],
           [
            {},
            {'sortname'   => {}},
            {'author'     => {}},
            {'editor'     => {}},
            {'translator' => {}},
            {'sorttitle'  => {}},
            {'title'      => {}}
           ],
           [
            {},
            {'sortyear'  => {}},
            {'year'      => {}}
           ],
           [
            {},
            {'sorttitle'       => {}},
            {'title'       => {}}
           ],
           [
            {},
            {'volume'     => {pad_char => '0',
                              pad_side => 'left',
                              pad_width => '4'}},
            {'0000'       => {}}
           ],
          ];

my $l4 = q|    \entry{L4}{book}{}
      \true{morelabelname}
      \name{labelname}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \true{moreauthor}
      \name{author}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \list{location}{1}{%
        {Cambridge}%
      }
      \list{publisher}{1}{%
        {Another press}%
      }
      \strng{namehash}{6eb389989020e8246fee90ac93fcecbe}
      \strng{fullhash}{6eb389989020e8246fee90ac93fcecbe}
      \field{labelalpha}{Doe\textbf{+}95}
      \field{sortinit}{D}
      \field{extraalpha}{2}
      \field{title}{Some title about sorting}
      \field{year}{1995}
    \endentry
|;

my $l1 = q|    \entry{L1}{book}{}
      \name{labelname}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \list{location}{1}{%
        {Cambridge}%
      }
      \list{publisher}{1}{%
        {A press}%
      }
      \strng{namehash}{bd051a2f7a5f377e3a62581b0e0f8577}
      \strng{fullhash}{bd051a2f7a5f377e3a62581b0e0f8577}
      \field{labelalpha}{Doe95}
      \field{sortinit}{D}
      \field{extraalpha}{1}
      \field{title}{Algorithms For Sorting}
      \field{year}{1995}
    \endentry
|;

my $l2 = q|    \entry{L2}{book}{}
      \name{labelname}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \list{location}{1}{%
        {Cambridge}%
      }
      \list{publisher}{1}{%
        {A press}%
      }
      \strng{namehash}{bd051a2f7a5f377e3a62581b0e0f8577}
      \strng{fullhash}{bd051a2f7a5f377e3a62581b0e0f8577}
      \field{labelalpha}{Doe95}
      \field{sortinit}{D}
      \field{extraalpha}{3}
      \field{title}{Sorting Algorithms}
      \field{year}{1995}
    \endentry
|;

my $l3 = q|    \entry{L3}{book}{}
      \name{labelname}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \name{author}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \list{location}{1}{%
        {Cambridge}%
      }
      \list{publisher}{1}{%
        {A press}%
      }
      \strng{namehash}{bd051a2f7a5f377e3a62581b0e0f8577}
      \strng{fullhash}{bd051a2f7a5f377e3a62581b0e0f8577}
      \field{labelalpha}{Doe95}
      \field{sortinit}{D}
      \field{extraalpha}{2}
      \field{title}{More and More Algorithms}
      \field{year}{1995}
    \endentry
|;

my $l5 = q|    \entry{L5}{book}{}
      \true{morelabelname}
      \name{labelname}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \true{moreauthor}
      \name{author}{1}{}{%
        {{hash=bd051a2f7a5f377e3a62581b0e0f8577}{Doe}{D\bibinitperiod}{John}{J\bibinitperiod}{}{}{}{}}%
      }
      \list{location}{1}{%
        {Cambridge}%
      }
      \list{publisher}{1}{%
        {Another press}%
      }
      \strng{namehash}{6eb389989020e8246fee90ac93fcecbe}
      \strng{fullhash}{6eb389989020e8246fee90ac93fcecbe}
      \field{labelalpha}{Doe\textbf{+}95}
      \field{sortinit}{D}
      \field{extraalpha}{1}
      \field{title}{Some other title about sorting}
      \field{year}{1995}
    \endentry
|;


is_deeply( $main->get_sortscheme , $ss, 'sort scheme');
is( $out->get_output_entry($main,'L4'), $l4, '\alphaothers set by "and others"');
is( $out->get_output_entry($main,'L1'), $l1, 'bbl test 1');
is( $out->get_output_entry($main,'L2'), $l2, 'bbl test 2');
is( $out->get_output_entry($main,'L3'), $l3, 'bbl test 3');
is( $out->get_output_entry($main,'L5'), $l5, 'bbl test 4');
is_deeply([ $main->get_keys ], ['L5', 'L4', 'L1', 'L3', 'L2'], 'sortorder - 1');

# This would be the same as $main citeorder as both $main and $shs use same
# global sort spec but here it's null because we've removed all shorthands using a map
# above and the filter for the SHORTHANDS list only uses entries with SHORTHAND fields ...
is_deeply([ $shs->get_keys ], [], 'sortorder - 2');

# reset options and regenerate information
Biber::Config->setoption('sourcemap', undef); # no longer ignore shorthand*
# Have to set the sortscheme for the shorthand list explicitly as the sortlos option is processed
# during control file parsing so it won't be done automatically here. This is only a problem
# in tests where we want to change sortlos and re-run
$shs->set_sortscheme([
                      [ {'final' => 1},
                        {'sortshorthand'    => {}}
                      ],
                      [ {}, {'shorthand'     => {}} ] ]);
$main->set_sortscheme([
                       [ {'final' => 1},
                         {'shorthand'    => {}}
                       ]]);

# Need to reset all entries due to "skip if already in Entries"
# clause in bibtex.pm. Need to clear the cache as we've modified the T::B objects
# by the sourcemap. Need to clear everykeys otherwise we'll just skip the keys
$bibentries->del_entries;
$section->del_everykeys;
Biber::Input::file::bibtex->init_cache;
$biber->prepare;
$section = $biber->sections->get_section(0);
$shs = $biber->sortlists->get_list(0, 'shorthand', 'SHORTHANDS');

# Sort by shorthand
is_deeply([ $shs->get_keys ], ['L1', 'L2', 'L3', 'L4', 'L5'], 'sortorder - 3');

