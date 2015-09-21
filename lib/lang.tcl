# TKE - Advanced Programmer's Editor
# Copyright (C) 2014  Trevor Williams (phase1geo@gmail.com)
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
# Name:    lang.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    10/11/2013
# Brief:   Creates new internationalization files and helps to maintain
#          them.
######################################################################

set tke_dir [file dirname [file dirname [file normalize $argv0]]]

lappend auto_path [file join $tke_dir lib]

package require -exact tablelist 5.14
package require http
 
array set tablelistopts {
  selectbackground   RoyalBlue1
  selectforeground   white
  stretch            all
  stripebackground   #EDF3FE
  relief             flat
  border             0
  showseparators     yes
  takefocus          1
  setfocus           1
  activestyle        none
}

namespace eval lang {
  
  variable hide_xlates 0
  
  array set phrases {}
  array set xlates  {}
  array set widgets {}
  
  ######################################################################
  # Gets all of the msgcat::mc procedure calls for all of the library
  # files.
  proc gather_msgcat {} {
    
    variable phrases
    
    foreach src [glob -directory [file join $::tke_dir lib] *.tcl] {
      
      if {![catch "open $src r" rc]} {
        
        # Read the contents of the file and close the file
        set contents [read $rc]
        close $rc
        
        # Store all of the found msgcat::mc calls in the phrases array
        set start 0
        while {[regexp -indices -start $start {\[msgcat::mc\s+\"([^\"]+)\"} $contents -> phrase_index]} {
          set phrase [string range $contents {*}$phrase_index]
          if {[info exists phrases($phrase)]} {
            if {[lindex $phrases($phrase) 0] ne $src} {
              set phrases($phrase) [list General [expr [lindex $phrases($phrase) 1] + 1]]
            } else {
              set phrases($phrase) [list $src [expr [lindex $phrases($phrase) 1] + 1]]
            }
          } else {
            set phrases($phrase) [list $src 1]
          }
          set start [lindex $phrase_index 1]
        }
        
      }
      
    }
    
  }
  
  ######################################################################
  # Reads the contents of the specified language file
  proc fetch_lang {lang} {
    
    variable xlates
    
    # Clear the xlates array
    array unset xlates
    
    if {![catch "open [file join $::tke_dir data msgs $lang.msg] r" rc]} {
      
      # Read the file contents and close the file
      set contents [read $rc]
      close $rc
      
      # Parse the file
      foreach line [split $contents \n] {
        set line [string trim $line]
        if {[string index $line 0] eq "#"} {
          set fname [string trim [string range $line 1 end]]
        } elseif {[regexp {msgcat::mcmset} $line]} {
          set mcmset 1
          set xlate  [list]
        } elseif {$mcmset} {
          if {[string index $line 0] eq "\}"} {
            foreach {me other} $xlate {
              set xlates($me) [list $fname $other]
            }
            set mcmset 0
          } elseif {$line ne ""} {
            lappend xlate [string range $line 1 end-1]
          }
        }
      }
      
    }
    
    # Update the xlates array
    update_xlates

  }
    
  ######################################################################
  # Compares the source msgcat strings with the strings in the xlates
  # array.  At the end of the comparison, the xlates array will be
  # populated with the proper information.
  proc update_xlates {} {
      
    variable phrases
    variable xlates
    
    array set others [array get xlates]
    array unset xlates
    
    foreach str [array names phrases] {
      if {[info exists others($str)]} {
        set xlates($str) [list [lindex $phrases($str) 0] [lindex $others($str) 1]]
      } else {
        set xlates($str) [list [lindex $phrases($str) 0] ""]
      }
    }
      
  }
  
  ######################################################################
  # Write the translation information to the file based on the table
  # contents.
  proc write_lang {lang} {
    
    variable widgets
    
    if {![catch "open [file join $::tke_dir data msgs $lang.msg] w" rc]} {
      
      # Organize the strings by file
      for {set i 0} {$i < [$widgets(tbl) size]} {incr i} {
        if {[set xlate [$widgets(tbl) cellcget $i,xlate -text]] ne ""} {
          lappend srcs([$widgets(tbl) cellcget $i,src -text]) [list [$widgets(tbl) cellcget $i,str -text] $xlate]
        }
      }
      
      # Output to the file by source file
      foreach src [lsort [array names srcs]] {
        
        puts $rc "# [file tail $src]"
        puts $rc "msgcat::mcmset $lang \{\n"
        
        foreach xlate $srcs($src) {
          puts $rc "  \"[lindex $xlate 0]\""
          puts $rc "  \"[lindex $xlate 1]\"\n"
        }
        
        puts $rc "\}\n"
        
      }
      
      close $rc
      
    }
    
  }
  
  ######################################################################
  # Creates the UI.
  proc create_ui {} {
    
    variable widgets
    
    wm geometry . 800x600
    
    # Force the window to exit if the close button is clicked
    wm protocol . WM_DELETE_WINDOW {
      exit
    }
    
    ttk::frame .tf
    set widgets(tbl) [tablelist::tablelist .tf.tl -columns {0 String 0 Translation 0 {}} \
      -editselectedonly 1 -selectmode extended -exportselection 0 \
      -editendcommand "lang::edit_end_command" \
      -yscrollcommand ".tf.vb set"]
    ttk::scrollbar .tf.vb -orient vertical -command ".tf.tl yview"
    
    foreach {key value} [array get ::tablelistopts] {
      .tf.tl configure -$key $value
    }
    
    .tf.tl columnconfigure 0 -name str   -editable 0
    .tf.tl columnconfigure 1 -name xlate -editable 1
    .tf.tl columnconfigure 2 -name src   -editable 0 -hide 1
    
    grid rowconfigure    .tf 0 -weight 1
    grid columnconfigure .tf 0 -weight 1
    grid .tf.tl -row 0 -column 0 -sticky news
    grid .tf.vb -row 0 -column 1 -sticky ns
    
    ttk::frame .bf
    set widgets(xlate) [ttk::button      .bf.xlate -text "Add Translations"]
    set widgets(hide)  [ttk::checkbutton .bf.hide  -text "Hide translated" -variable lang::hide_xlates \
      -command "lang::show_hide_xlates"]
    set widgets(update) [ttk::button .bf.upd -text "Update" -width 6 -command "set ::update_lang 1; set ::update_done 1"]
    ttk::button .bf.cancel -text "Cancel" -width 6 -command "set ::update_done 1"
    
    pack .bf.xlate  -side left  -padx 2 -pady 2
    pack .bf.hide   -side left  -padx 2 -pady 2
    pack .bf.cancel -side right -padx 2 -pady 2
    pack .bf.upd    -side right -padx 2 -pady 2
    
    pack .tf -fill both -expand yes
    pack .bf -fill x
    
  }
  
  ######################################################################
  # Handles the end of a manual edit of a cell.
  proc edit_end_command {tbl row col value} {
    
    # Handle the show/hide status of the row
    if {$value ne ""} {
      after idle [list lang::show_hide_xlate $row]
    }
    
    return $value
    
  }
  
  ######################################################################
  # Updates the user interface with the given language information.
  proc populate_ui {auto lang} {
    
    variable widgets
    variable xlates
    
    wm title . "Translations for $lang"
    
    # Clear the table
    $widgets(tbl) delete 0 end
    
    # Populate the table
    set xlate_list [list]
    foreach xlate [lsort [array names xlates]] {
      lappend xlate_list [list $xlate [lindex $xlates($xlate) 1] [lindex $xlates($xlate) 0]]
    }
    $widgets(tbl) insertlist end $xlate_list
    
    # Ready the UI for translation
    set ::update_lang 0
    set ::update_done 0
    
    # Setup the translations button
    $widgets(xlate) configure -command "lang::perform_translations $lang"
    
    if {$auto} {
      
      # Specify that we want to hide the translated rows
      set lang::hide_xlates 1
      
      # Only show the lines that need to be translated
      lang::show_hide_xlates
      
      # Perform the translation
      lang::perform_translations $lang
      
      # Specify that the language was updated (if we were not cancellled)
      if {!$::update_done} {
        set ::update_lang 1
      }
      
    } else {
    
      # Wait for the user to Update or Cancel the window
      vwait ::update_done
       
      # Make sure any edited cells are in the not edit mode
      $widgets(tbl) finishediting
      
    }
    
    # If we need to write the language file, do so now
    if {$::update_lang} {
      write_lang $lang
    }
    
    return $::update_lang
    
  }
  
  ######################################################################
  # Toggles the show/hide translated status of the given row.
  proc show_hide_xlate {row} {
    
    variable widgets
    variable hide_xlates
    
    if {[$widgets(tbl) cellcget $row,xlate -text] ne ""} {
      $widgets(tbl) rowconfigure $row -hide $hide_xlates
      $widgets(tbl) selection clear $row
    }
    
  }
  
  ######################################################################
  # Toggles the show/hide translated items in the table.
  proc show_hide_xlates {} {
    
    variable widgets
    variable hide_xlates
    
    for {set i 0} {$i < [$widgets(tbl) size]} {incr i} {
      show_hide_xlate $i
    }
    
  }
  
  ######################################################################
  # Translates the item at the given row.  Throws an exception if there
  # was an error with the translation.
  proc perform_translation {row lang} {
    
    variable widgets
    
    # Prepare the search string for URL usage
    set str [http::formatQuery q [$widgets(tbl) cellcget $row,str -text]]
    set str "http://mymemory.translated.net/api/get?$str&langpair=en|$lang&de=phase1geo@gmail.com"
        
    # Perform http request
    set token [http::geturl $str -strict 0]
      
    # Get the data returned from the request
    if {[http::status $token] eq "ok"} {
      set data [http::data $token]
      if {[regexp {translatedText\":\"([^\"]+)\"} $data -> ttext]} {
        if {[string compare -length 17 "MYMEMORY WARNING:" $ttext] == 0} {
          return -code error "Row: $row, $ttext"
        }
        $widgets(tbl) cellconfigure $row,xlate -text [subst [string map {{[} {\[} {]} {\]}} $ttext]]
        $widgets(tbl) see $row
        show_hide_xlate $row
      }
    }
        
    # Cleanup request
    http::cleanup $token
    
  }
  
  ######################################################################
  # Translate any items that are empty.
  proc perform_translations {lang} {
    
    variable widgets
    
    # Disable the "Add Translations" button from being clicked again
    $widgets(xlate)  configure -state disabled
    $widgets(update) configure -state disabled
    
    # Get any selected rows
    set selected [$widgets(tbl) curselection]
    
    if {[catch {
        if {[llength $selected] > 0} {
          foreach row $selected {
            perform_translation $row $lang
          }
        } else {
          for {set i 0} {$i < [$widgets(tbl) size]} {incr i} {
            if {[$widgets(tbl) cellcget $i,xlate -text] eq ""} {
              perform_translation $i $lang
            }
          }
        }
      } rc]} {
      tk_messageBox -parent . -default ok -message "Translation error" -detail $rc -type ok
    }
    
    # Enable the 'Add Translations' button
    $widgets(xlate)  configure -state normal
    $widgets(update) configure -state normal
    
  }
  
  ######################################################################
  # Updates all of the specified language files.
  proc update_langs {auto langs} {
    
    variable xlates
    
    # Read the current msgcat information from the source files
    gather_msgcat
    
    # For each language, perform the update
    foreach lang $langs {
      
      # Read in the language, if it exists
      fetch_lang $lang
      
      # Update the UI with the current language information
      if {[populate_ui $auto $lang] == 0} {
        break
      }
      
    }
    
    # When we are done, exit
    exit
    
  }
  
}
 
######################################################################
# Displays usage information and exits.
proc usage {} {
  
  puts "Usage:  wish8.5 lang.tcl (-h | <lang>+)"
  puts ""
  puts "Options:"
  puts "  -h     Displays this help information and exits"
  puts "  -auto  Automatically starts the translations, updates and quits"
  puts ""
  
  exit
  
}
 
# Parse the command-line arguments
set i           0
set langs       [list]
set auto_update 0
while {$i < $argc} {
  switch -exact -- [lindex $argv $i] {
    -h      { usage }
    -auto   { set auto_update 1 }
    default { lappend langs [lindex $argv $i] }
  }
  incr i
}
 
if {[llength $langs] == 0} {
  usage
}

# Use the clam theme
ttk::style theme use clam
 
# Create the UI
lang::create_ui

# Gather all of the msgcat::mc calls in the library source files
lang::update_langs $auto_update $langs

