# Name:    commit.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    9/12/2013

# Read the contents of the version file to get the dot version
source "version.tcl"

# Get the global ID and local ID
set id [exec hg id -n]

if {[catch "open version.tcl w" rc]} {
  error $rc
  exit 1
} else {
  puts $rc "set version_major \"$version_major\""
  puts $rc "set version_minor \"$version_minor\""
  puts $rc "set version_hgid  \"[string range $id 0 end-1]\""
  close $rc
}

