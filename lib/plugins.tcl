# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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
# Name:    plugins.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace to support the plugin framework.
#
# List of available plugin actions:
#  menu         - Adds a menu to the main menubar
#  tab_popup    - Adds items to the tab popup menu
#  root_popup   - Adds items to a root directory sidebar popup menu
#  dir_popup    - Adds items to a non-root directory sidebar popup menu
#  file_popup   - Adds items to a file sidebar popup menu
#  text_binding - Adds one or more bindings to a created text field.
#  on_start     - Runs when the editor is started or when the plugin is installed
#  on_open      - Runs when a tab is opened
#  on_focusin   - Runs when a tab receives focus
#  on_close     - Runs when a tab is closed
#  on_update    - Runs when a tab is updated
#  on_quit      - Runs when the editor is exited
#  on_reload    - Takes action when the plugin is reloaded
#  on_save      - Runs prior to a file being saved
#  on_rename    - Runs when a file/folder is being renamed
#  on_duplicate - Runs when a file is being duplicated
#  on_delete    - Runs when a file/folder is being deleted
#  on_uninstall - Runs when the plugin is uninstalled by the user.  Allows UI cleanup, etc.
#  syntax       - Adds the given syntax file to the list of available syntaxes
#  vcs          - Adds support for a version control system to the difference viewer
######################################################################

namespace eval plugins {

  variable registry_size 0
  variable plugin_mb     ""
  variable tab_popup     ""
  variable root_popup    ""
  variable dir_popup     ""
  variable file_popup    ""

  array set registry     {}
  array set plugins      {}
  array set prev_sourced {}
  array set bound_tags   {}
  array set menu_vars    {}

  set plugins_file [file join $::tke_home plugins.tkedat]

  ######################################################################
  # Handles any changes to plugin menu variables.
  proc handle_menu_variable {index name1 name2 op} {

    variable registry
    variable menu_vars

    $registry($index,interp) eval set $name2 $menu_vars($name2)

  }

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

    # Get all of the plugin directories in the installation directory
    if {[namespace exists ::freewrap]} {
      set dirs [lmap item [zvfs::list [file join $::tke_dir plugins * header.tkedat]] {
        file dirname $item
      }]
    } else {
      set dirs [glob -nocomplain -directory [file join $::tke_dir plugins] -types d *]
    }

    foreach plugin $dirs {

      # Read the header information
      if {![catch { tkedat::read [file join $plugin header.tkedat] 0 } rc]} {

        array set header $rc

        # Store this information if the name is specified and it should be included
        if {[info exists header(name)] && ($header(name) ne "") && [info exists header(include)] && ($header(include) eq "yes")} {
          set registry($registry_size,selected)    0
          set registry($registry_size,status)      ""
          set registry($registry_size,interp)      ""
          set registry($registry_size,tgntd)       0
          set registry($registry_size,file)        [file join $plugin main.tcl]
          set registry($registry_size,name)        $header(name)
          set registry($registry_size,author)      [expr {[info exists header(author)]         ? $header(author)         : ""}]
          set registry($registry_size,email)       [expr {[info exists header(email)]          ? $header(email)          : ""}]
          set registry($registry_size,version)     [expr {[info exists header(version)]        ? $header(version)        : ""}]
          set registry($registry_size,description) [expr {[info exists header(description)]    ? $header(description)    : ""}]
          set registry($registry_size,treqd)       [expr {[info exists header(trust_required)] ? ([string compare -nocase $header(trust_required) "yes"] == 0) : 0}]
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
  proc reload {{file_index ""}} {

    variable registry
    variable registry_size
    variable prev_sourced

    # Delete all plugin menu items
    delete_all_menus

    # Delete all plugin text bindings
    delete_all_text_bindings

    # Delete all plugin syntax registrations
    delete_all_syntax

    # Delete all VCS commands
    delete_all_vcs_commands

    catch { array unset prev_sourced }
    for {set i 0} {$i < $registry_size} {incr i} {
      if {$registry($i,selected) && ($registry($i,interp) ne "")} {
        foreach action [array names registry $i,action,on_reload,*] {
          set prev_sourced($registry($i,name)) $registry($action)
        }
        handle_resourcing $i
        interpreter::destroy $registry($i,name)
        set registry($i,interp) ""
      }
    }

    # Clear the plugin information
    array unset registry
    set registry_size 0

    # Load plugin header information
    load

    # Add all of the plugins
    add_all_menus

    # Add all of the text bindings
    add_all_text_bindings

    # Add all of the syntaxes
    add_all_syntax

    # Add all of the VCS commands
    add_all_vcs_commands

    # Tell the user that the plugins have been successfully reloaded
    gui::set_info_message [msgcat::mc "Plugins successfully reloaded"]

  }

  ######################################################################
  # Writes the current plugin configuration file to the tke home directory.
  proc write_config {} {

    variable registry
    variable registry_size
    variable plugins
    variable plugins_file

    # Create the array to store in the plugins.tkedat file
    for {set i 0} {$i < $registry_size} {incr i} {
      set plugins($registry($i,name)) [list selected $registry($i,selected) trust_granted $registry($i,tgntd)]
    }

    # Store the data
    catch { tkedat::write $plugins_file [array get plugins] }

  }

  ######################################################################
  # Reads the user's plugin configuration file.
  proc read_config {} {

    variable registry
    variable registry_size
    variable plugins
    variable plugins_file
    variable prev_sourced

    set bad_sources [list]

    # Read the plugins file
    if {![catch { tkedat::read $plugins_file } rc]} {

      array set plugins $rc

      for {set i 0} {$i < $registry_size} {incr i} {
        if {[info exists plugins($registry($i,name))]} {
          array set data $plugins($registry($i,name))
          if {$data(selected) || [info exists prev_sourced($registry($i,name))]} {
            set registry($i,selected) 1
            set registry($i,tgntd)    $data(trust_granted)
            set interpreter [interpreter::create $registry($i,name) $data(trust_granted)]
            if {[catch { interp eval $interpreter source $registry($i,file) } status]} {
              handle_status_error "read_config" $i $status
              lappend bad_sources $i
              interpreter::destroy $registry($i,name)
            } else {
              set registry($i,interp) $interpreter
              handle_reloading $i
            }
              # add_all_text_bindings
          }
        }

      }

    }

    # If there was an error in sourcing any of the selected plugins, report the error to the user
    if {[llength $bad_sources] > 0} {
      set names [list]
      foreach bad_source $bad_sources {
        set registry($bad_source,selected) 0
        lappend names $registry($bad_source,name)
      }
      tk_messageBox -default ok -type ok -icon warning -parent . -title [msgcat::mc "Plugin Errors"] \
        -message [msgcat::mc "Syntax errors found in selected plugins"] -detail [join $names \n]
    }

    # Add all of the available VCS commands
    add_all_vcs_commands

  }

  ######################################################################
  # Handles an error when sourcing a plugin file.
  proc handle_status_error {procname index status} {

    variable registry

    # Save the status
    set registry($index,status) $status

    # Get the name of the plugin
    set name $registry($index,name)

    # If we are doing development, send the full error info to standard output
    if {[::tke_development]} {
      puts $::errorInfo
    }

    # Log the error information in the diagnostic logfile
    logger::log $::errorInfo

    # Set the current information message
    gui::set_info_message [format "%s (%s,%s): %s" [msgcat::mc "ERROR"] $name $procname [lindex [split $status \n] 0]]

  }

  ######################################################################
  # Called when a plugin is sourced.  Checks to see if the plugin wants
  # to be called to save data when it is resourced (data will otherwise
  # be lost once the plugin has been resourced.
  proc handle_resourcing {index} {

    variable registry
    variable prev_sourced

    set name $registry($index,name)

    if {$registry($index,selected) && [info exists prev_sourced($name)]} {
      if {[catch { $registry($index,interp) eval [lindex $prev_sourced($name) 0] $index } status]} {
        handle_status_error "handle_resourcing" $index $status
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
      if {[catch { $registry($index,interp) eval [lindex $prev_sourced($name) 1] $index } status]} {
        handle_status_error "handle_reloading" $index $status
      }
    }

  }

  ######################################################################
  # Allows a plugin to save temporary data to non-corruptible memory.
  # This memory will be cleared whenever the plugin retrieves the data.
  proc save_data {index name value} {

    variable temp_user_data

    set temp_user_data($index,$name) $value

  }

  ######################################################################
  # If a previous call to save_data form the same index/name combination
  # was called, returns the value stored for that variable.  Removes
  # temporary memory prior to returning.
  proc restore_data {index name} {

    variable temp_user_data

    if {[info exists temp_user_data($index,$name)]} {
      set value $temp_user_data($index,$name)
      unset temp_user_data($index,$name)
    } else {
      set value ""
    }

    return $value

  }

  ######################################################################
  # Installs available plugins.
  proc install {} {

    variable registry
    variable registry_size

    # Add registries to launcher
    for {set i 0} {$i < $registry_size} {incr i} {
      if {!$registry($i,selected)} {
        set name $registry($i,name)
        launcher::register_temp "`PLUGIN:$name" "plugins::install_item $i" $name 0 "plugins::show_detail $i"
      }
    }

    # Display the launcher in PLUGIN: mode
    launcher::launch "`PLUGIN:" 1

  }

  ######################################################################
  # Displays the plugin grant dialog window.
  proc grant_window {plugin_name} {

    variable grant

    # Default the permission to be reject
    set grant "reject"

    toplevel     .installwin
    wm title     .installwin [msgcat::mc "Plugin Trust Requested"]
    wm transient .installwin .
    wm resizable .installwin 0 0
    wm protocol  .installwin WM_DELETE_WINDOW {
      # Do nothing
    }

    ttk::frame .installwin.f
    ttk::label .installwin.f.l1 -text $plugin_name
    ttk::label .installwin.f.e1 -text ""
    ttk::label .installwin.f.l2 -text [msgcat::mc "Plugin requires permission to view or modify your system."]
    ttk::label .installwin.f.l3 -text [msgcat::mc "Grant permission?"]
    ttk::label .installwin.f.e2 -text ""

    pack .installwin.f.l1 -padx 2 -pady 2
    pack .installwin.f.e1 -padx 2
    pack .installwin.f.l2 -padx 2
    pack .installwin.f.l3 -padx 2
    pack .installwin.f.e2 -padx 2

    ttk::frame       .installwin.rf
    ttk::frame       .installwin.rf.f
    ttk::radiobutton .installwin.rf.f.r -text [format "  %s" [msgcat::mc "Reject"]] -variable plugins::grant -value "reject"
    ttk::radiobutton .installwin.rf.f.g -text [format "  %s" [msgcat::mc "Grant"]]  -variable plugins::grant -value "grant"
    ttk::radiobutton .installwin.rf.f.a -text [format "  %s" [msgcat::mc "Always grant from developer"]] -variable plugins::grant -value "always"
    ttk::label       .installwin.rf.f.e -text ""

    pack .installwin.rf.f.r -anchor w -padx 2
    pack .installwin.rf.f.g -anchor w -padx 2
    pack .installwin.rf.f.a -anchor w -padx 2
    pack .installwin.rf.f.e
    pack .installwin.rf.f

    set bwidth [msgcat::mcmax "OK" "Cancel"]

    ttk::frame  .installwin.bf
    ttk::button .installwin.bf.ok -style BButton -text [msgcat::mc "OK"] -width $bwidth -command {
      destroy .installwin
    }
    ttk::button .installwin.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width $bwidth -command {
      set plugins::grant "cancel"
      destroy .installwin
    }

    pack .installwin.bf.cancel -side right -padx 2 -pady 2
    pack .installwin.bf.ok     -side right -padx 2 -pady 2

    pack .installwin.f
    pack .installwin.rf -fill x
    pack .installwin.bf -fill x

    # Place the window
    ::tk::PlaceWindow .installwin widget .

    # Take the focus and grab
    ::tk::SetFocusGrab .installwin .installwin.r

    # Wait for the window to close
    tkwait window .installwin

    # Return the focus and grab
    ::tk::RestoreFocusGrab .installwin.r installwin

    return $grant

  }

  ######################################################################
  # Installs the plugin in the registry specified by name.
  proc install_item {index} {

    variable registry

    # Delete all plugin menu items
    delete_all_menus

    # Delete all plugin text bindings
    delete_all_text_bindings

    # Delete all syntax
    delete_all_syntax

    # Delete all VCS commands
    delete_all_vcs_commands

    # Source the file if it hasn't been previously sourced
    if {$registry($index,interp) eq ""} {
      if {$registry($index,treqd) && !$registry($index,tgntd)} {
        switch [grant_window $registry($index,name)] {
          "grant"  { set registry($index,tgntd) 1 }
          "reject" { set registry($index,tgntd) 0 }
          "always" { set registry($index,tgntd) 1 }
          default  {
            add_all_menus
            add_all_text_bindings
            add_all_syntax
            add_all_vcs_commands
            return
          }
        }
      }
      set interpreter [interpreter::create $registry($index,name) $registry($index,tgntd)]
      if {[catch { uplevel #0 [list interp eval $interpreter source $registry($index,file)] } status]} {
        handle_status_error "install_item" $index $status
        set registry($index,selected) 0
        interpreter::destroy $registry($index,name)
      } else {
        gui::set_info_message [format "%s (%s)" [msgcat::mc "Plugin installed"] $registry($index,name)]
        set registry($index,selected) 1
        set registry($index,interp)   $interpreter
        handle_reloading $index
        run_on_start_after_install $index
      }

    # Otherwise, just mark the plugin as being selected
    } else {
      gui::set_info_message [format "%s (%s)" [msgcat::mc "Plugin installed"] $registry($index,name)]
      set registry($index,selected) 1
      run_on_start_after_install $index
    }

    # Add all of the plugins
    add_all_menus

    # Add all of the text bindings
    add_all_text_bindings

    # Add all syntaxes
    add_all_syntax

    # Add all VCS commands
    add_all_vcs_commands

  }

  ######################################################################
  # This procedure is called in the install_item procedure and causes any
  # on_start actions associated with the plugin to be called when the plugin
  # is installed.
  proc run_on_start_after_install {index} {

    variable registry

    # If the given event contains an "on_uninstall" action, run it.
    foreach {name action} [array get registry $index,action,on_start,*] {
      if {[catch { $registry($index,interp) eval {*}$action } status]} {
        handle_status_error "run_on_start" $index $status
      }
    }

  }

  ######################################################################
  # Uninstalls previously installed plugins.
  proc uninstall {} {

    variable registry
    variable registry_size

    for {set i 0} {$i < $registry_size} {incr i} {
      if {$registry($i,selected)} {
        set name $registry($i,name)
        launcher::register_temp "`PLUGIN:$name" "plugins::uninstall_item $i" $name
      }
    }

    # Display the launcher in PLUGIN: mode
    launcher::launch "`PLUGIN:"

  }

  ######################################################################
  # Uninstalls the specified plugin.
  proc uninstall_item {index} {

    variable registry

    # Call "on_uninstall" command, if it exists
    handle_on_uninstall $index

    # Delete all plugin menu items
    delete_all_menus

    # Delete all text bindings
    delete_all_text_bindings

    # Delete all syntax
    delete_all_syntax

    # Delete all VCS commands
    delete_all_vcs_commands

    # Destroy the interpreter
    interpreter::destroy $registry($index,name)

    # Unselect the plugin
    set registry($index,selected) 0
    set registry($index,interp)   ""

    # Add all of the plugins
    add_all_menus

    # Add all of the text bindings
    add_all_text_bindings

    # Add all of the syntaxes
    add_all_syntax

    # Add all of the VCS commands
    add_all_vcs_commands

    # Display the uninstall message
    gui::set_info_message [format "%s (%s)" [msgcat::mc "Plugin uninstalled"] $registry($index,name)]

  }

  ######################################################################
  # Displays plugin information into the given text widget.
  proc show_detail {index txt} {

    variable registry

    $txt tag configure bold -underline 1

    $txt insert end "Version:\n\n" bold
    $txt insert end "$registry($index,version)\n\n\n"
    $txt insert end "Description:\n\n" bold
    $txt insert end $registry($index,description)

  }

  ######################################################################
  # Creates a new plugin
  proc create_new_plugin {} {

    set name ""

    if {[gui::get_user_response [msgcat::mc "Enter plugin name"] name]} {

      if {![regexp {^[a-zA-Z0-9_]+$} $name]} {
        gui::set_info_message [msgcat::mc "ERROR:  Plugin name is not valid (only alphanumeric and underscores are allowed)"]
        return
      }

      set dirname [file join $::tke_dir plugins $name]

      if {[file exists $dirname]} {
        gui::set_info_message [msgcat::mc "ERROR:  Plugin name already exists"]
        return
      }

      # Create the plugin directory
      if {[catch { file mkdir $dirname }]} {
        gui::set_info_message [msgcat::mc "ERROR:  Unable to create plugin directory"]
        return
      }

      # Create the filenames
      set header [file join $dirname header.tkedat]
      set main   [file join $dirname main.tcl]

      # Create the main file
      if {[catch { open $main w } rc]} {
        gui::set_info_message [msgcat::mc "ERROR:  Unable to write plugin files"]
        return
      }

      # Create the main file
      puts $rc "# Plugin namespace"
      puts $rc "namespace eval $name {"
      puts $rc ""
      puts $rc "  # INSERT CODE HERE"
      puts $rc ""
      puts $rc "}"
      puts $rc ""
      puts $rc "# Register all plugin actions"
      puts $rc "api::register $name {"
      puts $rc ""
      puts $rc "}"
      close $rc

      # Add the new file to the editor
      gui::add_file end $main -savecommand plugins::reload

      # Create the header file
      if {[catch { open $header w } rc]} {
        gui::set_info_message [msgcat::mc "ERROR:  Unable to write plugin files"]
        return
      }

      # Create the header file
      puts $rc "name           {$name}"
      puts $rc "author         {}"
      puts $rc "email          {}"
      puts $rc "version        {1.0}"
      puts $rc "include        {yes}"
      puts $rc "trust_required {no}"
      puts $rc "description    {}"
      close $rc

      # Add the file to the editor
      gui::add_file end $header -savecommand plugins::reload

    }

  }

  ######################################################################
  # Finds all of the registry entries that match the given action.
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
  proc menu_add {mnu action} {

    # Get the list of menu entries
    if {[llength [set entries [find_registry_entries $action]]] > 0} {
      $mnu add separator
    }

    # Add each of the entries
    foreach entry $entries {
      lassign $entry index type hier do state
      menu_add_item $index $mnu $action [split $hier /] $type $do $state
    }

  }

  ######################################################################
  # Adds menu item, creating all needed cascading menus.
  proc menu_add_item {index mnu action hier type do state} {

    variable registry
    variable menu_vars

    # If the type is a separator, we need to run the while loop one more time
    set force [expr {[lindex $type 0] eq "separator"}]

    # Add cascading menus
    while {([set hier_len [llength [set hier [lassign $hier level]]]] > 0) || $force} {
      set sub_mnu [string tolower [string map {{ } _} $level]]
      if {![winfo exists $mnu.$sub_mnu]} {
        set new_mnu [menu $mnu.$sub_mnu -tearoff 0 -postcommand "plugins::menu_state $mnu.$sub_mnu $action"]
        $registry($index,interp) alias $new_mnu interpreter::widget_win $registry($index,name) $new_mnu
        $mnu add cascade -label $level -menu $mnu.$sub_mnu
      }
      set mnu $mnu.$sub_mnu
      if {$hier_len == 0} {
        set force 0
      }
    }

    # Handle the state
    if {$state ne ""} {
      if {[catch { $registry($index,interp) eval $state } status]} {
        handle_status_error "menu_add_item" $index $status
        set state "disabled"
      } elseif {$status} {
        set state "normal"
      } else {
        set state "disabled"
      }
    }

    # Add menu item
    switch [lindex $type 0] {
      command {
        $mnu add command -label $level -command [list $registry($index,interp) eval {*}$do] -state $state
      }
      checkbutton {
        set menu_vars([lindex $type 1]) [$registry($index,interp) eval set [lindex $type 1]]
        $mnu add checkbutton -label $level -variable plugins::menu_vars([lindex $type 1]) \
          -command [list $registry($index,interp) eval {*}$do] -state $state
        trace variable plugins::menu_vars([lindex $type 1]) w "plugins::handle_menu_variable $index"
      }
      radiobutton {
        set menu_vars([lindex $type 1]) [$registry($index,interp) eval set [lindex $type 1]]
        $mnu add radiobutton -label $level -variable plugins::menu_vars([lindex $type 1]) \
          -value [lindex $type 2] -command [list $registry($index,interp) eval {*}$do] -state $state
        trace variable plugins::menu_vars([lindex $type 1]) w "plugins::handle_menu_variable $index"
      }
      cascade {
        set new_mnu_name "$mnu.[string tolower [string map {{ } _} $level]]"
        set new_mnu [menu $new_mnu_name -tearoff 0 -postcommand "plugins::post_cascade_menu $index $do $new_mnu_name"]
        $registry($index,interp) alias $new_mnu interpreter::widget_win $registry($index,name) $new_mnu
        $mnu add cascade -label $level -menu $new_mnu
      }
      separator {
        $mnu add separator
      }
    }

  }

  ######################################################################
  # Handles a cascade menu post command.
  proc post_cascade_menu {index do mnu} {

    variable registry

    # Recursively delete all of the items in the given menu
    menu_delete_cascade $mnu

    # Call the plugins do command to populate the menu
    if {[catch { $registry($index,interp) eval $do $mnu } status]} {
      handle_status_error "post_cascade_menu" $index $status
    }

  }

  ######################################################################
  # Recursively deletes all submenus of the given menu.
  proc menu_delete_cascade {mnu} {

    # If the menu is empty, stop now
    if {[$mnu index end] ne "none"} {

      # Recursively remove the children menus
      for {set i 0} {$i <= [$mnu index end]} {incr i} {
        if {[$mnu type $i] eq "cascade"} {
          menu_delete_cascade [set child_menu [$mnu entrycget $i -menu]]
          destroy $child_menu
        }
      }

      # Delete all of the menu items
      $mnu delete 0 end

    }

  }

  ######################################################################
  # Deletes all of the menus in the plugins menu.
  proc menu_delete {mnu action} {

    variable menus

    # Get the list of menu entries
    if {[llength [find_registry_entries $action]] > 0} {

      while {1} {
        switch [$mnu type last] {
          "separator" {
            $mnu delete last
            return
          }
          "cascade" {
            menu_delete_cascade [$mnu entrycget last -menu]
            destroy [$mnu entrycget last -menu]
            $mnu delete last
          }
          default {
            $mnu delete last
          }
        }
      }

    }

  }

  ######################################################################
  # Updates the plugin menu state of the given menu.
  proc menu_state {mnu action} {

    variable registry
    variable menus
    variable menu_vars

    foreach entry [find_registry_entries $action] {
      lassign $entry index type hier do state
      set entry_mnu $menus($action)
      if {[llength [set hier_list [split $hier /]]] > 1} {
        append entry_mnu ".[string tolower [string map {{ } _} [join [lrange $hier_list 0 end-1] .]]]"
      }
      if {$mnu eq $entry_mnu} {
        if {[catch { $registry($index,interp) eval $state } status]} {
          handle_status_error "menu_state" $index $status
        } elseif {$status} {
          $mnu entryconfigure [lindex $hier_list end] -state normal
        } else {
          $mnu entryconfigure [lindex $hier_list end] -state disabled
        }
        switch [lindex $type 0] {
          checkbutton { set menu_vars([lindex $type 1]) [$registry($index,interp) eval set [lindex $type 1]] }
          radiobutton { set menu_vars([lindex $type 1]) [$registry($index,interp) eval set [lindex $type 1]] }
        }
      }
    }

  }

  ######################################################################
  # Adds all of the plugins to the list of available menus.
  proc add_all_menus {} {

    variable menus

    foreach {action mnu} [array get menus] {
      menu_add $mnu $action
    }

  }

  ######################################################################
  # Adds all of the text bindings to all open text widgets.
  proc add_all_text_bindings {} {

    foreach {txt tags} [gui::get_all_texts] {
      handle_text_bindings $txt $tags
    }

  }

  ######################################################################
  # Adds all of the syntax files.
  proc add_all_syntax {} {

    variable registry

    foreach entry [find_registry_entries "syntax"] {
      lassign $entry index sfile
      set sfile [file join $::tke_dir plugins $registry($index,name) $sfile]
      syntax::add_syntax $sfile $registry($index,interp)
    }

  }

  ######################################################################
  # Deletes all plugins from their respective menus.
  proc delete_all_menus {} {

    variable menus

    foreach {action mnu} [array get menus] {
      menu_delete $mnu $action
    }

  }

  ######################################################################
  # Deletes all text bindings that were previously created.
  proc delete_all_text_bindings {} {

    variable bound_tags

    foreach {bt txts} [array get bound_tags] {
      foreach txt $txts {
        if {[set index [lsearch -exact [set btags [bindtags $txt]] $bt]] != -1} {
          bindtags $txt [lreplace $btags $index $index]
        }
        if {[set index [lsearch -exact [set btags [bindtags $txt.t]] $bt]] != -1} {
          bindtags $txt.t [lreplace $btags $index $index]
        }
      }
    }

    # Delete all of the bound tags
    array unset bound_tags

  }

  ######################################################################
  # Removes the given syntax files.
  proc delete_all_syntax {} {

    foreach entry [find_registry_entries "syntax"] {
      lassign $entry index sfile
      syntax::delete_syntax $sfile
    }

  }

  ######################################################################
  # Called when the plugin menu is created.
  proc handle_plugin_menu {mnu} {

    variable menus

    # Add the menu to the list of menus to update
    set menus(menu) $mnu

    # Add the menu items
    menu_add $mnu menu

  }

  ######################################################################
  # Adds any tab_popup menu items to the tab popup menu.
  proc handle_tab_popup {mnu} {

    variable menus

    # Add the menu to the list of menus to update
    set menus(tab_popup) $mnu

    # Add the menu items
    menu_add $mnu tab_popup

  }

  ######################################################################
  # Adds any root_popup menu items to the given menu.
  proc handle_root_popup {mnu} {

    variable menus

    # Add the menu items
    menu_add $mnu root_popup

  }

  ######################################################################
  # Adds any dir_popup menu items to the given menu.
  proc handle_dir_popup {mnu} {

    variable menus

    # Add the menu items
    menu_add $mnu dir_popup

  }

  ######################################################################
  # Adds any file_popup menu items to the given menu.
  proc handle_file_popup {mnu} {

    variable menus

    # Add the menu items
    menu_add $mnu file_popup

  }

  ######################################################################
  # Creates a bindtag on behalf of the user for the given text widget
  # and calls the associated procedure to have the bindings added.
  proc handle_text_bindings {txt tags} {

    variable registry
    variable bound_tags

    set ttags       [bindtags $txt.t]
    set tpre_index  [expr [lsearch -exact $ttags $txt.t] + 1]
    set tpost_index [lsearch -exact $ttags .]

    array set ptags {
      pretext  {}
      posttext {}
    }

    # Allow all plugins to access, query, and modify text widgets
    foreach entry [find_registry_entries "*"] {
      lassign $entry index
      interpreter::add_ctext $registry($index,interp) $registry($index,name) $txt
    }

    # Bind text widgets to tags
    foreach entry [find_registry_entries "text_binding"] {
      lassign $entry index type name bind_type cmd
      set bt "plugin__$registry($index,name)__$name"
      if {($bind_type eq "all") || ([lsearch $tags $bt] != -1)} {
        lappend ptags($type) $bt
        if {![info exists bound_tags($bt)]} {
          if {[catch { $registry($index,interp) eval $cmd $bt } status]} {
            handle_status_error "handle_text_bindings" $index $status
          }
          set bound_tags($bt) $txt
        } else {
          lappend bound_tags($bt) $txt
        }
      }
    }

    # Set the bindtags
    if {[llength $ptags(posttext)] > 0} {
      set ttags [linsert $ttags $tpost_index {*}$ptags(posttext)]
    }
    if {[llength $ptags(pretext)] > 0} {
      set ttags [linsert $ttags $tpre_index {*}$ptags(pretext)]
    }
    bindtags $txt.t $ttags

  }

  ######################################################################
  # Generically handles the given event.
  proc handle_event {event args} {

    variable registry

    foreach entry [find_registry_entries $event] {
      if {[catch { $registry([lindex $entry 0],interp) eval [lindex $entry 1] $args } status]} {
        handle_status_error "handle_event" [lindex $entry 0] $status
      }
    }

  }

  ######################################################################
  # Called whenever the application is started.
  proc handle_on_start {} {

    # Handle an application start
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
  # Called whenever a file/folder is renamed.
  proc handle_on_rename {old_fname new_fname} {

    handle_event "on_rename" $old_fname $new_fname

  }

  ######################################################################
  # Called whenever a file is duplicated.
  proc handle_on_duplicate {old_fname new_fname} {

    handle_event "on_duplicate" $old_fname $new_fname

  }

  ######################################################################
  # Called whenever a file/folder is deleted.
  proc handle_on_delete {fname} {

    handle_event "on_delete" $fname

  }

  ######################################################################
  # Called whenever a tab receives focus.
  proc handle_on_focusin {tab} {

    handle_event "on_focusin" $tab

  }

  ######################################################################
  # Called whenever a tab is closed.
  proc handle_on_close {file_index} {

    variable registry
    variable bound_tags

    handle_event "on_close" $file_index

    # Delete the list of bound tags
    set txt [gui::get_file_info $file_index txt]
    foreach entry [find_registry_entries "text_binding"] {
      lassign $entry index type name bind_type cmd
      set bt "plugin__$registry($index,name)__$name"
      if {[info exists bound_tags($bt)] && ([set findex [lsearch $bound_tags($bt) $txt]] != -1)} {
        set bound_tags($bt) [lreplace $bound_tags($bt) $findex $findex]
      }
    }

  }

  ######################################################################
  # Called whenever a tab is updated.
  proc handle_on_update {file_index} {

    handle_event "on_update" $file_index

  }

  ######################################################################
  # Called when the application is exiting.
  proc handle_on_quit {} {

    # Handle the on_quit event
    handle_event "on_quit"

    # Finally, write the plugin information file
    write_config

  }

  ######################################################################
  # Called when a plugin is uninstalled.
  proc handle_on_uninstall {index} {

    variable registry

    # If the given event contains an "on_uninstall" action, run it.
    foreach {name action} [array get registry $index,action,on_uninstall,*] {
      if {[catch { $registry($index,interp) eval {*}$action } status]} {
        handle_status_error "on_uninstall" $index $status
      }
    }

  }

  ######################################################################
  # Adds the VCS commands to the difference namespace.
  proc add_all_vcs_commands {} {

    foreach entry [find_registry_entries "vcs"] {
      lassign $entry index name handles versions file_cmd diff_cmd find_version version_log
      set ns ::diff::[string map {{ } _} [string tolower $name]]
      namespace eval $ns "proc name            {}              { return \"$name\" }"
      namespace eval $ns "proc type            {}              { return cvs }"
      namespace eval $ns "proc handles         {fname}         { return \[plugins::run_vcs $index $handles      \$fname\] }"
      namespace eval $ns "proc versions        {fname}         { return \[plugins::run_vcs $index $versions     \$fname\] }"
      namespace eval $ns "proc get_file_cmd    {version fname} { return \[plugins::run_vcs $index $file_cmd     \$fname \$version\] }"
      namespace eval $ns "proc get_diff_cmd    {v1 v2 fname}   { return \[plugins::run_vcs $index $diff_cmd     \$fname \$v1 \$v2\] }"
      namespace eval $ns "proc find_version    {fname v2 lnum} { return \[plugins::run_vcs $index $find_version \$fname \$v2 \$lnum\] }"
      namespace eval $ns "proc get_version_log {fname version} { return \[plugins::run_vcs $index $version_log  \$fname \$version\] }"
    }

  }

  ######################################################################
  # Removes the VCS commands from the diff namespace.
  proc delete_all_vcs_commands {} {

    foreach entry [find_registry_entries "vcs"] {
      lassign $entry index name
      namespace delete ::diff::[string map {{ } _} [string tolower $name]]
    }

  }

  ######################################################################
  # Runs the given VCS command.
  proc run_vcs {index cmd args} {

    variable registry

    if {[catch { $registry($index,interp) eval $cmd {*}$args } status]} {
      handle_status_error "run_vcs" $index $status
      return ""
    }

    return $status

  }

  ######################################################################
  # Returns the list of files in the TKE home directory to copy.
  proc get_share_items {dir} {

    return [list plugins.tkedat]

  }

  ######################################################################
  # Called whenever the share directory changes.
  proc share_changed {dir} {

    variable plugins_file

    set plugins_file [file join $dir plugins.tkedat]

  }

}
