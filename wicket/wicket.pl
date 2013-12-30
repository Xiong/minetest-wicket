#!/usr/bin/env perl
#       wicket.pl
#       = Copyright 2014 Xiong Changnian  <xiong@cpan.org>   =
#       = Free Software = Artistic License 2.0 = NO WARRANTY =

use 5.014002;   # 5.14.3    # 2012  # pop $arrayref, copy s///r
use strict;
use warnings;
use version; our $VERSION = qv('0.0.0');

# Core module
use lib qw| lib |;

# Project module
use Local::Wicket;

## use
#============================================================================#

exit Local::Wicket::run(@ARGV);

#============================================================================#
__END__     
