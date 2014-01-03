package Local::Wicket;
use 5.014002;   # 5.14.3    # 2012  # pop $arrayref, copy s///r
use strict;
use warnings;
use version; our $VERSION = qv('v0.0.1');

# Core modules
use Getopt::Long                            # Parses command-line options
    qw( GetOptionsFromArray ),              # not directly from @ARGV
    qw( :config bundling );                 # enable, for instance, -xyz
use Pod::Usage;                             # Build help text from POD
use Pod::Find qw{pod_where};                # POD is in ...

use Digest::MD5 qw(md5 md5_hex md5_base64);     # MD5 hashing

# Modules standard with wheezy
use DBI 1.616;          # Generic interface to a large number of databases
use DBD::mysql;         # DBI driver for MySQL

# Modules distributed in wheezy
use Config::Any;                # Load configs from any file format

# Module bundled in this project
use Devel::Comments '###', ({ -file => 'debug.log' });                   #~

## use
#============================================================================#

# Pseudo-globals
our $Debug          = 0;

# Compiled regexes
our $QRFALSE        = qr/\A0?\z/            ;
our $QRTRUE         = qr/\A(?!$QRFALSE)/    ;

# Command line interface
#   See: run()
my $cli       = {
    'help|h+'       => q{Try -h, -hh, -hhh for more help.},
    'version|v'     => q{Print wicket version and exit.},
    'username|u=s'  => q{Submit player's name (required unless -h or -v).},
    'password|p=s'  => q{Temporary password.},
    'config|c=s@'   => q{Configuration file (overrides defaults)},
    'insert|i'      => q{Create wiki account (if acceptable).},
    'debug|d+'      => q{Print verbose debugging info.},
};
my @default_config_files     = qw(
    wicket.yaml
    config.yaml
    score.yaml
);

# Messages
my $wicket_token    = q{%# };       # prefixed to every message
my $message         = {
    100 => q{Required parameter missing},
    101 => q{No username given},
    102 => q{Bad return value},
    113 => q{Unspecified error},
    114 => q{Tree fall-through},
    182 => q{No wicket config file found},
    183 => q{Config loader failed},
    184 => q{No configuration loaded},
    
    200 => q{This is wicket, version } . $VERSION,
    
    301 => q{This username can be registered onwiki},
    302 => q{The wiki cannot accept this username},
    303 => q{Ban this player},
    
    401 => q{Wiki DB account insertion success},
    402 => q{Can't create account onwiki},
    451 => q{Username: },
    452 => q{Password: },
#~     000 => q{},
};

## pseudo-globals
#----------------------------------------------------------------------------#

#=========# MAIN EXTERNAL ROUTINE
#
#~     exit run(@ARGV);     # invoke
#       
# Returns appropriate shell exit code: 0 for success, 1 for failure.
# 
sub run {
    my @argv            = @_;
    
    my @opt_setup       = keys %$cli;
    my $opt             = {};   # option keys and maybe config
    my $opt_rv          ;       # return value from Getopt
    my $score           ;
    my @config_files    ;
    my $cfg             = {};   # "everything"
    my $username        ;
    my $password        ;
    my $evalerr         ;
    
    # Parse options out of passed-in copy of @ARGV.
    $opt_rv     = GetOptionsFromArray( \@argv, $opt, @opt_setup );
    
    # General action tree.
    if ( exists $opt->{debug} )     { $Debug          = $opt->{debug}       };
    if ( exists $opt->{help} )      { _help( $opt->{help} );   return 0     }; 
    if ( exists $opt->{version} )   { _output(200);            return 0     }; 
    if ( exists $opt->{config} )    { @config_files   = @{ $opt->{config} } } 
        else { @config_files    = @default_config_files; };
    $cfg    = _load( @config_files );
    
    # Merge hashrefs; command line $opt overwrites stored config $cfg
    %$cfg   = ( %$cfg, %$opt );
    
    # Do for specific username now.
    if ( exists $cfg->{username} )  { $username   = $cfg->{username}; } 
        else { _crash(101); };
    $score      = _score( $cfg );
#~ ### $score
    given ($score) {
        when (/3/)  {
            _output(303);
            return 0;
        }
        when (/2/)  {
            _output(302);
            return 0;
        }
        when (/1/)  { 
            _output(301);
            if ( exists $cfg->{insert} and $cfg->{insert} ) {
                $password = eval{ insert($cfg) };
                $evalerr  = $@;
                if ($evalerr) {
                  _output(402);
                  return 1;         # failed insert
                }
                else {
                  _output( $message->{451} . $username );
                  _output( $message->{452} . $password );
                  _output(401);
                  return 0;
                }; # ?evalerr
            }
            else {
                return 0;
            }; ## ?insert  
        } ## case score 1
        default     { _crash(102) }
    }; ## given score
    
    _crash(114);
}; ## run

#=========# INTERNAL ROUTINE
#
#~     _insert({   # insert this user directly into the wiki database
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
    
    
    return $password;
}; ## _insert

#=========# INTERNAL ROUTINE
#
#   _load( @files );     # load config from some YAML files
#       
# Will actually accept "any" config file format.
# 
sub _load {
    my @files           = @_;
    _crash(182) if not @files;
#~ ### @files
    my $cfg             ;
    
    my $rv          = Config::Any->load_files({ 
        files           => \@files,     # aryref
        use_ext         => 1,           # format must match extension
        flatten_to_hash => 1,           # less wrapping paper
    });
    _crash(183) if not ref $rv or not keys $rv;     # got nothing
    
#~ ### $rv    
    # Merge results; later values overwrite earlier
    %$cfg = ( map {%$_} values %$rv );  # discard file keys themselves
#~ ### $cfg
    
    _crash(184) if not ref $cfg or not keys $cfg;   # got nothing
    return $cfg;
}; ## _load

#=========# INTERNAL ROUTINE
#
#~     _score({                        # score...
#~         username    => $username,       # ... this username...
#~         wiki        => $wiki,           #     ok to insert as wiki user
#~         nowiki      => $nowiki,         # not ok to insert as wiki user
#~         ban         => $ban,            # ban from game now; no explanation
# 
# Generate a numerical score for any username submitted.
# This is like golf; 1 is best and every stroke is worse. 
#   1 is ok as 'resident', 2 is ok only as 'visitor', 3 is ban outright
# Must pass both {wiki} and {nowiki} checks to qualify. 
# 
sub _score {
    my $args            = shift;
    my $username        = $args->{username} || _crash(100);
    my $wiki            = $args->{wiki}     || $QRTRUE    ;
    my $nowiki          = $args->{nowiki}   || $QRFALSE   ;
    my $ban             = $args->{ban}      || $QRFALSE   ;
    
    my $score           = 1;            # start with one point = best
    
    if ( not $username  =~ qr/$wiki/    ) {
        $score  = 2;
    };
    if ( $username      =~ qr/$nowiki/  ) {
        $score  = 2;
    };
    if ( $username      =~ qr/$ban/     ) {
        $score  = 3;
    };
    
    return $score;
}; ## _score

#=========# INTERNAL ROUTINE
#
#   _output();     # IPC
# 
# Mostly just a wrapper around say().
# 
sub _output {
    my @args            = @_;
    
    for (@args) { 
        if ( exists $message->{$_} ) {
            say $wicket_token . $_ . q{: } . $message->{$_}; 
        }
        else {
            say $wicket_token . $_;
        };
    };
    
}; ## _output

#=========# INTERNAL ROUTINE
#
#   _crash(113);        # fatal with this message number
#       
# 
sub _crash {
    my $msgno       = shift;
    my $text        = $wicket_token . $msgno . q{: } . $message->{$msgno};
    
    die $text;      # do not return!
}; ## _crash

#=========# INTERNAL ROUTINE
#
#~     _do_();     # short
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

This document describes Local::Wicket version v0.0.1

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





