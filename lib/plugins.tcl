# Name:    plugins.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace to support the plugin framework.

namespace eval plugins {

  variable registry_size 0
  
  array set registry     {}
  array set prev_sourced {}
  
  ######################################################################
  # Procedure that is called be each plugin that registers all of the
  # actions that the plugin can perform.
  proc registry {name cmdlist} {
    
    variable registry
    variable registry_size
    
    set i 0
    while {($i < $registry_size) && ($registry($i,name) ne $name)} {
      incr i
    }
    
    if {$i < $registry_size} {
      set registry($i,cmdlist) $cmdlist
    }
    
  }
  
  ######################################################################
  # Loads the header information from all available plugins.
  proc load {{read_config_file 1}} {
  
    variable registry
    variable registry_size
    
    set registry_size 0
    
    foreach plugin [glob -nocomplain -directory [file join $::tke_dir plugins] *.tcl] {
     
      if {![catch "open $plugin r" rc]} {
        
        # Read in the contents of the file and close it
        set contents [read $rc]
        close $rc
        
        # Initialize a new array storing the contents
        array set info {
          $registry_size,selected    0
          $registry_size,sourced     0
          $registry_size,status      ""
          $registry_size,file        $plugin
          $registry_size,name        ""
          $registry_size,category    ""
          $registry_size,author      ""
          $registry_size,date        ""
          $registry_size,version     ""
          $registry_size,description ""
        }
        
        # Initialize a few parsing variables
        set parse          0
        set in_description 0
        
        # Parse the file contents
        foreach line [split $contents \n] {
          if {[regexp {^\s*#(.*)} $line -> comment]} {
            if {[regexp {^\s*HEADER_BEGIN} $comment]} {
              set parse 1
            } elseif {[regexp {^\s*HEADER_END} $comment]} {
              break
            } elseif {$parse} {
              if {[regexp {^\s*NAME\s*(.*)$}              $comment -> info($registry_size,name)]} {
                set in_description 0 
              } elseif {[regexp {^\s*CATEGORY\s*(.*)$}    $comment -> info($registry_size,category)]} {
                set in_description 0
              } elseif {[regexp {^\s*AUTHOR\s*(.*)$}      $comment -> info($registry_size,author)]} {
                set in_description 0
              } elseif {[regexp {^\s*DATE\s*(.*)$}        $comment -> info($registry_size,date)]} {
                set in_description 0
              } elseif {[regexp {^\s*VERSION\s*(.*)$}     $comment -> info($registry_size,version)]} {
                set in_description 0
              } elseif {[regexp {^\s*INCLUDE\s*(.*)$}     $comment -> include]} {
                set in_description 0
              } elseif {[regexp {^\s*DESCRIPTION\s*(.*)$} $comment -> info($registry_size,description)]} {
                set in_description 1
              } elseif {$in_description} {
                append info($registry_size,DESCRIPTION) [string trim $comment]
              }
            }
          }
        } 
        
        # Add this information to the registry if is valid and included
        if {($info($registry_size,name) ne "") && ([string trim $include] eq "yes")} {
          array set registry [array get info]
          array unset info
          incr registry_size
        }
        
      }
      
    }
    
    # Read in the contents of the plugin configuration file
    if {$read_config_file} {
      read_config
    }
    
  }
  
  ######################################################################
  # Perfoms a reload of the available plugins.
  proc reload {} {
    
    variable registry
    variable registry_size
    variable prev_sourced
    
    catch { array unset prev_sourced }
    for {set i 0} {$i < $registry_size} {incr i} {
      if {$registry($i,selected) && $registry($i,sourced)} {
        foreach cmd $registry($i,cmdlist) {
          if {[lindex $cmd 0] eq "on_reload"} {
            set prev_sourced($registry($i,name)) [lrange $cmd 1 end]
          }
        }
      }  
    }
    
    # Clear the plugin information
    array unset registry
    set registry_size 0
    
    # Load plugin header information
    load
    
  }
  
  ######################################################################
  # Writes the current plugin configuration file to the tke home directory.
  proc write_config {} {
    
    variable registry
    variable registry_size
    
    if {![catch "open [file join $::tke_home plugins.dat] w" rc]} {
      
      # Write the selected plugins
      for {set i 0} {$i < $registry_size} {incr i} {
        if {$registry($i,selected)} {
          puts $rc "selected_plugin = $registry($i,name)"
        }
      }
      
      # Allow any plugins that need to write configuration information now
      for {set i 0} {$i < $registry_size} {incr i} {
        if {$registry($i,selected)} {
          foreach cmd $registry($i,cmdlist) {
            if {[lindex $cmd 0] eq "writeplugin"} {
              if {[catch "[lindex $cmd 1]" status]} {
                handle_status_error $i $status
              } else {
                foreach pair $status {
                  puts $rc "$registry($i,name).[lindex $pair 0] = [lindex $pair 1]"
                }
              }
            }
          }
        }
      }  
      
      close $rc
      
    }
    
  }
  
  ######################################################################
  # Reads the user's plugin configuration file.
  proc read_config {} {
    
    variable registry
    variable registry_size

    set bad_sources [list]
    
    if {![catch "open [file join $::tke_home plugins.dat] r" rc]} {
      
      foreach line [split [read $rc] \n] {
        
        if {[regexp {^(\S+)\s*=\s*(.*)$} $line -> option value]} {
          if {$option eq "selected_plugin"} {
            set i 0
            while {($i < $registry_size) && ($registry($i,name) ne $value)} {
              incr i
            }
            if {$i < $registry_size} {
              set registry($i,selected) 1
              handle_resourcing $i
              if {[catch "uplevel #0 [list source $registry($i,file)]" status]} {
                handle_status_error $i $status
                lappend bad_sources $i
              } else {
                set registry($i,sourced) 1
                handle_reloading $i
              }
            }
            
          } elseif {[regexp {^(\w+)\.(.*)$} $option -> prefix suboption]} {
            set i 0
            while {($i < $registry_size) && ($registry($i,name) ne $prefix)} {
              incr i
            }
            if {$i < $registry_size) && ($registry($i,selected) && [lsearch $bad_sources $i] == -1} {
              foreach cmd $registry($i,cmdlist) {
                if {[lindex $cmd 0] eq "readplugin"} {
                  if {[catch "[lindex $cmd 1] $suboption {$value}" status]} {
                    handle_status_error $i $status
                    lappend bad_sources $i
                  }
                }
              }
            }
            
          }
          
        }
        
      }
      
      close $rc
      
    }
      
    # If there was an error in sourcing any of the selected plugins, report the error to the user
    if {[llength $bad_sources] > 0} {
      set response [tk_messageBox -default ok -type okcancel -icon warning -parent . -title "Plugin Errors" \
        -message "Syntax errors found in selected plugins" -detail "Click OK to view plugin manager or Cancel to disable these plugins"
      if {$response eq "ok"} {
        start_manager
      } else {
        foreach bad_source $bad_sources {
          set registry($bad_source,selected) 0
        }
      }
    }
    
  }
  
  ######################################################################
  # Handles an error when sourcing a plugin file.
  proc handle_status_error {index status} {
    
    variable registry
    
    set registry($index,status) $status
    
  }
  
  ######################################################################
  # Called when a plugin is sourced.  Checks to see if the plugin wants
  # to be called to save data when it is resourced (data will otherwise
  # be lost once the plugin has been resourced.
  proc handle_resourcing {index} {
    
    variable registry
    variable prev_sourced
    
    if {$registry($index,selecte) && [info exists prev_sourced($registry($index,name))]} {
      if {[catch "[lindex $prev_sourced($registry($index,name)) 0] $index" status]} {
        handle_status_error $index $status
      }
    }
    
  }
  
  ######################################################################
  # Called when a plugin is sourced.  If the plugin retrieves saved information,
  # allows the plugin to do it.
  proc handle_reloading {index} {
    
    variable registry
    variable prev_sourced
    
    set name $registry($index,name)
    
    if {$registry($index,selected) && [info exists prev_sourced($name)]} {
      if {[catch "[lindex $prev_sourced($name) 1] $index" status]} {
        handle_status_error $index $status
      }
    }
    
  }
  
}
