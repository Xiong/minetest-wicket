use strict;
use warnings;
#~ use diagnostics;

use Test::More;

use Local::Wicket;
my $QRTRUE       = $Local::Wicket::QRTRUE    ;
my $QRFALSE      = $Local::Wicket::QRFALSE   ;

#----------------------------------------------------------------------------#
# run.t
#
# Functional test.
#
my $unit        = q{Local::Wicket::run};
my $base        = $unit . q{: };

#----------------------------------------------------------------------------#
# CONSTANTS

#----------------------------------------------------------------------------#
# GLOBALS

my $wicket_token    = q{%# };       # prefixed to every message

#----------------------------------------------------------------------------#
# CASES

my @td  = (
    
    {
        -skip       => 1,
        -case       => 'null',
    },
    
    {
        -case       => 'version',
        -args       => ['--version'],
        -need       => 0,               # shell OK
        -outlike    => words(qw( wicket version )),
    },
    
    {
        -case       => 'Joe',
        -args       => [qw(
                        --config    dummy.yaml
                        --config    test.yaml
                        --username  Joe
                        --password  777
                        
                    )],
        -need       => 0,               # shell OK
        -outlike    => words(qw( 301 onwiki )),
#~         -outlike    => $QRTRUE,     # tolerant
#~         -outlike    => $QRFALSE,    # force dump
    },
    
    {   -done => 1 },   # X X X X X X X X X X X X X X   DONE - SKIP ALL
    
    {
        -case       => 'missing arg',
        -die        => qr/(?:$wicket_token)100:/,
    },
    
    {
        -case       => 'BOO',                   # not title case
        -need       => 2,
    },
    
    {
        -case       => 'Zih77',                 # numerals
        -need       => 2,
    },
    
    {
        -case       => 'To',                    # too short
        -need       => 2,
    },
    
    {
        -case       => 'Thibidppy',             # too long
        -need       => 2,
    },
    
    {
        -case       => 'guest',                 # ban outright
        -need       => 3,
    },
    
    {
        -case       => '$mined',                 # ban outright (floats)
        -need       => 3,
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
#~    $Verbose++;

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
        if ( defined $t{-need} ) {
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
