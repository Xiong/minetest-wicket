use strict;
use warnings;
#~ use diagnostics;

use Test::More;

use Local::Wicket;
my $QRTRUE       = $Local::Wicket::QRTRUE    ;
my $QRFALSE      = $Local::Wicket::QRFALSE   ;

#----------------------------------------------------------------------------#
# output.t
#
# Check normal output (back to the Lua mod). 
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
                },
    },
    
    {
        -case   => 'bogus',
        -args   => [ 'bogus.yaml' ],        # BAD no such file
        -die    => words(qw/ 83 /),
    },
            
);

#----------------------------------------------------------------------------#
# EXECUTE AND CHECK

my $tc          ;
my @rv          ;
my $got         ;
my $want        ;
my $diag        = $base;
my $OLDOUT      ;   # saved STDOUT fh
my $OLDERR      ;   # saved STDERR fh

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
#~    $Verbose++;

for (@td) {
    return if $_->{-skip};          # skip the entire case
    $tc++;
    my %t           = %{ $_ };
    my $case        = $base . $t{-case};
    note( "---- $case" );
    subtest $case => sub {
        
        # per-case variables
        my $die         = $t{-die};     # must fail
        my $like        = $t{-like};    # regex supplied
        my $need        = $t{-need};    # exact return value supplied
        my $deep        = $t{-deep};    # traverse structure (e.g., hashref)
        my $code        = $t{-code};    # execute this code
        my $args        = $t{-args};    # ... with these args
        my $skip        = $t{-skip};    # or skip this case altogether
        
        my @args        ;               # dereferenced
        my $argstr      = q{};          #    then stringified (uninterpolated)
        my $stdout      = q{};          # captured string
        my $stderr      = q{};          # captured string
        my $evalerr     = q{};          # trapped  string
        
        # conditional unpack
        if ( $args ) {
            @args       = @$args;
            $argstr     = q{(@args)};
        };
        
        # conditional execution
        if ( not $code ) {
            $code           = $unit;        # sticky
        };
        if ( $code ) {                          # string eval
            $diag           = 'execute (s)';
            @rv             = eval "$code$argstr" ;
            pass( $diag );                  # test script didn't fatal
            $evalerr         = $@;
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

sub words {                         # sloppy match these strings
    my @words   = @_;
    my $regex   = q{};
    
    for (@words) {
        $regex  = $regex . $_ . '.*';
    };
    
    return qr/$regex/is;
};

__END__
