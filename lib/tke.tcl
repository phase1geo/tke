#!wish8.5

# Name:    tke.tcl
# Author:  Trevor Williams (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Tcl/Tk editor written in Tcl/Tk
# Usage:   tke [<options>] <file>*

set tke_dir  [file dirname [file dirname [file normalize [info script]]]]
set tke_home [file normalize [file join ~ .tke]]

######################################################################
# Returns 1 if we are doing TKE development; otherwise, returns 0.
proc tke_development {} {
  
  return [info exists ::env(TKE_DEVEL)]
  
}

set auto_path [list [file join $tke_dir lib] {*}$auto_path]

package require Tclx
package require -exact ctext 5.0
package require -exact tablelist 5.13
package require tooltip
package require msgcat
package require tokenentry
package require wmarkentry
package require tabbar
package require specl
catch { package require tkdnd }

source [file join $tke_dir lib version.tcl]
source [file join $tke_dir lib utils.tcl]
source [file join $tke_dir lib preferences.tcl]
source [file join $tke_dir lib gui.tcl]
source [file join $tke_dir lib sidebar.tcl]
source [file join $tke_dir lib indent.tcl]
source [file join $tke_dir lib menus.tcl]
source [file join $tke_dir lib launcher.tcl]
source [file join $tke_dir lib plugins.tcl]
source [file join $tke_dir lib interpreter.tcl]
source [file join $tke_dir lib snippets.tcl]
source [file join $tke_dir lib completer.tcl]
source [file join $tke_dir lib bindings.tcl]
source [file join $tke_dir lib bgproc.tcl]
source [file join $tke_dir lib multicursor.tcl]
source [file join $tke_dir lib cliphist.tcl]
source [file join $tke_dir lib texttools.tcl]
source [file join $tke_dir lib vim.tcl]
source [file join $tke_dir lib syntax.tcl]
source [file join $tke_dir lib api.tcl]
source [file join $tke_dir lib markers.tcl]
source [file join $tke_dir lib tkedat.tcl]
source [file join $tke_dir lib themer.tcl]
source [file join $tke_dir lib themes.tcl]
source [file join $tke_dir lib favorites.tcl]
source [file join $tke_dir lib logger.tcl]
source [file join $tke_dir lib diff.tcl]

if {[tk windowingsystem] eq "aqua"} {
  source [file join $tke_dir lib windowlist.tcl]
}

# Load the message file that is needed
msgcat::mcload [file join $::tke_dir data msgs]

# Set the default right click button number
set right_click 3

######################################################################
# Display the usage information to standard output and exits.
proc usage {} {

  puts "tke \[<options>\] <file>*"
  puts ""
  puts "Options:"
  puts "  -h     Displays usage information"
  puts "  -v     Displays version"
  puts "  -nosb  Avoids populating the sidebar with the current"
  puts "           directory contents (only valid if no files are"
  puts "           specified)."
  puts "  -e     Exits the application when the last tab is closed"
  puts "           (overrides preference setting)"
  puts "  -m     Creates a minimal editing environment (overrides"
  puts "           preference settings)"
  puts "  -n     Opens a new window without attempting to merge"
  puts "           with an existing window"
  puts ""
  
  exit

}

######################################################################
# Displays version information to standard output and exits.
proc version {} {

  if {$::version_point == 0} {
    puts "$::version_major.$::version_minor ($::version_hgid)"
  } else {
    puts "$::version_major.$::version_minor.$::version_point ($::version_hgid)"
  }
  
  exit
  
}

######################################################################
# Parse the command-line options
proc parse_cmdline {argc argv} {

  set ::cl_files         [list]
  set ::cl_sidebar       1
  set ::cl_exit_on_close 0
  set ::cl_minimal       0
  set ::cl_new_win       0
  
  set i 0
  while {$i < $argc} {
    switch -- [lindex $argv $i] {
      -h    { usage }
      -v    { version }
      -nosb { set ::cl_sidebar 0 }
      -e    { set ::cl_exit_on_close 1 }
      -m    { set ::cl_minimal 1 }
      -n    { set ::cl_new_win 1 }
      default {
        if {[lindex $argv $i] ne ""} {
          lappend ::cl_files [file normalize [lindex $argv $i]]
        }
      }
    }
    incr i
  }
  
}

######################################################################
# Handles an interrupt or terminate signal
proc handle_signal {} {

  # Kill the GUI
  catch { destroy . }
  
  # Exit the logger
  logger::on_exit
  
  # Exit the application
  exit

}

# If we are using aqua, define a few tk::mac procedures that the application can use
if {[tk windowingsystem] eq "aqua"} {

  ######################################################################
  # Called whenever the user opens a document via drag-and-drop or within
  # the finder.
  proc ::tk::mac::OpenDocument {args} {

    # Add the files
    foreach name $args {
      if {[file isdirectory $name]} {
        sidebar::add_directory $name
      } else {
        switch -exact -- [string tolower [file extension $name]] {
          .tmtheme {
            set ans [tk_messageBox -default yes -icon question -message [msgcat::mc "Import TextMate theme?"] -parent . -type yesnocancel]
            if {$ans eq "yes"} {
              themer::import_tm $name
            } elseif {$ans eq "no"} {
              gui::add_file end $name
            } else {
              return
            }
          }
          .tketheme {
            set ans [tk_messageBox -default yes -icon question -message [msgcat::mc "Edit theme?"] -parent . -type yesnocancel]
            if {$ans eq "yes"} {
              themer::import_tke $name
            } elseif {$ans eq "no"} {
              gui::add_file end $name
            } else {
              return
            }
          }
          default {
            gui::add_file end $name
          }
        }
      }
    }

    # Make sure that the window is raised
    ::tk::mac::ReopenApplication
  
  }

  ######################################################################
  # Called when the application exits.
  proc ::tk::mac::Quit {} {

    menus::exit_command

  }
  
  # Change the right_click
  set ::right_click 2
  
  ######################################################################
  # Mapping the about window.
  proc tkAboutDialog {} {
    
    gui::show_about
    
  }

}

# Set signal handlers
signal trap TERM handle_signal
signal trap INT  handle_signal

if {[catch {
  
  # Set the application name to tke
  tk appname tke
   
  # Parse the command-line options
  parse_cmdline $argc $argv
   
  # Attempt to add files or raise the existing application
  if {([tk appname] ne "tke") && ([tk windowingsystem] eq "x11") && !$cl_new_win} {
    if {[llength $cl_files] > 0} {
      if {![catch { send tke gui::add_files_and_raise [info hostname] end $cl_files } rc]} {
        destroy .
        exit
      } elseif {[regexp {X server} $rc]} {
        puts $rc
      }
      # puts "rc: $rc"
    } else {
      if {![catch "send tke gui::raise_window" rc]} {
        destroy .
        exit
      } elseif {[regexp {X server} $rc]} {
        puts $rc
      }
    }
  }
    
  # Make ourselves a drop target (if Tkdnd is available)
  catch {
      
    tkdnd::drop_target register . DND_Files
      
    bind . <<DropEnter>>    ::handle_drop_enter
    bind . <<DropPosition>> ::handle_drop_position %X %Y
    bind . <<DropLeave>>    ::handle_drop_leave
    bind . <<Drop>>         ::handle_drop %D
      
    proc handle_drop_enter {} {
      return "link"
    }
      
    proc handle_drop_position {x y} {
      return "link"
    }
      
    proc handle_drop_leave {} {
    }
      
    proc handle_drop {files} {
      foreach fname $files {
        if {[file isdirectory $fname]} {
          sidebar::add_directory $fname
        } else {
          gui::add_file end $fname
        }
      }
      return "link"
    }
      
  }
   
  # Create the ~/.tke directory if it doesn't already exist
  if {![file exists $tke_home]} {
    file mkdir $tke_home
  }
   
  # Initialize the themes
  themes::initialize
   
  # Load the preferences
  preferences::load
    
  # Initialize the diagnostic logger
  logger::initialize
   
  # If we need to check for updates on start, do that now
  if {[preferences::get General/UpdateCheckOnStart]} {
    if {[preferences::get General/UpdateReleaseType] eq "devel"} {
      specl::check_for_update 1 [expr $specl::RTYPE_STABLE | $specl::RTYPE_DEVEL]
    } else {
      specl::check_for_update 1 $specl::RTYPE_STABLE
    }
  }
   
  # Load the plugins
  plugins::load
   
  # Load the snippets
  snippets::load
   
  # Load the clipboard history
  cliphist::load
   
  # Load the syntax highlighting information
  syntax::load
   
  # Load the favorites information
  favorites::load
   
  # Set the delay to 1 second
  tooltip::tooltip delay 1000
   
  # Create GUI
  gui::create
   
  # Update the UI
  themes::handle_theme_change
   
  # Run any plugins that are required at application start
  plugins::handle_on_start
   
  # Populate the GUI with the command-line filelist (if specified)
  if {[llength $cl_files] > 0} {
    foreach cl_file $cl_files {
      set name [file normalize $cl_file]
      if {[file isdirectory $name]} {
        sidebar::add_directory $name
      } else {
        gui::add_file end $name
      }
    }
  }
   
  # Load the session file
  gui::load_session {}
    
  # If the number of loaded files is still zero, add a new blank file
  if {[gui::get_file_num] == 0} {
    gui::add_new_file end
  }
   
  # This will hide hidden files/directories but provide a button in the dialog boxes to show/hide theme
  catch {
    catch { tk_getOpenFile foo bar }
    # set ::tk::dialog::file::showHiddenBtn 1
    set ::tk::dialog::file::showHiddenVar 0
  } 
  
} rc]} {
  bgerror $rc
}

