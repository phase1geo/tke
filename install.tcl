#!tclsh8.5

# Name:         install.tcl
# Author:       Trevor Williams (phase1geo@gmail.com)
# Date:         5/26/2014
# Description:  Handles installation of TKE.

# Make sure that the Tk package is available on the system
if {[catch "package require Tk"]} {
  puts "Installation requires the Tk package"
  exit 1
}

# Make sure that the Tclx package is available on the system
if {[catch "package require Tclx"]} {
  puts "Installation requires the Tclx package"
  exit 1
}

proc get_yes_or_no {question} {

  set answer "x"
  
  while {![regexp {^([yn]?)$} [string tolower $answer] -> answer]} {
    puts "$question (Y/n)? "
    set answer [gets stdin]
  }
  
  return $answer
  
}

proc copy_lib_files {lib_dir} {

  file mkdir $lib_dir
  
  foreach directory [list data doc lib plugins] {
    puts -nonewline "Copying $directory to [file join $lib_dir $directory]...  "
    if {[catch "file copy $directory $lib_dir" rc]} {
      puts "error!"
      puts "  $rc"
      return
    } else {
      puts "done."
    }
  }
        
}

set install_dir ""

while {$install_dir eq ""} {
       
  # Get the installation directory from the user
  puts "Enter root installation directory: "
  set install_dir [file normalize [gets stdin]]
  set lib_dir     [file join $install_dir lib tke]
  set bin_dir     [file join $install_dir bin]
  
  # Make sure that the library directory can be written
  if {![file writable [file dirname $lib_dir]]} {
    puts "[file dirname $lib_dir] is not writable"
    set install_dir ""
    continue
  }
  
  # Make sure that the binary directory can be written
  if {![file writable $bin_dir]} {
    puts "$bin_dir is not writable"
    set install_dir ""
    continue
  }
  
  # Output path information to user
  puts "Library will be installed at: $lib_dir"
  puts "Binary will be installed at:  [file join $bin_dir tke]"
  puts ""
  
  # If the specified root directory is okay, install everything there
  if {[get_yes_or_no "Is this okay"] ne "n"} {
    
    # Copy directories to lib directory
    if {[file exists $lib_dir]} {
      if {[get_yes_or_no "$lib_dir exists.  Replace"] ne "n"} {
        file delete $lib_dir
        copy_lib_files $lib_dir
      } else {
        set install_dir ""
        continue
      }
    } else {
      copy_lib_files $lib_dir
    }
    
    # Create bin file
    if {![file exists $bin_dir]} {
      mkdir $bin_dir
    }
    
    # Create the file
    puts -nonewline "Creating [file join $bin_dir tke]...  "
    if {![catch "open [file join $bin_dir tke] w" rc]} {
      puts $rc "#!/bin/sh"
      puts $rc "wish8.5 [file join $lib_dir lib tke.tcl] -- \$@"
      close $rc
      puts "done."
    } else {
      puts "error."
      puts "  $rc"
    }

  }
  
}

