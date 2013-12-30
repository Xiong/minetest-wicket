use strict;
use warnings;
#~ use diagnostics;

use Test::More;

use Local::Wicket;
my $QRTRUE       = $Local::Wicket::QRTRUE    ;
my $QRFALSE      = $Local::Wicket::QRFALSE   ;

#----------------------------------------------------------------------------#
# score.t
#
# Generate a numerical score for any username submitted.
# This is like golf; 1 is best and every stroke is worse.  
#
my $unit        = q{Local::Wicket::_score};
my $base        = $unit . q{: };

#----------------------------------------------------------------------------#
# CONSTANTS

#----------------------------------------------------------------------------#
# GLOBALS

my $wicket_token    = q{%# };       # prefixed to every message
my $wiki    = q/^[A-Z][a-z]{2,7}$/; # 3..8 letters, Titlecased
my $nowiki  = q/wiki/;
my $ban     = q/athens|guest|mine|test|admin|mod|sysop/;

#----------------------------------------------------------------------------#
# CASES

my @td  = (
    
    {
        -case       => 'Joe',
        -args       => [{
                        username    => 'Joe',
                        wiki        => $wiki,
                        nowiki      => $nowiki,
                        ban         => $ban,
                    }],
        -need       => 1,
    },
    
    {
        -case       => 'missing arg',
        -args       => [{
                        username    => 'Joe',
                    #    wiki        => $wiki,      # missing arg no good
                        nowiki      => $nowiki,
                        ban         => $ban,
                    }],
        -die        => qr/100/,                     # how to check for this
    },
    
    {
        -case       => 'missing arg again',
        -args       => [{
                        username    => 'Joe',
                    #    wiki        => $wiki,      # missing arg no good
                        nowiki      => $nowiki,
                        ban         => $ban,
                    }],
        -die        => qr/(?:$wicket_token)100:/,
    },
    
    {
        -case       => 'BOO',                   # not title case
        -args       => [{
                        username    => 'BOO',
                        wiki        => $wiki,
                        nowiki      => $nowiki,
                        ban         => $ban,
                    }],
        -need       => 2,
    },
    
    {
        -case       => 'Zih77',                 # numerals
        -args       => [{
                        username    => 'Zih77',
                        wiki        => $wiki,
                        nowiki      => $nowiki,
                        ban         => $ban,
                    }],
        -need       => 2,
    },
    
    {
        -case       => 'To',                    # too short
        -args       => [{
                        username    => 'Zih77',
                        wiki        => $wiki,
                        nowiki      => $nowiki,
                        ban         => $ban,
                    }],
        -need       => 2,
    },
    
    {
        -case       => 'Thibidppy',             # too long
        -args       => [{
                        username    => 'Zih77',
                        wiki        => $wiki,
                        nowiki      => $nowiki,
                        ban         => $ban,
                    }],
        -need       => 2,
    },
    
    {
        -case       => 'guest',                 # ban outright
        -args       => [{
                        username    => 'guest',
                        wiki        => $wiki,
                        nowiki      => $nowiki,
                        ban         => $ban,
                    }],
        -need       => 3,
    },
    
    {
        -case       => '$mined',                 # ban outright (floats)
        -args       => [{
                        username    => '$mined',
                        wiki        => $wiki,
                        nowiki      => $nowiki,
                        ban         => $ban,
                    }],
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
