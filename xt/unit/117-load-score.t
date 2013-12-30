use strict;
use warnings;
#~ use diagnostics;

use Test::More;

use Local::Wicket;
my $QRTRUE       = $Local::Wicket::QRTRUE    ;
my $QRFALSE      = $Local::Wicket::QRFALSE   ;

#----------------------------------------------------------------------------#
# load.t
#
# Load the secret configuration YAML file. With improved framework.
#
my $unit        = q{Local::Wicket::_load};
my $base        = $unit . q{: };

#----------------------------------------------------------------------------#
# CONSTANTS

my $username    = 'Joe';                # (game) user to insert
my $password    = 'flimflam';           # temporary password given to user
my $dbname      = 'test';               # name of the wiki's MySQL DB
my $dbuser      = 'testuser';           # same as the wiki's DB user
my $dbpass      = 'testpass';           # DB password for above
my $dbtable     = 'test_table';         # name of the "user" table

#----------------------------------------------------------------------------#
# GLOBALS
my $configfn    = 'dummy.yaml';

#----------------------------------------------------------------------------#
# CASES

my @td  = (
    {
        -case   => 'setup',     # write a dummy config file
        -code   => q[
            note 'Writing dummy config...';
            eval{ unlink $configfn if -f $configfn };
            open my $fh, '>', $configfn or die '80';
            say {$fh} "dbname:  $dbname"  ;
            say {$fh} "dbuser:  $dbuser"  ;
            say {$fh} "dbpass:  $dbpass"  ;
            say {$fh} "dbtable: $dbtable" ;
            say {$fh} "" ;
            say {$fh} "# dummy regexes" ;
            say {$fh} "ban:" ;
            say {$fh} "     - /guest/" ;
            say {$fh} "     - /mine/" ;
            say {$fh} "     - /test/" ;
            close $fh or die '81';
            
            return 1;   # OK
        ],
        -need   => 1,
    },
    
    {
        -case   => 'load',
        -args   => [ $configfn ],
        -deep   => {
                    dbname  => $dbname  ,
                    dbuser  => $dbuser  ,
                    dbpass  => $dbpass  ,
                    dbtable => $dbtable ,
                    ban     => [
                        '/guest/',
                        '/mine/',
                        '/test/',
                    ],
                },
    },
    
    {
        -skip   => 1,
        -case   => 'bogus',
        -args   => [ 'bogus.yaml' ],        # BAD no such file
        -die    => words(qw/ 83 /),
    },
            
);

#----------------------------------------------------------------------------#
# EXECUTE AND CHECK

# persistent across cases if not cleared
my $tc          ;               # test counter (number of cases)
my @rv          = ();           # normal return value
my $stdout      = q{};          # captured string
my $stderr      = q{};          # captured string
my $evalerr     = q{};          # trapped  string
my $OLDOUT      ;               # saved STDOUT fh
my $OLDERR      ;               # saved STDERR fh

# scratch variables
my @args        ;
my $got         ;
my $want        ;
my $diag        = $base;

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
   $Verbose++;

for (@td) {
    next if $_->{-skip};          # skip the entire case
    last if $_->{-done};          # done with all cases
    $tc++;
    my %t           = %{ $_ };
    my $case        = $base . $t{-case};
    note( "---- $case" );
    subtest $case => sub {
        
        # per-case variables
        my $code        = $t{-code};    # execute this code
        my $args        = $t{-args};    # ... with these args
        my $die         = $t{-die};     # must fail
        my $like        = $t{-like};    # normal return value regex supplied
        my $need        = $t{-need};    # exact return value supplied
        my $deep        = $t{-deep};    # traverse structure (e.g., hashref)
        my $outlike     = $t{-outlike}; # STDOUT regex supplied
        my $errlike     = $t{-errlike}; # STDERR regex supplied
                
        # set up code under test
        if ( not $code ) {
            $code       = $unit;            # "sticky"
        };
        if ( $args and ref $args ) {        # concatenate if okay to deref
            @args       = @$args;
            $code       .= q{(@args)};
        }
        else {
            @args       = ();               # otherwise clear global
        };
        
        # test execution
        if ( $code ) {
            $diag           = 'execute';
            suppose( $code );               # this script gimmick
            pass( $diag );                  # gimmick didn't fatal
            note($evalerr) if $evalerr;     # did code under test fatal?
        };
        
        # conditional checks
        if ( $evalerr and not $die ) {
            $diag           = 'eval error';
            fail( $diag );
        };
        if ($die) {
            $diag           = 'should throw';
            $got            = $evalerr;
            $want           = $die;
            like( $got, $want, $diag );
        };
        if ($like) {
            $diag           = 'return-like';
            $got            = join qq{\n}, @rv;
            $want           = $like;
            like( $got, $want, $diag );
        }; 
        if ($need) {
            $diag           = 'return-is';
            $got            = $rv[0];
            $want           = $need;
            is( $got, $want, $diag );
        };
        if ($deep) {
            $diag           = 'return-is-deeply';
            $got            = $rv[0];
            $want           = $deep;
            is_deeply( $got, $want, $diag );
        };
        if ($outlike) {
            $diag           = 'stdout-like';
            $got            = $stdout;
            $want           = $outlike;
            like( $got, $want, $diag );
        }; 
        if ($errlike) {
            $diag           = 'stderr-like';
            $got            = $stderr;
            $want           = $errlike;
            like( $got, $want, $diag );
        }; 
        
        # Extra-verbose dump optional for test script debug.
        if ( $Verbose >= 1 ) {
            note( 'explain: ', explain \@rv     );
            note( ''                            );
        };
        
    }; ## subtest
}; ## for

#----------------------------------------------------------------------------#
# TEARDOWN

done_testing($tc);
exit 0;

#============================================================================#

sub suppose {
    my $code    =  shift;
    
    # clear before execution
    @rv          = ();           # normal return value
    $stdout      = q{};          # captured string
    $stderr      = q{};          # captured string
    $evalerr     = q{};          # trapped  string
    
    # capture ON
    open (my $OLDOUT, '>&', STDOUT);
        close STDOUT;
        open (STDOUT, '>', \$stdout);
    open (my $OLDERR, '>&', STDERR);
        close STDERR;
        open (STDERR, '>', \$stderr);
    
    # execute
    @rv         = eval "$code";
    
    # stash @!
    $evalerr    = $@;
    
    # capture OFF
    open (STDOUT, '>&', $OLDOUT);
    open (STDERR, '>&', $OLDERR);
    
    return @rv;
};

sub words {                         # sloppy match these strings
    my @words   = @_;
    my $regex   = q{};
    
    for (@words) {
        $regex  = $regex . $_ . '.*';
    };
    
    return qr/$regex/is;
};

__END__
