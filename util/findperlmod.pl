#!/usr/bin/env perl
#       findperlmod.pl
#       = Copyright 2014 Xiong Changnian  <xiong@cpan.org>   =
#       = Free Software = Artistic License 2.0 = NO WARRANTY =

# Find perl modules in @INC

use 5.014002;   # 5.14.3    # 2012  # pop $arrayref, copy s///r
use strict;
use warnings;

#~ use lib qw| lib |;
#~ use Error::Base;
#~ use Perl6::Form;
#~ use Test::More;
#~ use Test::Trap;

#~ use Devel::Comments '###';
#~ use Devel::Comments '###', ({ -file => 'debug.log' });                   #~

## use
#============================================================================#
#~ say "$0 Running...";

my $search          = shift;

for my $dir (@INC) {
    next if not -d $dir;
    my $cmd         = "find $dir/ -name '*$search*'";
#~     say $cmd;
    print `$cmd`;
};

#~ say "Done.";
exit;
#----------------------------------------------------------------------------#


#============================================================================#
__END__     
