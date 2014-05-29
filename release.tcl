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

source [file join lib version.tcl]

proc usage {} {
  
  puts ""
  puts "Usage:  tclsh8.5 release.tcl -- \[options\]"
  puts ""
  puts "Options:"
  puts "  -h    Display this help information"
  puts "  -v    Display current tool version"
  puts "  -m    Increment the major revision value"
  puts "  -g    Generate images only using latest tagged value"
  puts ""
  puts "Note:  If you need to recreate a tag, perform the following prior"
  puts "       to calling this script:"
  puts ""
  puts "       hg tag --remove <tag>"
  puts ""
  
  exit
  
}

proc get_latest_major_minor {} {
  
  if {![catch "exec -ignorestderr hg tags" rc]} {
    set last_major 0
    set last_minor 0
    foreach line [split $rc \n] {
      if {[regexp {^stable-(\d+)\.(\d+)$} [lindex $line 0] -> major minor]} {
        if {$major > $last_major} {
          set last_major $major
          set last_minor $minor
        } elseif {($major == $last_major) && ($minor > $last_minor)} {
          set last_major $major
          set last_minor $minor
        }
      }
    }
    return [list $last_major $last_minor]
  }
  
  return -code error "Unable to retrieve latest tag"
  
}

proc generate_changelog {tag} {
  
  puts -nonewline "Generating ChangeLog...  "
  flush stdout
  
  if {$tag eq ""} {
    if {[catch { exec -ignorestderr hg log -r "branch(default)" > ChangeLog } rc]} {
      puts "failed!"
      puts "  $rc"
      return -code error "Unable to generate ChangeLog"
    }
  } else {
    if {[catch { exec -ignorestderr hg log -r "branch(default) and tag('$tag')" > ChangeLog } rc]} {
      puts "failed!"
      puts "  $rc"
      return -code error "Unable to generate ChangeLog"
    }
  }
  
  puts "done."
  
}

proc update_version_file {major minor} {
  
  puts -nonewline "Updating version file...  "
  flush stdout
  
  if {![catch { open [file join lib version.tcl] w } rc]} {
    
    puts $rc "set version_major \"$major\""
    puts $rc "set version_minor \"$minor\""
    puts $rc "set version_hgid  \"$::version_hgid\""
    
    close $rc  
    
    puts "done."
    
  } else {
    
    puts "failed!"
    puts "  $rc"
    return -code error "Unable to update version file"
    
  }
  
}

proc create_archive {tag type} {
  
  puts -nonewline "Generating $type archive...  "
  flush stdout
  
  # Calculate release directory name
  set release_dir [file normalize [file join ~ projects releases tke-[string range $tag 7 end]]]
  
  # Create archive
  if {[catch { exec -ignorestderr hg archive -r $tag $release_dir } rc]} {
    puts "failed!"
    puts "  $rc"
    return -code error "Unable to generate archive"
  }
  
  puts "done."
  
  return $release_dir
  
}

proc generate_linux_tarball {tag} {
  
  # Create archive directory
  set release_dir [create_archive $tag Linux]
  
  puts -nonewline "Preparing Linux release directory...  "
  flush stdout
  
  # Delete the MacOSX directory
  if {[catch { file delete -force [file join $release_dir MacOSX] } rc]} {
    puts "failed!"
    puts "  $rc"
    file delete -force $release_dir
    return -code error "Unable to delete MacOSX directory"
  }
  
  # Delete the release.tcl file
  if {[catch { file delete -force [file join $release_dir release.tcl] } rc]} {
    puts "failed!"
    puts "  $rc"
    file delete -force $release_dir
    return -code error "Unable to delete release.tcl"
  }
  
  puts "done."
  
  puts "tar -czf [file tail $release_dir].tar.gz -C [file dirname $release_dir] $release_dir"
  
  puts -nonewline "Generating Linux tarball...  "
  flush stdout
  
  # Generate the tarball
  if {[catch { exec -ignorestderr tar -czf [file tail $release_dir].tar.gz -C [file dirname $release_dir] $release_dir } rc]} {
    puts "failed!"
    puts "  $rc"
    file delete -force $release_dir
    return -code error "Unable to create tar file"
  }
  
  # Finally, delete the release directory
  if {[catch { file delete -force $release_dir } rc]} {
    puts "failed!"
    puts "  $rc"
    return -code error "Unable to delete directory"
  }
  
  puts "done."
  
}

proc generate_macosx_dmg {tag} {
  
  # Create archive directory
  set release_dir [create_archive $tag Linux]
  
  puts -nonewline "Preparing MacOSX release directory...  "
  flush stdout
  
  set scripts_dir [file join $release_dir MacOSX Tke.app Contents Resources Scripts]
  
  foreach dir [list data doc lib plugins] {
    
    # Delete the symbolic link
    if {[file exists [file join $scripts_dir $dir]]} {
      if {[catch { file delete -force [file join $scripts_dir $dir] } rc]} {
        puts "failed!"
        puts "  $rc"
        file delete -force $release_dir
        return -code error "Unable to delete $dir link"
      }
    }
    
    # Copy the directory
    if {[catch { file copy -force [file join $release_dir $dir] $scripts_dir } rc]} {
      puts "failed!"
      puts "  $rc"
      file delete -force $release_dir
      return -code error "Unable to copy $dir directory"
    }
    
  }
  
  puts "done."
  
  puts -nonewline "Generating MacOSX disk image...  "
  flush stdout
  
  # Create the disk image using the hdiutil command-line utility
  if {[catch { exec -ignorestderr hdiutil create [file join $release_dir.dmg] -srcfolder [file join $release_dir MacOSX Tke.app] } rc]} {
    puts "failed!"
    puts "  $rc"
    file delete -force $release_dir
    return -code error "Unable to create disk image"
  }
  
  # Finally, delete the release directory
  if {[catch { file delete -force $release_dir } rc]} {
    puts "failed!"
    puts "  $rc"
    return -code error "Unable to delete directory"
  }
  
  puts "done."
  
}

catch {
  
  # Initialize variables that might be overridden on the command-line
  set increment_major 0
  set generate_only   0
   
  # Parse command-line options
  set i 1
  while {$i < $argc} { 
    switch [lindex $argv $i] {
      -v      { puts "$version_major.$version_minor"; exit }
      -m      { set increment_major 1 }
      -g      { set generate_only 1 }
      default { usage }
    }
    incr i
  }
   
  # Get the latest major/minor tag
  lassign [get_latest_major_minor] major minor
   
  # Update major/minor values and create needed tags 
  if {!$generate_only} {
    if {$major == 0} {
      set last_tag ""
      set major    1
      set minor    0
    } else {
      set last_tag "stable-$major.$minor"
      if {$increment_major} {
        incr major 
        set minor 0
      } else {
        incr minor
      }
    }
  } else {
    if {$major == 0} {
      return -code error "The project must be tagged prior to using the -g option"
    }
  }
   
  # Create next_tag value
  set next_tag "stable-$major.$minor"
   
  if {!$generate_only} {
    
    # If a tag hasn't been created yet, just use the default branch to update the
    # ChangeLog file.
    generate_changelog $last_tag
    
    # Update the version file
    update_version_file $major $minor
    
    # Commit the ChangeLog change
    puts -nonewline "Committing and pushing ChangeLog...  "
    flush stdout
    if {[catch { exec -ignorestderr hg commit -m "ChangeLog for $next_tag release" } rc]} {
      puts "failed!"
      puts "  $rc"
      return -code error "Unable to commit ChangeLog"
    }
     
    # Push the ChangeLog change to master
    if {[catch { exec -ignorestderr hg push } rc]} {
      puts "failed!"
      puts "  $rc"
      return -code error "Unable to push changelist"
    }
    puts "done."
     
    # Tag the new release
    puts -nonewline "Tagging repository with $next_tag...  "
    flush stdout
    if {[catch { exec -ignorestderr hg tag $next_tag } rc]} {
      puts "failed!"
      puts "  $rc"
      return -code error "Unable to tag repository to $next_tag"
    }
    puts "done."
    
  }
   
  # Generate the linux tarball
  generate_linux_tarball $next_tag
   
  # Generate the Mac OSX disk image
  if {$tcl_platform(os) eq "Darwin"} {
    generate_macosx_dmg $next_tag
  }
   
  puts "Done!"
  puts ""
  puts "Releases are available in: [file normalize [file join ~ projects releases]]"
  puts ""
    
  exit
  
} rc
puts "ERROR:  $rc"
