#!tclsh8.6

# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:         install.tcl
# Author:       Trevor Williams (phase1geo@gmail.com)
# Date:         5/26/2014
# Description:  Handles installation of TKE.
######################################################################

# Bring in the version information
source [file join lib version.tcl]

# Check to make sure that the Tcl version is okay
puts -nonewline "Tcl version 8.6.x or higher is required...  "
flush stdout
lassign [split [set version [info patchlevel]] .] major minor
if {($major > 8) || (($major == 8) && ($minor >= 6))} {
  puts "Found ($version)"
} else {
  puts "Not Found! ($version)"
  exit 1
}

# Update the version to just the major/minor revision information
set version [string range $version 0 2]

# Make sure that wish exists
puts -nonewline "Installation requires wish$version...            "
flush stdout
if {![file exists [set wish [file join [file dirname [info nameofexecutable]] wish$version]]]} {
  puts "Not Found! ($wish)"
  exit 1
} else {
  puts "Found ($wish)"
}

# Make sure that the Tk package is available on the system
puts -nonewline "Installation requires the Tk package...     "
flush stdout
if {[catch "package require Tk" rc]} {
  puts "Not Found! ($rc)"
  puts "Install tk8.6 package"
  exit 1
} else {
  puts "Found"
}

# Make sure that the Tclx package is available on the system
puts -nonewline "Installation requires the Tclx package...   "
flush stdout
if {[catch "package require Tclx" rc]} {
  puts "Not Found! ($rc)"
  puts "Install tclx package"
  exit 1
} else {
  puts "Found"
}

# Make sure that the Tcllib package is available on the system
puts -nonewline "Installation requires the Tcllib package... "
flush stdout
if {[catch "package require struct::set" rc]} {
  puts "Not Found! ($rc)"
  puts "Install tcllib package"
  exit 1
} else {
  puts "Found"
}

# Make sure that the Tklib package is available on the system
puts -nonewline "Installation requires the Tklib package...  "
flush stdout
if {[catch "package require tooltip" rc]} {
  puts "Not Found! ($rc)"
  puts "Install tklib package"
  exit 1
} else {
  puts "Found"
}

# Check to see if tkdnd package is available on the system
puts -nonewline "Checking for tkdnd package...               "
flush stdout
if {[catch "package require tkdnd" rc]} {
  puts "Not Found (Drag and drop support will be disabled)"
  puts "Install tkdnd package"
} else {
  puts "Found"
}

# Check to see if Expect package is available on the system
puts -nonewline "Checking for Expect package...              "
flush stdout
if {[catch "package require Expect" rc]} {
  puts "Not Found (SFTP support will be disabled)"
  puts "Install expect package"
} else {
  puts "Found"
}

# Check to see if Img package is available on the system
puts -nonewline "Checking for Img package...                 "
flush stdout
if {[catch "package require Img" rc]} {
  puts "Not Found (Only .gif, .bmp and .png images will be previewable in the file information panel)"
} else {
  puts "Found"
}

# Check to see if the tcl-vfs package is available on the system
puts -nonewline "Checking for tcl-vfs package...             "
flush stdout
if {[catch "package require vfs" rc]} {
  puts "Not Found! (Zip/Unzip functions will use zip/unzip on the system)"
  puts "Install tcl-vfs package"
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
  foreach {src dst} [list data data doc doc lib lib plugins plugins specl specl LICENSE LICENSE \
                          [file join scripts uninstall.tcl] uninstall.tcl] {
    puts -nonewline "Copying $src to [file join $lib_dir $dst]...  "
    flush stdout
    if {[catch "file copy $src $lib_dir" rc]} {
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
      puts $rc ""
      puts $rc "$wish [file join $lib_dir lib tke.tcl] -name tke -- \$@"
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
    puts $rc "Exec=$wish [file join $lib_dir lib tke.tcl] -name tke -- -nosb %f"
    puts $rc "Icon=[file join $lib_dir lib images tke_logo.svg]"
    puts $rc "Type=Application"
    puts $rc "Comment=Advanced code editor"
    puts $rc "Categories=Programming;Development;Utility;TextEditor"
    puts $rc "GenericName=Text Editor"
    puts $rc "MimeTypes=text/plain;text/html;text/css;text/x-script.csh;text/x-fortran;text/x-java-source;text/javascript;text/x-pascal;text/pascal;text/x-script.python;text/x-asm;text/xml;text/x-script.tcl;application/x-tkethemz;application/x-tkeplugz"
    close $rc
    puts "done."
  } else {
    puts "not done."
  }
}

# Create the MIME file so that the TKE theme and plugin bundle file extensions will be opened by TKE
if {[file exists [set mime_dir [file join / usr share mime packages]]]} {
  set mime_file     [file join $mime_dir tke.xml]
  set mime_icon_dir [file join / usr share icons hicolor scalable mimetypes]
  puts -nonewline "Creating mime file $mime_file...  "
  flush stdout
  if {![catch "open $mime_file w" rc]} {
    puts $rc "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    puts $rc "<mime-info xmlns=\"http://www.freedesktop.org/standards/shared-mime-info\">"
    puts $rc "  <mime-type type=\"application/x-tkethemz\">"
    puts $rc "    <comment>TKE theme bundle</comment>"
    puts $rc "    <generic-icon name=\"application-x-tkethemz\"/>"
    puts $rc "    <glob pattern=\"*.tkethemz\"/>"
    puts $rc "  </mime-type>"
    puts $rc "  <mime-type type=\"application/x-tkeplugz\">"
    puts $rc "    <comment>TKE plugin bundle</comment>"
    puts $rc "    <generic-icon name=\"application-x-tkeplugz\"/>"
    puts $rc "    <glob pattern=\"*.tkeplugz\"/>"
    puts $rc "  </mime-type>"
    puts $rc "</mime-info>"
    close $rc
    puts "done."
    puts -nonewline "Updating mime database...  "
    flush stdout
    catch { file copy -force [file join $lib_dir lib images tke_theme.svg]  [file join $mime_icon_dir application-x-tkethemz.svg] }
    catch { file copy -force [file join $lib_dir lib images tke_plugin.svg] [file join $mime_icon_dir application-x-tkeplugz.svg] }
    if {![catch { exec -ignorestderr update-mime-database [file join / usr share mime] }]} {
      puts "done."
    } else {
      puts "not done."
      catch { file delete -force $mime_file }
    }
  } else {
    puts "not done."
  }
}

# If we are running on a system that can use appdata, add the file there
if {[file exists [set appdata_dir [file join / usr share appdata]]]} {
  puts -nonewline "Copying tke.appdata.xml to [file join $appdata_dir tke.appdata.xml]...  "
  flush stdout
  if {[catch "file copy [file join data tke.appdata.xml] $appdata_dir"]} {
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

