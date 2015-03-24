# Name:     diff.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     3/23/2015
# Brief:    Contains namespace which handles displaying file version differences

namespace eval diff {
  
  source [file join $::tke_dir lib ns.tcl]
    
  array set data {}
  
  ######################################################################
  # Creates the menubutton for the CVS in the diff bar.
  proc create_cvs_menubutton {txt win} {
    
    # Create menubutton
    ttk::menubutton $win -text "Select Version System" -menu $win.mnu -direction above
    
    # Create the menu
    menu $win.mnu -tearoff 0
    
    # Get the associated diff frame
    set df [winfo parent $win]
    
    # Create menu
    foreach cvs [list Perforce Mercurial Git Subversion CVS diff] {
      $win.mnu add radiobutton -label $cvs -variable [ns diff]::data($txt,cvs) -value $cvs -command [list [ns diff]::update_diff_frame $txt $df]
    }
    
    return $win
    
  }
  
  ######################################################################
  # Attempts to determine the default CVS that is used to manage the
  # current file.
  proc get_default_cvs {} {
    
    # Get the current filename
    set fname [current_filename]
    
    # Check each of the CVS
    foreach cvs [file Perforce Mercurial Git Subversion CVS] {
      if {[check_for_[string to lower $cvs] $fname]} {
        return $cvs
      }
    }
    
    return "diff"
    
  }
  
  ######################################################################
  # Check to see if the given filename is managed by Perforce.
  proc check_for_perforce {fname} {
    
    return [expr {![catch { exec p4 filelog $fname }]}]
    
  }
  
  ######################################################################
  # Check to see if the given filename is managed by Mercurial.
  proc check_for_mercurial {fname} {
    
    return [expr {![catch { exec hg status $fname }]}]
    
  }
  
  ######################################################################
  # Check to see if the given filename is managed by Git.
  proc check_for_git {fname} {
    
    # TBD
    
    return 0
    
  }
  
  ######################################################################
  # Check to see if the given filename is managed by Subversion.
  proc check_for_subversion {fname} {
    
    # TBD
    
    return 0
    
  }
  
  ######################################################################
  # Check to see if the given filename is managed by CVS.
  proc check_for_cvs {fname} {
    
    # TBD
    
    return 0
    
  }
  
  ######################################################################
  # Sets the cvs version value to diff and display the file difference
  # frame.
  proc update_diff_frame {txt df} {
    
    variable data
    
    if {$data($txt,cvs) eq "diff"} {
      
      grid remove $df.vf
      grid $df.ff
      focus $df.ff.e
      
    } else {
      
      grid remove $df.ff
      grid $df.vf
      focus $df.vf.v1
      
      # Get all of the versions available for the file
      get_versions $txt
      
      # Configure the menu buttons
      $df.vf.v1 configure -text [lindex $data($txt,versions) 1]
      $df.vf.v2 configure -text [lindex $data($txt,versions) 0]
      
    }
    
    # Set the menubutton name
    $df.mb configure -text $data($txt,cvs)
    
  }
  
  ######################################################################
  # Creates the menubutton for the version-1 selection in the diff bar.
  proc create_v1_menubutton {tid win} {
    
    # Create the menubutton
    ttk::menubutton $win -text "Start Version" -menu $win.mnu -direction above
    
    # Create the menu
    menu $win.mnu -tearoff 0 -postcommand [list [ns diff]::add_v1 $tid $win.mnu]
    
    return $win
    
  }
  
  ######################################################################
  # Creates the menubutton for the version-1 selection in the diff bar.
  proc create_v2_menubutton {tid win} {
    
    # Create the menubutton
    ttk::menubutton $win -text "End Version" -menu $win.mnu -direction above
    
    # Create the menu
    menu $win.mnu -tearoff 0 -postcommand [list [ns diff]::add_v2 $tid $win.mnu]
    
    return $win
    
  }
  
  ######################################################################
  # Get the available versions based on the currently selected CVS.
  proc get_versions {txt} {
    
    variable data
    
    # Clear the versions
    set data($txt,versions) "Current"
    
    # Get the versions
    get_[string tolower $data($txt,cvs)]_versions $txt [[ns gui]::current_filename]
    
    # Set the version 2 value to the current value
    set data($txt,v2) "Current"
    
    # Set the version 1 value to the second value
    set data($txt,v1) [lindex $data($txt,versions) 1]
    
  }
  
  ######################################################################
  # Retrieves all available versions of the current file in the Perforce
  # repository.
  proc get_perforce_versions {txt fname} {
    
    variable data
    
    if {![catch { exec p4 filelog $fname } rc]} {
      foreach line [split $rc \n] {
        if {[regexp {^\.\.\.\s+#(\d+)} $line -> version]} {
          lappend data($txt,versions) $version
        }
      }
    }
    
  }
  
  ######################################################################
  # Retrieves all available versions of the current file in the Mercurial
  # repository.
  proc get_mercurial_versions {txt fname} {
    
    variable data
    
    if {![catch { exec hg log $fname } rc]} {
      foreach line [split $rc \n] {
        if {[regexp {changeset:\s+(\d+):} $line -> version]} {
          lappend data($txt,versions) $version
        }
      }
    }
    
  }
  
  ######################################################################
  # Retrieves all available versions of the current file in the Git
  # repository.
  proc get_git_versions {txt fname} {

    variable data

    if {![catch { exec git log $fname } rc]} {
      foreach line [split $rc \n] {
        if {[regexp {commit\s+([0-9a-fA-F]+)} $line -> version]} {
          lappend data($txt,versions) $version
        }
      }
    }

  }

  ######################################################################
  # Adds the starting version menu items.
  proc add_v1 {tid mnu} {
    
    variable data
    
    # Get the current txt widget
    set txt [[ns gui]::current_txt $tid]
    
    # Get the menubutton from the menu
    set mb [winfo parent $mnu]
    
    # Clear the menu
    $mnu delete 0 end
    
    # Add the items to the menu
    foreach version $data($txt,versions) {
      if {$version ne "Current"} {
        $mnu add radiobutton -label $version -variable [ns diff]::data($txt,v1) -value $version -command [list [ns diff]::handle_v1 $tid $mb]
      }
    }
    
  }
  
  ######################################################################
  # If the version of the ending version is less than or equal to the new
  # starting version, adjust the ending version to be one version newer
  # than the starting version.
  proc handle_v1 {tid mb} {
    
    variable data
    
    # Get the current txt widget
    set txt [[ns gui]::current_txt $tid]
    
    # Adjust version 2, if necessary
    if {$data($txt,v1) >= $data($txt,v2)} {
      set index         [lsearch $data($txt,versions) $data($txt,v1)]
      set data($txt,v2) [lindex $data($txt,versions) [expr $index - 1]]
    }
    
    # Set the menubutton text
    $mb configure -text $data($txt,v1)
    
  }
  
  ######################################################################
  # Adds the ending version menu items.
  proc add_v2 {tid mnu} {
    
    variable data
    
    # Get the current txt widget
    set txt [[ns gui]::current_txt $tid]
    
    # Get the menubutton from the menu
    set mb [winfo parent $mnu]
    
    # Clear the menu
    $mnu delete 0 end
    
    # Add the items to the menu
    foreach version $data($txt,versions) {
      if {($version eq "current") || ($version > $data($txt,v1))} {
        $mnu add radiobutton -label $version -variable [ns diff]::data($txt,v2) -value $version -command [list [ns diff]::handle_v2 $tid $mb]
      }
    }
    
  }
  
  ######################################################################
  # Handles a change to the V2 widget.
  proc handle_v2 {tid mb} {
    
    variable data
    
    # Get the current text widget
    set txt [[ns gui]::current_txt $tid]
    
    # Get the current filename
    set fname [current_filename]
    
    # If the currently selected version is not current, get the file command
    if {$data($txt,v2) ne "Current"} {
      set fname [get_[string tolower $data($txt,cvs)]_file_cmd $txt $fname]
    }
      
    # Execute the file open and update the text widget
    if {![catch { open $fname r } rc]} {
      $txt configure -state normal
      $txt delete 1.0 end
      $txt insert end [read $rc]
      $txt configure -state disabled
    }
      
    # Set the menubutton text
    $mb configure -text $data($txt,v2)
    
  }
  
  ######################################################################
  # Returns the Perforce command to execute in an open command to retrieve the
  # file contents of the given file version.
  proc get_perforce_file_cmd {txt fname} {
    
    variable data
    
    return "|p4 print $fname#$data($txt,v2)"
    
  }
  
  ######################################################################
  # Returns the Mercurial command to execute in an open command to retrieve the
  # file contents of the given file version.
  proc get_mercurial_file_cmd {txt fname} {
    
    variable data
    
    return "|hg cat -r $data($txt,v2) $fname"
    
  }
  
  ######################################################################
  # Performs the difference command and displays it in the text widget.
  proc show_diff {tid} {
    
    variable data
    
    # Get the current text widget
    set txt [[ns gui]::current_txt $tid]
    
    # Get the current filename
    set fname [[ns gui]::current_filename]

    # If the CVS has not been set, attempt to figure it out
    if {![info exists data($txt,cvs)] || ($data($txt,cvs) eq "")} {
      set data($txt,cvs) [get_default_cvs]
    }
    
    # Displays the difference data
    show_[string tolower $data($txt,cvs)]_diff $txt $fname
    
  }
  
  ######################################################################
  # Display the perforce diff information in the viewer.
  proc show_perforce_diff {txt fname} {
    
    variable data
    
    # Parse and display the difference
    if {$data($txt,v2) eq "Current"} {
      set ::env(P4DIFF) ""
      parse_unified_diff $txt "p4 diff -du ${fname}#$data($txt,v1)"
    } else {
      parse_unified_diff $txt "p4 diff2 -u ${fname}#$data($txt,v1) ${fname}#$data($txt,v2)"
    }
      
  }
  
  ######################################################################
  # Display the Mercurial diff information in the viewer.
  proc show_mercurial_diff {txt fname} {
    
    variable data
    
    # Parse and display the difference
    if {$data($txt,v2) eq "Current"} {
      parse_unified_diff $txt "hg diff -r $data($txt,v1) $fname"
    } else {
      parse_unified_diff $txt "hg diff -r $data($txt,v1) -r $data($txt,v2) $fname"
    }
    
  }

  ######################################################################
  # Display the Git diff information in the viewer.
  proc show_git_diff {txt fname} {

    variable data

    # TBD

  }
  
  ######################################################################
  # Display the Subversion diff information in the viewer.
  proc show_subversion_diff {txt fname} {

    variable data

    # TBD

  }
  
  ######################################################################
  # Display the Subversion diff information in the viewer.
  proc show_cvs_diff {txt fname} {

    variable data

    # TBD

  }
  
  ######################################################################
  # Display the Subversion diff information in the viewer.
  proc show_diff_diff {txt fname} {

    variable data

    # TBD

  }
    
  ######################################################################
  # Executes the given diff command that produces diff output in unified
  # format.  Updates the specified text widget with the result.  The
  # command must be called only after the file is inserted into the editor.
  # Additionally, the file that is in the editor must be the same version
  # that is associated with the '+++' file in the diff output.
  proc parse_unified_diff {txt cmd} {

    # Execute the difference command
    if {[catch { exec -ignorestderr {*}$cmd } rc]} {
      return -code error "ERROR:  Diff command failed, $rc"
    }

    # Open the UI for editing
    $txt configure -state normal
    
    # Reset the diff output
    $txt diff reset

    # Initialize variables
    set adds       0
    set subs       0
    set strSub     ""
    set total_subs 0
     
    # Parse the output
    foreach line [split $rc \n] {
      if {[regexp {^@@\s+\-\d+,\d+\s+\+(\d+),\d+\s+@@$} $line -> tline]} {
        set adds   0
        set subs   0
        set strSub ""
        incr tline $total_subs
      } else {
        if {[regexp {^\+([^+]|$)} $line]} {
          if {$subs > 0} {
            $txt diff sub [expr $tline - $subs] $subs $strSub
            set subs   0
            set strSub ""
          }
          incr adds
        } elseif {[regexp {^\-([^-].*$|$)} $line -> str]} {
          if {$adds > 0} {
            $txt diff add [expr $tline - $adds] $adds
            set adds 0
          }
          append strSub "$str\n"
          incr subs
          incr total_subs
        } else {
          if {$adds > 0} {
            $txt diff add [expr $tline - $adds] $adds
            set adds 0
          } elseif {$subs > 0} {
            $txt diff sub [expr $tline - $subs] $subs $strSub
            set subs   0
            set strSub ""
          }
        }
        incr tline
      }
    }

    # Disable the text window from editing
    $txt configure -state disabled
    
  }
  
}
