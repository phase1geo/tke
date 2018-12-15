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
# Name:    plugins.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace to support the plugin framework.
#
# List of available plugin actions:
#  menu            - Adds a menu to the main menubar
#  tab_popup       - Adds items to the tab popup menu
#  root_popup      - Adds items to a root directory sidebar popup menu
#  dir_popup       - Adds items to a non-root directory sidebar popup menu
#  file_popup      - Adds items to a file sidebar popup menu
#  text_binding    - Adds one or more bindings to a created text field.
#  on_start        - Runs when the editor is started or when the plugin is installed
#  on_open         - Runs when a tab is opened
#  on_focusin      - Runs when a tab receives focus
#  on_close        - Runs when a tab is closed
#  on_update       - Runs when a tab is updated
#  on_quit         - Runs when the editor is exited
#  on_reload       - Takes action when the plugin is reloaded
#  on_save         - Runs prior to a file being saved
#  on_rename       - Runs when a file/folder is being renamed
#  on_duplicate    - Runs when a file is being duplicated
#  on_delete       - Runs when a file/folder is being deleted
#  on_trash        - Runs when a file/folder is moved to the trash
#  on_uninstall    - Runs when the plugin is uninstalled by the user.  Allows UI cleanup, etc.
#  on_pref_load    - Runs when the plugin preference items need to be added.
#  on_pref_ui      - Runs when the plugin preference panel needs to be displayed in the preferences window.
#  on_drop         - Runs when a file or text is dropped in an editing buffer.
#  on_theme_change - Runs after the user has changed themes.
#  syntax          - Adds the given syntax file to the list of available syntaxes
#  vcs             - Adds support for a version control system to the difference viewer
#  info_panel      - Adds items to the sidebar information panel.
#  expose          - Adds procedures that can be called from any plugin.
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
  array set exposed      {}

  array set categories [list \
    miscellaneous [msgcat::mc "Miscellaneous"] \
    editing       [msgcat::mc "Editing"] \
    tools         [msgcat::mc "Tools"] \
    sessions      [msgcat::mc "Sessions"] \
    search        [msgcat::mc "Search"] \
    filesystem    [msgcat::mc "File System"] \
    vcs           [msgcat::mc "Version Control"] \
    documentation [msgcat::mc "Documentation"] \
    syntax        [msgcat::mc "Syntax"] \
    sidebar       [msgcat::mc "Sidebar"] \
  ]

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

    # Get any plugins from the user's home directory
    if {[file exists [file join $::tke_home iplugins]]} {
      lappend dirs {*}[glob -nocomplain -directory [file join $::tke_home iplugins] -types d *]
    }

    foreach plugin $dirs {

      # Read the header information
      if {![catch { tkedat::read [file join $plugin header.tkedat] 0 } rc]} {

        array set header $rc

        # Store this information if the name is specified and it should be included
        if {[info exists header(name)] && ($header(name) ne "") && [info exists header(include)] && ($header(include) eq "yes")} {
          set registry($registry_size,selected)     0
          set registry($registry_size,status)       ""
          set registry($registry_size,interp)       ""
          set registry($registry_size,tgntd)        0
          set registry($registry_size,file)         [file join $plugin main.tcl]
          set registry($registry_size,name)         $header(name)
          set registry($registry_size,display_name) [expr {[info exists header(display_name)]   ? $header(display_name)   : [make_display_name $header(name)]}]
          set registry($registry_size,author)       [expr {[info exists header(author)]         ? $header(author)         : ""}]
          set registry($registry_size,website)      [expr {[info exists header(website)]        ? $header(website)        : ""}]
          set registry($registry_size,email)        [expr {[info exists header(email)]          ? $header(email)          : ""}]
          set registry($registry_size,version)      [expr {[info exists header(version)]        ? $header(version)        : ""}]
          set registry($registry_size,category)     [expr {[info exists header(category)]       ? [string tolower $header(category)] : "miscellaneous"}]
          set registry($registry_size,description)  [expr {[info exists header(description)]    ? $header(description)    : ""}]
          set registry($registry_size,treqd)        [expr {[info exists header(trust_required)] ? ([string compare -nocase $header(trust_required) "yes"] == 0) : 0}]
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

    # Delete all exposed procedures
    delete_all_exposed

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

    # Add all exposed procedures
    add_all_exposed

    # Add all of the plugins
    add_all_menus

    # Add all of the text bindings
    add_all_text_bindings

    # Add all of the syntaxes
    add_all_syntax

    # Add all of the VCS commands
    add_all_vcs_commands

    # Update the preferences
    handle_on_pref_load

    # Update the file information panel
    ipanel::insert_info_panel_plugins

    # Re-apply menu bindings in case the user added some for plugins
    bindings::load_file 1

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
          }
        }

      }

    }

    # If there was an error in sourcing any of the selected plugins, report the error to the user
    if {[llength $bad_sources] > 0} {
      set names [list]
      foreach bad_source $bad_sources {
        set registry($bad_source,selected) 0
        lappend names $registry($bad_source,display_name)
      }
      tk_messageBox -default ok -type ok -icon warning -parent . -title [msgcat::mc "Plugin Errors"] \
        -message [msgcat::mc "Syntax errors found in selected plugins"] -detail [join $names \n]
    }

    # Add all of the exposed procs
    add_all_exposed

    # Add all of the available VCS commands
    add_all_vcs_commands

    # Add preference items
    handle_on_pref_load

  }

  ######################################################################
  # Handles an error when sourcing a plugin file.
  proc handle_status_error {procname index status} {

    variable registry

    # Save the status
    set registry($index,status) $status

    # Get the name of the plugin
    set name $registry($index,display_name)

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
        set name         $registry($i,name)
        set display_name $registry($i,display_name)
        launcher::register_temp "`PLUGIN:$display_name" "plugins::install_item $i" $display_name 0 "plugins::show_detail $i"
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

    # Delete all exposed procedures
    delete_all_exposed

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
            add_all_exposed
            add_all_menus
            add_all_text_bindings
            add_all_syntax
            add_all_vcs_commands
            ipanel::insert_info_panel_plugins
            handle_on_pref_load
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
        gui::set_info_message [format "%s (%s)" [msgcat::mc "Plugin installed"] $registry($index,display_name)]
        set registry($index,selected) 1
        set registry($index,interp)   $interpreter
        handle_reloading $index
        run_on_start_after_install $index
      }

    # Otherwise, just mark the plugin as being selected
    } else {
      gui::set_info_message [format "%s (%s)" [msgcat::mc "Plugin installed"] $registry($index,display_name)]
      set registry($index,selected) 1
      run_on_start_after_install $index
    }

    # Add all exposed procedures
    add_all_exposed

    # Add all of the plugins
    add_all_menus

    # Add all of the text bindings
    add_all_text_bindings

    # Add all syntaxes
    add_all_syntax

    # Add all VCS commands
    add_all_vcs_commands

    # Update file information
    ipanel::insert_info_panel_plugins

    # Re-apply menu bindings in case the user added some for plugins
    bindings::load_file 1

    # Add all loaded preferences
    handle_on_pref_load

    # Save the installation information to the config file
    write_config

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
        set name         $registry($i,name)
        set display_name $registry($i,display_name)
        launcher::register_temp "`PLUGIN:$display_name" "plugins::uninstall_item $i" $display_name
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

    # Delete all exposed procedures
    delete_all_exposed

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

    # Add all exposed procedures
    add_all_exposed

    # Add all of the plugins
    add_all_menus

    # Add all of the text bindings
    add_all_text_bindings

    # Add all of the syntaxes
    add_all_syntax

    # Add all of the VCS commands
    add_all_vcs_commands

    # Update file information
    ipanel::insert_info_panel_plugins

    # Re-apply menu bindings in case the user added some for plugins
    bindings::load_file 1

    # Save the plugin information
    write_config

    # Display the uninstall message
    gui::set_info_message [format "%s (%s)" [msgcat::mc "Plugin uninstalled"] $registry($index,display_name)]

  }

  ######################################################################
  # Displays the installed plugins and their information (if specified).
  proc show_installed {} {

    variable registry
    variable registry_size

    for {set i 0} {$i < $registry_size} {incr i} {
      if {$registry($i,selected)} {
        set name         $registry($i,name)
        set display_name $registry($i,display_name)
        launcher::register_temp "`PLUGIN:$display_name" [list plugins::show_installed_item $i] $display_name 0 [list plugins::show_detail $i]
      }
    }

    # Display the launcher in PLUGIN: mode
    launcher::launch "`PLUGIN:" 1

  }

  ######################################################################
  # Displays the installed item's detail and README information (if specified).
  proc show_installed_item {index} {

    variable registry

    set display_name $registry($index,display_name)

    # Create a buffer
    gui::add_buffer end [format "%s: %s" [msgcat::mc "Plugin"] $display_name] "" -readonly 1 -lang "Markdown"

    # Get the newly added buffer
    gui::get_info {} current txt

    # Allow the text buffer to be edited
    $txt configure -state normal

    # Display the plugin detail
    $txt insert end "__Version:__\n\n"
    $txt insert end "$registry($index,version)\n\n\n"
    $txt insert end "__Author:__\n\n"
    $txt insert end "$registry($index,author)  ($registry($index,email))\n\n\n"
    if {$registry($index,website) ne ""} {
      $txt insert end "__Website:__\n\n"
      $txt insert end "\[$registry($index,website)\]($registry($index,website))\n\n\n"
    }
    $txt insert end "__Description:__\n\n"
    $txt insert end $registry($index,description)

    # Add the README contents (if it exists)
    if {![catch { open [file join [file dirname $registry($index,file)] README.md] r } rc]} {
      $txt insert end "\n\n\n__README Content:__\n\n" bold
      $txt insert end [read $rc]
      close $rc
    }

    # Hide the meta characters
    menus::hide_meta_chars .menubar.view

    # Disallow the text buffer to be edited
    $txt configure -state disabled

  }

  ######################################################################
  # Displays plugin information into the given text widget.
  proc show_detail {index txt} {

    variable registry

    $txt tag configure bold -underline 1

    $txt insert end "Version:" bold "  $registry($index,version)\n\n"
    $txt insert end "Author:" bold "  $registry($index,author)  ($registry($index,email))\n\n"
    if {$registry($index,website) ne ""} {
      $txt insert end "Website:" bold "  $registry($index,website)\n\n"
    }
    $txt insert end "Description:\n\n" bold
    $txt insert end $registry($index,description)

  }

  ######################################################################
  # Generates the Tcl name based on the given display name.
  proc make_tcl_name {display_name} {

    return [string tolower [string map {{ } _} $display_name]]

  }

  ######################################################################
  # Generates a display name based on the given Tcl name.
  proc make_display_name {name} {

    return [utils::str2titlecase [string map {_ { }} $name]]

  }

  ######################################################################
  # Creates a new plugin.  If 'install_dir' is true, the plugin will be
  # created in the TKE installed directory (only valid for TKE development).
  # If 'install_dir' is false, the plugin will be created in the user's
  # iplugins directory in their TKE home directory.
  proc create_new_plugin {{install_dir 0}} {

    set name ""

    if {[gui::get_user_response [msgcat::mc "Enter plugin name"] name]} {

      if {![regexp {^[a-zA-Z0-9_]+$} $name]} {
        gui::set_info_message [msgcat::mc "ERROR:  Plugin name is not valid (only alphanumeric and underscores are allowed)"]
        return
      }

      if {$install_dir} {
        set dirname [file join $::tke_dir plugins $name]
      } else {
        set dirname [file join $::tke_home iplugins $name]
      }

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

      # Create the display name
      set display_name [utils::str2titlecase [string map {_ { }} $name]]

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
      gui::add_file end $main

      # Create the header file
      if {[catch { open $header w } rc]} {
        gui::set_info_message [msgcat::mc "ERROR:  Unable to write plugin files"]
        return
      }

      # Create the header file
      puts $rc "name           {$name}"
      puts $rc "display_name   {$display_name}"
      puts $rc "author         {}"
      puts $rc "email          {}"
      puts $rc "website        {}"
      puts $rc "version        {1.0}"
      puts $rc "include        {yes}"
      puts $rc "trust_required {no}"
      puts $rc "category       {miscellaneous}"
      puts $rc "description    {}"
      close $rc

      # Add the file to the editor
      gui::add_file end $header

    }

  }

  ######################################################################
  # Returns the list of available categories in a sorted list.
  proc get_categories {type} {

    variable categories

    if {$type eq "lower"} {
      return [lsort [array names categories]]
    } else {
      set cats [list]
      foreach {lower display} [array get categories] {
        lappend cats $display
      }
      return [lsort $cats]
    }

  }

  ######################################################################
  # Called when the user clicks on a category within the text editor.
  # We will display a popup menu that will list the possible categories.
  # If the user clicks on a category, automatically replaces the existing
  # category with the selected one.
  proc edit_categories {txt startpos endpos} {

    variable categories
    variable current_category

    # Get the current category from the text
    set current_category [string map {\{ {} \} {}} [$txt get $startpos $endpos]]

    if {[winfo exists [set mnu $txt.categoryPopup]]} {
      destroy $mnu
    }

    menu $mnu -tearoff 0

    foreach category [lsort [array names categories]] {
      $mnu add radiobutton -label $categories($category) -variable plugins::current_category -value $category -command [list plugins::change_category $txt $startpos $endpos $category]
    }

    lassign [$txt bbox $startpos] x y w h

    tk_popup $mnu [expr [winfo rootx $txt] + $x] [expr [winfo rooty $txt] + ($y + $h)]

  }

  ######################################################################
  # Changes the category
  proc change_category {txt startpos endpos category} {

    $txt replace $startpos $endpos "\{$category\}"

  }

  ######################################################################
  # Returns the index of the plugin that matches the given name if found;
  # otherwise, returns the empty string.
  proc get_plugin_index {name} {

    variable registry
    variable registry_size

    for {set i 0} {$i < $registry_size} {incr i} {
      if {$registry($i,name) eq $name} {
        return $i
      }
    }

    return ""

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
  # Adds to the list of all exposed procedures.
  proc add_all_exposed {} {

    variable registry
    variable exposed

    foreach entry [find_registry_entries "expose"] {
      foreach p [lassign $entry index] {
        if {![catch { $registry($index,interp) eval info procs $p } rc] && ($rc eq "::$p")} {
          set exposed($p) $index
        } else {
          handle_status_error "exposed" $index "Exposed proc $p does not exist"
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
  # Clears the list of all exposed procedures.
  proc delete_all_exposed {} {

    variable exposed

    array unset exposed

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
        if {![winfo exists $txt]} continue
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

    # Add the menu to the list of menus to update
    set menus(root_popup) $mnu

    # Add the menu items
    menu_add $mnu root_popup

  }

  ######################################################################
  # Adds any dir_popup menu items to the given menu.
  proc handle_dir_popup {mnu} {

    variable menus

    # Add the menu to the list of menus to update
    set menus(dir_popup) $mnu

    # Add the menu items
    menu_add $mnu dir_popup

  }

  ######################################################################
  # Adds any file_popup menu items to the given menu.
  proc handle_file_popup {mnu} {

    variable menus

    # Add the menu to the list of menus to update
    set menus(file_popup) $mnu

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
    set tpre_index  [expr [lsearch -exact $ttags all] + 1]
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
  # Called whenever a file/folder is moved to the trash.
  proc handle_on_trash {fname} {

    handle_event "on_trash" $fname

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
  # Called when the preferences file is loaded.  This plugin should return
  # a list
  proc handle_on_pref_load {} {

    variable registry

    set prefs [list]

    foreach entry [find_registry_entries "on_pref_load"] {
      if {[catch { $registry([lindex $entry 0],interp) eval [lindex $entry 1] } status]} {
        handle_status_error "handle_on_pref_load" [lindex $entry 0] $status
      }
      foreach {name value} $status {
        lappend prefs "Plugins/$registry([lindex $entry 0],name)/$name" $value
      }
    }

    # Update the preferences namespace
    preferences::add_plugin_prefs $prefs

  }

  ######################################################################
  # Called when the preferences window is created.  This procedure is
  # responsible for creating the plugin preference frames.
  proc handle_on_pref_ui {w} {

    variable registry

    set plugins [list]

    foreach entry [find_registry_entries "on_pref_ui"] {
      $w add [ttk::frame [set win $w.$registry([lindex $entry 0],name)]]
      scrolledframe::scrolledframe $win.f  -yscrollcommand [list utils::set_yscrollbar $win.vb]
      scroller::scroller           $win.vb -orient vertical -command [list $win.f yview]
      grid rowconfigure    $win 0 -weight 1
      grid columnconfigure $win 0 -weight 1
      grid $win.f  -row 0 -column 0 -sticky news
      grid $win.vb -row 0 -column 1 -sticky ns
      theme::register_widget $win.vb misc_scrollbar
      if {[catch { $registry([lindex $entry 0],interp) eval [lindex $entry 1] $win.f.scrolled } status]} {
        handle_status_error "handle_on_pref_ui" [lindex $entry 0] $status
      } else {
        lappend plugins $registry([lindex $entry 0],name)
      }
    }

    return $plugins

  }

  ######################################################################
  # Handles a file/text drop event.
  proc handle_on_drop {file_index type data} {

    variable registry

    set owned 0

    foreach entry [find_registry_entries "on_drop"] {
      if {[catch { $registry([lindex $entry 0],interp) eval [lindex $entry 1] $file_index $type $data } status]} {
        handle_status_error "handle_on_drop" [lindex $entry 0] $status
      } elseif {![string is boolean $status]} {
        handle_status_error "handle_on_drop" [lindex $entry 0] "Callback procedure for handle_on_drop_enter did not return a boolean value"
      } elseif {$status} {
        set owned 1
      }
    }

    return $owned

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
  # Called when the theme has changed.
  proc handle_on_theme_changed {} {

    handle_event "on_theme_changed"

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
      lassign $entry index name handles versions file_cmd diff_cmd find_version current_version version_log
      set ns ::diff::[string map {{ } _} [string tolower $name]]
      namespace eval $ns "proc name            {}              { return \"$name\" }"
      namespace eval $ns "proc type            {}              { return cvs }"
      namespace eval $ns "proc handles         {fname}         { return \[plugins::run_vcs $index $handles      \$fname\] }"
      namespace eval $ns "proc versions        {fname}         { return \[plugins::run_vcs $index $versions     \$fname\] }"
      namespace eval $ns "proc get_file_cmd    {version fname} { return \[plugins::run_vcs $index $file_cmd     \$fname \$version\] }"
      namespace eval $ns "proc get_diff_cmd    {v1 v2 fname}   { return \[plugins::run_vcs $index $diff_cmd     \$fname \$v1 \$v2\] }"
      namespace eval $ns "proc find_version    {fname v2 lnum} { return \[plugins::run_vcs $index $find_version \$fname \$v2 \$lnum\] }"
      namespace eval $ns "proc get_current_version {fname}     { return \[plugins::run_vcs $index $current_version \$fname] }"
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
  # Returns file information titles to add.
  proc get_sidebar_info_titles {} {

    set titles [list]
    set i      0

    foreach entry [find_registry_entries "info_panel"] {
      lassign $entry index title copyable
      lappend titles $i $title $copyable
      incr i
    }

    return $titles

  }

  ######################################################################
  # Retrieves the file information for the given filename.
  proc get_sidebar_info_values {fname} {

    variable registry

    set values [list]
    set i      0

    foreach entry [find_registry_entries "info_panel"] {
      lassign $entry index title copyable value_cmd
      if {[catch { $registry($index,interp) eval $value_cmd $fname } status]} {
        handle_status_error "get_sidebar_info_values" $index $status
        set status ""
      }
      lappend values $i $status
      incr i
    }

    return $values

  }

  ######################################################################
  # Returns true if the given name is exposed.
  proc is_exposed {name} {

    variable exposed

    return [info exists exposed($name)]

  }

  ######################################################################
  # Executes the exposed procedure with the given arguments and returns
  # the value returned from the procedure.
  proc execute_exposed {name args} {

    variable registry
    variable exposed

    if {![info exists exposed($name)]} {
      return -code error "Attempting to execute a non-existent exposed proc"
    }

    set index $exposed($name)

    if {[catch { $registry($index,interp) eval $name $index $args } status]} {
      handle_status_error "execute_exposed" $index $status
      return -code error $status
    } else {
      return $status
    }

  }

  ######################################################################
  # Show the iplugins directory in the sidebar.
  proc show_iplugins {} {

    sidebar::add_directory [file join $::tke_home iplugins] -record 0

  }

  ######################################################################
  # Returns true if a plugin export is currently possible; otherwise, returns
  # false.
  proc export_available {} {

    set iplugins [file join $::tke_home iplugins]

    # Get the currently selected file
    gui::get_info {} current txt fname

    # If the given file exists in the iplugins directory, proceed with the export
    return [expr {[string compare -length [string length $iplugins] $iplugins $fname] == 0}]

  }

  ######################################################################
  # Exports the plugin that is currently opened in the editor.
  proc export {} {

    # If the export is not available, stop immediately
    if {![export_available]} {
      return
    }

    # Get the currently selected file
    gui::get_info {} current txt fname
    set split_fname   [file split $fname]
    set iplugin_index [lsearch $split_fname iplugins]
    set plugdir       [file join {*}[lrange $split_fname 0 [expr $iplugin_index + 1]]]

    # Perform the export
    plugmgr::export_win $plugdir

  }

  ######################################################################
  # Recursively gathers a list of files to zip.
  proc get_file_list {abs {rel ""}} {

    set file_list [list]

    foreach item [glob -directory $abs *] {
      if {[file isdirectory $item]} {
        lappend file_list {*}[get_file_list $item [file join $rel [file tail $item]]]
      } elseif {[file isfile $item]} {
        lappend file_list [file join $rel [file tail $item]]
      }
    }

    return $file_list

  }

  ######################################################################
  # Exports the specified plugin as a .tkeplugz file.  This filetype will
  # support drag-and-drop to install a given plugin.
  proc export_plugin {parent_win name odir} {

    # Get the directory to export
    set idir [file join $::tke_home iplugins $name]

    # If the directory does not exist return 0.
    if {![file exists $idir]} {
      return 0
    }

    # Get the current working directory
    set pwd [pwd]

    # Set the current working directory to the user themes directory
    cd [file dirname $idir]

    # Get the list of files to use in list2zip
    set file_list [get_file_list $idir $name]

    # Make sure there isn't a zipfile of the same name
    catch { file delete -force [file join $odir $name.tkeplugz] }

    # Perform the archive
    if {[catch { zipper::list2zip [file dirname $idir] $file_list [file join $odir $name.tkeplugz] } rc]} {
      if {[catch { exec -ignorestderr zip -r [file join $odir $name.tkeplugz] $name } rc]} {
        tk_messageBox -parent $parent_win -icon error -type ok -default ok \
          -message [format "%s %s" [msgcat::mc "Unable to zip plugin"] $name]
      }
    }

    # Restore the current working directory
    cd $pwd

    return 1

  }

  ######################################################################
  # Opens a file browser to allow the user to select an installable plugin
  # file.
  proc import {} {

    # Get the list of files to import from the user
    set ifiles  [tk_getOpenFile -parent . -initialdir [gui::get_browse_directory] -filetypes {{{TKE Plugin File} {.tkeplugz}}} -defaultextension .tkeplugz -multiple 1]

    # Perform the import for each selected file
    if {[llength $ifiles] > 0} {
      set success 1
      foreach ifile $ifiles {
        if {[import_plugin . $ifile] eq ""} {
          set success 0
        }
      }
      if {$success} {
        reload
        gui::set_info_message [msgcat::mc "Plugin import completed successfully"]
      }
    }

  }

  ######################################################################
  # Imports the given plugin, copying the data to the user's home plugins
  # directory.
  proc import_plugin {parent_win fname} {

    # Make sure that the plugins directory exists
    file mkdir [file join $::tke_home iplugins]

    # If the directory exists, move it out of the way
    set odir [file join $::tke_home iplugins [file rootname [file tail $fname]]]
    if {[file exists $odir]} {
      file rename $odir $odir.old
    }

    # Unzip the file contents
    if {[catch { zipper::unzip $fname [file dirname $odir] } rc]} {
      if {[catch { exec -ignorestderr unzip -u $fname -d [file dirname $odir] } rc]} {
        catch { file rename $odir.old $odir }
        tk_messageBox -parent $parent_win -icon error -type ok -default ok \
          -message [format "%s %s" [msgcat::mc "Unable to unzip plugin"] $fname] -detail $rc
        return ""
      }
    }

    # Remove the old file if it exists
    catch { file delete -force $odir.old }

    # We need to set the file permissions to be readable
    foreach ifile [get_file_list $odir] {
      catch { file attributes [file join $odir $ifile] -permissions rw-r--r-- }
    }

    return $odir

  }

  ######################################################################
  # Returns the value of the given plugin attribute.
  proc get_header_info {plugin attr} {

    variable registry
    variable registry_size

    array set fields {
      display_name   display_name
      name           name
      author         author
      email          email
      website        website
      version        version
      trust_required treqd
      description    description
      category       category
    }

    if {![info exists fields($attr)]} {
      return -code "Unsupported header field requested ($attr)"
    }

    # Find the associated plugin and, when found, return the attribute value
    for {set i 0} {$i < $registry_size} {incr i} {
      if {$registry($i,name) eq $plugin} {
        return $registry($i,$fields($attr))
      }
    }

    return ""

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
