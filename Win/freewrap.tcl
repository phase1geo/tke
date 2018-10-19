# Name:     freewrap.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     9/23/2015
# Version:  $Revision$
# Brief:    Builds the Windows TKE executable.
# Usage:    tclsh8.5 freewrap.tcl

array set dnames {}

proc find_package_helper {dname pkg} {

  # Keep track of where we have been and if we start looping, stop
  set dname [file normalize $dname]
  if {[info exists ::dnames($dname)]} {
    return 0
  }
  set ::dnames($dname) 1

  # If we can find a pkgIndex.tcl file in the dname directory
  # see if it calls an ifneeded for the given package.
  if {[file exists [set pkg_index [file join $dname pkgIndex.tcl]]]} {
    if {![catch { open $pkg_index r } rc]} {
      foreach line [split [read $rc] \n] {
        if {[regexp "^\\s*package\\s+ifneeded\\s+$pkg" $line]} {
          lappend ::new_auto_path $dname
          close $rc
          return 1
        }
      }
      close $rc
    }
  }

  # Continue to search in subdirectories
  if {[catch { glob -nocomplain -directory $dname -types d * } sdnames]} {
    set sdnames [list]
  }

  foreach sdname $sdnames {
    if {[find_package_helper $sdname $pkg]} {
      return 1
    }
  }

  return 0

}

proc find_package {pkg} {

  foreach dname $::auto_path {
    if {[find_package_helper $dname $pkg]} {
      return 1
    }
  }

  return 0

}

proc get_files {parent} {

  set files [list]

  foreach fname [glob -nocomplain -directory $parent *] {
    if {[file isfile $fname]} {
      lappend files $fname
    } elseif {[file isdirectory $fname]} {
      lappend files {*}[get_files $fname]
    }
  }

  return $files

}

proc create_freewrap_files {} {

  set files [list]

  puts -nonewline "Creating freewrap.files...  "
  flush stdout

  # Create the freewrap file
  foreach dir [list data doc lib plugins] {
    lappend files {*}[get_files [file join $::tke_dir $dir]]
  }

  # Add tkdnd package files
  lappend files {*}[get_files [file join $::tke_dir lib win tkdnd2.8-64]]

  # Add expect package files
  # DISABLING - lappend files {*}[get_files [file join $::tke_dir Win expect]]

  # Add binit executable
  lappend files {*}[get_files [file join $::tke_dir Win binit]]

  # Remove excluded directories
  foreach exclude [list doc/html lib/tke.tcl] {
    set files [lsearch -inline -not -all $files [file join $::tke_dir $exclude]*]
  }

  # Write the files to the given directory
  if {![catch { open freewrap.files w } rc]} {
    foreach fname $files {
      puts $rc $fname
    }
    close $rc
  }

  puts "Done!"

}

######################################################################
# Sets auto_path to include the list of directories for the needed
# packages.
proc set_auto_path {} {

  puts -nonewline "Setting auto_path...  "
  flush stdout

  set new_auto_path $::auto_path

  foreach pkg [list Tclx] {
    if {![find_package $pkg]} {
      error "Unable to find package $pkg in auto_path"
    }
  }

  set ::auto_path $new_auto_path

  puts "Done!"

}

######################################################################

# Set the main TKE directory
set tke_dir [file normalize [file join [pwd] ..]]

# Set the releases directory
set release_dir [file normalize [file join [pwd] .. .. releases]]
file mkdir $release_dir

# Set the global auto_path to include all needed packages
set_auto_path

# Create the freewrap.files file with the current directory contents
create_freewrap_files

# If a tke.exe file already exists, delete it
if {[file exists tke.exe]} {
  file delete -force tke.exe
}

puts -nonewline "Running freewrap...  "
flush stdout

if {$::tcl_platform(platform) eq "windows"} {

  # Generate the TKE executable using freewrap
  if {![catch { exec -ignorestderr [file join freewrap664 win64 freewrap.exe] [file join $tke_dir lib tke.tcl] -debug -f freewrap.files -i [file join $tke_dir lib images tke.ico] -1 } rc]} {
    puts "Success!"
  } else {
    puts "Failed!"
    puts $rc
  }

} else {

  # Generate the TKE executable using freewrap in non-Windows environment
  if {![catch { exec -ignorestderr [file join freewrap664 linux64 freewrap] [file join $tke_dir lib tke.tcl] -debug -w [file join freewrap664 win32 freewrap.exe] -f freewrap.files -i [file join $tke_dir lib images tke.ico] -1 } rc]} {
    puts "Success!"
  } else {
    puts "Failed!"
    puts $rc
  }

}

puts "Moving tke.exe to $release_dir"

# Move the zipped file to the releases directory
file rename -force tke.exe [file join $release_dir tke.exe]
