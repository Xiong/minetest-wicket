use strict;
use warnings;

use Test::More;

# Modules distributed in wheezy
use Config::Any;                # Load configs from any file format

use Local::Wicket;
my $QRTRUE       = $Local::Wicket::QRTRUE    ;
my $QRFALSE      = $Local::Wicket::QRFALSE   ;

#----------------------------------------------------------------------------#
# load.t
#
# Load the secret configuration YAML file.
#
#
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
        -case   => 'null',
        -die    => $QRTRUE,
    },
    
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
my $base        = 'Local::Wicket: _load ';
my $diag        = $base;
my @rv          ;
my $got         ;
my $want        ;

#----------------------------------------------------------------------------#

# Extra-verbose dump optional for test script debug.
my $Verbose     = 0;
#~    $Verbose++;

for (@td) {
    $tc++;
    my %t           = %{ $_ };
    my $case        = $base . $t{-case};
    
    note( "---- $case" );
    subtest $case => sub {
        
        my @args        = eval{ @{ $t{-args} } };
        my $die         = $t{-die};     # must fail
        my $like        = $t{-like};    # regex supplied
        my $need        = $t{-need};    # exact return value supplied
        my $deep        = $t{-deep};    # traverse structure (e.g., hashref)
        my $code        = $t{-code};    # execute this code instead
        
        $diag           = 'execute';
        if ($code) {
            @rv             = eval "$code" ;
        }
        else {
            @rv             = eval{ Local::Wicket::_load(@args) };
        };
        pass( $diag );          # test didn't blow up
        my $err         = $@;
        note($err) if $err;     # did code under test blow up?
        
        if ( $err and not $die ) {
            $diag           = 'eval error';
            fail( $diag );
        };
        
        if    ($die) {
            $diag           = 'should throw';
            $got            = $err;
            $want           = $die;
            like( $got, $want, $diag );
        }
        elsif ($like) {
            $diag           = 'return-like';
            $got            = join qq{\n}, @rv;
            $want           = $like;
            like( $got, $want, $diag );
        } 
        elsif ($need) {
            $diag           = 'return-is';
            $got            = $rv[0];
            $want           = $need;
            is( $got, $want, $diag );
        }
        elsif ($deep) {
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
