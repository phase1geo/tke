#!tclsh8.5

######################################################################
# Name:    release.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    05/27/2014
# Brief:   Performs a release of TKE, creating packages for Linux and
#          Mac OSX.  (Windows can be added here if we can get this to
#          work.
# Usage:   tclsh8.5 release.tcl
######################################################################

# TBD

# hg log -r "branch(default) and tag('<tagname>')::" > ChangeLog
# hg commit
# hg push
# hg tag <new tagname>
# hg archive -r <new tagname> -t tgz ~/projects/release/ptwidgets-<new_version>.tgz
