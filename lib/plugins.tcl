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
#  on_start    - Runs when the editor is started
#  on_open     - Runs when a tab is opened
#  on_focusin  - Runs when a tab receives focus
#  on_close    - Runs when a tab is closed
#  on_quit     - Runs when the editor is exited
#  on_reload   - Takes action when the plugin is reloaded
#  on_save     - Runs prior to a file being saved

namespace eval plugins {

  variable registry_size 0
  variable plugin_mb     ""
  
  array set registry     {}
  array set prev_sourced {}
  
  ######################################################################
  # Procedure that is called be each plugin that registers all of the
  # actions that the plugin can perform.
  proc register {name actions} {
    
    variable registry
    variable registry_size
    
    set i 0
    while {($i < $registry_size) && ($registry($i,name) ne $name)} {
      incr i
    }
    
    if {$i < $registry_size} {
      set j 0
      foreach action $actions {
        set registry($i,action,[lindex $action 0],$j) [lrange $action 1 end]
        incr j
      }
    }
    
  }
  
  ######################################################################
  # Loads the header information from all available plugins.
  proc load {{read_config_file 1}} {
  
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
        foreach action [array names registry $i,action,on_reload,*] {
          set prev_sourced($registry($i,name)) $registry($action)
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
      foreach action [array names registry *,action,writeplugin,*] {
        lassign [split $action ,] i
        if {$registry($i,selected)} {
          if {[catch "[lindex $registry($action) 0]" status]} {
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
            if {($i < $registry_size) && $registry($i,selected) && ([lsearch $bad_sources $i] == -1)} {
              foreach action [array names registry $i,action,readplugin,*] {
                puts "[lindex $registry($action) 0] $suboption {$value}"
                if {[catch "[lindex $registry($action) 0] $suboption {$value}" status]} {
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
      set names [list]
      foreach bad_source $bad_sources {
        set registry($bad_source,selected) 0
        lappend names $registry($bad_source,name)
      }
      tk_messageBox -default ok -type ok -icon warning -parent . -title "Plugin Errors" \
        -message "Syntax errors found in selected plugins" -detail [join $names \n]
    }
    
  }
  
  ######################################################################
  # Handles an error when sourcing a plugin file.
  proc handle_status_error {index status} {
    
    variable registry
    
    # Save the status
    set registry($index,status) $status
    
    # Set the current information message
    after 100 [list gui::set_info_message "ERROR: [lindex [split $status \n] 0]"]
    
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
    
    # Delete all plugin menu items
    handle_menu_delete
    
    # Source the file if it hasn't been previously sourced
    if {$registry($index,sourced) == 0} {
      handle_resourcing $index
      if {[catch "source $registry($index,file)" status]} {
        handle_status_error $index $status
        set registry($index,selected) 0
      } else {
        after 100 [list gui::set_info_message "Plugin $registry($index,name) installed"]
        set registry($index,sourced)  1
        set registry($index,selected) 1
        handle_reloading $index
      }
      
    # Otherwise, just mark the plugin as being selected
    } else {
      after 100 [list gui::set_info_message "Plugin $registry($index,name) installed"]
      set registry($index,selected) 1
    }
    
    # Add all of the plugins
    handle_menu_add
  
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
    
    # Delete all plugin menu items
    handle_menu_delete
    
    # Unselect the plugin
    set registry($index,selected) 0
    
    # Add all of the plugins
    handle_menu_add
    
    # Display the uninstall message
    after 100 [list gui::set_info_message "Plugin $registry($index,name) uninstalled"]
    
  }
  
  ######################################################################
  # Creates a new plugin
  proc create_new_plugin {} {
  
    set name ""
    
    if {[gui::user_response_get "Enter plugin name" name]} {
    
      if {[regexp {^[a-zA-Z0-9_]+$} $name]} {
      
        set fname [file join [file dirname $::tke_dir] plugins $name.tcl]
    
        if {![catch "open $fname w" rc]} {
        
          # Create the file contents
          puts $rc "# HEADER_BEGIN"
          puts $rc "# NAME         $name"
          puts $rc "# AUTHOR       "
          puts $rc "# DATE         [clock format [clock seconds] -format {%D}]"
          puts $rc "# INCLUDE      yes"
          puts $rc "# DESCRIPTION  "
          puts $rc "# HEADER_END"
          puts $rc ""
          puts $rc "namespace eval plugins::$name {"
          puts $rc ""
          puts $rc "}"
          puts $rc ""
          puts $rc "plugins::register $name {"
          puts $rc ""
          puts $rc "}"
          close $rc
          
          # Add the new file to the editor
          gui::add_file end $fname plugins::reload 
          
        } else {
          gui::set_info_message "ERROR:  Unable to write plugin file"
        }

      } else {
        gui::set_info_message "ERROR:  Plugin name is not valid (only alphanumeric and underscores are allowed)"
      }
            
    }
    
  }
  
  ######################################################################
  # Finds all of the registry entries that match the given type.
  proc find_registry_entries {type} {
  
    variable registry
    
    set plugin_list [list]
    foreach action [lsort -dictionary [array names registry *,action,$type,*]] {
      lassign [split $action ,] index
      if {$registry($index,selected)} {
        lappend plugin_list [concat $index $registry($action)]
      }
    }
    
    return $plugin_list
  
  }
  
  ######################################################################
  # Adds the menus to the given plugin menu.  This is called after the
  # plugin menu is initially created.
  proc handle_menu_add {{mb ""}} {
  
    variable plugin_mb
    
    # Save the plugin menu
    if {$mb ne ""} {
      set plugin_mb $mb
    }
    
    # Get the list of menu entries
    if {[llength [set entries [find_registry_entries "menu"]]] > 0} {
      $plugin_mb add separator
    }
    
    # Add each of the entries
    foreach entry $entries {
      lassign $entry index type hier do
      handle_menu_add_item $plugin_mb [split $hier .] $type $do
    }
    
  }
  
  ######################################################################
  # Adds menu item, creating all needed cascading menus.
  proc handle_menu_add_item {mnu hier type do} {
    
    # Add cascading menus
    while {[llength [set hier [lassign $hier level]]] > 0} {
      set sub_mnu [string tolower [string map {{ } _} $level]]
      if {![winfo exists $mnu.$sub_mnu]} {
        set new_mnu [menu $mnu.$sub_mnu -tearoff 0 -postcommand "plugins::handle_menu_state $mnu.$sub_mnu"]
        $mnu add cascade -label $level -menu $mnu.$sub_mnu
      }
      set mnu $mnu.$sub_mnu
    }
    
    # Add menu item
    switch [lindex $type 0] {
      command {
        $mnu add command -label $level -command $do
      }
      checkbutton {
        $mnu add checkbutton -label $level -variable [lindex $type 1] -command $do
      }
      radiobutton {
        $mnu add radiobutton -label $level -variable [lindex $type 1] -value [lindex $type 2] -command $do
      }
    }
    
  }
  
  ######################################################################
  # Deletes all of the menus in the plugins menu.
  proc handle_menu_delete {} {
  
    variable plugin_mb
    
    # Get the list of menu entries
    if {[llength [set entries [find_registry_entries "menu"]]] > 0} {
      
      # Delete all of the plugin items
      foreach entry $entries {
        lassign $entry index hier
        if {[handle_menu_delete_item $plugin_mb [lrange [split [string tolower [string map {{ } _} $hier]] .] 0 end-1]]} {
          $plugin_mb delete last
        }
      }
      
      # Delete the last separator
      $plugin_mb delete last
    
    }
  
  }
  
  ######################################################################
  # Deletes one upper level
  proc handle_menu_delete_item {mnu hier} {
  
    while {[llength $hier] > 0} {
      if {![winfo exists $mnu.[join $hier .]]} {
        return 0
      }
      catch { destroy $mnu.[join $hier .] }
      set hier [lrange $hier 0 end-1]
    }
    
    return 1
    
  }
  
  ######################################################################
  # Updates the plugin menu state of the given menu.
  proc handle_menu_state {mnu} {
  
    variable plugin_mb
  
    set mnu_index 0
    foreach entry [find_registry_entries "menu"] {
      lassign $entry index hier do state
      set entry_mnu "$plugin_mb.[string tolower [string map {{ } _} [join [lrange [split $hier .] 0 end-1] .]]]"
      if {$mnu eq $entry_mnu} {
        if {[catch "$state" status]} {
          handle_status_error $index $status
        } elseif {$status} {
          $mnu entryconfigure $mnu_index -state normal
        } else {
          $mnu entryconfigure $mnu_index -state disabled
        }
      }
      incr mnu_index
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
  # Called whenever the application is started.
  proc handle_on_start {} {
    
    handle_event "on_start" 
    
  }
  
  ######################################################################
  # Called whenever a file is opened in a tab.
  proc handle_on_open {file_index} {
    
    handle_event "on_open" $file_index
    
  }
  
  ######################################################################
  # Called whenever a file is saved.
  proc handle_on_save {file_index} {
    
    handle_event "on_save" $file_index
    
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
