#!tclsh8.5

# Name:         install.tcl
# Author:       Trevor Williams (phase1geo@gmail.com)
# Date:         5/26/2014
# Description:  Handles installation of TKE.

# Bring in the version information
source [file join lib version.tcl]

# Check to make sure that the Tcl version is okay
puts -nonewline "Tcl version 8.5.x is required...          "
flush stdout
if {[string range [set version [info patchlevel]] 0 2] ne "8.5"} {
  puts "Not Found! ($version)"
  exit 1
} else {
  puts "Found ($version)"
}

# Make sure that wish8.5 exists
puts -nonewline "Installation requires wish8.5...          "
flush stdout
if {![file exists [set wish85 [file join [file dirname [info nameofexecutable]] wish8.5]]]} {
  puts "Not Found! ($wish85)"
  exit 1
} else {
  puts "Found ($wish85)"
}

# Make sure that the Tk package is available on the system
puts -nonewline "Installation requires the Tk package...   "
flush stdout
if {[catch "package require Tk" rc]} {
  puts "Not Found! ($rc)"
  exit 1
} else {
  puts "Found"
}

# Make sure that the Tclx package is available on the system
puts -nonewline "Installation requires the Tclx package... "
flush stdout
if {[catch "package require Tclx"]} {
  puts "Not Found! ($rc)"
  exit 1
} else {
  puts "Found"
}

proc get_yes_or_no {question} {

  set answer "x"
  
  while {![regexp {^([yn]?)$} [string tolower $answer] -> answer]} {
    puts -nonewline "$question (Y/n)? "
    flush stdout
    set answer [gets stdin]
  }
  
  return $answer
  
}

proc copy_lib_files {lib_dir} {

  # Create the lib directory
  file mkdir $lib_dir
  
  # Copy each of the top-level directories recursively to the new lib directory
  foreach directory [list data doc lib plugins] {
    puts -nonewline "Copying $directory to [file join $lib_dir $directory]...  "
    flush stdout
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
  puts -nonewline "\nEnter root installation directory (or Control-C to quit): "
  flush stdout
  set install_dir [file normalize [gets stdin]]
  set lib_dir     [file join $install_dir lib tke]
  set bin_dir     [file join $install_dir bin]
  
  # Make sure that the library directory can be written
  if {[file exists [file dirname $lib_dir]] && ![file writable [file dirname $lib_dir]]} {
    puts "[file dirname $lib_dir] is not writable"
    set install_dir ""
    continue
  }
  
  # Make sure that the binary directory can be written
  if {[file exists $bin_dir] && ![file writable $bin_dir]} {
    puts "$bin_dir is not writable"
    set install_dir ""
    continue
  }
  
  # Output path information to user
  puts ""
  puts "Library will be installed at: $lib_dir"
  puts "Binary will be installed at:  [file join $bin_dir tke]"
  puts ""
  
  # If the specified root directory is okay, install everything there
  if {[get_yes_or_no "Is this okay"] ne "n"} {
    
    puts ""
    
    # Copy directories to lib directory
    if {[file exists $lib_dir]} {
      if {[get_yes_or_no "$lib_dir exists.  Replace"] ne "n"} {
        puts ""
        file delete -force $lib_dir
        copy_lib_files $lib_dir
      } else {
        set install_dir ""
        continue
      }
    } else {
      copy_lib_files $lib_dir
    }
    
    # Create the bin directory if it doesn't exist
    if {![file exists $bin_dir]} {
      file mkdir $bin_dir
    }
  
    # Create the file
    puts -nonewline "Creating [file join $bin_dir tke]...  "
    flush stdout
    if {![catch "open [file join $bin_dir tke] w" rc]} {
      puts $rc "#!/bin/sh"
      puts $rc "$wish85 [file join $lib_dir lib tke.tcl] -name tke -- \$@"
      close $rc
      file attributes [file join $bin_dir tke] -permission rwxr-xr-x
      puts "done."
    } else {
      puts "error."
      puts "  $rc"
      set install_dir ""
      continue
    }

  } else {
    set install_dir ""
  }
  
}

# If we are running on a system with a /usr/share/applications directory, create a tke.desktop file there
if {[file exists [set app_dir [file join / usr share applications]]]} {
  set app_file [file join $app_dir tke.desktop]
  puts -nonewline "Creating $app_file...  "
  flush stdout
  if {![catch "open $app_file w" rc]} {
    puts $rc "\[Desktop Entry\]"
    puts $rc "Name=TKE"
    puts $rc "Exec=$wish85 [file join $lib_dir lib tke.tcl] -name tke -- -nosb"
    puts $rc "Icon=[file join $lib_dir lib images tke_logo_128.gif]"
    puts $rc "Type=Application"
    puts $rc "Categories=Programming"
    close $rc
    puts "done."
  } else {
    puts "not done."
  }
}

# If we are running on a system that can use appdata, add the file there
if {[file exists [set appdata_dir [file join / usr share appdata]]]} {
  puts -nonewline "Copying tke.appdata.xml to [file join $appdata_dir tke.appdata.xml]...  "
  flush stdout
  if {[catch "file copy tke.appdata.xml $appdata_dir"]} {
    puts "not done."
  } else {
    puts "done."
  }
}

# Check to see if the bin directory is in the user's path
if {[lsearch [split $env(PATH) :] $bin_dir] == -1} {
  puts "\n$bin_dir is not in your PATH environment variable list."
  puts "Make sure that you put this directory into your path in your startup script.\n"
}

# Exit the application
exit

