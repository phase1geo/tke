# Name:    plugins.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace to support the plugin framework.
#
# List of available plugin actions:
#  menu        - Adds a menu to the main menubar
#  sb_popup    - Adds items to the file sidebar popup menu
#  writeplugin - Writes local plugin information to a save file (saves data between sessions)
#  readplugin  - Reads local plugin information from a save file
#  on_open     - Runs when a tab is opened
#  on_focusin  - Runs when a tab receives focus
#  on_close    - Runs when a tab is closed
#  on_quit     - Runs when the editor is exited
#  on_reload   - Takes action when the plugin is reloaded

namespace eval plugins {

  variable registry_size 0
  
  array set registry     {}
  array set prev_sourced {}
  
  ######################################################################
  # Procedure that is called be each plugin that registers all of the
  # actions that the plugin can perform.
  proc register {name cmdlist} {
    
    variable registry
    variable registry_size
    
    set i 0
    while {($i < $registry_size) && ($registry($i,name) ne $name)} {
      incr i
    }
    
    if {$i < $registry_size} {
      set registry($i,cmdlist,[lindex $cmdlist 0]) [lrange $cmdlist 1 end]
    }
    
  }
  
  ######################################################################
  # Loads the plugin directory files and initializes the namespace.
  proc load {} {
  
    # Add launcher registrations
    launcher::register "Plugins: Install"   plugins::install
    launcher::register "Plugins: Uninstall" plugins::uninstall
    launcher::register "Plugins: Reload"    plugins::reload
    
    # Load the plugin directory contents
    load_directory
    
  }
  
  ######################################################################
  # Loads the header information from all available plugins.
  proc load_directory {{read_config_file 1}} {
  
    variable registry
    variable registry_size
    
    set registry_size 0
    
    foreach plugin [glob -nocomplain -directory [file join [file dirname $::tke_dir] plugins] *.tcl] {
    
      if {![catch "open $plugin r" rc]} {
        
        # Read in the contents of the file and close it
        set contents [read $rc]
        close $rc
        
        # Initialize a new array storing the contents
        array set info [list \
          $registry_size,selected    0 \
          $registry_size,sourced     0 \
          $registry_size,status      "" \
          $registry_size,file        $plugin \
          $registry_size,name        "" \
          $registry_size,category    "" \
          $registry_size,author      "" \
          $registry_size,date        "" \
          $registry_size,version     "" \
          $registry_size,description "" \
        ]
        
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
        foreach cmd $registry($i,cmdlist,on_reload) {
          set prev_sourced($registry($i,name)) $cmd
        }
      }  
    }
    
    # Clear the plugin information
    array unset registry
    set registry_size 0
    
    # Load plugin header information
    load_directory
    
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
      foreach cmd [array names registry *,cmdlist,writeplugin] {
        lassign [split $cmd ,] i
        if {$registry($i,selected)} {
          if {[catch "[lindex $registry($cmd) 0]" status]} {
            handle_status_error $i $status
          } else {
            foreach pair $status {
              puts $rc "$registry($i,name).[lindex $pair 0] = [lindex $pair 1]"
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
              foreach cmd $registry($i,cmdlist,readplugin) {
                if {[catch "[lindex $registry(cmd) 0] $suboption {$value}" status]} {
                  handle_status_error $i $status
                  lappend bad_sources $i
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
      tk_messageBox -default ok -type ok -icon warning -parent . -title "Plugin Errors" \
        -message "Syntax errors found in selected plugins" -detail [join $bad_sources \n]
      foreach bad_source $bad_sources {
        set registry($bad_source,selected) 0
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
    
    if {$registry($index,selected) && [info exists prev_sourced($registry($index,name))]} {
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
      if {[catch "[lindex $prev_sourced($name) 0pre] $index" status]} {
        handle_status_error $index $status
      }
    }
    
  }
  
  ######################################################################
  # Installs available plugins.
  proc install {} {
  
    variable registry
    variable registry_size
    
    set plugins [list]
    
    # Add registries to launcher
    for {set i 0} {$i < $registry_size} {incr i} {
      if {!$registry($i,selected)} {
        set name $registry($i,name)
        lappend plugins $name
        launcher::register_temp "`PLUGIN:$name" "plugins::install_item $i" $name
      }
    }
    
    # Display the launcher in PLUGIN: mode
    launcher::launch "`PLUGIN:"
    
    # Unregister the plugins
    foreach name $plugins {
      launcher::unregister "`PLUGIN:$name"
    }
  
  }
  
  ######################################################################
  # Installs the plugin in the registry specified by name.
  proc install_item {index} {
  
    variable registry
    
    # Source the file if it hasn't been previously sourced
    if {$registry($index,sourced) == 0} {
      handle_resourcing $index
      if {[catch "source $registry($index,file)" status]} {
        puts "status: $status"
        set registry($index,status)   $status
        set registry($index,selected) 0
        # FIXME - Let the user know about the plugin error
      } else {
        puts "$registry($index,name) installed"
        set registry($index,sourced)  1
        set registry($index,selected) 1
        handle_reloading $index
      }
      
    # Otherwise, just mark the plugin as being selected
    } else {
      puts "$registry($index,name) installed"
      set registry($index,selected) 1
    }
  
  }
  
  ######################################################################
  # Uninstalls previously installed plugins.
  proc uninstall {} {
  
    variable registry
    variable registry_size
    
    set plugins [list]
    
    for {set i 0} {$i < $registry_size} {incr i} {
      if {$registry($i,selected)} {
        set name $registry($i,name)
        lappend plugins $name
        launcher::register_temp "`PLUGIN:$name" "plugins::uninstall_item $i" $name
      }
    }
    
    # Display the launcher in PLUGIN: mode
    launcher::launch "`PLUGIN:"
    
    # Unregister the plugins
    foreach name $plugins {
      launcher::unregister "`PLUGIN:$name"
    }
  
  }
  
  ######################################################################
  # Uninstalls the specified plugin.
  proc uninstall_item {index} {
  
    variable registry
    
    puts "$registry($index,name) uninstalled"
    set registry($index,selected) 0
    
  }
  
  ######################################################################
  # Finds all of the registry entries that match the given type.
  proc find_registry_entries {type} {
  
    variable registry
    
    set plugin_list [list]
    foreach cmd [array names registry *,cmdlist,$type] {
      lassign [split $cmd ,] index
      lappend plugin_list [concat $index $registry($cmd)]
    }
    
    return $plugin_list
  
  }
  
  ######################################################################
  # Adds the menus to the given plugin menu.
  proc handle_menu_add {mb} {
    
    foreach entry [find_registry_entries "menu"] {
      
    }
    
  }
  
  ######################################################################
  # Updates the plugin menu state of the given menu.
  proc handle_menu_state {mb} {
    
    # Remove prefix text from mb name
    set mb [string range $mb [string length ".menubar.plugins."] end]
    
    foreach entry [find_registry_entries "menu"] {
      
    }
    
  }
  
  ######################################################################
  # Generically handles the given event.
  proc handle_event {event args} {
    
    foreach entry [find_registry_entries $event] {
      if {[catch "[lindex $entry 1] $args" status]} {
        handle_status_error [lindex $entry 0] $status
      }
    }
    
  }
  
  ######################################################################
  # Called whenever a file is opened in a tab.
  proc handle_on_open {file_index} {
    
    handle_event "on_open" $file_index
    
  }
  
  ######################################################################
  # Called whenever a tab receives focus.
  proc handle_on_focusin {tab} {
    
    handle_event "on_focusin" $tab
    
  }
  
  ######################################################################
  # Called whenever a tab is closed.
  proc handle_on_close {file_index} {
    
    handle_event "on_close" $file_index
    
  }
  
  ######################################################################
  # Called when the application is exiting.
  proc handle_on_quit {} {
    
    # Handle the on_quit event
    handle_event "on_quit"
    
    # Finally, write the plugin information file
    write_config
  
  }
  
}
