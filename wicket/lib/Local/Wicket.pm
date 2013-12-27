package Local::Wicket;
use 5.014002;   # 5.14.3    # 2012  # pop $arrayref, copy s///r
use strict;
use warnings;
use version; our $VERSION = qv('v0.0.0');

# Core modules
use Getopt::Long;                           # Parses command-line options
Getopt::Long::Configure ("bundling");       # enable, for instance, -xyz
use Pod::Usage;                             # Build help text from POD
use Pod::Find qw{pod_where};                # POD is in ...

use Digest::MD5 qw(md5 md5_hex md5_base64);     # MD5 hashing

# Modules standard with wheezy
use DBI 1.616;          # Generic interface to a large number of databases
use DBD::mysql;         # DBI driver for MySQL

# Modules distributed in wheezy
use Config::Any;                # Load configs from any file format

# Alternate uses
#~ use Devel::Comments '###', ({ -file => 'debug.log' });                   #~

## use
#============================================================================#

# Pseudo-globals

# Compiled regexes
our $QRFALSE            = qr/\A0?\z/            ;
our $QRTRUE             = qr/\A(?!$QRFALSE)/    ;

## pseudo-globals
#----------------------------------------------------------------------------#

#=========# INTERNAL ROUTINE
#
#~     _insert({       # insert this user directly into the wiki database
#~         username    => $username,   # (game) user to insert
#~         password    => $password,   # temporary password given to user
#~         dbname      => $dbname,     # name of the wiki's MySQL DB
#~         dbuser      => $dbuser,     # same as the wiki's DB user
#~         dbpass      => $dbpass,     # DB password for above
#~         dbtable     => $dbtable,    # name of the "user" table
#~     });
#       
# Pass named parms in a hashref.
# Host 'localhost' is assumed.
# 
sub _insert {
    my $argrf       = shift;
    my $username    = $argrf->{ username    } || die '64';
    my $password    = $argrf->{ password    } || die '65';
    my $dbname      = $argrf->{ dbname      } || die '66';
    my $dbhost      = 'localhost'           ;
    my $dbuser      = $argrf->{ dbuser      } || die '67';
    my $dbpass      = $argrf->{ dbpass      } || die '68';
    my $dbtable     = $argrf->{ dbtable     } || die '69';
    
    my $err_connect = 70;
    
    my $hashed      ;   # password hash
    
    my $dsn         = "DBI:mysql:database=$dbname;host=$dbhost";
    my $dbh         ;   # DB handle
    my $stmt        ;   # SQL text
    my $errno       ;   # MySQL or DBI/DBD error
    
    # Connect to the DB.
    $dbh            = DBI->connect( $dsn, $dbuser, $dbpass,
                    { PrintError => 0 }
                    );
    die $err_connect if not ref $dbh;               # can't connect
    $errno = $dbh->{'mysql_errno'};
    die $errno if $errno;

    # Hash the password. See: 
    #   https://www.mediawiki.org/wiki/Manual:User_table#user_password
    my $salt    = sprintf "%08x", ( int( rand() * 2**31 ) );
    $hashed     = md5_hex( $password );
    $hashed     = md5_hex( $salt . q{-} . $hashed );
    $hashed     = q{:B:} . $salt . q(:) . $hashed  ;

    # Compose insert. 
    $stmt   = qq{INSERT INTO $dbtable }
            .  q{(user_id, user_name) }
            .  q{VALUES (}
            .  q{'0',}                          # user_id (auto_increment)
            . $dbh->quote($username)            # user_name
            .  q{)}
            ;
    $dbh->do( $stmt );
    $errno = $dbh->{'mysql_errno'};
    die $errno if $errno;

    # Set password.
    $stmt   = qq{UPDATE $dbtable SET user_password=}
            . $dbh->quote($hashed)
            .  q{ WHERE user_name =}
            . $dbh->quote($username)
            ;
    $dbh->do( $stmt );
    $errno = $dbh->{'mysql_errno'};
    die $errno if $errno;

    $dbh->disconnect();
    
    
    return 1;
}; ## _insert

#=========# INTERNAL ROUTINE
#
#   _load( $configfn );     # load config from a YAML file
#       
# ____
# 
sub _load {
    my $configfn        = shift;
    die '82' if not $configfn;
    
    my $config          ;
    
    my $rv          = Config::Any->load_files({ 
        files           => [$configfn], # aryref
        use_ext         => 1,           # format must match extension
        flatten_to_hash => 1,           # less wrapping paper
    });
    
    $config = $rv->{$configfn};
    die '83' if not ref $config or not keys $config;    # got nothing
    return $config;
}; ## _load

#=========# INTERNAL ROUTINE
#
#   _do_();     # short
#       
# Purpose   : ____
# Parms     : ____
# Reads     : ____
# Returns   : ____
# Writes    : ____
# Throws    : ____
# See also  : ____
# 
# ____
# 
sub _do_ {
    
    
    
}; ## _do_



## END MODULE
1;
#============================================================================#
__END__

=head1 NAME

Local::Wicket - Minetest-Mediawiki bridge

=head1 VERSION

This document describes Local::Wicket version v0.0.0

=head1 SYNOPSIS

    use Local::Wicket;

=head1 DESCRIPTION

=over

I< One day the war will be over. > 
-- Lt. Colonel Nicholson

=back



=head1 PUBLIC FUNCTIONS 

=head2 new()

=head1 PRIVATE FUNCTIONS

No user-accessible parts in here. 

=head1 SEE ALSO

L<< Some::Module|Some::Module >>

=head1 INSTALLATION

Do not install this module at all. It's only meaningful as part of the 'wicket' Minetest mod (addon, plugin, extension). Refer to mod docs. 

=head1 DIAGNOSTICS

=over

=item C<< some error message >>

Some explanation. 

=back

=head1 CONFIGURATION AND ENVIRONMENT

None. 

=head1 DEPENDENCIES

There are no non-core dependencies. 

=begin html

<!--

=end html

L<< version|version >> 0.99 E<10> E<8> E<9>
Perl extension for Version Objects

=begin html

-->

<DL>

<DT>    <a href="http://search.cpan.org/perldoc?version" 
            class="podlinkpod">version</a> 0.99 
<DD>    Perl extension for Version Objects

</DL>

=end html

This module requires perl 5.14.2;
maybe exactly perl (5.14.2-21+deb7u1). 

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

This is an early release. Reports and suggestions will be warmly welcomed. 

Please report any issues to: 
L<https://github.com/Xiong/minetest-wicket/issues>.

=head1 DEVELOPMENT

This project is hosted on GitHub at: 
L<https://github.com/Xiong/minetest-wicket>. 

=head1 THANKS

Somebody helped!

=head1 AUTHOR

Xiong Changnian C<< <xiong@cpan.org> >>

=head1 LICENSE

Copyright (C) 2013 
Xiong Changnian C<< <xiong@cpan.org> >>

This library and its contents are released under Artistic License 2.0:

L<http://www.opensource.org/licenses/artistic-license-2.0.php>

=begin fool_pod_coverage

No, I'm not just lazy. I think it's counterproductive to give each accessor 
its very own section. Sorry if you disagree. 

=head2 put_attr

=head2 get_attr

=end   fool_pod_coverage

=cut





