# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2017  Trevor Williams (phase1geo@gmail.com)
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
# Name:     diff.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     3/23/2015
# Brief:    Contains namespace which handles displaying file version differences
######################################################################

# msgcat::note Go to File menu and select "Show File Differences".  Strings are shown at bottom of editor.

namespace eval diff {

  array set data {}

  # Check to see if the ttk::spinbox command exists
  if {[catch { ttk::spinbox .__tmp }]} {
    set bg            [utils::get_default_background]
    set fg            [utils::get_default_foreground]
    set data(sb)      "spinbox"
    set data(sb_opts) "-relief flat -buttondownrelief flat -buttonuprelief flat -background $bg -foreground $fg"
  } else {
    set data(sb)      "ttk::spinbox"
    set data(sb_opts) "-justify center"
    destroy .__tmp
  }

  proc create_diff_bar {txt win} {

    variable data

    # Initialize values
    set data($txt,win)     $win
    set data($txt,v1)      ""
    set data($txt,v2)      ""
    set data($txt,last_v1) ""
    set data($txt,last_v2) ""

    ttk::frame      $win
    ttk::menubutton $win.cvs  -menu $win.cvsMenu -direction above
    ttk::button     $win.show -text [msgcat::mc "Update"] -command "diff::show $txt"
    message         $txt.log

    # Create the version frame
    ttk::frame $win.vf
    ttk::label $win.vf.l1 -text [msgcat::mc "    Start: "]
    $data(sb)  $win.vf.v1 {*}$data(sb_opts) -textvariable diff::data($txt,v1) -width 10 -state readonly -command "diff::handle_v1 $txt"
    ttk::label $win.vf.l2 -text [msgcat::mc "    End: "]
    $data(sb)  $win.vf.v2 {*}$data(sb_opts) -textvariable diff::data($txt,v2) -width 10 -state readonly -command "diff::handle_v2 $txt"

    bind $win.vf.v1 <FocusIn>  [list diff::show_hide_version_log $txt v1 on]
    bind $win.vf.v1 <FocusOut> [list diff::show_hide_version_log $txt v1 off]
    bind $win.vf.v2 <FocusIn>  [list diff::show_hide_version_log $txt v2 on]
    bind $win.vf.v2 <FocusOut> [list diff::show_hide_version_log $txt v2 off]

    grid rowconfigure    $win.vf 0 -weight 1
    grid columnconfigure $win.vf 2 -weight 1
    grid $win.vf.l1 -row 0 -column 0 -sticky ew -padx 2
    grid $win.vf.v1 -row 0 -column 1 -sticky ew -padx 2
    grid $win.vf.l2 -row 0 -column 2 -sticky ew -padx 2
    grid $win.vf.v2 -row 0 -column 3 -sticky ew -padx 2

    # Create the file frame
    ttk::frame             $win.ff
    wmarkentry::wmarkentry $win.ff.e -watermark [msgcat::mc "Enter starting file"] \
      -validate key -validatecommand [list diff::handle_file_entry $win %P]

    bind [$win.ff.e entrytag] <Return> [list diff::show $txt]

    grid rowconfigure    $win.ff 0 -weight 1
    grid columnconfigure $win.ff 0 -weight 1
    grid $win.ff.e -row 0 -column 0 -sticky ew -padx 2

    # Create the command frame
    ttk::frame $win.cf
    wmarkentry::wmarkentry $win.cf.e -watermark [msgcat::mc "Enter difference command"]

    bind [$win.cf.e entrytag] <Return> [list diff::show $txt]

    grid rowconfigure    $win.cf 0 -weight 1
    grid columnconfigure $win.cf 0 -weight 1
    grid $win.cf.e -row 0 -column 0 -sticky ew -padx 2

    grid rowconfigure    $win 0 -weight 1
    grid columnconfigure $win 2 -weight 1
    grid $win
    grid $win.cvs  -row 0 -column 0 -sticky ew -padx 2 -pady 2
    grid $win.vf   -row 0 -column 1 -sticky ew         -pady 2
    grid $win.ff   -row 0 -column 2 -sticky ew         -pady 2
    grid $win.cf   -row 0 -column 3 -sticky ew         -pady 2
    grid $win.show -row 0 -column 4 -sticky ew -padx 2 -pady 2

    # Hide the version frame, file frame and update button until they are valid
    grid remove $win.vf
    grid remove $win.ff
    grid remove $win.cf
    grid remove $win.show

    # When text widget is destroyed delete our data
    bind $win <Configure> "diff::configure $txt"
    bind $win <Destroy>   "diff::destroy $txt"

    # Create the CVS menu
    menu $win.cvsMenu -tearoff 0

    # Populate the CVS menu
    set first 1
    foreach type [list cvs file command] {
      if {!$first} {
        $win.cvsMenu add separator
      }
      foreach name [get_cvs_names $type] {
        $win.cvsMenu add radiobutton -label $name -variable diff::data($txt,cvs) -value $name -command "diff::update_diff_frame $txt"
      }
      set first 0
    }

    return $win

  }

  ######################################################################
  # Handles any changes to the file entry window.
  proc handle_file_entry {win value} {

    if {[file exists $value] && [file isfile $value]} {
      grid $win.show
    } else {
      grid remove $win.show
    }

    return 1

  }

  ######################################################################
  # Handles changes to the windowing theme.
  proc handle_theme_change {sb_opts} {

    variable data

    # Get the default background and foreground colors
    set bg  [utils::get_default_background]
    set fg  [utils::get_default_foreground]

    # Update the spinboxes (if we are not using ttk::spinbox)
    if {$data(sb) eq "spinbox"} {
      foreach win [array names data *,win] {
        $win.vf.v1 configure -background $bg -foreground $fg
      }
    }

  }

  ######################################################################
  # Handles a configure window call to the difference widget.
  proc configure {txt} {

    variable data

    # Remove the log window
    place forget $txt.log
    set data($txt,logmode) 0

  }

  ######################################################################
  # Deletes all data associated with the given text widget.
  proc destroy {txt} {

    variable data

    array unset data $txt,*

  }

  ######################################################################
  # Performs the difference command and displays it in the text widget.
  proc show {txt {force_update 0}} {

    variable data

    # Get the current working directory
    set cwd [pwd]

    # Get the filename
    gui::get_info $txt txt fname

    # Set the current working directory to the directory of the file
    cd [file dirname $fname]

    # Set fname to the tail of fname
    set fname [file tail $fname]

    # If the CVS has not been set, attempt to figure it out
    if {![info exists data($txt,cvs)] || ($data($txt,cvs) eq "")} {
      set_default_cvs $txt
    }

    # Get the CVS namespace name
    set cvs_ns [string tolower $data($txt,cvs)]

    # If the V2 file changed, replace the file with the new content
    if {($data($txt,v2) ne $data($txt,last_v2)) || $force_update} {

      set v2_fname $fname

      # If the currently selected version is not current, get the file command
      if {$data($txt,v2) ne "Current"} {
        set v2_fname [${cvs_ns}::get_file_cmd $data($txt,v2) $fname]
      }

      # Execute the file open and update the text widget
      if {![catch { open $v2_fname r } rc]} {
        $txt configure -state normal
        $txt delete 1.0 end
        $txt insert end [read $rc]
        $txt configure -state disabled
      }

      # Save the last V2
      set data($txt,last_v2) $data($txt,v2)

    }

    # Displays the difference data
    switch [${cvs_ns}::type] {
      cvs     { parse_unified_diff $txt [${cvs_ns}::get_diff_cmd $data($txt,v1) $data($txt,v2) $fname] }
      file    { parse_unified_diff $txt [${cvs_ns}::get_diff_cmd [$data($txt,win).ff.e get] $fname] }
      command { parse_unified_diff $txt [$data($txt,win).cf.e get] }
    }

    # Save the value of V1 to last V1
    set data($txt,last_v1) $data($txt,v1)

    # Hide the update button
    grid remove $data($txt,win).show

    # Reset the current working directory
    cd $cwd

  }

  ######################################################################
  # Returns true if the specified text widget is eligible for a file
  # update via the gui::update_file command.
  proc updateable {txt} {

    variable data

    return [expr {$data($txt,v2) eq "Current"}]

  }

  ######################################################################
  # Sets the V1 widget to the version found for the current difference view line.
  proc find_current_version {txt fname lnum} {

    variable data

    # Get the CVS namespace name
    set cvs_ns [string tolower $data($txt,cvs)]

    if {[${cvs_ns}::type] eq "cvs"} {

      if {[set v2 [${cvs_ns}::find_version $fname $data($txt,v2) [$txt diff line [lindex [split [$txt index sel.first] .] 0] add]]] ne ""} {

        # Set version 2 to the found value
        set data($txt,v2) $v2

        # Set version 1 to the previous value
        set data($txt,v1) [lindex $data($txt,versions) [expr [lsearch $data($txt,versions) $v2] + 1]]

        # Show the file
        show $txt

      }

    }

  }

  ######################################################################
  # Returns a list containing information to store to the session file
  # for the given text widget.
  proc get_session_data {txt} {

    variable data

    return [list $data($txt,cvs) $data($txt,last_v1) $data($txt,last_v2)]

  }

  ######################################################################
  # Loads the given data list from the session file.
  proc set_session_data {txt data_list} {

    variable data

    # Extract the contents of the data_list
    lassign $data_list data($txt,cvs) v1 v2

    # If last_v1 is non-empty, the user performed an update in the last session;
    # otherwise, there is nothing left to do.
    if {$v1 ne ""} {

      # Display the original changes
      update_diff_frame $txt

      # Set v1 and v2
      set data($txt,v1) $v1
      set data($txt,v2) $v2

    }

  }

  ######################################################################
  # PRIVATE PROCEDURES
  ######################################################################

  ######################################################################
  # Gets a sorted list of all available CVS names.
  proc get_cvs_names {type} {

    set names [list]

    foreach name [namespace children] {
      if {([${name}::type] eq $type) && ([${name}::name] ne "CVS")} {
        lappend names [${name}::name]
      }
    }

    return [lsort $names]

  }

  ######################################################################
  # Returns the versioning system that handles the given filename.
  proc get_default_cvs {fname} {

    foreach cvs [get_cvs_names cvs] {
      if {[[string tolower $cvs]::handles $fname]} {
        return [string tolower $cvs]
      }
    }

    return "diff"

  }

  ######################################################################
  # Attempts to determine the default CVS that is used to manage the
  # file associated with the text widget and updates the UI elements to match.
  proc set_default_cvs {txt} {

    variable data

    # Get the filename
    set fname [file tail [gui::get_info $txt txt fname]]

    set data($txt,cvs) [get_default_cvs $fname]
    set data($txt,v2)  "Current"

    # Update the UI to match the selected CVS
    update_diff_frame $txt

  }

  ######################################################################
  # Called whenever the CVS value is changed.
  proc update_diff_frame {txt} {

    variable data

    set win $data($txt,win)

    switch [[string tolower $data($txt,cvs)]::type] {

      cvs {

        # Remove the file and command frames from view
        grid remove $win.ff
        grid remove $win.cf

        # Get all of the versions available for the file
        get_versions $txt

        if {[llength $data($txt,versions)] > 1} {

          # Show the version frame and update button
          grid $win.vf
          grid $win.show

          # Configure the spinboxes buttons
          $win.vf.v1 configure -values [lreverse [lrange $data($txt,versions) 1 end]]
          $win.vf.v2 configure -values [lreverse [lrange $data($txt,versions) 0 end-1]]

        } else {

          grid remove $win.vf
          grid remove $win.show

        }

      }

      file {

        # Remove the version and command frames
        grid columnconfigure $win 4 -weight 0
        grid remove $win.vf
        grid remove $win.cf
        grid remove $win.show

        # Display the file frame and update button
        grid columnconfigure $win 3 -weight 1
        grid $win.ff

        # Clear the filename
        $win.ff.e delete 0 end

        # Set keyboard focus to the entry widget
        focus $win.ff.e

      }

      command {

        # Remove the version and file frames
        grid columnconfigure $win 3 -weight 0
        grid remove $win.vf
        grid remove $win.ff

        # Display the command frame and update button
        grid columnconfigure $win 4 -weight 1
        grid $win.cf
        grid $win.show

        # Set keyboard focus to the entry widget
        focus $win.cf.e.e

      }

    }

    # Set the menubutton name
    $win.cvs configure -text $data($txt,cvs)

  }

  ######################################################################
  # Get the available versions based on the currently selected CVS.
  proc get_versions {txt} {

    variable data

    # Get the versions
    set data($txt,versions) [list "Current" {*}[[string tolower $data($txt,cvs)]::versions [gui::get_info $txt txt fname]]]

    # Set the version 2 value to the current value
    set data($txt,v2) "Current"

    # Set the version 1 value to the second value
    set data($txt,v1) [lindex $data($txt,versions) 1]

  }

  ######################################################################
  # If the version of the ending version is less than or equal to the new
  # starting version, adjust the ending version to be one version newer
  # than the starting version.
  proc handle_v1 {txt} {

    variable data

    # Find the current V1 version in the versions list
    set index [lsearch $data($txt,versions) $data($txt,v1)]

    # Adjust version 2, if necessary
    if {$data($txt,v1) >= $data($txt,v2)} {
      set data($txt,v2) [lindex $data($txt,versions) [expr $index - 1]]
    }

    # Make sure the update button is visible
    grid $data($txt,win).show

    # Update the version log information
    show_hide_version_log $txt v1 on

  }

  ######################################################################
  # Handles a change to the V2 widget.
  proc handle_v2 {txt} {

    variable data

    # Find the current V2 version in the versions list
    set index [lsearch $data($txt,versions) $data($txt,v2)]

    # Adjust version 1, if necessary
    if {$data($txt,v1) >= $data($txt,v2)} {
      set data($txt,v1) [lindex $data($txt,versions) [expr $index + 1]]
    }

    # Make sure the update button is visible
    grid $data($txt,win).show

    # Update the version log information
    show_hide_version_log $txt v2 on

  }

  ######################################################################
  # Shows/hides the file version information in a tooltip just above the
  # associated version widget.
  proc show_hide_version_log {txt widget mode} {

    variable data

    if {[preferences::get View/ShowDifferenceVersionInfo] &&
        (![info exists data($txt,logmode)] || \
         (!$data($txt,logmode) && ($mode eq "toggle")) || \
         ($mode eq "on") || \
         ($data($txt,logmode) && ($mode eq "update")))} {

      # Get the filename
      gui::get_info $txt txt fname

      # Get the current working directory
      set cwd [pwd]

      # Set the current working directory to the dirname of fname
      cd [file dirname $fname]

      # Get the version information
      if {[set log [[string tolower $data($txt,cvs)]::get_version_log [file tail $fname] $data($txt,$widget)]] ne ""} {

        # Create the message widget
        $txt.log configure -text $log -width [expr [winfo width $txt] - 10]

        # Place the message widget
        place $txt.log -in $txt -x 10 -y [expr [winfo height $txt] - ([winfo reqheight $txt.log] + 10)]

        set data($txt,logmode) 1

        # Return the working directory to the previous directory
        cd $cwd

        return

      }

      # Return the working directory to the previous directory
      cd $cwd

    }

    # Destroy the message widget
    place forget $txt.log

    set data($txt,logmode) 0

  }

  ######################################################################
  # Executes the given diff command that produces diff output in unified
  # format.  Updates the specified text widget with the result.  The
  # command must be called only after the file is inserted into the editor.
  # Additionally, the file that is in the editor must be the same version
  # that is associated with the '+++' file in the diff output.
  proc parse_unified_diff {txt cmd} {

    # Execute the difference command
    catch { exec -ignorestderr {*}$cmd } rc

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

    # If we have any adds or subs left over to process, process them now
    if {$adds > 0} {
      $txt diff add [expr $tline - $adds] $adds
    } elseif {$subs > 0} {
      $txt diff sub [expr $tline - $subs] $subs $strSub
    }

    # Disable the text window from editing
    $txt configure -state disabled

    # Update the scrollers
    gui::get_info $txt txt tab
    gui::update_tab_markers $tab

  }

  ######################################################################
  # Returns the difference mark information as required by the scroller
  # widget.
  proc get_marks {txt} {

    # Get the total number of lines in the text widget
    set lines [$txt count -lines 1.0 end]

    # Add the difference marks
    set marks [list]
    foreach type [list sub add] {
      set color [theme::get_value syntax difference_$type]
      foreach {start end} [$txt diff ranges $type] {
        set start_line [lindex [split $start .] 0]
        set end_line   [lindex [split $end .] 0]
        lappend marks [expr $start_line.0 / $lines] [expr $end_line.0 / $lines] $color
      }
    }

    return $marks

  }

  ######################################################################
  # CVS TOOL NAMESPACES
  ######################################################################

  ######################################################################
  # Handles Perforce commands
  namespace eval perforce {

    proc name {} {
      return "Perforce"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec p4 filelog $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      if {![catch { exec p4 filelog $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^\.\.\.\s+#(\d+)} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|p4 print $fname#$version"
    }

    proc get_diff_cmd {v1 v2 fname} {
      if {$v2 eq "Current"} {
        set ::env(P4DIFF) ""
        return "p4 diff -du ${fname}#$v1"
      } else {
        return "p4 diff2 -u ${fname}#$v1 ${fname}#$v2"
      }
    }

    proc get_current_version {fname} {
      if {![catch { exec p4 have $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^\.\.\.\s+#(\d+)} $line -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc find_version {fname v2 lnum} {
      if {$v2 eq "Current"} {
        if {![catch { exec p4 annotate $fname } rc]} {
          if {[regexp {^(\d+):} [lindex [split $rc \n] $lnum] -> version]} {
            return $version
          }
        }
      } else {
        if {![catch { exec p4 annotate ${fname}#$v2 } rc]} {
          if {[regexp {^(\d+):} [lindex [split $rc \n] $lnum] -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc get_version_log {fname version} {
      if {![catch { exec p4 filelog -l -m 1 $fname#$version } rc]} {
        return $rc
      }
      return ""
    }

  }

  ######################################################################
  # Handles Mercurial commands
  namespace eval mercurial {

    proc name {} {
      return "Mercurial"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec hg status $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      if {![catch { exec hg log $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {changeset:\s+(\d+):} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|hg cat -r $version $fname"
    }

    proc get_diff_cmd {v1 v2 fname} {
      if {$v2 eq "Current"} {
        return "hg diff -r $v1 $fname"
      } else {
        return "hg diff -r $v1 -r $v2 $fname"
      }
    }

    proc get_current_version {fname} {
      if {![catch { exec hg parent $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {changeset:\s+(\d+):} $line -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc find_version {fname v2 lnum} {
      if {$v2 eq "Current"} {
        if {![catch { exec hg annotate $fname } rc]} {
          if {[regexp "^\\s*(\\d+):" [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
            return $version
          }
        }
      } else {
        if {![catch { exec hg annotate -r $v2 $fname } rc]} {
          if {[regexp "^\\s*(\\d+):" [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc get_version_log {fname version} {
      if {![catch { exec hg log -r $version $fname } rc]} {
        return $rc
      }
      return ""
    }

  }

  ######################################################################
  # Handles GIT commands
  namespace eval git {

    proc name {} {
      return "Git"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec git log -n 1 $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      set ::env(PAGER) ""
      if {![catch { exec git log --abbrev-commit $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^commit ([0-9a-fA-F]+)} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|git show $version:$fname"
    }

    proc get_diff_cmd {v1 v2 fname} {
      if {$v2 eq "Current"} {
        return "git diff $v1 $fname"
      } else {
        return "git diff $v1 $v2 $fname"
      }
    }

    proc get_current_version {fname} {
      if {![catch { exec git log --abbrev-commit $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^commit ([0-9a-fA-F]+)} $line -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc find_version {fname v2 lnum} {
      if {$v2 eq "Current"} {
        if {![catch { exec git blame $fname } rc]} {
          if {[regexp {^([0-9a-fA-F]+)} [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
            return $version
          }
        }
      } else {
        if {![catch { exec git blame $v2 $fname } rc]} {
          if {[regexp {^([0-9a-fA-F]+)} [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc get_version_log {fname version} {
      if {![catch { exec git log -n 1 $version $fname } rc]} {
        return $rc
      }
      return ""
    }

  }

  ######################################################################
  # Handles Bazaar commands
  namespace eval bazaar {

    proc name {} {
      return "Bazaar"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec bzr status $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      if {![catch { exec bzr log $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {revno:\s+(\d+)} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|bzr cat -r $version $fname"
    }

    proc get_diff_cmd {v1 v2 fname} {
      if {$v2 eq "Current"} {
        return "bzr diff -r$v1 $fname"
      } else {
        return "bzr diff -r$v1..$v2 $fname"
      }
    }

    proc get_current_version {fname} {
      if {![catch { exec bzr log $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {revno:\s+(\d+)} $line -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc find_version {fname v2 lnum} {
      if {$v2 eq "Current"} {
        if {![catch { exec bzr annotate $fname } rc]} {
          if {[regexp {^(\d+)} [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
            return $version
          }
        }
      } else {
        if {![catch { exec bzr annotate -r $v2 $fname } rc]} {
          if {[regexp {^(\d+)} [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc get_version_log {fname version} {
      if {![catch { exec bzr log -r $version $fname } rc]} {
        return $rc
      }
      return ""
    }

  }

  ######################################################################
  # Handles Subversion commands
  namespace eval subversion {

    proc name {} {
      return "Subversion"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec svn log $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      if {![catch { exec svn log $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^r(\d+)\s*\|} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|svn cat -r $version $fname"
    }

    proc get_diff_cmd {v1 v2 fname} {
      if {$v2 eq "Current"} {
        return "svn diff -r $v1 $fname"
      } else {
        return "svn diff -r $v1:$v2 $fname"
      }
    }

    proc get_current_version {fname} {
      if {![catch { exec svn FOOBAR $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^r(\d+)\s*\|} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return ""
    }

    proc find_version {fname v2 lnum} {
      if {$v2 eq "Current"} {
        if {![catch { exec svn annotate $fname } rc]} {
          if {[regexp {^\s*(\d+)} [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
            return $version
          }
        }
      } else {
        if {![catch { exec svn annotate -r $v2 $fname } rc]} {
          if {[regexp {^\s*(\d+)} [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc get_version_log {fname version} {
      if {![catch { exec svn log -r $version $fname } rc]} {
        return $rc
      }
      return ""
    }

  }

  ######################################################################
  # Handles CVS commands
  namespace eval cvs {

    proc name {} {
      return "CVS"
    }

    proc type {} {
      return "cvs"
    }

    proc handles {fname} {
      return [expr {![catch { exec cvs log $fname }]}]
    }

    proc versions {fname} {
      set versions [list]
      if {![catch { exec cvs log $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^revision\s+(.*)$} $line -> version]} {
            lappend versions $version
          }
        }
      }
      return $versions
    }

    proc get_file_cmd {version fname} {
      return "|cvs update -p -r $version $fname"
    }

    proc get_diff_cmd {v1 v2 fname} {
      if {$v2 eq "Current"} {
        return "cvs diff -u -r $v1 $fname"
      } else {
        return "cvs diff -u -r $v1 -r $v2 $fname"
      }
    }

    proc get_current_version {fname} {
      if {![catch { exec cvs FOOBAR $fname } rc]} {
        foreach line [split $rc \n] {
          if {[regexp {^revision\s+(.*)$} $line -> version]} {
            return $version
          }
        }
      }
      return ""
    }

    proc find_version {fname v2 lnum} {
      if {$v2 eq "Current"} {
        if {![catch { exec cvs annotate $fname } rc]} {
          if {[regexp {^(\S+)} [lindex [split $rc \n] [expr $lnum - 2]] -> version]} {
            return $version
          }
        }
      } else {
        if {![catch { exec cvs annotate -r $v2 $fname } rc]} {
          if {[regexp {^(\S+)} [lindex [split $rc \n] [expr $lnum - 2]] -> version]} {
            return $version
          }
        }
      }
    }

    proc get_version_log {fname version} {
      if {![catch { exec cvs log -r$version $fname } rc]} {
        return $rc
      }
      return ""
    }

  }

  ######################################################################
  # Handles diff commands
  namespace eval diff {

    proc name {} {
      return "diff"
    }

    proc type {} {
      return "file"
    }

    proc handles {fname} {
      return 0
    }

    proc get_diff_cmd {fname1 fname2} {
      return "diff -u $fname1 $fname2"
    }

    proc get_current_version {fname} {
      return ""
    }

  }

  ######################################################################
  # Handles custom commands
  namespace eval custom {

    proc name {} {
      return "custom"
    }

    proc type {} {
      return "command"
    }

    proc handles {fname} {
      return 0
    }

  }

  ######################################################################
  # DIFFERENCE MAP WIDGET
  ######################################################################

  ######################################################################
  # Creates the difference map which is basically a colored scrollbar.
  proc map {win txt args} {

    variable data

    array set opts {
      -background "black"
      -foreground "white"
      -command ""
    }
    array set opts $args

    set data($txt,-background) $opts(-background)
    set data($txt,-foreground) $opts(-foreground)
    set data($txt,-command)    $opts(-command)

    # Create the canvas
    set data($txt,canvas) [canvas $win -width 15 -relief flat -bd 1 -highlightthickness 0 -bg $data($txt,-background)]

    # Create canvas bindings
    bind $data($txt,canvas) <Configure>  [list diff::map_configure $txt]
    bind $data($txt,canvas) <Button-1>   [list diff::map_position_slider %W %y $txt]
    bind $data($txt,canvas) <B1-Motion>  [list diff::map_position_slider %W %y $txt]
    bind $data($txt,canvas) <MouseWheel> [list event generate $txt.t <MouseWheel> -delta %D]
    bind $data($txt,canvas) <4>          [list event generate $txt.t <4>]
    bind $data($txt,canvas) <5>          [list event generate $txt.t <5>]

    rename ::$win $win
    interp alias {} ::$win {} diff::map_command $txt

    return $win

  }

  ######################################################################
  # Executes map commands.
  proc map_command {txt args} {

    variable data

    set args [lassign $args cmd]

    switch $cmd {

      get {
        return [list $data($txt,first) $data($txt,last)]
      }

      set {
        lassign $args first last
        set height [winfo height $data($txt,canvas)]
        set y1     [expr int( $height * $first )]

        # Adjust the size and position of the slider
        $data($txt,canvas) coords $data($txt,slider) 2 [expr $y1 + 2] 15 [expr $y1 + $data($txt,sheight)]
      }

      configure {
        array set opts $args
        if {[info exists opts(-background)]} {
          set data($txt,-background) $opts(-background)
        }
        if {[info exists opts(-foreground)]} {
          set data($txt,-foreground) $opts(-foreground)
        }
        $data($txt,canvas) configure -bg $data($txt,-background)
        if {[info exists data($txt,slider)]} {
          $data($txt,canvas) itemconfigure $data($txt,slider) -outline $data($txt,-foreground)
        }
      }

      default {
        return -code error "difference map called with invalid command ($cmd)"
      }

    }

  }

  ######################################################################
  # Handles a left-click or click-drag in the canvas area, positioning
  # the cursor at the given position.
  proc map_position_slider {W y txt} {

    variable data

    if {$data($txt,-command) ne ""} {

      # Calculate the moveto fraction
      set moveto [expr ($y.0 - ($data($txt,sheight) / 2)) / [winfo height $W]]

      # Call the command
      uplevel #0 "$data($txt,-command) moveto $moveto"

    }

  }

  ######################################################################
  # Called whenever the map widget is configured.
  proc map_configure {txt} {

    variable data

    # Remove all canvas items
    $data($txt,canvas) delete all

    # Add the difference bars
    foreach type [list sub add] {
      foreach {start end} [$txt diff ranges $type] {
        set start_line [lindex [split $start .] 0]
        set end_line   [lindex [split $end .] 0]
        map_add $txt $type $start_line [expr $end_line - $start_line]
      }
    }

    # Calculate the slider height
    lassign [$txt yview] first last
    set height             [winfo height $data($txt,canvas)]
    set sheight            [expr ((int( $height * $last ) - int( $height * $first )) + 1) - 4]
    set data($txt,sheight) [expr ($sheight < 11) ? 11 : $sheight]

    # Add cursor
    set data($txt,slider) [$data($txt,canvas) create rectangle 2 0 15 10 -outline $data($txt,-foreground) -width 2]
    map_command $txt set $first $last

  }

  ######################################################################
  # Adds a sub or add bar to the associated widget.
  proc map_add {txt type start lines} {

    variable data

    # Get the number of lines in the text widget
    set txt_lines [lindex [split [$txt index end-1c] .] 0]

    # Get the height of the box to add
    set y1 [expr int( ($start.0 / $txt_lines) * [winfo height $data($txt,canvas)] )]
    set y2 [expr int( (($start + $lines.0) / $txt_lines) * [winfo height $data($txt,canvas)] )]

    # Get the color to display
    set color [expr {($type eq "sub") ? [$txt cget -diffsubbg] : [$txt cget -diffaddbg]}]

    # Create the rectangle and place it in the widget
    $data($txt,canvas) create rectangle 0 $y1 15 $y2 -fill $color -width 0

  }

}


