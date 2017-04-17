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
# Name:    emmet.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    02/24/2016
# Brief:   Namespace containing Emmet-related functionality.
######################################################################

source [file join $::tke_dir lib emmet_parser.tcl]
source [file join $::tke_dir lib emmet_css.tcl]

namespace eval emmet {

  variable custom_file
  variable customizations

  array set data {
    tag       {(.*)(<\/?[\w:-]+(?:\s+[\w:-]+(?:\s*=\s*(?:(?:".*?")|(?:'.*?')|[^>\s]+))?)*\s*(\/?)>)}
    brackets  {(.*?)(\[.*?\]|\{.*?\})}
    space     {(.*?)(\s+)}
    tagname   {[a-zA-Z0-9_:-]+}
    other_map {"100" "001" "001" "100"}
    dir_map   {"100" "next" "001" "prev"}
    index_map {"100" 1 "001" 0}
  }

  # Create the custom filename
  set custom_file [file join $::tke_home emmet.tkedat]

  ######################################################################
  # Initializes Emmet aliases.
  proc load {} {

    variable custom_file

    # Copy the Emmet customization file from the TKE installation directory to the
    # user's home directory.
    if {![file exists $custom_file]} {
      file copy [file join $::tke_dir data emmet.tkedat] $custom_file
    }

    # Load the user's custom alias file
    load_custom_aliases

  }

  ######################################################################
  # Returns a three element list containing the snippet text, starting and ending
  # position of that text.
  proc get_snippet_text_pos {} {

    variable data

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the current line and column numbers
    lassign [split [$txt index insert] .] line endcol

    # Get the current line
    set str [$txt get "insert linestart" insert]

    # Get the prespace of the current line
    regexp {^([ \t]*)} $str -> prespace

    # If we have a tag, ignore all text prior to it
    set startcol [expr {[regexp $data(tag) $str match] ? [string length $match] : 0}]

    # Gather the positions of any square or curly brackets in the left-over area
    foreach key [list brackets space] {
      set pos($key) [list]
      set col       $startcol
      while {[regexp -start $col -- $data($key) $str match pre]} {
        lappend pos($key) [expr $col + [string length $pre]] [expr $col + [string length $match]]
        set col [lindex $pos($key) end]
      }
    }

    # See if there is a space which does not exist within a square or curly brace
    foreach {endpos startpos} [lreverse $pos(space)] {
      if {[expr [lsearch [lsort -integer [concat $pos(brackets) $endpos]] $endpos] % 2] == 0} {
        return [list [string range $str $endpos end] $line.$endpos $line.$endcol $prespace]
      }
    }

    return [list [string range $str $startcol end] $line.$startcol $line.$endcol $prespace]

  }

  ######################################################################
  # Parses the current Emmet snippet found in the current editing buffer.
  # Returns a three element list containing the generated code, the
  # starting index of the snippet and the ending index of the snippet.
  proc expand_abbreviation {} {

    set txt [gui::current_txt]

    # Get the language of the current insertion cursor
    if {[set lang [ctext::get_lang $txt insert]] eq ""} {
      set lang [syntax::get_language $txt]
    }

    # If the current language is CSS, translate the abbreviation as such
    if {$lang eq "CSS"} {

      # Get the abbreviation text, translate it and insert it back into the text
      if {[regexp {(\S+)$} [$txt get "insert linestart" insert] -> abbr]} {
        if {![catch { emmet_css::parse $abbr } str]} {
          snippets::insert_snippet_into_current $str -delrange [list "insert-[string length $abbr]c" insert] -separator 0
        }
      }

    } else {

      # Find the snippet text
      lassign [get_snippet_text_pos] str startpos endpos prespace

      # Parse the snippet and if no error, insert the resulting string
      if {![catch { ::parse_emmet $str $prespace } str]} {
        snippets::insert_snippet_into_current $str -delrange [list $startpos $endpos] -separator 0
      }

    }

  }

  ######################################################################
  # Display the custom abbreviation file in an editing buffer.
  proc edit_abbreviations {} {

    pref_ui::create "" "" emmet "Node Aliases"

  }

  ######################################################################
  # Handles any save operations to the Emmet customization file.
  proc load_custom_aliases {args} {

    variable custom_file
    variable customizations

    # Read in the emmet customizations
    if {![catch { tkedat::read $custom_file 1 } rc]} {

      array unset customizations

      # Save the customization information
      array set customizations $rc

    }

  }

  ######################################################################
  # Updates the given alias value.
  proc update_alias {type curr_alias new_alias value} {

    variable customizations
    variable custom_file

    # Get the affected aliases and store it in an array
    array set aliases $customizations($type)

    # Remove the old alias information if the curr_alias value does not match the new_alias value
    if {$curr_alias ne $new_alias} {
      catch { unset aliases($curr_alias) }
    }

    if {$new_alias ne ""} {
      set aliases($new_alias) $value
    }

    # Store the aliases list back into the customization array
    set customizations($type) [array get aliases]

    # Write the customization value to file
    catch { tkedat::write $custom_file [array get customizations] 1 [list node_aliases array abbreviation_aliases array] }

  }

  ######################################################################
  # Returns the alias value associated with the given alias name.  If
  # no alias was found, returns the empty string.
  proc lookup_alias_helper {type alias} {

    variable customizations

    if {[info exists customizations($type)]} {
      array set aliases $customizations($type)
      if {[info exists aliases($alias)]} {
        return $aliases($alias)
      }
    }

    return ""

  }

  ######################################################################
  # Perform a lookup of a customized node alias and returns its value,
  # if found.  If not found, returns the empty string.
  proc lookup_node_alias {alias} {

    return [lookup_alias_helper node_aliases $alias]

  }

  ######################################################################
  # Perform a lookup of a customized abbreviation alias and returns its value,
  # if found.  If not found, returns the empty string.
  proc lookup_abbr_alias {alias} {

    return [lookup_alias_helper abbreviation_aliases $alias]

  }

  ######################################################################
  # Get the alias information.
  proc get_aliases {} {

    variable customizations

    return [array get customizations]

  }

  ######################################################################
  # Gets the tag that begins before the current insertion cursor.  The
  # value of -dir must be "next or "prev".  The value of -type must be
  # "100" (start), "001" (end), "010" (both) or "*" (any).  The value of
  # name is the tag name to search for (if specified).
  #
  # Returns a list of 6 elements if a tag was found that matches:
  #  - starting tag position
  #  - ending tag position
  #  - tag name
  #  - type of tag found (10=start, 01=end or 11=both)
  #  - number of starting tags encountered that did not match
  #  - number of ending tags encountered that did not match
  proc get_tag {txt args} {

    array set opts {
      -dir   "next"
      -type  "*"
      -name  "*"
      -start "insert"
    }
    array set opts $args

    # Initialize counts
    set missed [list]

    # Get the tag
    if {$opts(-dir) eq "prev"} {
      if {[set start [lindex [$txt tag prevrange _angledL $opts(-start)] 0]] eq ""} {
        return ""
      } elseif {[set end [lindex [$txt tag nextrange _angledR $start] 1]] eq ""} {
        return ""
      }
    } else {
      if {[set end [lindex [$txt tag nextrange _angledR $opts(-start)] 1]] eq ""} {
        return ""
      } elseif {[set start [lindex [$txt tag prevrange _angledL $end] 0]] eq ""} {
        return ""
      }
    }

    while {1} {

      # Get the tag elements
      if {[$txt get "$start+1c"] eq "/"} {
        set found_type "001"
        set found_name [regexp -inline -- {[a-zA-Z0-9_:-]+} [$txt get "$start+2c" "$end-1c"]]
      } else {
        if {[$txt get "$end-1c"] eq "/"} {
          set found_type "010"
          set found_name [regexp -inline -- {[a-zA-Z0-9_:-]+} [$txt get "$start+1c" "$end-2c"]]
        } else {
          set found_type "100"
          set found_name [regexp -inline -- {[a-zA-Z0-9_:-]+} [$txt get "$start+1c" "$end-1c"]]
        }
      }

      # If we have found what we are looking for, return now
      if {[string match $opts(-type) $found_type] && [string match $opts(-name) $found_name]} {
        return [list $start $end $found_name $found_type $missed]
      }

      # Update counts
      lappend missed "$found_name,$found_type"

      # Otherwise, get the next tag
      if {$opts(-dir) eq "prev"} {
        if {[set end [lindex [$txt tag prevrange _angledR $start] 1]] eq ""} {
          return ""
        } elseif {[set start [lindex [$txt tag prevrange _angledL $end] 0]] eq ""} {
          return ""
        }
      } else {
        if {[set start [lindex [$txt tag nextrange _angledL $end] 0]] eq ""} {
          return ""
        } elseif {[set end [lindex [$txt tag nextrange _angledR $start] 1]] eq ""} {
          return ""
        }
      }

    }

  }

  ######################################################################
  # If the insertion cursor is currently inside of a tag element, returns
  # the tag information; otherwise, returns the empty string
  proc inside_tag {txt} {

    set retval [get_tag $txt -dir prev -start "insert+1c"]

    if {($retval ne "") && [$txt compare insert < [lindex $retval 1]] && ([lindex $retval 3] ne "010")} {
      return $retval
    }

    return ""

  }

  ######################################################################
  # Returns the character range for the current node based on the given
  # outer type.
  proc get_node_range {txt} {

    variable data

    array set other $data(other_map)
    array set dir   $data(dir_map)
    array set index $data(index_map)

    # Get the tag that we are inside of
    if {[set itag [inside_tag $txt]] eq ""} {
      return ""
    }

    lassign $itag start end name type

    # If we are on a starting tag, look for the ending tag
    set retval [list $start $end]
    set others 0
    while {1} {
      if {[set retval [get_tag $txt -dir $dir($type) -name $name -type $other($type) -start [lindex $retval $index($type)]]] eq ""} {
        return
      }
      if {[incr others [llength [lsearch -all [lindex $retval 4] $name,$type]]] == 0} {
        switch $type {
          "100" { return [list $start $end {*}[lrange $retval 0 1]] }
          "001" { return [list {*}[lrange $retval 0 1] $start $end] }
          default { return -code error "Error finding node range" }
        }
      }
      incr others -1
    }

  }

  ######################################################################
  # Returns the outer range of the given node range value as a list.
  proc get_outer {node_range} {

    if {$node_range ne ""} {
      return [list [lindex $node_range 0] [lindex $node_range 3]]
    }

    return ""

  }

  ######################################################################
  # Returns the inner range of the given node range value as a list.
  proc get_inner {node_range} {

    if {$node_range ne ""} {
      return [lrange $node_range 1 2]
    }

    return ""

  }

  ######################################################################
  # Wraps the current tag with a user-specified Emmet abbreviation.
  proc wrap_with_abbreviation {} {

    set abbr ""

    # Get the abbreviation from the user
    if {[gui::get_user_response [format "%s:" [msgcat::mc "Abbreviation"]] abbr]} {

      # Get the current text widget
      set txt [gui::current_txt]

      # Get the node to surround
      if {[llength [set range [$txt tag ranges sel]]] != 2} {
        set range [get_outer [get_node_range $txt]]
      }

      # Parse the snippet and if no error, insert the resulting string
      if {![catch { ::parse_emmet $abbr "" [$txt get {*}$range] } str]} {
        snippets::insert_snippet_into_current $str -delrange $range -separator 0
      }

    }

  }

  ######################################################################
  # Starting at a given tag, set the insertion cursor at the start of
  # the matching tag.
  proc go_to_matching_pair {} {

    variable data

    array set other $data(other_map)
    array set dir   $data(dir_map)
    array set index $data(index_map)

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the tag that we are inside of
    if {[set itag [inside_tag $txt]] eq ""} {
      return
    }

    lassign $itag start end name type

    # If we are on a starting tag, look for the ending tag
    set retval [list $start $end]
    set others 0
    while {1} {
      if {[set retval [get_tag $txt -dir $dir($type) -name $name -type $other($type) -start [lindex $retval $index($type)]]] eq ""} {
        return
      }
      if {[incr others [llength [lsearch -all [lindex $retval 4] $name,$type]]] == 0} {
        ::tk::TextSetCursor $txt [lindex $retval 0]
        return
      }
      incr others -1
    }

  }

  ######################################################################
  # Performs tag balancing.
  proc balance_outward {} {

    variable data

    array set other $data(other_map)
    array set dir   $data(dir_map)
    array set index $data(index_map)

    # Get the current text widget
    set txt [gui::current_txt]

    # Adjust the insertion cursor if we are on a starting tag and there
    # is a selection.
    if {[$txt tag ranges sel] ne ""} {
      $txt mark set insert "insert-1c"
    }

    # If the insertion cursor is on a tag, get the outer node range
    if {[set node_range [get_outer [get_node_range $txt]]] eq ""} {

      # Find the beginning tag that we are currently inside of
      set retval [list insert]
      set count  0

      while {1} {
        if {[set retval [get_tag $txt -dir prev -type 100 -start [lindex $retval 0]]] eq ""} {
          return
        }
        if {[incr count [expr [llength [lsearch -all [lindex $retval 4] *,100]] - [llength [lsearch -all [lindex $retval 4] *,001]]]] == 0} {
          set range_start [lindex $retval 1]
          set range_name  [lindex $retval 2]
          break
        }
        incr count
      }

      # Find the ending tag based on the beginning tag
      set retval [list {} insert]
      set count 0

      while {1} {
        if {[set retval [get_tag $txt -dir next -type 001 -name $range_name -start [lindex $retval 1]]] eq ""} {
          return
        }
        if {[incr count [llength [lsearch -all [lindex $retval 4] $range_name,100]]] == 0} {
          set range_end [lindex $retval 0]
          break
        }
        incr count -1
      }

      set node_range [list $range_start $range_end]

    }

    # Set the cursor at the beginning of the range
    ::tk::TextSetCursor $txt [lindex $node_range 0]

    # Select the current range
    $txt tag add sel {*}$node_range

  }

  ######################################################################
  # Performs an Emmet balance inward operation based on the current
  # selection state.
  proc balance_inward {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # If we already have a selection, perform the inward balance
    if {[llength [$txt tag ranges sel]] == 2} {
      if {[set tag_range [get_inner [get_node_range $txt]]] eq ""} {
        if {([set retval [get_tag $txt -dir next -type 100]] ne "") && ([lindex $retval 4] eq "")} {
          ::tk::TextSetCursor $txt [lindex $retval 0]
          if {[set tag_range [get_outer [get_node_range $txt]]] eq ""} {
            return
          }
        } else {
          return
        }
      }

      # Set the cursor and the selection
      ::tk::TextSetCursor $txt [lindex $tag_range 0]
      $txt tag add sel {*}$tag_range

    # Otherwise, perform an outward balance to make the selection
    } else {

      balance_outward

    }

  }

  ######################################################################
  # Returns a list of files/directories used by the Emmet namespace for
  # importing/exporting purposes.
  proc get_share_items {dir} {

    return [list emmet.tkedat]

  }

  ######################################################################
  # Called when the share directory changes.
  proc share_changed {dir} {

    variable custom_file

    set custom_file [file join $dir emmet.tkedat]

  }

}

