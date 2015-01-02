# Name:    launcher.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace for the launcher functionality.

namespace eval launcher {

  source [file join $::tke_dir lib ns.tcl]

  variable launcher_file  [file join $::tke_home launcher.dat]
  variable match_commands {}
  
  array set read_commands {}
  array set commands      {}
  array set widgets       {}
  array set options       {
    -results       10
  }
  array set command_names {
    name         0
    validate_cmd 1
    temporary    2
  }
  array set command_values {
    description    0
    command        1
    auto_register  2
    count          3
    search_str     4
    detail_command 5
  }
  
  ######################################################################
  # Loads the launcher functionality.
  proc load {} {
  
    variable launcher_file
    variable read_commands
    
    if {![catch { open $launcher_file r } rc]} {
      array set read_commands [read $rc]
      close $rc
    }
    
    # Add preferences traces
    trace variable preferences::prefs(Appearance/CommandLauncherEntryFontSize)   w launcher::handle_entry_font_size
    trace variable preferences::prefs(Appearance/CommandLauncherPreviewFontSize) w launcher::handle_preview_font_size

  }
  
  ######################################################################
  # Writes the launcher information to the launcher file.
  proc write {} {
  
    variable launcher_file
    variable commands
    
    if {![catch { open $launcher_file w } rc]} {
      foreach {name value} [array get commands] {
        puts $rc "[list $name] [list $value]"
      }
      close $rc
    }
    
  }
  
  ######################################################################
  # Launches the command launcher.
  proc launch {{mode ""} {show_detail 0}} {
  
    variable widgets

    if {![winfo exists .lwin]} {
      
      set widgets(win) .lwin

      ttk::frame $widgets(win) -borderwidth 2

      set widgets(entry) [ttk::entry $widgets(win).entry -width 50 -validate key -validatecommand "launcher::lookup %P {$mode} $show_detail" -invalidcommand {bell}]
      
      if {[lsearch [font names] launcher_entry] == -1} {
        font create launcher_entry -family [font configure [$widgets(entry) cget -font] -family] \
          -size [preferences::get Appearance/CommandLauncherEntryFontSize]
      }
      
      $widgets(entry) configure -font launcher_entry
  
      set widgets(mf) [ttk::frame $widgets(win).mf]
      set widgets(lf) [ttk::frame $widgets(win).mf.lf]
      set widgets(lb) [listbox $widgets(lf).lb -exportselection 0 -bg white -height 0 -width 35 \
        -yscrollcommand "utils::set_yscrollbar $widgets(lf).vb" -listvariable launcher::match_commands]
      ttk::scrollbar $widgets(lf).vb -orient vertical -command "$widgets(lb) yview"
      
      grid rowconfigure    $widgets(lf) 0 -weight 1
      grid columnconfigure $widgets(lf) 0 -weight 1
      grid $widgets(lf).lb -row 0 -column 0 -sticky news
      grid $widgets(lf).vb -row 0 -column 1 -sticky ns
      
      # Create a special font for the text widget
      set widgets(txt) [text $widgets(win).mf.txt -font [font create -size 7] -width 60 -height 15 \
                          -relief flat -wrap word -state disabled \
                          -fg [utils::get_default_foreground] -bg [utils::get_default_background]]
                          
      if {[lsearch [font names] launcher_preview] == -1} {
        font create launcher_preview -family [font configure [$widgets(txt) cget -font] -family] \
          -size [preferences::get Appearance/CommandLauncherPreviewFontSize]
      }
      
      $widgets(txt) configure -font launcher_preview
      
      grid rowconfigure    $widgets(mf) 0 -weight 1
      grid columnconfigure $widgets(mf) 0 -weight 1
      grid $widgets(lf)  -row 0 -column 0 -sticky news
      grid $widgets(txt) -row 0 -column 1 -sticky news
      
      # Hide the text widget
      grid remove $widgets(txt)
      
      pack $widgets(entry) -fill x

      # Bind the escape key to exit the window
      bind $widgets(win)   <Destroy>  "launcher::handle_win_destroy"
      bind $widgets(entry) <Escape>   "destroy $widgets(win)"
      bind $widgets(win)   <FocusOut> "destroy $widgets(win)"

      # Position the window in the center of the main window
      place $widgets(win) -relx 0.4 -rely 0.25

      # Get current focus and grab
      ::tk::SetFocusGrab $widgets(win) $widgets(entry)

      # If we are running in a mode, display the default results
      if {$mode ne ""} {
        lookup "" $mode $show_detail
      }

    }
      
  }
  
  ######################################################################
  # Called when the launcher window is destroyed.
  proc handle_win_destroy {} {

    variable widgets

    # Reset the original focus and grab
    ::tk::RestoreFocusGrab $widgets(win) $widgets(entry)
      
    # Destroy temporary registrations
    remove_temporary

  }

  ######################################################################
  # Handles any changes to the entry font size preferences variable.
  proc handle_entry_font_size {name1 name2 op} {
    
    if {[lsearch [font names] launcher_entry] != -1} {
      font configure launcher_entry -size [preferences::get Appearance/CommandLauncherEntryFontSize]
    }
    
  }
  
  ######################################################################
  # Handles any changes to the preview font size preferences variable.
  proc handle_preview_font_size {name1 name2 op} {
    
    if {[lsearch [font names] launcher_preview] != -1} {
      font configure launcher_preview -size [preferences::get Appearance/CommandLauncherPreviewFontSize]
    }
    
  }
  
  ############################################################################
  # Moves the currently selected command up by one row.
  proc move_up {} {

    variable widgets
    
    set selected [$widgets(lb) curselection]

    if {$selected > 0} {
      select [expr $selected - 1]
    }

  }

  ############################################################################
  # Moves the currently selected command down by one row.
  proc move_down {} {
    
    variable widgets

    set selected [$widgets(lb) curselection]

    if {$selected < [expr [$widgets(lb) size] - 1]} {
      select [expr $selected + 1]
    }

  }
  
  ############################################################################
  # Selects the current row within the selection table.
  proc select {row} {
    
    variable widgets
    variable commands
    variable command_values
    variable matches
    
    # Set the selection
    $widgets(lb) selection clear 0 end
    $widgets(lb) selection set $row $row
    $widgets(lb) see $row
    
    # If the text widget is shown, clear it and display the current detail information
    if {[lsearch [grid slaves $widgets(mf)] $widgets(txt)] != -1} {
      $widgets(txt) configure -state normal
      $widgets(txt) delete 1.0 end
      if {[set detail_command [lindex $commands([lindex $matches $row]) $command_values(detail_command)]] ne ""} {
        uplevel #0 "$detail_command $widgets(txt)"
      }
      $widgets(txt) configure -state disabled
    }

  }
  
  ######################################################################
  # Adds a new command that is registered for use by the widget.
  proc register {name command {detail_command ""} {validate_cmd "launcher::okay"} {auto_register 0}} {

    variable commands
    variable read_commands
    variable command_names
    variable command_values

    # If the read file has not been read, do it now and bind ourselves
    if {[array size read_commands] == 0} {
      load
    }

    # Create default values
    set count        0
    set search_str   ""
    set command_name [get_command_name $name $validate_cmd 0]

    # Update the commands array
    if {[llength [array names commands $command_name]] == 0} {
      if {[info exists read_commands($command_name)]} {
        set count      [lindex $read_commands($command_name) $command_values(count)]
        set search_str [lindex $read_commands($command_name) $command_values(search_str)]
      }
    }

    # Create the command list
    set command_value [lrepeat [array size command_values] ""]
    lset command_value $command_values(description)    [string trim $name]
    lset command_value $command_values(command)        $command
    lset command_value $command_values(auto_register)  $auto_register
    lset command_value $command_values(count)          $count
    lset command_value $command_values(search_str)     $search_str
    lset command_value $command_values(detail_command) $detail_command

    # Populate the command in the lookup table
    set commands($command_name) $command_value

  }

  ############################################################################
  # Adds a new command that is registered for use by the widget but will not
  # be saved.
  proc register_temp {name command description {order 0x7fffffff} {detail_command ""} {validate_cmd "launcher::okay"}} {

    variable commands
    variable command_names
    variable command_values
    
    # Create the command name list
    set command_name [get_command_name $name $validate_cmd 1]

    # Create the command value list
    set command_value [lrepeat [array size command_values] ""]
    lset command_value $command_values(description)    [string trim $description]
    lset command_value $command_values(command)        $command
    lset command_value $command_values(auto_register)  0
    lset command_value $command_values(count)          [expr 0x7fffffff - $order]
    lset command_value $command_values(search_str)     $name
    lset command_value $command_values(detail_command) $detail_command

    # Populate the command in the lookup table
    set commands($command_name) $command_value
    
    return $command_name

  }
  
  ######################################################################
  # Unregisters launcher commands that match the given pattern.
  proc unregister {name_pattern {command_pattern *} {temp_pattern *}} {
  
    variable commands
    
    array unset commands [get_command_name $name_pattern $command_pattern $temp_pattern]
    
  }
    
  ######################################################################
  # Removes all of the temporary registrations.
  proc remove_temporary {} {
    
    # Unregister all temporary registrations
    unregister * * 1
    
  }
  
  ######################################################################
  # Returns the command name given the specified values.
  proc get_command_name {name validate_cmd temporary} {

    variable command_names

    # Create the command name list
    set command_name [lrepeat [array size command_names] ""]
    lset command_name $command_names(name)         [string tolower $name]
    lset command_name $command_names(validate_cmd) $validate_cmd
    lset command_name $command_names(temporary)    $temporary

    return $command_name

  }
  
  ######################################################################
  # Default validate command.
  proc okay {} {
  
    return 1
    
  }
  
  ######################################################################
  # Validate command for calculations.
  proc calc_okay {} {
  
    return 1
    
  }
  
  ######################################################################
  # Validate command for symbols.
  proc symbol_okay {} {
    
    return 1
    
  }
  
  ######################################################################
  # Validate command for markers.
  proc marker_okay {} {
    
    return 1
    
  }
  
  ######################################################################
  # Validate command for clipboard history.
  proc clip_okay {} {
    
    return 1
    
  }
  
  ######################################################################
  # Validate command for URL launching.
  proc url_okay {} {
    
    return 1
    
  }
  
  ######################################################################
  # Validate command for snippet insertion.
  proc snip_okay {} {
    
    return 1
    
  }
  
  ######################################################################
  # Called whenever the user enters a value
  proc lookup {value mode show_detail} {

    variable widgets
    variable commands
    variable matches
    variable options
    variable match_commands
    variable command_names
    variable command_values
    
    if {($value ne "") || ($mode ne "")} {

      # Find all of the matches
      find_matches $value $mode

      # Get the number of matches
      set match_num [llength $matches]

      # Only display results if we have some to display
      if {$match_num > 0 } {

        # Limit the match list to the top
        if {$match_num > $options(-results)} {
          $widgets(lb) configure -height $options(-results)
        } else {
          $widgets(lb) configure -height $match_num
        }
        
        # If we need to show detail, display the text widget
        if {$show_detail} {
          grid $widgets(txt)
        }

        # Update the table
        set match_commands [list]
        for {set i 0} {$i < $match_num} {incr i} {
          lappend match_commands [lindex $commands([lindex $matches $i]) $command_values(description)]
        }

        # Bind up/down and return keys
        bind $widgets(entry) <Up>       "launcher::move_up"
        bind $widgets(entry) <Down>     "launcher::move_down"
        bind $widgets(entry) <Return>   "launcher::execute"
        bind $widgets(entry) <Escape>   "destroy $widgets(win)"
        bind $widgets(lb)    <Button-1> "launcher::execute"

        # Set tablelist selection to the first entry
        select 0

        # Pack the listbox, if it isn't already
        if {[catch "pack info $widgets(mf)"]} {    
          pack $widgets(mf) -fill both -expand yes
        }

      } else {

        # Remove the results frame
        pack forget $widgets(mf)

        # Unbind up and down arrows
        bind $widgets(entry) <Up>     ""
        bind $widgets(entry) <Down>   ""
        bind $widgets(entry) <Return> "destroy $widgets(win)"
        bind $widgets(entry) <Escape> "destroy $widgets(win)"

      }

    } else {

      # Remove the results frame
      pack forget $widgets(mf)

      # Unbind up and down arrows
      bind $widgets(entry) <Up>     ""
      bind $widgets(entry) <Down>   ""
      bind $widgets(entry) <Return> "destroy $widgets(win)"
      bind $widgets(entry) <Escape> "destroy $widgets(win)"

    }

    return 1

  }
 
  ############################################################################
  # Updates the contents of the matches array which contains all of the entries
  # that match the given user input.
  proc find_matches {str mode} {

    variable commands
    variable command_names
    variable command_values
    variable matches
    variable curr_states
    variable last_url

    set matches [list]
    
    if {$mode eq ""} {
      
      switch [string index $str 0] {
        "@" {
          if {[llength [array names commands [get_command_name * launcher::symbol_okay 1]]] == 0} {
            unregister * * 1
            set i 0
            foreach {procedure pos} [gui::get_symbol_list {}] {
              lappend matches [register_temp "@$procedure" "gui::jump_to {} $pos" $procedure $i "" launcher::symbol_okay]
              incr i
            }
          }
        }
        "," {
          if {[llength [array names commands [get_command_name * launcher::marker_okay 1]]] == 0} {
            unregister * * 1
            set i 0
            foreach {marker pos} [gui::get_marker_list {}] {
              lappend matches [register_temp ",$marker" "gui::jump_to {} $pos" $marker $i "" launcher::marker_okay]
              incr i
            }
          }
        }
        "#" {
          if {[llength [array names commands [get_command_name * launcher::clip_okay 1]]] == 0} {
            unregister * * 1
            set i 0
            foreach strs [cliphist::get_history] {
              lassign $strs name str
              lappend matches [register_temp "#$name" [list cliphist::add_to_clipboard $str] $name $i [list cliphist::add_detail $str] launcher::clip_okay]
              incr i
            }
          }
        }
        ":" {
          if {[llength [array names commands [get_command_name * launcher::snip_okay 1]]] == 0} {
            unregister * * 1
            set i 0
            foreach snippet [snippets::get_current_snippets] {
              lassign $snippet name value
              lappend matches [register_temp ":$name" [list snippets::insert_snippet_into_current {} $value] $name $i "" launcher::snip_okay]
              incr i
            }
          }
        }
        default {
          unregister * * 1
          if {([string first {[} $str] == -1) && [handle_calculation $str]} {
            # Nothing more to do
          } elseif {[regexp {^((https?://)?[a-z0-9\-]+\.[a-z0-9\-\.]+(?:/|(?:/[a-zA-Z0-9!#\$%&'\*\+,\-\.:;=\?@\[\]_~]+)*))$} $str -> url]} {
            lappend matches [register_temp "" [list launcher::open_url_and_bookmark $url] "Open URL $url" 0 "" launcher::url_okay]
          }
        }
      }
    
    }
 
    # Get the precise match (if one exists)
    set results [list]
    foreach {name value} [array get commands [get_command_name * * *]] {
      if {[lindex $value $command_values(search_str)] eq "$mode$str"} {
        if {[eval [lindex $name $command_names(validate_cmd)]]} {
          lappend results [list $name $value]
        }
      }
    }
    
    # Make the string regular expression friendly
    set tmpstr [string map {{.} {\.} {*} {\*} {+} {\+} {?} {\?} {[} {\[}} $str]
    
    # Sort the results by relevance
    sort_match_results $results 1

    # Get exact matches that match the beginning of the statement
    sort_match_results [get_match_results \{?$mode$tmpstr.*] 0

    # Get all of the exact matches within the string
    sort_match_results [get_match_results \{?$mode.*$tmpstr.*] 0

    # Get all of the fuzzy matches
    sort_match_results [get_match_results \{?$mode.*[join [string map {{.} {\\\.} {*} {\\\*} {+} {\\\+} {?} {\\\?} {[} {\\\[}} [split $str {}]] .*].*] 1
    
  }

  ############################################################################
  # Searches the list of commands that match the top widget and the given search
  # pattern.
  proc get_match_results {regex_pattern} {

    variable commands
    variable command_names
    variable command_values
    variable matches

    set results [list]
          
    foreach name [array name commands -regexp [get_command_name $regex_pattern * *]] {
      set value $commands($name)
      if {[lsearch -exact $matches $name] == -1} {
        set validate_cmd [lindex $name $command_names(validate_cmd)]
        if {[eval $validate_cmd]} {
          if {$validate_cmd ne "launcher::okay"} {
            lset value $command_values(count) [expr [lindex $value $command_values(count)] + 1000000]
          }
          lappend results [list $name $value]
        }
      }
    }

    return $results

  }

  ############################################################################
  # Sorts the results by last accessed time and appends the sorted results
  # to the matches list.
  proc sort_match_results {results type} {

    variable command_values
    variable matches

    # Sort the results by relevance
    foreach result [lsort -integer -index [list 1 $command_values(count)] -decreasing $results] {
      lappend matches [lindex $result 0]
    }

  }

  ############################################################################
  # Executes the selected command, saving usage information.
  proc execute {} {

    variable widgets
    variable matches
    variable commands
    variable command_values
    variable widgets
    variable last_command

    # Get the current selection
    set row [$widgets(lb) curselection]

    # Retrieve the command name
    set command_name [lindex $matches $row]

    # Create the command value
    set command_value $commands($command_name)
    lset command_value $command_values(count) \
      [expr [lindex $command_value $command_values(count)] + 1]
    lset command_value $command_values(search_str) \
      [$widgets(entry) get]

    # Store the relevance by using the new execution count and the entered search string
    set commands($command_name) $command_value
    set command [lindex $commands($command_name) $command_values(command)]

    # Store the last command and type
    set last_command $command_name

    # Destroy the widget
    destroy $widgets(win)
    
    # Execute the associated command
    after 1 [list launcher::execute_helper $command]

  }

  ############################################################################
  # Helper procedure for the execute procedure.
  proc execute_helper {command} {

    # Execute the command
    eval "$command"

    # Write the launcher information
    bgproc::command launcher_write launcher::write -cancelable 1

  }
  
  ############################################################################
  # Handles a calculation that is presented on the command-line.  The calculation
  # can be either a Tcl expression or a Verilog expression.
  proc handle_calculation {str} {

    variable matches
    
    # Check to see if the string is a valid Tcl expression
    if {![catch "expr $str" rc]} {

      lappend matches [register_temp "" [list launcher::copy_calculation $rc] "Copy $rc to clipboard" 0 "" launcher::calc_okay]
            
      return 1
            
    }
          
    return 0
    
  }

  ############################################################################
  # Copies the current calculation to the clipboard.
  proc copy_calculation {value} {

    variable last_command

    # Clear the clipboard and add the calculation
    clipboard clear
    clipboard append $value
    
    # Add the clipboard content to the clipboard history manager
    cliphist::add_from_clipboard

    # Clear the last command so that we don't have the calculated value stuck in memory
    set last_command ""

  }
        
  ######################################################################
  # Displays the given URL and bookmarks it.
  proc open_url_and_bookmark {url} {
    
    # Open the URL in the local browser
    open_url $url
    
    # Add the URL to the bookmark list
    register "Open bookmarked URL $url" [list launcher::open_url $url]
    
  }
        
  ######################################################################
  # Shows the given URL and adds it to the URL history if it does not
  # exist.
  proc open_url {url} {
    
    # If the URL did not contain the http portion, add it so that the external launcher knows
    # this is a URL.
    if {[string range $url 0 3] ne "http"} {
      set url "http://$url"
    }
          
    # Displays the URL in the local browser
    utils::open_file_externally $url
          
  }
  
}
