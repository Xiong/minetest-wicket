use Test::More tests => 1;

BEGIN {
    $SIG{__DIE__}   = sub {
        warn @_;
        BAIL_OUT( q[Couldn't use module; can't continue.] );    
        
    };
}   

BEGIN {
use Local::Wicket;              # Minetest-Mediawiki bridge
    
}

pass( 'Use modules.' );
diag( "Testing Local::Wicket $Local::Wicket::VERSION" );
