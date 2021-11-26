# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2019  Trevor Williams (phase1geo@gmail.com)
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
    if {[set lang [ctext::getLang $txt insert]] eq ""} {
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
      if {[set start [lindex [$txt syntax prevrange angledL $opts(-start)] 0]] eq ""} {
        return ""
      } elseif {[set end [lindex [$txt syntax nextrange angledR $start] 1]] eq ""} {
        return ""
      }
    } else {
      if {[set end [lindex [$txt syntax nextrange angledR $opts(-start)] 1]] eq ""} {
        return ""
      } elseif {[set start [lindex [$txt syntax prevrange angledL $end] 0]] eq ""} {
        return ""
      }
    }

    while {1} {

      # Get the tag elements
      if {[$txt get "$start+1c"] eq "/"} {
        set found_type "001"
        set found_name [regexp -inline -- {[a-zA-Z0-9_:-]+} [$txt get "$start+2c" "$end-1c"]]
      } else {
        if {[$txt get "$end-2c"] eq "/"} {
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
        if {[set end [lindex [$txt syntax prevrange angledR $start] 1]] eq ""} {
          return ""
        } elseif {[set start [lindex [$txt syntax prevrange angledL $end] 0]] eq ""} {
          return ""
        }
      } else {
        if {[set start [lindex [$txt syntax nextrange angledL $end] 0]] eq ""} {
          return ""
        } elseif {[set end [lindex [$txt syntax nextrange angledR $start] 1]] eq ""} {
          return ""
        }
      }

    }

  }

  ######################################################################
  # Wraps the current tag with a user-specified Emmet abbreviation.
  proc wrap_with_abbreviation {args} {

    array set opts {
      -test ""
    }
    array set opts $args

    set abbr $opts(-test)

    # Get the abbreviation from the user
    if {($abbr ne "") || [gui::get_user_response [format "%s:" [msgcat::mc "Abbreviation"]] abbr]} {

      # Get the current text widget
      set txt [gui::current_txt]

      # Get the node to surround
      if {[llength [set range [$txt tag ranges sel]]] != 2} {
        set range [ctext::get_outer [ctext::get_node_range $txt]]
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
    if {[set itag [ctext::inside_tag $txt]] eq ""} {
      return
    }

    lassign $itag start end name type

    # If we are on a starting tag, look for the ending tag
    set retval [list $start $end]
    set others 0
    while {1} {
      if {[set retval [ctext::get_tag $txt -dir $dir($type) -name $name -type $other($type) -start [lindex $retval $index($type)]]] eq ""} {
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
    if {[set node_range [ctext::get_node_range $txt]] eq ""} {
      $txt mark set insert "insert+1c"
      return
    }

    # Set the cursor at the beginning of the range
    if {[$txt compare [lindex $node_range 1] <= insert] && [$txt compare insert < [lindex $node_range 2]]} {
      set node_range [ctext::get_inner $node_range]
    } else {
      set node_range [ctext::get_outer $node_range]
    }

    # Set the cursor position
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
      if {([ctext::inside_tag $txt] eq "") || ([set tag_range [ctext::get_inner [ctext::get_node_range $txt]]] eq "")} {
        if {([set retval [ctext::get_tag $txt -dir next -type 100]] ne "") && ([lindex $retval 4] eq "")} {
          ::tk::TextSetCursor $txt [lindex $retval 0]
          if {[set tag_range [ctext::get_outer [ctext::get_node_range $txt]]] eq ""} {
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
  # Returns the list of attributes such that each attribute as the following
  # properties:
  #   - attribute name
  #   - attribute name start index
  #   - attribute value
  #   - attribute value start index
  proc get_tag_attributes {txt tag_info} {

    lassign $tag_info start end name type

    # Attributes cannot exist in ending attributes, so just return
    if {$type eq "001"} {
      return [list]
    }

    # Get the attribute contents after the tag name
    set start    [$txt index "$start+[expr [string length $name] + 1]c"]
    set contents [$txt get $start "$end-1c"]

    set attrs [list]
    while {[regexp {^(\s*)(\w+)="(.*?)"(.*)$} $contents -> prespace attr_name attr_value contents]} {
      set attr_name_start [$txt index "$start+[string length $prespace]c"]
      set attr_val_start  [$txt index "$attr_name_start+[expr [string length $attr_name] + 2]c"]
      lappend attrs $attr_name $attr_name_start $attr_value $attr_val_start
      set start [$txt index "$attr_val_start+[expr [string length $attr_value] + 1]c"]
    }

    return $attrs

  }

  ######################################################################
  # Returns an index that contains an empty, indented line; otherwise,
  # returns the empty string.
  proc get_blank_line {txt dir startpos endpos} {

    if {$dir eq "next"} {
      if {[$txt compare $startpos >= "$startpos lineend-1 display chars"]} {
        set startpos [$txt index "$startpos+1 display lines linestart"]
      }
      while {[$txt compare $startpos < $endpos]} {
        if {([string trim [$txt get "$startpos linestart" "$startpos lineend"]] eq "") && \
            ([$txt compare "$startpos linestart" != "$startpos lineend"])} {
          return $startpos
        }
        set startpos [$txt index "$startpos+1 display lines"]
      }
    } else {
      set startpos [$txt index "$startpos-1 display lines linestart"]
      while {[$txt compare $startpos > $endpos]} {
        if {([string trim [$txt get "$startpos linestart" "$startpos lineend"]] eq "") && \
            ([$txt compare "$startpos linestart" != "$startpos lineend"])} {
          return $startpos
        }
        set startpos [$txt index "$startpos-1 display lines"]
      }
    }

    return ""

  }

  ######################################################################
  # Jumps the insertion cursor to an HTML edit point.
  proc go_to_edit_point {dir} {

    # Get the current text widget
    set txt [gui::current_txt]

    # If we are inside a tag, look for an empty attribute
    if {[set retval [ctext::inside_tag $txt]] eq ""} {
      if {[set retval [ctext::get_tag $txt -dir $dir]] eq ""} {
        return
      } else {
        set endpos [expr {($dir eq "next") ? [lindex $retval 0] : [lindex $retval 1]}]
        if {[set index [get_blank_line $txt $dir insert $endpos]] ne ""} {
          ::tk::TextSetCursor $txt "$index lineend"
          return
        }
      }
    }

    # Look for an empty attribute
    if {$dir eq "next"} {

      while {1} {
        foreach {attr_name attr_name_start attr_value attr_value_start} [get_tag_attributes $txt $retval] {
          if {($attr_value eq "") && [$txt compare $attr_value_start > insert]} {
            ::tk::TextSetCursor $txt $attr_value_start
            return
          }
        }
        if {[set next_tag [ctext::get_tag $txt -dir next -start [lindex $retval 1]]] ne ""} {
          if {[$txt compare [lindex $retval 1] == [lindex $next_tag 0]]} {
            ::tk::TextSetCursor $txt [lindex $next_tag 0]
            return
          } elseif {[set index [get_blank_line $txt next [lindex $retval 1] [lindex $next_tag 0]]] ne ""} {
            ::tk::TextSetCursor $txt "$index lineend"
            return
          } else {
            set retval $next_tag
          }
        } else {
          return
        }
      }

    } else {

      while {1} {
        foreach {attr_value_start attr_value attr_name_start attr_name} [lreverse [get_tag_attributes $txt $retval]] {
          if {($attr_value eq "") && [$txt compare $attr_value_start < insert]} {
            ::tk::TextSetCursor $txt $attr_value_start
            return
          }
        }
        if {[set prev_tag [ctext:ctext:::get_tag $txt -dir prev -start [lindex $retval 0]]] ne ""} {
          if {[$txt compare [lindex $prev_tag 1] == [lindex $retval 0]] && \
              [$txt compare insert != [lindex $retval 0]]} {
            ::tk::TextSetCursor $txt [lindex $retval 0]
            return
          } elseif {[set index [get_blank_line $txt prev [lindex $retval 0] [lindex $prev_tag 1]]] ne ""} {
            ::tk::TextSetCursor $txt "$index lineend"
            return
          } else {
            set retval $prev_tag
          }
        } else {
          return
        }
      }

    }

  }

  ######################################################################
  # Selects the next value in the HTML attribute list of values.
  proc select_html_attr_value {txt dir selected attr_value attr_value_start} {

    if {$attr_value eq ""} {
      return 0
    }

    set select         0
    set pattern        [expr {($dir eq "next") ? {^\s*(\S+)} : {(\S+)\s*$}}]
    set attr_value_end [$txt index "$attr_value_start+[string length $attr_value]c"]

    if {((($dir eq "next") && ($selected eq [list $attr_value_start $attr_value_end])) || \
         (($dir eq "prev") && ($selected ne "") && [$txt compare [lindex $selected 0] > $attr_value_end])) && [regexp {\s} $attr_value]} {
      set select 1
    }

    while {[regexp -indices $pattern $attr_value -> match]} {
      set value_start [$txt index "$attr_value_start+[lindex $match 0]c"]
      set value_end   [$txt index "$attr_value_start+[expr [lindex $match 1] + 1]c"]
      if {$select} {
        ::tk::TextSetCursor $txt $value_end
        $txt tag add sel $value_start $value_end
        return 1
      } elseif {$selected eq [list $value_start $value_end]} {
        set select 1
      }
      if {$dir eq "next"} {
        set attr_value       [string range $attr_value [expr [lindex $match 1] + 1] end]
        set attr_value_start [$txt index "$attr_value_start+[expr [lindex $match 1] + 1]c"]
      } else {
        set attr_value       [string range $attr_value 0 [expr [lindex $match 0] - 1]]
      }
    }

    if {$select} {
      return 0
    } else {
      ::tk::TextSetCursor $txt $attr_value_end
      $txt tag add sel $attr_value_start $attr_value_end
      return 1
    }

  }

  ######################################################################
  # Selects the next or previous HTML item.
  proc select_html_item {txt dir} {

    set startpos "insert"

    # If the cursor is not within a start tag, go find the next start tag
    if {([set retval [ctext::inside_tag $txt -allow010 1]] eq "") || [string match "001" [lindex $retval 3]]} {
      set retval [ctext::get_tag $txt -dir $dir -type "??0"]
    }

    # Get the currently selected text
    if {[llength [set selected [$txt tag ranges sel]]] != 2} {
      set selected ""
    }

    if {$dir eq "next"} {

      while {$retval ne ""} {

        # Figure out the index of the end of the name
        set end_name "[lindex $retval 0]+[expr [string length [lindex $retval 2]] + 1]c"

        # Select the tag name if it is the next item
        if {[$txt compare $startpos < $end_name]} {
          ::tk::TextSetCursor $txt $end_name
          $txt tag add sel "[lindex $retval 0]+1c" $end_name
          return

        # Otherwise, check the attributes within the tag for selectable items
        } else {
          foreach {attr_name attr_name_start attr_value attr_value_start} [get_tag_attributes $txt $retval] {
            set attr_end [$txt index "$attr_value_start+[expr [string length $attr_value] + 1]c"]
            if {[$txt compare $startpos > $attr_end]} {
              continue
            }
            if {[$txt compare $startpos < $attr_value_start]} {
              ::tk::TextSetCursor $txt $attr_end
              $txt tag add sel $attr_name_start $attr_end
              return
            } elseif {(($selected eq [list $attr_name_start $attr_end]) && ($attr_value ne "")) || ($selected eq "")} {
              ::tk::TextSetCursor $txt "$attr_end-1c"
              $txt tag add sel $attr_value_start "$attr_end-1c"
              return
            } elseif {[select_html_attr_value $txt $dir $selected $attr_value $attr_value_start ]} {
              return
            }
          }
        }

        # Get the next tag
        set retval [ctext::get_tag $txt -dir $dir -type "??0" -start [lindex $retval 1]]

      }

    } else {

      while {$retval ne ""} {

        set attr_name_start ""

        foreach {attr_value_start attr_value attr_name_start attr_name} [lreverse [get_tag_attributes $txt $retval]] {
          set attr_end [$txt index "$attr_value_start+[expr [string length $attr_value] + 1]c"]
          if {($selected eq [list $attr_name_start $attr_end]) || [$txt compare $startpos < $attr_name_start]} {
            continue
          }
          if {($selected eq [list $attr_value_start [$txt index $attr_end-1c]]) || \
              (($attr_value eq "") && [$txt compare $startpos > $attr_name_start])} {
            ::tk::TextSetCursor $txt $attr_end
            $txt tag add sel $attr_name_start $attr_end
            return
          } elseif {[select_html_attr_value $txt $dir $selected $attr_value $attr_value_start]} {
            return
          } elseif {[$txt compare $startpos > $attr_value_start] && ($attr_value ne "")} {
            ::tk::TextSetCursor $txt "$attr_end-1c"
            $txt tag add sel $attr_value_start "$attr_end-1c"
            return
          }
        }

        set start_name [$txt index "[lindex $retval 0]+1c"]
        set end_name   [$txt index "[lindex $retval 0]+[expr [string length [lindex $retval 2]] + 1]c"]

        # Highlight the tag name if the first full attribute is highlighted or
        # if nothing was highlighted but the cursor is after the beginning of
        # the tag name
        if {(($selected ne [list $start_name $end_name]) && [$txt compare $startpos > [lindex $retval 0]]) || \
            (($attr_name_start ne "") && ($selected eq [list $attr_name_start $attr_end]))} {
          ::tk::TextSetCursor $txt $end_name
          $txt tag add sel $start_name $end_name
          return
        }

        # Get the previous tag
        set retval [ctext::get_tag $txt -dir $dir -type "??0" -start [lindex $retval 0]]

      }

    }

  }

  ######################################################################
  # Perform next/previous item selection.
  proc select_item {dir} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the language of the current insertion cursor
    if {[set lang [ctext::getLang $txt insert]] eq ""} {
      set lang [syntax::get_language $txt]
    }

    if {$lang eq "CSS"} {
      emmet_css::select_item $txt $dir
    } else {
      select_html_item $txt $dir
    }

  }

  ######################################################################
  # Toggles the current HTML node with an HTML comment.
  proc toggle_html_comment {txt} {

    if {[$txt is incomment insert]} {

      if {([set comment_end [lassign [$txt syntax prevrange comstr1c0 insert] comment_start]] eq "") || \
          [$txt compare insert > $comment_end]} {
        lassign [$txt syntax prevrange comstr1c1 insert] comment_start comment_end
      }

      set i 0
      foreach index [$txt search -backwards -all -count lengths -regexp -- {<!--\s*|\s*-->} $comment_end $comment_start] {
        $txt delete $index "$index+[lindex $lengths $i]c"
        incr i
      }

    } else {

      if {[set node_range [ctext::get_node_range $txt]] ne ""} {
        lassign [ctext::get_outer $node_range] comment_start comment_end
      } elseif {[set retval [ctext::inside_tag $txt -allow010 1]] ne ""} {
        lassign $retval comment_start comment_end
      } else {
        return
      }

      # Remove any comments found within range that we are going to comment
      set i 0
      foreach index [$txt search -backwards -all -count lengths -regexp -- {<!--\s*|\s*-->} $comment_end $comment_start] {
        $txt delete $index "$index+[lindex $lengths $i]c"
        incr i
      }

      $txt insert $comment_end   " -->"
      $txt insert $comment_start "<!-- "

    }

  }

  ######################################################################
  # Toggles the comment of a full HTML tag or CSS rule/property.
  proc toggle_comment {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the language of the current insertion cursor
    if {[set lang [ctext::getLang $txt insert]] eq ""} {
      set lang [syntax::get_language $txt]
    }

    if {$lang eq "CSS"} {
      emmet_css::toggle_comment $txt
    } else {
      toggle_html_comment $txt
    }

  }

  ######################################################################
  # Split/Join a tag
  proc split_join_tag {} {

    set txt [gui::current_txt]

    # If the cursor is within a node range, join the range
    if {[set retval [ctext::get_node_range $txt]] ne ""} {

      $txt delete [lindex $retval 1] [lindex $retval 3]
      $txt insert "[lindex $retval 1]-1c" " /"

    # Otherwise, split the tag
    } elseif {[set retval [ctext::inside_tag $txt -allow010 1]] ne ""} {

      set index [$txt search -regexp -- {\s*/>$} [lindex $retval 0] [lindex $retval 1]]
      $txt replace $index [lindex $retval 1] "></[lindex $retval 2]>"

    }

  }

  ######################################################################
  # Removes the current start/end tag and adjusts indentation of all
  # included tags.
  proc remove_tag {} {

    set txt [gui::current_txt]

    # If the cursor is within a node range, delete the start/end tags
    # and adjust indentation if necessary.
    if {[set retval [ctext::get_node_range $txt]] ne ""} {

      # If the start and end tags are on the same line and the tag is the only
      # tag on the line.
      if {[$txt compare "[lindex $retval 0] linestart" == "[lindex $retval 3] linestart"] && \
          ([string trim [$txt get [lindex $retval 1] [lindex $retval 2]]] eq "") && \
          ([string trim [$txt get "[lindex $retval 0] linestart" [lindex $retval 0]]] eq "") && \
          ([string trim [$txt get [lindex $retval 3] "[lindex $retval 3] lineend"]] eq "")} {

        $txt delete "[lindex $retval 0] linestart" "[lindex $retval 3]+1l linestart"

      } else {

        # Adjust the starting tag range
        if {([string trim [$txt get "[lindex $retval 0] linestart" [lindex $retval 0]]] eq "") && \
            ([string trim [$txt get [lindex $retval 1] "[lindex $retval 1] lineend"]] eq "")} {
          lset retval 0 [$txt index "[lindex $retval 0] linestart"]
          lset retval 1 [$txt index "[lindex $retval 1]+1l linestart"]
        }

        # Adjust the ending tag range
        if {([string trim [$txt get "[lindex $retval 2] linestart" [lindex $retval 2]]] eq "") && \
            ([string trim [$txt get [lindex $retval 3] "[lindex $retval 3] lineend"]] eq "")} {
          lset retval 2 [$txt index "[lindex $retval 2] linestart"]
          lset retval 3 [$txt index "[lindex $retval 3]+1l linestart"]
        }

        # These are the number of characters that will be removed from the start
        set count [$txt count -lines {*}[lrange $retval 1 2]]

        # Delete the tags
        $txt delete {*}[lrange $retval 2 3]
        $txt delete {*}[lrange $retval 0 1]

        # Just use the indentation algorithm
        $txt indent -mcursor 0 auto [lindex $retval 0] "[lindex $retval 0]+${count}l linestart"
        # indent::format_text $txt.t [lindex $retval 0] "[lindex $retval 0]+${count}l linestart" 0

      }

      # Add a separator
      $txt edit separator

    } elseif {[set retval [ctext::inside_tag $txt -allow010 1]] ne ""} {

      # Delete the tag
      if {([string trim [$txt get "[lindex $retval 0] linestart" [lindex $retval 0]]] eq "") && \
          ([string trim [$txt get [lindex $retval 1] "[lindex $retval 1] lineend"]] eq "")} {
        $txt delete "[lindex $retval 0] linestart" "[lindex $retval 1]+1l linestart"
      } else {
        $txt delete {*}[lrange $retval 0 1]
      }

      # Add a separator
      $txt edit separator

    }

  }

  ######################################################################
  # Merges all lines for a given node range.
  proc merge_lines {} {

    set txt [gui::current_txt]

    if {[set range [ctext::get_node_range $txt]] ne ""} {

      lassign $range startpos dummy1 dummy2 endpos

      # Get the number of lines to join
      set lines [$txt count -lines $startpos $endpos]

      for {set i 0} {$i < $lines} {incr i} {
        set line [string trimleft [$txt get "$startpos+1l linestart" "$startpos+1l lineend"]]
        $txt delete "$startpos lineend" "$startpos+1l lineend"
        if {$line ne ""} {
          $txt insert "$startpos lineend" $line
        }
      }

    }

  }

  ######################################################################
  # Updates the HTML size using the given image's width and height and
  # available attributes.
  proc update_html_image_size {txt} {

    if {([set retval [ctext::inside_tag $txt -allow010 1]] ne "") && ([lindex $retval 2] eq "img") && [string match "??0" [lindex $retval 3]]} {

      set width        ""
      set height       ""
      set src_end      ""
      set width_start  ""
      set width_end    ""
      set hstart       ""
      set height_start ""
      set height_end   ""

      foreach {attr_name attr_name_start attr_value attr_value_start} [get_tag_attributes $txt $retval] {
        switch $attr_name {
          "src" {
            if {![catch { exec php [file join $::tke_dir lib image_size.php] $attr_value } rc]} {
              lassign $rc width height
              if {![string is integer $width]} {
                set width ""
              }
            }
            set src_end [$txt index "$attr_value_start+[expr [string length $attr_value] + 1]c"]
          }
          "width" {
            set width_start $attr_value_start
            set width_end   [$txt index "$attr_value_start+[string length $attr_value]c"]
          }
          "height" {
            set hstart       $attr_name_start
            set height_start $attr_value_start
            set height_end   [$txt index "$attr_value_start+[string length $attr_value]c"]
          }
        }
      }

      if {$width ne ""} {
        if {$width_start ne ""} {
          if {$height_start ne ""} {
            if {[$txt compare $width_start < $height_start]} {
              $txt replace $height_start $height_end $height
              $txt replace $width_start  $width_end  $width
            } else {
              $txt replace $width_start  $width_end  $width
              $txt replace $height_start $height_end $height
            }
          } else {
            $txt insert "$width_end+1c" " height=\"$height\""
            $txt replace $width_start $width_end $width
          }
        } else {
          if {$height_start ne ""} {
            $txt replace $height_start $height_end $height
            $txt insert $hstart "width=\"$width\" "
          } else {
            $txt insert $src_end " width=\"$width\" height=\"$height\""
          }
        }
      }

    }

  }

  ######################################################################
  # Updates the image size of the current tag.
  proc update_image_size {} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the language of the current insertion cursor
    if {[set lang [ctext::getLang $txt insert]] eq ""} {
      set lang [syntax::get_language $txt]
    }

    if {$lang eq "CSS"} {
      emmet_css::update_image_size $txt
    } else {
      update_html_image_size $txt
    }

  }

  ######################################################################
  # Increment/decrement the number under the insertion cursor by the
  # given amount.
  proc change_number {amount} {

    set txt [gui::current_txt]

    # Get the range of the number
    if {[$txt get insert] eq "-"} {
      set num_start "insert"
      set num_end   [$txt index numberend -startpos "insert+1c" -adjust "+1c"]
      if {[$txt compare $num_end == "insert+1c"]} {
        return
      }
    } else {
      set num_start [$txt index numberstart]
      set num_end   [$txt index numberend -adjust "+1c"]
      if {[$txt compare $num_start == $num_end] || [$txt compare insert == $num_end]} {
        return
      }
      if {([$txt get "$num_start-1c"] eq "-") && ![$txt is escaped "$num_start-1c"]} {
        set num_start "$num_start-1c"
      }
    }

    # Get the number and only continue on if the value is not a hexidecimal
    if {[string range [set number [$txt get $num_start $num_end]] 0 1] ne "0x"} {

      # Get the decimal portions of the text number and the increment/decrement
      # amount
      set number_len [string length [lindex [split $number .] 1]]
      set amount_len [string length [lindex [split $amount .] 1]]
      set number     [expr $number + $amount]

      # Figure out the numerical formatting
      if {($number_len != 0) || ($amount_len != 0)} {
        if {$number_len < $amount_len} {
          set number [format "%.${amount_len}f" $number]
          if {[lindex [split $number .] 1] eq "0"} {
            set number [expr int( $number )]
          }
        } else {
          set number [format "%.${number_len}f" $number]
          if {[lindex [split $number .] 1] eq "0"} {
            set number [expr int( $number )]
          }
        }
      }

      # Get the insertion cursor position
      set cursor [$txt index insert]

      # Insert the number
      $txt replace $num_start $num_end $number

      # Set the cursor
      ::tk::TextSetCursor $txt.t $cursor

      # Create an undo separator
      $txt edit separator

    }

  }

  ######################################################################
  # Evaluate the current math expression.
  proc evaluate_math_expression {} {

    set txt        [gui::current_txt]
    set pre_match  ""
    set post_match ""

    regexp {(\S+)$} [$txt get "insert linestart" insert] pre_match
    regexp {^(\S+)} [$txt get insert "insert lineend"] post_match

    if {[set expression "$pre_match$post_match"] ne ""} {

      # Attempt to evaluate the expression
      if {![catch { expr $expression } rc]} {
        set startpos [$txt index "insert-[string length $pre_match]c"]
        set endpos   [$txt index "insert+[string length $post_match]c"]
        $txt replace $startpos $endpos $rc
        ::tk::TextSetCursor $txt $startpos
        $txt edit separator
      }

    }

  }

  ######################################################################
  # Perform the data:URL replacement.
  proc replace_data_url {txt startpos endpos url args} {

    array set opts {
      -test ""
    }
    array set opts $args

    # If we have base64 data, decode and save the information to a file
    if {[regexp {^data:image/(gif|png|jpg);base64,(.*)$} $url -> ext data]} {
      set fname $opts(-test)
      if {($fname ne "") || [set fname [tk_getSaveFile -parent . -defaultextension .$ext -title [msgcat::mc "Select File to Save"]]] ne ""} {
        if {![catch { open $fname w } rc]} {
          fconfigure $rc -encoding binary
          puts $rc [base64::decode $data]
          close $rc
          $txt replace $startpos $endpos [utils::relative_to $fname [pwd]]
          $txt edit separator
        }
      }
      return
    }

    # If the filename is a supported image type, convert the file to base64
    # and insert them.
    set type ""
    switch [file extension $url] {
      .gif  { set type "image/gif" }
      .png  { set type "image/png" }
      .jpg  { set type "image/jpg" }
      .jpeg { set type "image/jpg" }
    }

    # Get the filename to handle from the parsed URL
    set delete 1
    if {[file exists $url]} {
      set fname  $url
      set delete 0
    } elseif {[set fname [utils::download_url $url]] eq ""} {
      return
    }

    # Output the base64 output
    if {($type ne "") && ![catch { open $fname r } rc]} {
      fconfigure $rc -translation binary
      set data [read $rc]
      close $rc
      if {$delete} {
        file delete -force $fname
      }
      $txt replace $startpos $endpos "data:$type;base64,[base64::encode -maxlen 0 $data]"
      $txt edit separator
    }

  }

  ######################################################################
  # Runs encode/decode image to data:URL in HTML.
  proc encode_decode_html_image_to_data_url {txt args} {

    if {([set retval [ctext::inside_tag $txt -allow010 1]] eq "") || [string match "001" [lindex $retval 3]] || ([lindex $retval 2] ne "img")} {
      return
    }

    puts "encode_decode_html_image_to_data_url, retval: $retval, insert: [$txt index insert]"

    # Find the URL in the current img tag
    set url ""
    foreach {attr_name attr_name_start attr_value attr_value_start} [get_tag_attributes $txt $retval] {
      if {($attr_name eq "src") && \
          [$txt compare $attr_value_start <= insert] && \
          [$txt compare insert <= "$attr_value_start+[string length $attr_value]c"]} {
        set url      $attr_value
        set startpos $attr_value_start
        set endpos   [$txt index "$attr_value_start+[string length $attr_value]c"]
        break
      }
    }

    if {$url eq ""} {
      return
    }

    # Perform the replacement
    replace_data_url $txt $startpos $endpos $url {*}$args

  }

  ######################################################################
  # Executes encode/decode image to data:URL functionality.
  proc encode_decode_image_to_data_url {args} {

    # Get the current text widget
    set txt [gui::current_txt]

    # Get the language of the current insertion cursor
    if {[set lang [ctext::getLang $txt insert]] eq ""} {
      set lang [syntax::get_language $txt]
    }

    if {$lang eq "CSS"} {
      emmet_css::encode_decode_image_to_data_url $txt {*}$args
    } else {
      encode_decode_html_image_to_data_url $txt {*}$args
    }

  }

  ######################################################################
  # Displays the Emmet reference guide in a web browser.
  proc view_reference {} {

    utils::open_file_externally "https://docs.emmet.io" 1

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

