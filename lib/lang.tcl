######################################################################
# Name:    lang.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    10/11/2013
# Brief:   Creates new internationalization files and helps to maintain
#          them.
######################################################################

set tke_dir [file dirname [file dirname [file normalize $argv0]]]

lappend auto_path [file join $tke_dir lib]

package require -exact tablelist 5.9
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
      
      # Update the xlates array
      update_xlates
      
    }
    
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
      
      set last_src ""
      
      for {set i 0} {$i < [$widgets(tbl) size]} {incr i} {
        
        if {[set src [$widgets(tbl) cellcget $i,src -text]] ne $last_src} {
          if {$last_src ne ""} {
            puts $rc "\}\n"
          }
          puts $rc "# [file tail $src]"
          puts $rc "msgcat::mcmset $lang \{\n"
          set last_src $src
        }
        
        if {[set xlate [$widgets(tbl) cellcget $i,xlate -text]] ne ""} {
          puts $rc "  \"[$widgets(tbl) cellcget $i,str -text]\""
          puts $rc "  \"$xlate\"\n"
        }
        
      }
      
      puts $rc "\}\n"
      
      close $rc
      
    }
    
  }
  
  ######################################################################
  # Creates the UI.
  proc create_ui {} {
    
    variable widgets
    
    ttk::frame .tf
    set widgets(tbl) [tablelist::tablelist .tf.tl -columns {0 String 0 Translation 0 {}} \
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
    set widgets(xlate) [ttk::button .bf.xlate -text "Add Translations"]
    ttk::button .bf.upd    -text "Update" -width 6 -command "set ::update_lang 1; set ::update_done 1"
    ttk::button .bf.cancel -text "Cancel" -width 6 -command "set ::update_done 1"
    
    pack .bf.xlate  -side left  -padx 2 -pady 2
    pack .bf.cancel -side right -padx 2 -pady 2
    pack .bf.upd    -side right -padx 2 -pady 2
    
    pack .tf -fill both -expand yes
    pack .bf -fill x
    
  }
  
  ######################################################################
  # Updates the user interface with the given language information.
  proc populate_ui {lang} {
    
    variable widgets
    variable xlates
    
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
    
    # Wait for the user to Update or Cancel the window
    vwait ::update_done
    
    # If we need to write the language file, do so now
    if {$::update_lang} {
      write_lang $lang
    }
    
  }
  
  ######################################################################
  # Translate any items that are empty.
  proc perform_translations {lang} {
    
    variable widgets
    
    for {set i 0} {$i < [$widgets(tbl) size]} {incr i} {
      
      if {[$widgets(tbl) cellcget $i,xlate -text] eq ""} {
        
        # Prepare the search string for URL usage
        set str [http::formatQuery q [$widgets(tbl) cellcget $i,str -text]]
        set str "http://mymemory.translated.net/api/get?$str&langpair=en|$lang"
        
        # Perform http request
        set token [http::geturl $str -strict 0]
        
        # Get the data returned from the request
        if {[http::status $token] eq "ok"} {
          set data [http::data $token]
          if {[regexp {translatedText\":\"([^\"]+)\"} $data -> ttext]} {
            $widgets(tbl) cellconfigure $i,xlate -text $ttext
          }
        }
        
        # Cleanup request
        http::cleanup $token
        
      }
 
    }
    
    
  }
  
  ######################################################################
  # Updates all of the specified language files.
  proc update_langs {langs} {
    
    variable xlates
    
    # Read the current msgcat information from the source files
    gather_msgcat
    
    # For each language, perform the update
    foreach lang $langs {
      
      # Read in the language, if it exists
      fetch_lang $lang
      
      # Update the UI with the current language information
      populate_ui $lang
      
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
  puts "  -h    Displays this help information and exits"
  puts ""
  
  exit
  
}
 
# Parse the command-line arguments
set i     0
set langs [list]
while {$i < $argc} {
  switch -exact -- [lindex $argv $i] {
    -h      { usage }
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
lang::update_langs $langs
