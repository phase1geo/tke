# Name:    launcher.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace for the launcher functionality.

namespace eval launcher {

  variable launcher_file  [file join $::tke_home launcher.dat]
  variable closed         0
  variable match_commands {}
  variable last_calc      ""
  
  array set read_commands {}
  array set commands      {}
  array set widgets       {}
  array set options       {
    -results       10
  }
  array set command_names {
    name         0
    validate_cmd 1
  }
  array set command_values {
    command       0
    auto_register 1
    temporary     2
    count         3
    search_str    4
  }

  ######################################################################
  # Loads the launcher functionality.
  proc load {} {
  
    variable launcher_file
    variable read_commands
    
    if {![catch "open $launcher_file r" rc]} {
      array set read_commands [read $rc]
      close $rc
    }
  
  }
  
  ######################################################################
  # Writes the launcher information to the launcher file.
  proc write {} {
  
    variable launcher_file
    variable commands
    
    if {![catch "open $launcher_file w" rc]} {
      foreach {name value} [array get commands] {
        puts $rc "[list $name] [list $value]"
      }
      close $rc
    }
  
  }
  
  ######################################################################
  # Launches the command launcher.
  proc launch {} {
  
    variable widgets
    variable closed
  
    if {![winfo exists .lwin]} {

      set widgets(win) .lwin

      toplevel            $widgets(win) -class Dialog -bg black -bd 2
      wm overrideredirect $widgets(win) 1
      wm transient        $widgets(win) .

      set widgets(entry) [ttk::entry $widgets(win).entry -width 50 -validate key -validatecommand "launcher::lookup %P" -invalidcommand {bell}]
      set widgets(lb)    [listbox    $widgets(win).lb    -exportselection 0 -bg white -height 0 -listvariable launcher::match_commands]

      pack $widgets(entry) -fill x

      # Bind the escape key to exit the window
      set closed 0
      bind $widgets(win) <Destroy>  "set launcher::closed 1"
      bind $widgets(win) <Escape>   "set launcher::closed 1"
      bind $widgets(win) <FocusOut> "set launcher::closed 1"

      # Position the window in the center of the main window
      wm withdraw $widgets(win)
      update idletasks
      set x [expr (([winfo width  .] / 2) - ([winfo reqwidth  $widgets(win)] / 2)) + [winfo x .]]
      set y [expr (([winfo height .] / 4) - ([winfo reqheight $widgets(win)] / 2)) + [winfo y .]]
      if {$x < 0} {
        set x 0
      }
      if {$y < 0} {
        set y 0
      }
      wm geometry  $widgets(win) +$x+$y
      wm deiconify $widgets(win)

      # Get current focus and grab
      set old_focus [focus]
      set old_grab  [grab current $widgets(win)]
      if {$old_grab ne ""} {
        set grab_status [grab status $old_grab]
      }

      # Make sure the entry field is given focus
      focus $widgets(entry)

      # Wait for the window to be destroyed
      vwait launcher::closed

      # Reset the original focus and grab
      catch {focus $old_focus}
      catch {destroy $widgets(win)}
      if {$old_grab ne ""} {
        if {$grab_status ne "global"} {
          grab $old_grab
        } else {
          grab -global $old_grab
        }
      }

    }
  
  }
  
  ############################################################################
  # Moves the currently selected command up by one row.
  proc move_up {lb} {

    set selected [$lb curselection]

    if {$selected > 0} {
      select $lb [expr $selected - 1]
    }

  }

  ############################################################################
  # Moves the currently selected command down by one row.
  proc move_down {lb} {

    set selected [$lb curselection]

    if {$selected < [expr [$lb size] - 1]} {
      select $lb [expr $selected + 1]
    }

  }
  
  ############################################################################
  # Selects the current row within the selection table.
  proc select {lb row} {

    # Get the currently selected row
    set curr_sel [$lb curselection]

    # Set the selection
    $lb selection clear 0 end
    $lb selection set $row $row

  }
  
  ######################################################################
  # Adds a new command that is registered for use by the widget.
  proc register {name command {validate_cmd "launcher::okay"} {auto_register 0}} {

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
    set command_name [get_command_name $name $validate_cmd]

    # Update the commands array
    if {[llength [array names commands $command_name]] == 0} {
      if {[info exists read_commands($command_name)]} {
        set count      [lindex $read_commands($command_name) $command_values(count)]
        set search_str [lindex $read_commands($command_name) $command_values(search_str)]
      }
    }

    # Create the command list
    set command_value [lrepeat [array size command_values] ""]
    lset command_value $command_values(command)       $command
    lset command_value $command_values(auto_register) $auto_register
    lset command_value $command_values(temporary)     0
    lset command_value $command_values(count)         $count
    lset command_value $command_values(search_str)    $search_str

    # Populate the command in the lookup table
    set commands($command_name) $command_value

  }

  ############################################################################
  # Adds a new command that is registered for use by the widget but will not
  # be saved.
  proc register_temp {name command {validate_cmd "launcher::okay"}} {

    variable commands
    variable command_names
    variable command_values

    # Create default values
    set count      0
    set search_str ""

    # Create the command value list
    set command_value [lrepeat [array size command_values] ""]
    lset command_value $command_values(command)       $command
    lset command_value $command_values(auto_register) 0
    lset command_value $command_values(temporary)     1
    lset command_value $command_values(count)         $count
    lset command_value $command_values(search_str)    $search_str

    # Populate the command in the lookup table
    set commands([get_command_name $name $validate_cmd]) $command_value

  }
    
  ######################################################################
  # Returns the command name given the specified values.
  proc get_command_name {name validate_cmd} {

    variable command_names

    # Create the command name list
    set command_name [lrepeat [array size command_names] ""]
    lset command_name $command_names(name)         $name
    lset command_name $command_names(validate_cmd) $validate_cmd

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
  # Called whenever the user enters a value
  proc lookup {value} {

    variable widgets
    variable commands
    variable matches
    variable options
    variable match_commands
    variable command_names

    if {$value ne ""} {

      # Find all of the matches
      find_matches $value

      # Get the number of matches
      set match_num [llength $matches]

      # Only display results if we have some to display
      if {$match_num > 0 } {

        # Limit the match list to the top
        if {$match_num > $options(-results)} {
          set match_num $options(-results)
        }
        $widgets(lb) configure -height $match_num

        # Update the table
        set match_commands [list]
        for {set i 0} {$i < $match_num} {incr i} {
          lappend match_commands [lindex $matches $i $command_names(name)]
        }

        # Bind up/down and return keys
        bind $widgets(win) <Up>     "launcher::move_up   $widgets(lb)"
        bind $widgets(win) <Down>   "launcher::move_down $widgets(lb)"
        bind $widgets(win) <Return> "launcher::execute   $widgets(lb)"

        # Set tablelist selection to the first entry
        select $widgets(lb) 0

        # Pack the listbox, if it isn't already
        if {[catch "pack info $widgets(lb)"]} {    
          pack $widgets(lb) -fill both -expand yes
        }

      } else {

        # Remove the results frame
        pack forget $widgets(lb)

        # Unbind up and down arrows
        bind $widgets(win) <Up>     ""
        bind $widgets(win) <Down>   ""
        bind $widgets(win) <Return> "set launcher::closed 1"

      }

    } else {

      # Remove the results frame
      pack forget $widgets(lb)

      # Unbind up and down arrows
      bind $widgets(win) <Up>     ""
      bind $widgets(win) <Down>   ""
      bind $widgets(win) <Return> "set launcher::closed 1"

    }

    return 1

  }
 
  ############################################################################
  # Updates the contents of the matches array which contains all of the entries
  # that match the given user input.
  proc find_matches {str} {

    variable commands
    variable command_names
    variable command_values
    variable matches
    variable match_types
    variable curr_states
    variable last_url

    set matches     [list]
    set match_types [list]

    # Check to see if this is a calculation
    if {[regexp {[]0-9a-zA-Z',{}_ ()*/%&|^~:+<>-]+} $str]} {
      handle_calculation $str
    }
    
#    # Check to see if this is a URL
#    if {[regexp {(\S+\.[[:alpha:]][[:alpha:]]+)$} $str -> url]} {
#
#      set last_command_name [get_command_name $top launcher::url_okay $last_url]
#      set curr_command_name [get_command_name $top launcher::url_okay $url]
#      
#      # Change the command to the updated command
#      set value $commands($last_command_name)
#      array unset commands $last_command_name
#     set commands($curr_command_name) $value
#      set last_url $url
#
#      # Add this to the list of matches
#      lappend matches     $curr_command_name
#      lappend match_types 2
#
#    }

    # Get the precise match (if one exists)
    set results [list]
    foreach {name value} [array get commands [get_command_name * *]] {
      if {[lindex $value $command_values(search_str)] eq $str} {
        if {[eval [lindex $name $command_names(validate_cmd)]]} {
          lappend results [list $name $value]
        }
      }
    }

    # Sort the results by relevance
    sort_match_results $results 1

    # Get exact matches that match the beginning of the statement
    sort_match_results [get_match_results $str*] 0

    # Get all of the exact matches within the string
    sort_match_results [get_match_results *$str*] 0

    # Get all of the fuzzy matches
    sort_match_results [get_match_results *[join [split $str {}] *]*] 1

  }

  ############################################################################
  # Searches the list of commands that match the top widget and the given search
  # pattern.
  proc get_match_results {pattern} {

    variable commands
    variable command_names
    variable command_values
    variable matches

    set results [list]

    foreach {name value} [array get commands [get_command_name $pattern *]] {
      if {[lsearch $matches $name] == -1} {
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
  # to the matches and match_types lists.
  proc sort_match_results {results type} {

    variable command_values
    variable matches
    variable match_types

    # Sort the results by relevance
    foreach result [lsort -integer -index [list 1 $command_values(count)] -decreasing $results] {
      lappend matches     [lindex $result 0]
      lappend match_types $type
    }

  }

  ############################################################################
  # Executes the selected command, saving usage information.
  proc execute {lb} {

    variable matches
    variable match_types
    variable commands
    variable command_values
    variable widgets
    variable last_command
    variable closed

    # Get the current selection
    set row [$lb curselection]

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

    # Store the last command and type
    set last_command $command_name

    # Cause the window to close
    set closed 1

    # Execute the associated command
    after 1 [list launcher::execute_helper [lindex $commands($command_name)) $command_values(command)]]

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
    variable match_types
    variable commands
    variable last_calc

    set last_command_name [get_command_name $last_calc launcher::calc_okay]

    # Check to see if the string is a valid Tcl expression
    if {![catch "expr $str" rc]} {

      set curr_command_name [get_command_name $rc launcher::calc_okay]

      # Change the command to the updated command
      set value $commands($last_command_name)
      array unset commands $last_command_name
      set commands($curr_command_name) $value
      set last_calc $rc

      # Add this to the list of valid results
      lappend matches     $curr_command_name
      lappend match_types 2

    }

  }

  ############################################################################
  # Copies the current calculation to the clipboard.
  proc copy_calculation {} {

    variable last_calc
    variable last_command

    # Clear the clipboard and add the calculation
    clipboard clear
    clipboard append $last_calc

    # Clear the last command so that we don't have the calculated value stuck in memory
    set last_command ""

  }
  
  # Register the calculator
  register_temp "" launcher::copy_calculation launcher::calc_okay
   
}
