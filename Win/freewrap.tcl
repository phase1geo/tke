proc find_package_helper {dname pkg} {
  
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
  foreach sdname [glob -nocomplain -directory $dname -types d *] {
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

set new_auto_path $auto_path

foreach pkg [list Tclx] {
  if {![find_package $pkg]} {
    error "Unable to find package $pkg in auto_path"
  }
}

puts "A auto_path: $auto_path"
set auto_path $new_auto_path
puts "B auto_path: $auto_path"

if {![catch { exec -ignorestderr freewrap [file join [pwd] lib tke.tcl] -debug -f freewrap.files -i tke.ico } rc]} {
  puts "Worked!"
}

