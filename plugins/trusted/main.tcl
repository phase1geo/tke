namespace eval trusted {

  variable passed  0
  variable failed  0
  
  proc test {name condition {cleanup ""}} {
  
    variable passed
    variable failed
    
    if {[eval $condition]} {
      puts "  - Test passed $name"
      incr passed
    } else {
      puts "  - Test failed $name"
      incr failed
    }
    
    # Perform test cleanup
    if {$cleanup ne ""} {
      eval $cleanup
    }
    
  }
  
  proc test_file {} {
  
    # Verify that a file in an untrusted location can be checked
    test file-atime-0 { string is integer [file atime ~] } }
    
    # Verify that a file that has permissions can be checked
    test file-atime-1 { string is integer [file atime [api::get_home_directory]] }
    
    # Verify that a file that does not have permission to be checked returns an error
    test file-attributes-0 { expr [llength [file attributes ~]] > 0 }
    
    # Verify that a file that has permissions returns a valid attribute list
    test file-attributes-1 { expr [llength [file attributes [api::get_home_directory]]] > 0 }
  
    # Verify that a file that does not have permission to be checked returns an error
    test file-exists-0 { catch { file exists [file join ~ foobar.txt] } } 
    
    # Verify that a file that does not exist in a valid directory returns 0
    test file-exists-1 { expr [file exists [file join [api::get_home_directory] foobar.txt]] == 0 }
    
    # Verify that a file that exists in a valid directory returns 1
    test file-exists-2 { file exists [api::get_plugin_directory] }
    
    # Verify that you cannot get the channels for a given file
    test file-channels-0 { catch { file channels } }
    
    # Verify that you cannot copy a file
    test file-copy-0 { catch { file copy [file join [api::get_home_directory] main.tcl] foobar.tcl } }
    
    # Verify that you cannot delete a file you don't have permissions for
    test file-delete-0 { catch { file delete [file join ~ foobar.txt] } }
    
    # Verify that you can delete a file that you have permissions for
    test file-delete-1 {
      set foobar [file join [api::get_home_directory] foobar.txt]
      close [open $foobar w]
      if {[file exists $foobar]} {
        file delete $foobar
        expr ![file exists $foobar]
      } else {
        expr 0
      }
    }
    
    # Verify that we can delete multiple files
    test file-delete-2 {
      set foobar1 [file join [api::get_home_directory] foobar1.txt]
      set foobar2 [file join [api::get_home_directory] foobar2.txt]
      foreach fname [list $foobar1 $foobar2] {
        close [open $fname w]
      }
      if {[file exists $foobar1] && [file exists $foobar2]} {
        file delete $foobar1 $foobar2
        expr ![file exists $foobar1] && ![file exists $foobar2]
      } else {
        expr 0
      }
    }
    
    # Verify that we can delete a file starting with a dash
    test file-delete-3 {
      set foobar -foobar.txt
      close [open $foobar w]
      if {[file exists $foobar]} {
        file delete -- $foobar
        expr ![file exists $foobar]
      } else {
        expr 0
      }
    }
    
    # Verify that we do not delete a file with the double-dash option
    test file-delete-4 {
      set foobar -foobar.txt
      close [open $foobar w]
      if {[file exists $foobar]} {
        catch { file delete $foobar }
      } else {
        expr 0
      }
    } { file delete -- -foobar.txt }
    
    # Verify that if the directory of the pathname is not within a directory, we return an error
    test file-dirname-0 { catch { file dirname [api::get_home_directory] } }
      
    # Verify that if the directory of the pathname is within a directory, we return the directory
    test file-dirname-1 { expr { [file dirname [file join [api::get_home_directory] main.tcl]] eq [api::get_home_directory] } }
    
    # Verify that if the file of the pathname is not accessible, we return an error
    test file-executable-0 { catch { file executable [file join ~] } }
    
    # Verify that if the file is accessible we get a valid return value
    test file-executable-1 { file executable [api::get_home_directory] }
    
    # Verify that the extension subcommand returns the correct value even if the file is not valid
    test file-extension-0 { expr { [file extension ~] eq "" } }
    
    # Verify that the extension subcommand returns the correct value for a file
    test file-extension-1 { expr { [file extension [file join [api::get_home_directory] main.tcl]] eq ".tcl" } }
    
    # Verify that the isdirectory command returns an error for a file that is not accessible
    test file-isdirectory-0 { catch { file isdirectory ~ } }
    
    # Verify that the isdirectory command returns a value for an accessible file
    test file-isdirectory-1 { file isdirectory [api::get_images_directory] }
    
    # Verify that the isfile command returns an error for a file that is not accessible
    test file-isfile-0 { catch { file isfile ~ } }
    
    # Verify that the isfile command returns a value for an accessible file
    test file-isfile-1 { expr ![file isfile [api::get_images_directory]] }
    
    # Verify that a file cannot be linked
    test file-link-0 { catch { file link [file join [api::get_plugin_directory] main.tcl] foobar.tcl } }
    
    # Verify that the lstat command cannot be used
    test file-lstat-0 { catch { file lstat [api::get_plugin_directory] foobar } }
    
    # Verify that we cannot create a directory in a directory that we don't own
    test file-mkdir-0 { catch { file mkdir [file join ~ foobar] } }
    
    # Verify that we can create a directory in a directory that we own
    test file-mkdir-1 {
      set foobar [file join [api::get_home_directory] foobar barfoo] 
      file mkdir $foobar
      file exists $foobar
    } { file delete -force [file join [api::get_home_directory] foobar] }
    
    # Verify that we can create more than two directories
    test file-mkdir-2 {
      set foobar1 [file join [api::get_home_directory] foobar1]
      set foobar2 [file join [api::get_home_directory] foobar2]
      file mkdir $foobar1 $foobar2
      expr [file exists $foobar1] && [file exists $foobar2]
    } { file delete -force [file join [api::get_home_directory] foobar1] [file join [api::get_home_directory] foobar2] }
    
    # Verify that if two directories are given (one with access and one without) only the one with
    # access gets created
    test file-mkdir-3 {
      set foobar1 [file join [api::get_home_directory] foobar1]
      set foobar2 [file join ~ foobar2]
      file mkdir $foobar1 $foobar2
      file exists $foobar1
    } { file delete -force [file join [api::get_home_directory] foobar1] }
    
    # Verify that the mtime command returns an error if the file is not accessible
    test file-mtime-0 { catch { file mtime ~ } }
    
    # Verify that the mtime command returns a good value for a valid file
    test file-mtime-1 { file mtime [api::get_plugin_directory] }
    
    # Verify that the nativename command always returns an error
    test file-nativename-0 { catch { file nativename [api::get_plugin_directory] } }
    
    # Verify that the normalize command always returns an error
    test file-normalize-0 { catch { file normalize [file join [api::get_home_directory] .. test] } }
    
    # Verify that the owned command returns an error when the file is not accessible
    test file-owned-0 { catch { file owned ~ } }
    
    # Verify that the owned command returns a valid value for a file
    test file-owned-1 { expr ![file owned foobar] }
    
    # Verify that the pathtype command always fails
    test file-pathtype-0 { catch { file pathtype [api::get_home_directory] } }
    
    # Verify that the readable command returns an error when the file is not accessible
    test file-readable-0 { catch { file readable ~ } }
    
    # Verify that the readable command returns a valid value when the file is accessible
    test file-readable-1 { file readable [api::get_home_directory] }
    
    # Verify that the value of readlink always returns an error
    test file-readlink-0 { catch { file readlink [api::get_home_directory] } }
    
    # Verify that the rename command always returns an error
    test file-rename-0 { catch { file rename [file join [api::get_plugins_directory] main.tcl] [file join [api::get_plugins_directory] foobar.tcl] } }
    
    # Verify that the rootname command always works
    test file-rootname-0 { expr { [file rootname ~] eq "~" } }
    
    # Verify that the separator command always works without a filename
    test file-separator-0 { expr { [file separator] eq "/" } }
    
    # Verify that the separator command always works with a filename
    test file-separator-1 { expr { [file separator ~] eq "/" } }
    
    # Verify that the split command returns an error if given a file has an access error
    test file-split-0 { expr { [file split ~] eq "~" } }
    
    # Verify that the split command returns the correct value if the file has permissions
    test file-split-1 { expr { [file split [file join [api::get_home_directory] foobar.tcl]] eq [list [api::get_home_directory] foobar.tcl] } }
    
    # Verify that the stat command always returns an error
    test file-stat-0 { catch { file stat [api::get_home_directory] foobar } }
    
    # Verify that the system command always returns an error
    test file-system-0 { catch { file system [api::get_home_directory] } }
    
    # Verify that the tail command always works
    test file-tail-0 { expr { [file tail [api::get_home_directory]] eq [api::get_home_directory] } }
    
    # Verify that the volumes command always returns an error
    test file-volumes-0 { catch { file volumes } }
    
    # Verify that the writable command returns an error when the file does not have access
    test file-writable-0 { catch { file writable ~ } }
    
    # Verify that the writable command returns a valid value when the file has access
    test file-writable-1 { file writable [api::get_home_directory] }
    
  }
  
  proc handle_store {index} {
  
  }
  
  proc handle_restore {index} {
  
    variable passed
    variable failed
    
    puts "--------------------------------"
    puts "Running trusted regression suite"
    puts "--------------------------------"
    
    puts [api::get_home_directory]
    
    test_file
    
    puts "--------------------------------"
    puts "Passed: $passed, Failed: $failed, Total: [expr $passed + $failed]"
    puts ""
    
  }
  
}

plugins::register trusted {
  {on_reload trusted::handle_store trusted::handle_restore}
}
