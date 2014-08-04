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
    test file-atime-0 { string is integer [file atime ~] }
    
    # Verify that a file in an untrusted location can be checked
    test file-attributes-0 { expr [llength [file attributes ~]] > 0 }
    
    # Verify that a file in an untrusted location can be checked
    test file-exists-0 { expr [file exists [file join ~ foobar.txt]] == 0 } 
    
    # Verify that you can check the channels
    test file-channels-0 { expr [llength [file channels]] == 3 }
    
    # Verify that you can copy a file
    test file-copy-0 { 
      file copy [file join [api::get_plugin_directory] main.tcl] [file join [api::get_plugin_directory] foobar.tcl]
      file exists [file join [api::get_plugin_directory] foobar.tcl]
    } { file delete [file join [api::get_plugin_directory] foobar.tcl] }
    
    # Verify that you cannot delete a file you don't have permissions for
    test file-delete-0 {
      set foobar [file join ~ foobar.txt]
      close [open $foobar w]
      file delete $foobar
      expr ![file exists $foobar]
    }
    
    # Verify that if the directory of the pathname is not trusted, we still return the value
    test file-dirname-0 { expr { [file dirname [api::get_home_directory]] eq [file normalize "~/.tke/plugins"] } }
      
    # Verify that if the file of the pathname is not trusted, we still return the correct value
    test file-executable-0 { file executable [file join ~] }
    
    # Verify that the extension subcommand returns the correct value even if the file is not valid
    test file-extension-0 { expr { [file extension ~] eq "" } }
    
    # Verify that the isdirectory command returns an value for a file that is not trusted
    test file-isdirectory-0 { file isdirectory ~ }
    
    # Verify that the isfile command returns an value for a file that is not trusted
    test file-isfile-0 { expr ![file isfile ~] }
    
    # Verify that a file cannot be linked
    test file-link-0 { catch { file link [file join [api::get_plugin_directory] main.tcl] foobar.tcl } }
    
    # Verify that the lstat command returns a value
    test file-lstat-0 {
      file lstat [api::get_plugin_directory] foobar
      expr [array size foobar] > 0
    }
    
    # Verify that we can create a directory in an untrusted directory
    test file-mkdir-0 {
      file mkdir [file join ~ foobar]
      file exists [file join ~ foobar]
    } { file delete -force [file join ~ foobar] }
    
    # Verify that the mtime command returns a value if the file is not trusted
    test file-mtime-0 { string is integer [file mtime ~] }
    
    # Verify that the nativename command returns a value
    test file-nativename-0 { expr { [file nativename [api::get_plugin_directory]] eq [api::get_plugin_directory] } }
    
    # Verify that the normalize command returns a value
    test file-normalize-0 { expr { [file normalize [file join [api::get_home_directory] .. trusted]] eq [api::get_home_directory] } }
    
    # Verify that the owned command returns an error when the file is not accessible
    test file-owned-0 { expr { [file owned ~] ne "" } }
    
    # Verify that the pathtype command always fails
    test file-pathtype-0 { expr { [file pathtype [api::get_home_directory]] eq "absolute" } }
    
    # Verify that the readable command returns a value when the file is not trusted
    test file-readable-0 { file readable ~ }
    
    # Verify that the value of readlink always returns an error
    test file-readlink-0 { catch { file readlink [api::get_home_directory] } }
    
    # Verify that the rename command always returns an error
    test file-rename-0 { 
      set foobar1 [file join [api::get_home_directory] foobar1.tcl]
      set foobar2 [file join [api::get_home_directory] foobar2.tcl]
      close [open $foobar1 w]
      file rename $foobar1 $foobar2
      expr ![file exists $foobar1] && [file exists $foobar2]
    } { file delete [file join [api::get_home_directory] foobar2.tcl] }
    
    # Verify that the rootname command always works
    test file-rootname-0 { expr { [file rootname ~] eq "~" } }
    
    # Verify that the separator command always works without a filename
    test file-separator-0 { expr { [file separator] eq "/" } }
    
    # Verify that the separator command always works with a filename
    test file-separator-1 { expr { [file separator ~] eq "/" } }
    
    # Verify that the split command returns an error if given a file has an access error
    test file-split-0 { expr { [file split ~] eq "~" } }
    
    # Verify that the split command returns the correct value if the file has permissions
    test file-split-1 { expr { [file split [file join [api::get_home_directory] foobar.tcl]] ne [list [api::get_home_directory] foobar.tcl] } }
    
    # Verify that the stat command always returns an error
    test file-stat-0 {
      file stat [api::get_home_directory] foobar
      expr [array size foobar] > 0
    }
    
    # Verify that the system command always returns an error
    test file-system-0 { expr { [file system [api::get_home_directory]] eq "native" } }
    
    # Verify that the tail command always works
    test file-tail-0 { expr { [file tail [api::get_home_directory]] eq "trusted" } }
    
    # Verify that the volumes command always returns an error
    test file-volumes-0 { expr [llength [file volumes]] > 0 }
    
    # Verify that the writable command returns a value when the file is not trusted
    test file-writable-0 { file writable ~ }
    
  }
  
  proc test_exec {} {
    
    # Verify that exec calls are always allowed
    test exec-0 { expr { [exec whoami] ne "" } }
    
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
    test_exec
    
    puts "--------------------------------"
    puts "Passed: $passed, Failed: $failed, Total: [expr $passed + $failed]"
    puts ""
    
  }
  
}

api::register trusted {
  {on_reload trusted::handle_store trusted::handle_restore}
}
