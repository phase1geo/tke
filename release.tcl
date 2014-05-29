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
  
  puts "release_dir: $release_dir"
  
}

proc generate_macosx_dmg {tag} {
  
  # TEMPORARY
  return
  
  set release_dir [create_archive $tag Linux]
  
  puts "release_dir: $release_dir"
  
}

# Get the latest major/minor tag
lassign [get_latest_major_minor] major minor

if {$major == 0} {
  set last_tag ""
  set next_tag "stable-1.0"
} else {
  set last_tag "stable-$major.$minor"
  set next_tag "stable-$major.[expr $minor + 1]"
}

puts "last_tag: $last_tag, next_tag: $next_tag"

# If a tag hasn't been created yet, just use the default branch to update the
# ChangeLog file.
generate_changelog $last_tag
  
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

# Generate the linux tarball
generate_linux_tarball $next_tag

# Generate the Mac OSX disk image
generate_macosx_dmg $next_tag

puts "Done!"
