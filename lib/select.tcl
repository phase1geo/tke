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
# Name:    select.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    06/05/2017
# Brief:   Provides select mode functionality.
######################################################################

namespace eval select {

  array set data [list]

  ######################################################################
  # Adds bindings for selection mode.  Returns the hierarchical reference
  # to the select mode sidebar widget which needs to be packed into a grid
  # controlled layout manager and hidden from view.
  proc add {txt frame} {

    variable data

    set data($txt.t,mode)      0
    set data($txt.t,object)    none
    set data($txt.t,type)      char
    set data($txt.t,anchor)    1.0
    set data($txt.t,anchorend) 0
    set data($txt.t,sidebar)   [create_sidebar $txt.t $frame]
    set data($txt.t,moved)     0

    bind select <Key>     "if {\[select::handle_any %W %K\]} break"
    bind select <Return>  "if {\[select::handle_return %W\]} break"
    bind select <Escape>  "if {\[select::handle_escape %W\]} break"

    bindtags $txt.t [linsert [bindtags $txt.t] [expr [lsearch [bindtags $txt.t] $txt.t] + 1] select]

    # Make sure that our defaults are checked
    check_item $txt.t object none
    check_item $txt.t type   char

  }

  ######################################################################
  # Creates the selection mode sidebar which displays the currently selected
  # modes, their key bindings and their description.
  proc create_sidebar {txtt w} {

    ttk::frame $w

    ttk::labelframe $w.object -text [msgcat::mc "Object Mode"]
    create_item $txtt $w.object [msgcat::mc "None"]  - none  object
    create_item $txtt $w.object [msgcat::mc "Inner"] i inner object
    create_item $txtt $w.object [msgcat::mc "Outer"] o outer object

    ttk::labelframe $w.type -text [msgcat::mc "Selection Type"]
    create_item $txtt $w.type [msgcat::mc "Character"]       c  char type
    create_item $txtt $w.type [msgcat::mc "Line"]            l  line type
    create_item $txtt $w.type [msgcat::mc "Block"]           b  block type
    create_item $txtt $w.type [msgcat::mc "Word"]            w  word type
    create_item $txtt $w.type [msgcat::mc "Non-Whitespace"]  n  nonws type
    create_item $txtt $w.type [msgcat::mc "Sentence"]        s  sentence type
    create_item $txtt $w.type [msgcat::mc "Paragraph"]       p  paragraph type
    create_item $txtt $w.type [msgcat::mc "Tag"]             t  tag type
    create_item $txtt $w.type [msgcat::mc "Square Brackets"] \[ square type
    create_item $txtt $w.type [msgcat::mc "Parenthesis"]     \( paren type
    create_item $txtt $w.type [msgcat::mc "Curly Brackets"]  \{ curly type
    create_item $txtt $w.type [msgcat::mc "Double Quotes"]   \" double type
    create_item $txtt $w.type [msgcat::mc "Single Quotes"]   \' single type
    create_item $txtt $w.type [msgcat::mc "Backticks"]       \` btick type

    ttk::labelframe $w.dir -text [msgcat::mc "Selection Motion"]
    create_item $txtt $w.dir [msgcat::mc "Select Next"]        "\u2192" next
    create_item $txtt $w.dir [msgcat::mc "Select Previous"]    "\u2190" prev
    create_item $txtt $w.dir [msgcat::mc "Select Parent"]      "\u2191" parent
    create_item $txtt $w.dir [msgcat::mc "Select First Child"] "\u2193" child

    ttk::button $w.anchor -text [msgcat::mc "Swap Selection Anchor"] -command [list select::handle_a $txtt]

    pack $w.object -fill x -padx 2 -pady 2
    pack $w.type   -fill x -padx 2 -pady 2
    pack $w.dir    -fill x -padx 2 -pady 2
    pack $w.anchor -padx 2 -pady 2

    return $w

  }

  ######################################################################
  # Creates an item that will be displayed in the selection sidebar.
  proc create_item {txtt w name key value {var ""}} {

    set row [lindex [grid size $w] 1]

    grid [ttk::label $w.${value}_cb   -text " "]   -row $row -column 0 -sticky news -pady 2
    grid [ttk::label $w.${value}_key  -text $key]  -row $row -column 1 -sticky news -pady 2
    grid [ttk::label $w.${value}_name -text $name] -row $row -column 2 -sticky news -pady 2

    if {$var ne ""} {
      bind $w.${value}_cb   <Enter>    [list select::set_item_state $w.$value active]
      bind $w.${value}_cb   <Leave>    [list select::set_item_state $w.$value !active]
      bind $w.${value}_key  <Enter>    [list select::set_item_state $w.$value active]
      bind $w.${value}_key  <Leave>    [list select::set_item_state $w.$value !active]
      bind $w.${value}_name <Enter>    [list select::set_item_state $w.$value active]
      bind $w.${value}_name <Leave>    [list select::set_item_state $w.$value !active]
      bind $w.${value}_cb   <Button-1> [list select::check_item $txtt $var $value]
      bind $w.${value}_key  <Button-1> [list select::check_item $txtt $var $value]
      bind $w.${value}_name <Button-1> [list select::check_item $txtt $var $value]
    }

  }

  ######################################################################
  # Sets the state of the entire item
  proc set_item_state {item state} {

    ${item}_cb   state $state
    ${item}_key  state $state
    ${item}_name state $state

  }

  ######################################################################
  # Toggles the state of the given item, deselecting any other selected
  # item.
  proc check_item {txtt var value} {

    variable data

    # Clear the last checkmark
    $data($txtt,sidebar).$var.$data($txtt,$var)_cb configure -text ""

    # Set our checkmark
    $data($txtt,sidebar).$var.${value}_cb configure -text "\u2713"

    # Sets the variable to the given value
    set data($txtt,$var) $value

    # Update the selection
    if {$data($txtt,mode)} {
      update_selection $txtt init
    }

  }

  ######################################################################
  # Updates the current selection based on the current object and type
  # selections along with the given motion type (init, next, prev, parent,
  # child).
  proc update_selection {txtt motion} {

    variable data

    set range [list insert insert]
    
    # If we have already moved, change an init motion to a next/prev
    # motion based on the anchorend.
    if {$data($txtt,moved) && ($motion eq "init")} {
      set motion [expr {$data($txtt,anchorend) ? "prev" : "next"}]
    }
    
    switch $motion {
      init {
        switch $data($txtt,object) {
          none {
            switch $data($txtt,type) {
              char { set range [list $data($txtt,anchor) "$data($txtt,anchor)+1 display chars"] }
            }
          }
          inner -
          outer {
            switch $data($txtt,type) {
              char    { set range [list $data($txtt,anchor) "$data($txtt,anchor)+1 display chars"] }
              nonws   { set range [edit::get_range $txtt [list WORD 1] [list] [string index $data($txtt,object) 0] 0] }
              default { set range [edit::get_range $txtt [list $data($txtt,type) 1] [list] [string index $data($txtt,object) 0] 0] }
            }
          }
        }
      }
      next -
      prev {
        set range [$txtt tag ranges sel]
        set index [expr $data($txtt,anchorend) ^ 1]
        switch $data($txtt,type) {
          char      { set positions [list dchar     dchar] }
          line      { set positions [list linestart lineend] }
          word      { set positions [list wordstart [list wordend -startpos "[lindex $range 1]-1 display chars" -adjust "+1 display chars"]] }
          nonws     { set positions [list WORDstart WORDend] }
          sentence  { set positions [list sentence  sentence] }
          paragraph { set positions [list paragraph paragraph] }
          tag       { set positions [list tagstart  tagend] }
          square    { set positions [list {char -char \[} {char -char \]}] }
          curly     { set positions [list {char -char \{} {char -char \}}] }
          paren     { set positions [list {char -char \(} {char -char \)}] }
          angled    { set positions [list {char -char <}  {char -char >}] }
          double    { set positions [list {char -char \"} {char -char \"}] }
          single    { set positions [list {char -char \'} {char -char \'}] }
          btick     { set positions [list {char -char \`} {char -char \`}] }
        }
        lset range $index [edit::get_index $txtt {*}[lindex $positions $index] -dir $motion -startpos [lindex $range $index]]
        set data($txtt,moved) 1
      }
      parent {
        # TBD
      }
      child {
        # TBD
      }
    }

    puts "range: $range"

    # Set the tag
    if {[$txtt compare [lindex $range 0] < [lindex $range 1]]} {
      if {$data($txtt,anchorend) == 0} {
        ::tk::TextSetCursor $txtt [lindex $range 0]
      } else {
        ::tk::TextSetCursor $txtt [lindex $range 1]
      }
      $txtt tag add sel {*}$range
    }

  }

  ######################################################################
  # Open the sidebar for view.  This should only be called by the
  # set_select_mode internal procedure.
  proc open_sidebar {txtt} {

    variable data

    # Make the sidebar visible
    grid $data($txtt,sidebar)

  }

  ######################################################################
  # Closes the selection mode sidebar from view.  This should only be
  # called by the set_select_mode internal procedure.
  proc close_sidebar {txtt} {

    variable data

    # Hide the sidebar
    grid remove $data($txtt,sidebar)

  }

  ######################################################################
  # Sets the selection mode for the given text widget to the given value.
  # This will cause the selection sidebar to appear or disappear as needed.
  proc set_select_mode {txtt value} {

    variable data

    # Set the mode
    if {$data($txtt,mode) != $value} {
      if {$value == 0} {
        close_sidebar $txtt
      } else {
        open_sidebar $txtt
      }
      set data($txtt,mode) $value
      if {$value} {
        set data($txtt,anchor) [$txtt index insert]
        set data($txtt,moved)  0
        update_selection $txtt init
      }
    }

  }

  ######################################################################
  # Handles the Return key when in selection mode.  Ends selection mode,
  # leaving the selection in place.
  proc handle_return {txtt} {

    variable data

    if {$data($txtt,mode) == 0} {
      return 0
    }

    # Disable selection mode
    set_select_mode $txtt 0

    return 1

  }

  ######################################################################
  # Handles the Escape key when in selection mode.  Ends selection mode
  # and clears the selection.
  proc handle_escape {txtt} {

    variable data

    if {$data($txtt,mode) == 0} {
      return 0
    }

    # Disable selection mode
    set_select_mode $txtt 0

    # Clear the selection
    $txtt tag remove sel 1.0 end

    return 1

  }

  ######################################################################
  # Handles any other entered keys when in selection mode.
  proc handle_any {txtt keysym} {

    variable data

    if {$data($txtt,mode) == 0} {
      return 0
    }

    # Handle the specified key
    catch { handle_$keysym $txtt }

    return 1

  }

  ######################################################################
  # Handles the user hitting the "-" key which will cause the selection
  # to only move on the non-anchored end of the selection.
  proc handle_minus {txtt} {

    check_item $txtt object none

  }

  ######################################################################
  # Handles the user hitting the "i" key which will adjust the selection
  # to include the "inner" portion of the current selection type.  This
  # is not valid for character, line or block selection.
  proc handle_i {txtt} {

    check_item $txtt object inner

  }

  ######################################################################
  # Handles the user hitting the "o" key which will adjust the selection
  # to include the "outer" portion of the current selection type.  This
  # is not valid for character, line or block selection.
  proc handle_o {txtt} {

    check_item $txtt object outer

  }

  ######################################################################
  # Sets the current selection type to character mode.
  proc handle_c {txtt} {

    check_item $txtt type char

  }

  ######################################################################
  # Sets the current selection type to line mode.
  proc handle_l {txtt} {

    check_item $txtt type line

  }

  ######################################################################
  # Sets the current selection type to block mode.
  proc handle_b {txtt} {

    check_item $txtt type block

  }

  ######################################################################
  # Set the current selection type to word mode.
  proc handle_w {txtt} {

    check_item $txtt type word

  }

  ######################################################################
  # Set the current selection type to WORD mode.
  proc handle_n {txtt} {

    check_item $txtt type nonws

  }

  ######################################################################
  # Set the current selection type to sentence mode.
  proc handle_s {txtt} {

    check_item $txtt type sentence

  }

  ######################################################################
  # Set the current selection type to paragraph mode.
  proc handle_p {txtt} {

    check_item $txtt type paragraph

  }

  ######################################################################
  # Set the current selection type to tag mode.
  proc handle_t {txtt} {

    check_item $txtt type tag

  }

  ######################################################################
  # Set the current selection type to curly mode.
  proc handle_braceleft {txtt} {

    check_item $txtt type curly

  }

  ######################################################################
  # Set the current selection type to parenthesis mode.
  proc handle_parenleft {txtt} {

    check_item $txtt type paren

  }

  ######################################################################
  # Set the current selection type to angled mode.
  proc handle_less {txtt} {

    check_item $txtt type angled

  }

  ######################################################################
  # Set the current selection type to square mode.
  proc handle_bracketleft {txtt} {

    check_item $txtt type square

  }

  ######################################################################
  # Set the current selection type to double quote mode.
  proc handle_quotedbl {txtt} {

    check_item $txtt type double

  }

  ######################################################################
  # Set the current selection type to single quote mode.
  proc handle_quoteright {txtt} {

    check_item $txtt type single

  }

  ######################################################################
  # Set the current selection type to backtick mode.
  proc handle_quoteleft {txtt} {

    check_item $txtt type btick

  }

  ######################################################################
  # Handles moving the selection back by the selection type amount.
  proc handle_Left {txtt} {

    update_selection $txtt prev

  }

  ######################################################################
  # Handles moving the selection forward by the selection type amount.
  proc handle_Right {txtt} {

    update_selection $txtt next

  }

  ######################################################################
  # Handles moving the entire selection to include the parent of the
  # currently selected text.
  proc handle_Up {txtt} {

    update_selection $txtt parent

  }

  ######################################################################
  # Handles moving the entire selection to include just the first child
  # of the currently selected text.
  proc handle_Down {txtt} {

    update_selection $txtt child

  }

  ######################################################################
  # Changes the selection anchor to the other side of the selection.
  proc handle_a {txtt} {

    variable data

    # If the selection type is block mode, don't change anything
    if {$data($txtt,type) eq "block"} {
      return
    }

    # Change the anchor end
    set data($txtt,anchorend) [expr $data($txtt,anchorend) ^ 1]

    # Set the anchor
    set data($txtt,anchor) [lindex [$txtt tag ranges sel] $data($txtt,anchorend)]

  }

}
