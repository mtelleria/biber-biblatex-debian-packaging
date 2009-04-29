package Biber ;
use strict ;
use warnings ;
use Carp ;
use IO::File ;
use Encode ;
use POSIX qw/locale_h/ ; # for sorting with built-in "sort"
use Biber::Constants ;
use List::Util qw( first );
use Biber::Internals ;
use Biber::Utils ;
use LaTeX::Decode ;
use base 'Biber::Internals' ;
our @ISA ;

=head1 NAME

Biber - main module for biber, a bibtex replacement for users of biblatex

=head1 VERSION

Version 0.4.2

=cut

our $VERSION = '0.4.2' ;

=head1 SYNOPSIS

    use Biber ;

    my $biber = Biber->new() ;
    $biber->parse_auxfile("example.aux");
    $biber->prepare;
    $biber->print_to_bbl("example.bbl");

=cut

#TODO read config file (e.g. $HOME/.biber.conf to change default options)

#TODO put the following hashes in a Biber::Config object ?
our %seenkeys    = () ;
our %crossrefkeys = () ;
our %entrieswithcrossref = () ;
our %inset_entries = () ;
our %localoptions = () ;
our %seennamehash = () ;
our %uniquenamecount = () ;
our %seenauthoryear = () ;
our %seenlabelyear = () ;
our %is_name_entry = map { $_ => 1 } @NAMEFIELDS ;

=head1 FUNCTIONS

=head2 new

    Initialize the Biber object, optionally passing options as argument in a hashref.

    my $opts = { fastsort => 1, datafile => 'biblatex.xml', outfile => 'test.bbl' } ;
    my $biber = Biber->new($opts) ;

=cut

sub new {
    my ($class, $opts) = @_ ;
    my $self = bless {}, $class ;
    $self->_initopts() ;
    $self->_initblxopts() ;
    if ($opts) {
        my %params = %$opts;
        foreach (keys %params) {
            $self->{config}->{$_} = $params{$_} ;
        }
    };
    return $self
}

sub _initblxopts {
    my $self = shift ;
    foreach (keys %BLX_CONFIG_DEFAULT) {
        $self->{config}{biblatex}{global}{$_} = $BLX_CONFIG_DEFAULT{$_}
    }
    return;
}

=head2 config

    Returns the value of a biber configuration parameter.

    $biber->config('param') ;

=cut

sub config {
    my ($self, $opt) = @_ ;
    return $self->{config}->{$opt};
}

sub _initopts {
    my $self = shift ;
    foreach (keys %CONFIG_DEFAULT) {
        $self->{config}->{$_} = $CONFIG_DEFAULT{$_}
    }
    return;
}

=head2 citekeys

    my @citekeys = $biber->citekeys ;
    
    Returns the array of all citation keys currently registered by Biber.

=cut

sub citekeys {
    my $self = shift ;
    if ( $self->{citekeys} ) {
        return @{ $self->{citekeys} }
    } else {
        return ()
    }
}

=head2 bibentry

    my %bibentry = $biber->bibentry($citekey) ;
    
    Returns a hash containing the data of bibliographic entry for a given citekey.

=cut

sub bibentry {
    my ($self, $key) = @_ ;
    return %{ $self->{bib}->{$key} }
    # TODO return bless $self->{bib}->{$key}, Biber::Entry
}

=head2 bib

    Return a hash containing all bibliographic data.

=cut

sub bib {
    my $self = shift ;
    if ( $self->{bib} ) {
        return %{ $self->{bib} } 
    }
    else {
        return 
    }
}

=head2 shorthands
    
    Returns the list of all shorthands. 

=cut

sub shorthands {
    my $self = shift ;
    if ( $self->{shorthands} ) {
        return @{ $self->{shorthands} }
    } else {
        return
    }
}

sub _addshorthand {
    my ($self, $key) = @_ ;
    my @los ;
    if ( $self->{shorthands} ) {
        @los = @{ $self->{shorthands} } 
    } else {
        @los = () ;
    } ;
    push @los, $key ;
    $self->{shorthands} = [ @los ] ;    
    return
}

=head2 parse_auxfile

    Read the .aux file generated by LaTeX, identify all citekeys and configuration
    parameters, and store them in the Biber object.

=cut

sub parse_auxfile {

    my $self = shift ;
    my $auxfile = shift ; 
    my @bibdatafiles = ();
    if ($self->config('bibdata')) { 
        @bibdatafiles = @{ $self->{config}->{bibdata} }
    } ;

    my @auxcitekeys = $self->citekeys ;

    croak "Cannot find file '$auxfile'!\n" unless -f $auxfile ;
    croak "File '$auxfile' is not an .aux file!\n" unless $auxfile =~ m/\.aux$/ ;

    my $aux = new IO::File "<$auxfile" or croak "Failed to open $auxfile : $!" ;

    my $ctrl_file = "" ;

    local $/ = "\n" ;

    print "Reading $auxfile\n" unless $self->config('quiet') ;
    
    while (<$aux>) {
    
        if ( $_ =~ /^\\bibdata/ ) { 
        
            # There can be more than one bibdata file! 
            # We can parse many bib and/or xml files
            # Datafile given as option -d should be parsed first, then the other ones
            (my $bibdatastring) = $_ =~ m/^\\bibdata{ #{ <- for balancing brackets in vim
                                               ([^}]+)
                                                      }/x ;
            
            my @tmp = split/,/, $bibdatastring ; 
            
            shift @tmp ;  #PK remove this when biblatex stops putting the control file name
                          # in the AUX file.
						$ctrl_file = $auxfile;
						$ctrl_file =~ s/\.aux\z//xms;

            print "control file is $ctrl_file.bcf\n" if $self->config('biberdebug');
            
            if (defined $bibdatafiles[0]) {

                push (@bibdatafiles, @tmp) ;

            }
            else {

                @bibdatafiles = @tmp ;

            }

            $self->{config}->{bibdata} = [ @bibdatafiles ] ;
        }

        if ( $_ =~ /^\\citation/ ) { 
            m/^\\citation{ #{ for readability in vim
                          ([^}]+)
                                 }/x ;  
            if ( $1 eq '*' ) {

                $self->{config}->{allentries} = 1 ;

                print "Processing all citekeys\n" 
                    unless ( $self->config('quiet') ) ;

                # we stop reading the aux file as soon as we encounter \citation{*}
                last

            } elsif ( ! $seenkeys{$1} && ( $1 ne "biblatex-control" ) ) {

                push @auxcitekeys, decode_utf8($1) ;

                $seenkeys{$1}++

            }
        }
    }

    $self->parse_ctrlfile($ctrl_file) if $ctrl_file;
    
    unless (@bibdatafiles) {
        croak "No database is provided in the file '$auxfile'!\nExiting\n"
    }

    unless ($self->config('allentries') or @auxcitekeys) {
        croak "The file '$auxfile' does not contain any citations!\n"
    }

    print "Found ", $#auxcitekeys+1 , " citekeys in aux file\n" 
        unless ( $self->config('quiet') or $self->config('allentries') ) ;

    @auxcitekeys = sort @auxcitekeys if $self->config('biberdebug') ;

    print "The citekeys are:\n", "@auxcitekeys", "\n\n" 
        if ( $self->config('biberdebug') && ! $self->config('allentries') ) ;
    
    $self->{citekeys} = [ @auxcitekeys ] ;

    return
}

=head2 parse_ctrlfile

    This method is automatically called by parse_auxfile. It reads the control file
    generated by biblatex to figure out the various biblatex options.

=cut

sub parse_ctrlfile {
    my ($self, $ctrl_file) = @_ ;

    carp "Cannot find control file '$ctrl_file.bcf'!\n" unless -f "$ctrl_file.bcf" ;

    my $ctrl = new IO::File "<$ctrl_file.bcf"
          or croak "Cannot open $ctrl_file.bcf: $!" ;

    print "Reading $ctrl_file.bcf\n" unless $self->config('quiet');

    while (<$ctrl>) {
        next if /\A\#/xms;
				if (/\AGLOBAL\s+([^\n]+)\Z/xms) { # Global BibLaTeX options
					my $gconfig = $1;
					foreach my $c (split /\s+/, $gconfig) {
						my ($k,$v) = split /=/, $c;
						if ($k =~ /\A(?:labelname)\z/xms) { # labelname is special
							$self->{config}{biblatex}{global}{$k} = [ split /,/, $v ];
						}
						elsif ($k =~ /\A(?:sorting)\z/xms) { # sorting is even more special
							$self->{config}{biblatex}{global}{$k} = [ map {[split /:/, $_]} split /,/, $v ];
						}
						else { # normal binary or single-valued options
							$self->{config}{biblatex}{global}{$k} = $v;
						}
					}
					my $controlversion = $self->getblxoption('controlversion') ;
					carp "Warning: You are using biblatex version $controlversion : 
            biber is more likely to work with version $BIBLATEX_VERSION.\n" 
            unless substr($controlversion, 0, 3) eq $BIBLATEX_VERSION ;
				}
				elsif (/\AENTRYTYPE\s+([^\s]+)\s+([^\n]+)\Z/xms) { # Entry-type specific BibLaTeX options
					my $entrytype = $1;
					my $tconfig = $2;
					foreach my $c (split /\s+/, $tconfig) {
						my ($k,$v) = split /=/, $c;
						if ($k =~ /\A(?:labelname)\z/xms) { # labelname is special
							$self->{config}{biblatex}{$entrytype}{$k} = [ split /,/, $v ];
						}
						elsif ($k =~ /\A(?:sorting)\z/xms) { # sorting is even more special
							$self->{config}{biblatex}{$entrytype}{$k} = [ map {[split /:/, $_]} split /,/, $v ];
						}
						else { # normal binary or single-valued options
							$self->{config}{biblatex}{$entrytype}{$k} = $v;
						}
					}
				}
			}
    return;
}




#=====================================================
# Parse BIB file
#=====================================================

=head2 parse_bibtex

    This is a wrapper method to parse a bibtex database. If available it will
    pass the job to Text::BibTeX via Biber::BibTeX, otherwise if relies on a
    slower pure Perl parser implemented in Biber::BibTeX::PRD.

    $biber->parse_bibtex("data.bib") ;

=cut

sub parse_bibtex {
    my ($self, $filename) = @_ ;
    
    print "Processing bibtex file $filename\n" unless $self->config('quiet') ;

    my @localkeys = () ;

    my $ufilename = "$filename.utf8" ;

    if ( !$self->config('unicodebib') && $self->config('unicodebbl') ) {
        require LaTeX::Decode ;
        require File::Slurp ; 
        my $ubib      = IO::File->new( $ufilename, ">:utf8" ) ;
        # $ubib->binmode(':utf8') ;

        my $mode = "";

#        if ( $self->config('inputencoding') ) {
#            $mode = ':encoding(' . $self->config('inputencoding') . ')' ;
#        } else {
#            $mode = "" ;
#        } ;
        
        my $infile = IO::File->new( $filename, "<$mode" ) ;

        my $buf    = File::Slurp::read_file($infile) or croak "Can't read $filename" ;

        if ( $self->config('inputencoding') ) {
            $buf = decode($self->config('inputencoding'), $buf)
        } ;

        print $ubib LaTeX::Decode::latex_decode($buf) or croak "Can't write to $ufilename : $!" ;
        $ubib->close or croak "Can't close filehandle to $ufilename: $!" ;

        $filename  = $ufilename ;
        
        $self->{config}->{unicodebib} = 1 ;
    }

    unless ( eval "require Text::BibTeX; 1" ) {
        $self->{config}->{useprd} = 1
    }

    unless ( $self->config('useprd') ) {
        
        require Biber::BibTeX ;
        push @ISA, 'Biber::BibTeX' ;

        @localkeys = $self->_text_bibtex_parse($filename) ;
        
    }
    else {

        require Biber::BibTeX::PRD ;
        push @ISA, 'Biber::BibTeX::PRD' ;

        print "Using a Parse::RecDescent parser...\n";

        # we only add this warning if the bib file is larger than 20KB
        if (-s $filename > 20000 ) {
            print "Note that it can be very slow with large bib files!\n" ;
            print "You are advised to install Text::BibTeX for faster processing!\n\n" ;
        } ;
        
        @localkeys = $self->_bibtex_prd_parse($filename) ;
    }

    #FIXME optional?
    unlink $ufilename if -f $ufilename ;

    if ($self->config('allentries')) {
        map { $seenkeys{$_}++ } @localkeys
    }
    
    my %bibentries = $self->bib ;

    # if allentries, push all bibdata keys into citekeys (if they are not already there)
    # Can't just make citekeys = bibdata keys as this loses information about citekeys
    # that are missing data entries.
    if ($self->config('allentries')) {
        foreach my $bibkey (keys %{$self->{bib}}) {
            push @{$self->{citekeys}}, $bibkey 
                unless (first {$bibkey eq $_} @{$self->{citekeys}});
        }
    }

    return

}

=head2 parse_biblatexml

    $biber->parse_biblatexml('data.xml') ;

    Parse a database in the BibLaTeXML format with Biber::BibLaTeXML (via
    XML::LibXML). If the suffix is dbxml, then the database is assumed to
    be stored in a Berkeley DBXML container and will be queried through the
    Sleepycat::DbXml interface.

=cut

sub parse_biblatexml {
    my ($self, $xml) = @_ ;
    require Biber::BibLaTeXML;
    push @ISA, 'Biber::BibLaTeXML';
    $self->_parse_biblatexml($xml);
}

=head2 process_crossrefs
    
    $biber->process_crossrefs ;

    Ensures proper inheritance of data from cross-references. 
    This method is automatically called by C<prepare>.

=cut

sub process_crossrefs {
    my $self = shift ;
    my %bibentries = $self->bib ;
    foreach my $citekeyx (keys %entrieswithcrossref) {
        my $xref = $entrieswithcrossref{$citekeyx} ; 
        my $type = $bibentries{$citekeyx}->{entrytype} ;
        if ($type eq 'review') {
                #TODO
        }
        if ($type =~ /^in(proceedings|collection|book)$/) {
            # inherit all that is undefined, except title etc
            foreach my $field (keys %{$bibentries{$xref}}) {
                next if $field =~ /title/ ;
                if (! $bibentries{$citekeyx}->{$field}) {
                    $bibentries{$citekeyx}->{$field} = $bibentries{$xref}->{$field} ;
                }
            }
            # inherit title etc as booktitle etc
            $bibentries{$citekeyx}->{booktitle} = $bibentries{$xref}->{title} ; 
            if ($bibentries{$xref}->{titleaddon}) {
                $bibentries{$citekeyx}->{booktitleaddon} = $bibentries{$xref}->{titleaddon}
            }
            if ($bibentries{$xref}->{subtitle}) {
                $bibentries{$citekeyx}->{booksubtitle} = $bibentries{$xref}->{subtitle}
            }
        }
        else { # inherits all
            foreach my $field (keys %{$bibentries{$xref}}) {
                if (! $bibentries{$citekeyx}->{$field}) {
                    $bibentries{$citekeyx}->{$field} = $bibentries{$xref}->{$field} ;
                }
            }
       }
       if ($type eq 'inbook') {
            $bibentries{$citekeyx}->{bookauthor} = $bibentries{$xref}->{author} 
        }
        # MORE?
        #$bibentries{$citekeyx}->{} = $bibentries{$xref}->{} 
    }

    # we make sure that crossrefs that are directly cited or cross-referenced 
    # at least $mincrossrefs times are included in the bibliography
    foreach my $k ( keys %crossrefkeys ) {
        if ( $seenkeys{$k} || $crossrefkeys{$k} >= $self->config('mincrossrefs') ) {
            delete $crossrefkeys{$k} ;
        }
    }

    $self->{bib} = { %bibentries }
}

=head2 postprocess

    Various postprocessing operations, mostly to generate special fields for
    biblatex. This method is automatically called by C<prepare>.

=cut

###############################################
# internal post-processing to prepare output

# Here we parse names, generate the "namehash" and the strings for
# "labelname", "labelyear", "labelalpha", "sortstrings", etc.

#TODO flesh out this monster into several internal subs :)

sub postprocess {
    my $self = shift ;
    
    my %namehashcount = () ;
    my @foundkeys = () ;

    foreach my $citekey ( $self->citekeys ) {

        my $origkey = $citekey ;

        # try lc($citekey), uc($citekey) and ucinit($citekey) before giving up
        if ( ! $self->{bib}->{$citekey} ) {

            if ($self->{bib}->{ lc($citekey)}) {
                
                $citekey = lc($citekey) ;

            } elsif ($self->{bib}->{ uc($citekey)}) {
                
                $citekey = uc($citekey) ;

            } elsif ($self->{bib}->{ ucinit($citekey)}) {
                
                $citekey = ucinit($citekey) ;

            } else {
                print "Warning--I didn't find a database entry for \"$citekey\"\n";
                $self->{warnings}++;
                next ;
            } 
        };

        my $be = $self->{bib}->{$citekey} ;

        push @foundkeys, $citekey ;

        $be->{origkey} = $origkey ;

        print "Postprocessing $citekey\n" if $self->config('biberdebug') ;
        

        ##############################################################
        # 1. get day month year from date field if no year is supplied
        ##############################################################

        if ( $be->{date} && !$be->{year} ) {
            my $date = $be->{date} ;
            $be->{year}  = substr $date, 0, 4 ;
            $be->{month} = substr $date, 5, 2 if length $date > 6 ;
            $be->{day}   = substr $date, 8, 2 if length $date > 9 ;
        }
        
        ##############################################################
        # 2. set local options to override global options for individual entries
        ##############################################################

        if ( $be->{options} ) {
            my @entryoptions = split /\s*,\s*/, $be->{options} ;
            foreach (@entryoptions) {
                m/^([^=]+)=?(.+)?$/ ;
                if ( $2 and $2 eq "false" ) {
                    $localoptions{$citekey}->{$1} = 0 ;
                }
                elsif ( $2 and $2 eq "true" ) {
                    $localoptions{$citekey}->{$1} = 1 ;
                }
                elsif ($2) {
                    $localoptions{$citekey}->{$1} = $2 ;
                }
                else {
                    $localoptions{$citekey}->{$1} = 1 ;
                }
            }
        }

        ##############################################################
        # 3. post process "set" entries:
        ##############################################################

        if ( $be->{entrytype} eq 'set' ) {

            my @entrysetkeys = split /\s*,\s*/, $be->{entryset} or 
                carp "No entryset found for entry $citekey of type 'set'" ;
                
            if ( $be->{crossref} && 
                $be->{crossref} ne $entrysetkeys[0] ) {

                carp "Problem with entry $citekey :\n" . 
                     "\tcrossref (" . $be->{crossref} . 
                     ") should be identical to the first element of the entryset" ;

                $be->{crossref} = $entrysetkeys[0] ;

            } elsif ( ! $be->{crossref} ) {
                
                $be->{crossref} = $entrysetkeys[0] ;
            }
        }

        ##############################################################
        # 4. generate labelname name
        ##############################################################

				# Here, "labelnamename" is the name of the labelname field
				# and "labelname" is the actual copy of the relevant field

				my $lnamescheme = $self->getblxoption('labelname', $citekey);

				LNAME: foreach my $ln (@{$lnamescheme}) {
					my $lnameopt;
					if ($ln =~ /\Ashort(.+)\z/) {
						$lnameopt = $1;
					}
					else {
						$lnameopt = $ln;
					}
					if ( $be->{$ln} and $self->getblxoption("use$lnameopt", $citekey) ) {
            $be->{labelnamename} = $ln;
						last LNAME;
					}
				}

				unless ($be->{labelnamename}) {
            carp "Could not determine the labelname of entry $citekey" if $self->config('biberdebug')
        }

        ##############################################################
        # 5a. determine namehash and fullhash
        ##############################################################

        my $namehash ;
        my $fullhash ;
        my $nameid ;
        my $nameinitid ;
        if ( $be->{sortname}
             and (   $self->getblxoption('useauthor', $citekey )
                  or $self->getblxoption('useeditor', $citekey )
                 )
           )
        {
            my @aut = @{ $be->{sortname} } ;
            $namehash   = $self->_getnameinitials( $citekey, @aut ) ;
            $fullhash   = $self->_getallnameinitials( $citekey, @aut ) ;
            $nameid     = makenameid(@aut) ;
            $nameinitid = makenameinitid(@aut)
              if ( $self->getblxoption('uniquename', $citekey) == 2 ) ;
        }
        elsif ( $self->getblxoption('useauthor', $citekey)
                and $be->{author} ) {
            my @aut = @{ $be->{author} } ;
            $namehash   = $self->_getnameinitials( $citekey, @aut ) ;
            $fullhash   = $self->_getallnameinitials( $citekey, @aut ) ;
            $nameid     = makenameid(@aut) ;
            $nameinitid = makenameinitid(@aut)
              if ( $self->getblxoption('uniquename', $citekey) == 2 ) ;
        }
        elsif ( ($be->{entrytype} =~ /^(collection|proceedings)/ #<<-- keep this? FIXME
                    and $self->getblxoption('useeditor', $citekey) )
                 and $be->{editor} ) 
        {
            my @edt = @{ $be->{editor} } ;
            $namehash   = $self->_getnameinitials( $citekey, @edt ) ;
            $fullhash   = $self->_getallnameinitials( $citekey, @edt ) ;
            $nameid     = makenameid(@edt) ;
            $nameinitid = makenameinitid(@edt)
              if ( $self->getblxoption('uniquename', $citekey) == 2 ) ;
        }
        elsif ( $self->getblxoption('usetranslator', $citekey)
                and $be->{translator} ) {
            my @trs = @{ $be->{translator} } ;
            $namehash   = $self->_getnameinitials( $citekey, @trs ) ;
            $fullhash   = $self->_getallnameinitials( $citekey, @trs ) ;
            $nameid     = makenameid(@trs) ;
            $nameinitid = makenameinitid(@trs)
              if ( $self->getblxoption('uniquename', $citekey) == 2 ) ;
        }
        else {    # initials of title
            if ( $be->{sorttitle} ) {
                $namehash   = terseinitials( $be->{sorttitle} ) ; 
                $fullhash   = $namehash ;
                $nameid     = normalize_string_underscore( $be->{sorttitle}, 1 ) ;
                $nameinitid = $nameid if ( $self->getblxoption('uniquename', $citekey) == 2 ) ;
            }
            else {
                $namehash   = terseinitials( $be->{title} ) ; 
                $fullhash   = $namehash ;
                $nameid     = normalize_string_underscore( $be->{title}, 1 ) ;
                $nameinitid = $nameid if ( $self->getblxoption('uniquename', $citekey) == 2 ) ;
            }
        }

        ## hash suffix

        my $hashsuffix = 1 ;

        if ( $namehashcount{$namehash}{$nameid} ) {
            $hashsuffix = $namehashcount{$namehash}{$nameid}
        }
        elsif ($namehashcount{$namehash}) {
            my $count = scalar keys %{ $namehashcount{$namehash} } ;
            $hashsuffix = $count + 1 ;
            $namehashcount{$namehash}{$nameid} = $hashsuffix ;
        }
        else {
            $namehashcount{$namehash} = { $nameid => 1 }
        } ;
             
        $namehash .= $hashsuffix ;
        $fullhash .= $hashsuffix ;

        $be->{namehash} = $namehash ;
        $be->{fullhash} = $fullhash ;

        $seennamehash{$fullhash}++ ;

        
        ##############################################################
        # 5b. Populate the uniquenamecount hash to later determine 
        #     the uniquename counter
        ##############################################################

        my $lname = $be->{labelnamename} ;
            { # Keep these variables scoped over the new few blocks
                my $lastname;
                my $namestring;
                my $singlename;

                if ($lname) {
                    if ($lname =~ m/\Ashort/xms) { # short* fields are just strings, not complex data
                        $lastname   = $be->{$lname};
                        $namestring = $be->{$lname};
                        $singlename = 1;
                    } else {
                        $lastname   = $be->{$lname}->[0]->{lastname} ;
                        $namestring = $be->{$lname}->[0]->{nameinitstring} ;
                        $singlename = scalar @{ $be->{$lname} };
                    }
                }

                if ( $lname and $self->getblxoption('uniquename', $citekey) and $singlename == 1 ) {

                    if ( ! $uniquenamecount{$lastname}{$namehash} ) {
                        if ($uniquenamecount{$lastname}) {
                            $uniquenamecount{$lastname}{$namehash} = 1 ;
                        } else {
                            $uniquenamecount{$lastname} = { $namehash => 1 } ;
                        }
                    }

                    if ( ! $uniquenamecount{$namestring}{$namehash} ) {
                        if ($uniquenamecount{$namestring}) {
                            $uniquenamecount{$namestring}{$namehash} = 1 ;
                        } else {
                            $uniquenamecount{$namestring} = { $namehash => 1 } ;
                        }
                    }
                } else {
                        $be->{ignoreuniquename} = 1
                }
           }
        ##############################################################
        # 6. Generate the labelalpha
        ##############################################################

        if ( $self->getblxoption('labelalpha', $citekey) ) {
            my $label ;

            if ($be->{shorthand}) 
            {
                $label = $be->{shorthand} 
            }
            else 
            {
                if ($be->{label}) 
                {
                    $label = $be->{label}
                } 
                elsif ( $be->{author} and $self->getblxoption('useauthor', $citekey) )
                { 
                    $label = $self->_getlabel($citekey, "author");
                }
                elsif ( $be->{editor} and $self->getblxoption('useeditor', $citekey ) )
                {
                    $label = $self->_getlabel($citekey, "editor");
                }
                else 
                {
                    $label = "Zzz"    # ??? FIXME
                } ;

                my $yr ;

                if ( $be->{year} ) {
                    $yr = substr $be->{year}, 2, 2 ;
                }
                else {
                    $yr = "00" ;
                }

                $label .= $yr ;

            } ;

            $be->{labelalpha} = $label ;
        }

        ##############################################################
        # 7. track author/year
        ##############################################################

        my $tmp = $self->_getnamestring($citekey) . 
            "0" . $self->_getyearstring($citekey) ;
        $seenauthoryear{$tmp}++ ;
        $be->{authoryear} = $tmp ;

        ##############################################################
        # 8. track shorthands
        ##############################################################

        if ( $be->{shorthand} ) {
            $self->_addshorthand($citekey) ;
        }

        ##############################################################
        # 9. generate sort strings 
        ##############################################################

        if ( $be->{sortkey} ) {
            my $pre ;
            if ( $be->{presort} ) {
                $pre = $be->{presort} 
            } else {
                $pre = 'mm'
            } ;
            my $sortkey = lc( $be->{sortkey} ) ;
            $sortkey = latex_decode($sortkey) unless $self->_nodecode($citekey) ;
            $be->{sortstring} = "$pre $sortkey" ;
        } else {
            $self->_generatesortstring($citekey) ;
        }

        ##############################################################
        # 9. when type of patent is not stated, simply assume 'patent'
        ##############################################################
          
        if ( ( $be->{entrytype} eq 'patent' )  &&  ( ! $be->{type} ) ) {
            $be->{type} = 'patent'
        } ;

        ##############################################################
        # 10. update the entry in the biber object
        ##############################################################

        $self->{bib}->{$citekey} = $be
    } ;

    $self->{citekeys} = [ @foundkeys ] ;

    print "Finished postprocessing entries\n" if $self->config('biberdebug') ;

    return
}


=head2 sortentries

    Sort the entries according to a certain sorting scheme.
    This method is automatically called by C<prepare>.

=cut

#===========================
# SORTING
#===========================

sub sortentries {
    my $self = shift ;
    my %bibentries = $self->bib ;
    my @auxcitekeys = $self->citekeys ;
    
    if ( $self->getblxoption('sorting') ) {

        print "Sorting entries...\n" if $self->config('biberdebug') ;
    
        if ( $self->config('fastsort') ) {
            if ($self->config('locale')) {
                my $thislocale = $self->config('locale') ;
                setlocale( $thislocale ) or carp "Unavailable locale $thislocale"
            }
            @auxcitekeys = sort {
                $bibentries{$a}->{sortstring} cmp $bibentries{$b}->{sortstring}
            } @auxcitekeys ;
        }
        else {
            require Unicode::Collate ;
            my $opts = $self->config('collate_options') ;
            my %collopts = eval "( $opts )" or carp "Incorrect collate_options: $@" ;
            my $Collator = Unicode::Collate->new( %collopts ) ;
            my $UCAversion = $Collator->version() ;
            print "Sorting with Unicode::Collate ($opts, UCA version: $UCAversion)\n" 
                unless $self->config('quiet');
            @auxcitekeys = sort {
                $Collator->cmp( $bibentries{$a}->{sortstring},
                    $bibentries{$b}->{sortstring} )
            } @auxcitekeys ;
        }
    $self->{citekeys} = [ @auxcitekeys ] ;
    }
    
    return
}

=head2 prepare

    Post-process and sort all entries before writing the bbl output.
    This is a convenience method that calls C<process_crossref>, C<postprocess>
    and C<sortentries>.

=cut

sub prepare {
    my $self = shift ;
    $self->process_crossrefs ;
    $self->postprocess ;
    $self->sortentries ;
    return
}

=head2 output_to_bbl
    
    $biber->output_to_bbl("output.bbl") ;

    Write the bbl file for biblatex.

=cut

#=====================================================
# OUTPUT .BBL FILE FOR BIBLATEX
#=====================================================

sub output_to_bbl {
    my $self = shift ;
    my $bblfile = shift ;
    my @auxcitekeys = $self->citekeys ;

    print "Preparing final output...\n" if $self->config('biberdebug') ;

    my $mode ;

    if ( $self->config('inputencoding') and ! $self->config('unicodebbl') ) {
        $mode = ':encoding(' . $self->config('inputencoding') . ')' ;
    } else {
        $mode = ":utf8" ;
    } ;

    my $BBLFILE = IO::File->new($bblfile, ">$mode") or croak "Failed to open $bblfile : $!" ;

    # $BBLFILE->binmode(':utf8') if $self->config('unicodebbl') ;

    my $ctrlver = $self->getblxoption('controlversion') ;
    my $BBL = <<"EOF"
% \$ biblatex auxiliary file \$
% \$ biblatex version $ctrlver \$
% \$ biber version $VERSION \$
% Do not modify the above lines!
%
% This is an auxiliary file used by the 'biblatex' package.
% This file may safely be deleted. It will be recreated by
% biber or bibtex as required.
%
\\begingroup
\\makeatletter
\\\@ifundefined{ver\@biblatex.sty}
  {\\\@latex\@error
     {Missing 'biblatex' package}
     {The bibliography requires the 'biblatex' package.}
      \\aftergroup\\endinput}
  {}
\\endgroup

EOF
    ;

    $BBL .= "\\preamble{%\n" . $self->{preamble} . "%\n}\n" 
        if $self->{preamble} ;

    foreach my $k (@auxcitekeys) {
        ## skip crossrefkeys (those that are directly cited or 
        #  crossref'd >= mincrossrefs were previously removed)
        next if ( $crossrefkeys{$k} ) ;
        $BBL .= $self->_print_biblatex_entry($k) ;
    }
    if ( $self->getblxoption('sortlos') and $self->shorthands ) {
        $BBL .= "\\lossort\n" ;
        foreach my $sh ($self->shorthands) {
            $BBL .= "  \\key{$sh}\n" ;
        }
        $BBL .= "\\endlossort\n" ;
    }
    $BBL .= "\\endinput\n" ;

#    if ( $self->config('inputencoding') and ! $self->config('unicodebbl') ) {
#        $BBL = encode($self->config('inputencoding'), $BBL) 
#    } ;


    print $BBLFILE $BBL or croak "Failure to write to $bblfile: $!" ;
    print "Output to $bblfile\n" unless $self->config('quiet') ;
    close $BBLFILE or croak "Failure to close $bblfile: $!" ;
    return
}

=head2 _dump

    Dump the biber object with Data::Dumper for debugging

=cut

sub _dump {
    my ($self, $file) = @_ ;
    require Data::Dumper or carp ;
    my $fh = IO::File->new($file, '>') or croak "Can't open file $file for writing" ;
    print $fh Data::Dumper::Dumper($self) ;
    close $fh ;
    return
}

=head1 AUTHOR

François Charette, C<< <firmicus at gmx.net> >>

=head1 BUGS

Please report any bugs or feature requests on our sourceforge tracker at
L<https://sourceforge.net/tracker2/?func=browse&group_id=228270>. 

=head1 COPYRIGHT & LICENSE

Copyright 2009 François Charette, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1 ;

# vim: set tabstop=4 shiftwidth=4:
