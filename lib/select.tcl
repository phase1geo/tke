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

  array set motions   {}
  array set data      {}
  array set positions {
    char      {dchar     dchar}
    block     {dchar     dchar}
    line      {linestart lineend}
    word      {wordstart {wordend   -forceadjust "+1 display chars"}}
    sentence  {sentence  sentence}
    paragraph {paragraph paragraph}
    node      {tagstart  {tagend    -forceadjust "+1 display chars"}}
    square    {{char -char \[} {char -char \]}}
    curly     {{char -char \{} {char -char \}}}
    paren     {{char -char \(} {char -char \)}}
    angled    {{char -char <}  {char -char >}}
    double    {{char -char \"} {char -char \"}}
    single    {{char -char \'} {char -char \'}}
    btick     {{char -char \`} {char -char \`}}
  }
  variable types [list \
    [list [msgcat::mc "Character"]       c  char] \
    [list [msgcat::mc "Word"]            w  word] \
    [list [msgcat::mc "Line"]            e  line] \
    [list [msgcat::mc "Sentence"]        s  sentence] \
    [list [msgcat::mc "Paragraph"]       p  paragraph] \
    [list [msgcat::mc "Node"]            n  node] \
    [list [msgcat::mc "Square Brackets"] \[ square] \
    [list [msgcat::mc "Parenthesis"]     \( paren] \
    [list [msgcat::mc "Curly Brackets"]  \{ curly] \
    [list [msgcat::mc "Angled Brackets"] \< angled] \
    [list [msgcat::mc "Double Quotes"]   \" double] \
    [list [msgcat::mc "Single Quotes"]   \' single] \
    [list [msgcat::mc "Backticks"]       \` btick] \
    [list [msgcat::mc "Block"]           b  block] \
  ]

  ######################################################################
  # Adds bindings for selection mode.  Returns the hierarchical reference
  # to the select mode bar widget which needs to be packed into a grid
  # controlled layout manager and hidden from view.
  proc add {txt frame} {

    variable data

    set data($txt.t,mode)       0
    set data($txt.t,type)       none
    set data($txt.t,anchor)     1.0
    set data($txt.t,anchorend)  0
    set data($txt.t,moved)      0
    set data($txt.t,dont_close) 0

    bind select <<Selection>>                   [list select::handle_selection %W]
    bind select <FocusOut>                      [list select::handle_focusout %W]
    bind select <Key>                           "if {\[select::handle_any %W %K\]} break"
    bind select <Return>                        "if {\[select::handle_return %W\]} break"
    bind select <Escape>                        "if {\[select::handle_escape %W\]} break"
    bind select <BackSpace>                     "if {\[select::handle_backspace %W\]} break"
    bind select <Delete>                        "if {\[select::handle_delete %W\]} break"
    # bind select <ButtonPress-1>           "if {\[select::handle_single_press %W %x %y\]} break"
    # bind select <ButtonRelease-1>         "if {\[select::handle_single_release %W %x %y\]} break"
    # bind select <B1-Motion>               "if {\[select::handle_motion %W %x %y\]} break"
    bind select <Double-Button-1>               "if {\[select::handle_double_click %W %x %y\]} break"
    bind select <Triple-Button-1>               "if {\[select::handle_triple_click %W %x %y\]} break"
    bind select <Alt-ButtonPress-1>             "if {\[select::handle_single_press %W %x %y\]} break"
    bind select <Alt-ButtonRelease-1>           "if {\[select::handle_single_release %W %x %y\]} break"
    bind select <Alt-B1-Motion>                 "if {\[select::handle_alt_motion %W %x %y\]} break"
    bind select <Control-Double-Button-1>       "if {\[select::handle_control_double_click %W %x %y\]} break"
    bind select <Control-Triple-Button-1>       "if {\[select::handle_control_triple_click %W %x %y\]} break"
    bind select <Shift-Control-Double-Button-1> "if {\[select::handle_shift_control_double_click %W %x %y\]} break"
    bind select <Shift-Control-Triple-Button-1> "if {\[select::handle_shift_control_triple_click %W %x %y\]} break"

    bindtags $txt.t [linsert [bindtags $txt.t] [expr [lsearch [bindtags $txt.t] $txt.t] + 1] select]

    # Use the selection background color
    set bg [$txt.t cget -selectbackground]
    set fg [$txt.t cget -selectforeground]

  }

  ######################################################################
  # Creates the selection mode bar which displays the currently selected
  # modes, their key bindings and their description.
  proc show_help {txtt} {

    variable types
    variable data

    if {[winfo exists .selhelp]} {
      return
    }

    # Create labels and their shortcuts
    set left   [list [msgcat::mc "Left"]                 "j"]
    set right  [list [msgcat::mc "Right"]                "k"]
    set up     [list [msgcat::mc "Up"]                   "i"]
    set down   [list [msgcat::mc "Down"]                 "m"]
    set lshift [list [msgcat::mc "Shift Left"]           "H"]
    set rshift [list [msgcat::mc "Shift Right"]          "L"]
    set ushift [list [msgcat::mc "Shift Up"]             "K"]
    set dshift [list [msgcat::mc "Shift Down"]           "J"]
    set next   [list [msgcat::mc "Next"]                 "l"]
    set prev   [list [msgcat::mc "Previous"]             "h"]
    set parent [list [msgcat::mc "Parent"]               "k"]
    set child  [list [msgcat::mc "First Child"]          "j"]
    set swap   [list [msgcat::mc "Swap Anchor"]          "a"]
    set help   [list [msgcat::mc "Toggle Help"]          "?"]
    set ret    [list [msgcat::mc "Keep Selection"]       "\u21b5"]
    set esc    [list [msgcat::mc "Clear Selection"]      "Esc"]
    set del    [list [msgcat::mc "Delete Selected Text"] "Del"]

    toplevel            .selhelp
    wm transient        .selhelp .
    wm overrideredirect .selhelp 1

    ttk::label     .selhelp.title -text [msgcat::mc "Selection Mode Command Help"] -anchor center -padding 4
    ttk::separator .selhelp.sep -orient horizontal
    ttk::frame     .selhelp.f

    ttk::labelframe .selhelp.f.types -text [msgcat::mc "Modes"]
    create_list .selhelp.f.types $types $txtt

    ttk::labelframe .selhelp.f.motions -text [msgcat::mc "Motions"]
    switch $data($txtt,type) {
      char -
      block {
        create_list .selhelp.f.motions [list $left $right $up $down $lshift $rshift $ushift $dshift]
      }
      word -
      sentence -
      paragraph {
        create_list .selhelp.f.motions [list $next $prev $lshift $rshift]
      }
      line {
        create_list .selhelp.f.motions [list $next $prev $ushift $dshift]
      }
      node {
        create_list .selhelp.f.motions [list $next $prev $parent $child]
      }
      default {
        # Nothing to display
      }
    }

    ttk::labelframe .selhelp.f.anchors -text [msgcat::mc "Anchor"]
    create_list .selhelp.f.anchors [list $swap]

    ttk::labelframe .selhelp.f.help -text [msgcat::mc "Help"]
    create_list .selhelp.f.help [list $help]

    ttk::labelframe .selhelp.f.exit -text [msgcat::mc "Exit Selection Mode"]
    create_list .selhelp.f.exit [list $ret $esc $del]

    # Pack the labelframes
    grid .selhelp.f.types   -row 0 -column 0 -sticky news -padx 2 -pady 2 -rowspan 4
    grid .selhelp.f.motions -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .selhelp.f.anchors -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid .selhelp.f.help    -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid .selhelp.f.exit    -row 3 -column 1 -sticky news -padx 2 -pady 2

    pack .selhelp.title -fill x
    pack .selhelp.sep   -fill x
    pack .selhelp.f     -fill both -expand yes

    # Place the window in the middle of the main window
    ::tk::PlaceWindow .selhelp widget .

  }

  ######################################################################
  # Hide the help window from view.
  proc hide_help {} {

    # Destroy the help window if it is displayed
    catch { destroy .selhelp }

  }

  ######################################################################
  # Create the motions list.
  proc create_list {w items {txtt ""}} {

    variable data

    set i 0

    foreach item $items {
      lassign $item lbl shortcut type
      if {$type ne ""} {
        grid [ttk::label $w.c$i -text [expr {($data($txtt,type) eq $type) ? "\u2713" : " "}]] -row $i -column 0 -sticky news -padx 2 -pady 2
      }
      grid [ttk::label $w.s$i -text $shortcut -anchor e -width 3] -row $i -column 1 -sticky news -padx 4 -pady 2
      grid [ttk::label $w.l$i -text $lbl -anchor w -width 20]     -row $i -column 2 -sticky news -padx 2 -pady 2
      incr i
    }

  }

  ######################################################################
  # Set the type information
  proc set_type {txtt value {init 1}} {

    variable data

    # Set the type
    set data($txtt,type) $value

    # Update the selection
    if {$data($txtt,mode) && $init} {
      if {$value eq "paragraph"} {
        return
      }
      update_selection $txtt init
    }

  }

  ######################################################################
  # Updates the current selection based on the current type
  # selections along with the given motion type (init, next, prev, parent,
  # child).
  proc update_selection {txtt motion args} {

    variable data
    variable positions

    array set opts {
      -startpos ""
    }
    array set opts $args

    # Get the current selection ranges
    set range [$txtt tag ranges sel]

    # If we have already moved, change an init motion to a next/prev
    # motion based on the anchorend.
    if {$data($txtt,moved) && ($motion eq "init")} {
      set motion [expr {$data($txtt,anchorend) ? "prev" : "next"}]
    }

    switch $motion {
      init {
        if {$opts(-startpos) eq ""} {
          $txtt mark set insert $data($txtt,anchor)
        } else {
          $txtt mark set insert $opts(-startpos)
        }
        switch $data($txtt,type) {
          char -
          block   { set range [list $data($txtt,anchor) "$data($txtt,anchor)+1 display chars"] }
          line    { set range [edit::get_range $txtt linestart lineend "" 0] }
          word    {
            if {[string is space [$txtt get insert]]} {
              set wstart [edit::get_index $txtt wordstart -dir next]
              if {[$txtt compare $wstart > "insert lineend"]} {
                set wstart [edit::get_index $txtt wordstart -dir prev]
              }
              $txtt mark set insert $wstart
            }
            set range [edit::get_range $txtt [list $data($txtt,type) 1] [list] i 0]
          }
          sentence -
          paragraph {
            return
            set range [edit::get_range $txtt [list $data($txtt,type) 1] [list] o 0]
          }
          node      { set range [edit::get_range $txtt [list "tag" 1] [list] o 0] }
          default   { set range [edit::get_range $txtt [list $data($txtt,type) 1] [list] i 0] }
        }
      }
      next -
      prev {
        set pos   $positions($data($txtt,type))
        set index [expr $data($txtt,anchorend) ^ 1]
        switch $data($txtt,type) {
          line {
            set count ""
            if {[$txtt compare [lindex $range $index] == "[lindex $range $index] [lindex $pos $index]"]} {
              set count [expr {($motion eq "next") ? "+1 display lines" : "-1 display lines"}]
            }
            lset range $index [$txtt index "[lindex $range $index]$count [lindex $pos $index]"]
          }
          node {
            $txtt mark set insert [lindex $range 0]
            if {[set parent [emmet::get_outer [emmet::get_node_range_within [winfo parent $txtt]]]] ne ""} {
              if {$motion eq "next"} {
                if {$data($txtt,anchorend) == 1} {
                  set range [emmet::get_outer [emmet::get_node_range [winfo parent $txtt]]]
                }
                if {[set tag [emmet::get_tag [winfo parent $txtt] -dir next -type 1*0 -start [lindex $range 1]]] ne ""} {
                  $txtt mark set insert [lindex $tag 0]
                  set outer [emmet::get_outer [emmet::get_node_range [winfo parent $txtt]]]
                  if {[$txtt compare [lindex $parent 1] > [lindex $outer 1]]} {
                    if {$data($txtt,anchorend) == 0} {
                      lset range 1 [lindex $outer 1]
                    } else {
                      lset range 0 [lindex $outer 0]
                    }
                  }
                }
              } else {
                if {$data($txtt,anchorend) == 0} {
                  $txtt mark set insert "[lindex $range 1]-1c"
                  set range [emmet::get_outer [emmet::get_node_range [winfo parent $txtt]]]
                }
                if {[set tag [emmet::get_tag [winfo parent $txtt] -dir prev -type 0*1 -start [lindex $range 0]]] ne ""} {
                  $txtt mark set insert [lindex $tag 0]
                  set outer [emmet::get_outer [emmet::get_node_range [winfo parent $txtt]]]
                  if {[$txtt compare [lindex $parent 0] < [lindex $outer 0]]} {
                    if {$data($txtt,anchorend) == 0} {
                      lset range 1 [lindex $outer 1]
                    } else {
                      lset range 0 [lindex $outer 0]
                    }
                  }
                }
              }
            }
          }
          default {
            if {($index == 1) && ($motion eq "prev") && ([lsearch [list word tag] $data($txtt,type)] != -1)} {
              lset range 1 [$txtt index "[lindex $range 1]-1 display chars"]
            }
            if {$opts(-startpos) ne ""} {
              lset range $index [edit::get_index $txtt {*}[lindex $pos $index] -dir $motion -startpos $opts(-startpos)]
            } else {
              lset range $index [edit::get_index $txtt {*}[lindex $pos $index] -dir $motion -startpos [lindex $range $index]]
            }
          }
        }
        if {([lindex $range $index] eq "") || [$txtt compare [lindex $range 0] >= [lindex $range 1]]} {
          return
        }
        set data($txtt,moved) 1
      }
      rshift -
      lshift {
        if {$data($txtt,type) eq "block"} {
          set trange $range
          if {$motion eq "rshift"} {
            set range [list]
            foreach {startpos endpos} $trange {
              lappend range [$txtt index "$startpos+1 display chars"]
              if {[$txtt compare "$endpos+1 display chars" < "$endpos lineend"]} {
                lappend range [$txtt index "$endpos+1 display chars"]
              } else {
                lappend range [$txtt index "$endpos lineend"]
              }
            }
          } elseif {[$txtt compare "[lindex $range 0]-1 display chars" >= "[lindex $range 0] linestart"]} {
            set range [list]
            foreach {startpos endpos} $trange {
              lappend range [$txtt index "$startpos-1 display chars"] [$txtt index "$endpos-1 display chars"]
            }
          }
        } else {
          set pos   $positions($data($txtt,type))
          set dir   [expr {($motion eq "rshift") ? "next" : "prev"}]
          if {($motion eq "lshift") && ([lsearch [list word tag] $data($txtt,type)] != -1)} {
            lset range 1 [$txtt index "[lindex $range 1]-1 display chars"]
          }
          foreach index {0 1} {
            lset range $index [edit::get_index $txtt {*}[lindex $pos $index] -dir $dir -startpos [lindex $range $index]]
          }
        }
      }
      ushift {
        if {[$txtt compare "[lindex $range 0]-1 display lines" < [lindex $range 0]]} {
          switch $data($txtt,type) {
            line {
              if {[$txtt compare [lindex $range 0] > 1.0]} {
                lset range 0 [$txtt index "[lindex $range 0]-1 display lines linestart"]
                lset range 1 [$txtt index "[lindex $range 1]-1 display lines lineend"]
              }
            }
            node {
              $txtt mark set insert [lindex $range 0]
              if {[set parent [emmet::get_outer [emmet::get_node_range_within [winfo parent $txtt]]]] ne ""} {
                if {[set tag [emmet::get_tag [winfo parent $txtt] -dir prev -type 0*1 -start [lindex $range 0]]] ne ""} {
                  $txtt mark set insert [lindex $tag 0]
                  set outer [emmet::get_outer [emmet::get_node_range [winfo parent $txtt]]]
                  if {[$txtt compare [lindex $parent 0] < [lindex $outer 0]]} {
                    set range $outer
                  }
                }
              }
            }
            default {
              set trange $range
              set range  [list]
              foreach {pos} $trange {
                lappend range [$txtt index "$pos-1 display lines"]
              }
            }
          }
        }
      }
      dshift {
        if {[$txtt compare "[lindex $range end]+1 display lines" > "[lindex $range end] lineend"]} {
          switch $data($txtt,type) {
            line {
              if {[$txtt compare [lindex $range 1] < "end-1 display lines lineend"]} {
                lset range 1 [$txtt index "[lindex $range 1]+1 display lines lineend"]
                lset range 0 [$txtt index "[lindex $range 0]+1 display lines linestart"]
              }
            }
            node {
              $txtt mark set insert [lindex $range 0]
              if {[set parent [emmet::get_outer [emmet::get_node_range_within [winfo parent $txtt]]]] ne ""} {
                if {[set tag [emmet::get_tag [winfo parent $txtt] -dir next -type 1*0 -start [lindex $range 1]]] ne ""} {
                  $txtt mark set insert [lindex $tag 0]
                  set outer [emmet::get_outer [emmet::get_node_range [winfo parent $txtt]]]
                  if {[$txtt compare [lindex $parent 1] > [lindex $outer 1]]} {
                    set range $outer
                  }
                }
              }
            }
            default {
              set trange $range
              set range  [list]
              foreach {pos} $trange {
                lappend range [$txtt index "$pos+1 display lines"]
              }
            }
          }
        }
      }
      left {
        if {$data($txtt,anchorend) == 1} {
          set i 0
          foreach {startpos endpos} $range {
            if {[$txtt compare "$startpos-1 display chars" >= "$startpos linestart"]} {
              lset range $i [$txtt index "$startpos-1 display chars"]
              incr i 2
            }
          }
        } else {
          set i 1
          foreach {startpos endpos} $range {
            if {[$txtt compare "$endpos-1 display chars" > $startpos]} {
              lset range $i [$txtt index "$endpos-1 display chars"]
            }
            incr i 2
          }
        }
      }
      right {
        if {$data($txtt,anchorend) == 1} {
          set i 0
          foreach {startpos endpos} $range {
            if {[$txtt compare "$startpos+1 display chars" < $endpos]} {
              lset range $i [$txtt index "$startpos+1 display chars"]
            }
            incr i 2
          }
        } else {
          set i 1
          foreach {startpos endpos} $range {
            if {[$txtt compare "$endpos+1 display chars" <= "$endpos lineend"]} {
              lset range $i [$txtt index "$endpos+1 display chars"]
            }
            incr i 2
          }
        }
      }
      up {
        if {$data($txtt,anchorend) == 1} {
          if {[$txtt compare "[lindex $range 0]-1 display lines" > 1.0]} {
            set range [list [$txtt index "[lindex $range 0]-1 display lines"] [$txtt index "[lindex $range 1]-1 display lines"] {*}$range]
          }
        } else {
          if {[$txtt compare "[lindex $range end-1]-1 display lines" >= [lindex $range 0]]} {
            set range [lreplace $range end-1 end]
          }
        }
      }
      down {
        if {$data($txtt,anchorend) == 1} {
          if {[$txtt compare "[lindex $range 0]+1 display lines" <= [lindex $range end-1]]} {
            set range [lreplace $range 0 1]
          }
        } else {
          if {[$txtt compare "[lindex $range end-1]+1 display lines" < end]} {
            lappend range [$txtt index "[lindex $range end-1]+1 display lines"] [$txtt index "[lindex $range end]+1 display lines"]
          }
        }
      }
      parent {
        $txtt mark set insert [lindex $range 0]
        if {[set node_range [emmet::get_node_range_within [winfo parent $txtt]]] ne ""} {
          set range [list [lindex $node_range 0] [lindex $node_range 3]]
        }
      }
      child {
        $txtt mark set insert [lindex $range 0]
        set inner [emmet::get_inner [emmet::get_node_range [winfo parent $txtt]]]
        $txtt mark set insert [lindex [emmet::get_inner [emmet::get_node_range [winfo parent $txtt]]] 0]
        if {([set retval [emmet::get_tag [winfo parent $txtt] -dir next -type 100]] ne "") && ([lindex $retval 4] eq "")} {
          $txtt mark set insert [lindex $retval 0]
          set range [emmet::get_outer [emmet::get_node_range [winfo parent $txtt]]]
        }
      }
    }

    # If the range was not set to a valid range, return now
    if {[set cursor [lindex $range [expr {$data($txtt,anchorend) ? 0 : "end"}]]] eq ""} {
      return
    }

    # Set the cursor and selection
    $txtt mark set insert $cursor
    $txtt see $cursor
    clear_selection $txtt
    $txtt tag add sel {*}$range

  }

  ######################################################################
  # Clears the selection in such a way that will keep selection mode
  # enabled.
  proc clear_selection {txtt} {

    variable data

    # Indicate to handle_selection that we don't want to exit selection mode
    set data($txtt,dont_close) 1

    # Clear the selection
    $txtt tag remove sel 1.0 end

  }

  ######################################################################
  # Returns true if the given text widget is currently in selection mode;
  # otherwise, returns false.
  proc in_select_mode {txtt} {

    variable data

    if {![info exists data($txtt,mode)]} {
      return 0
    }

    return $data($txtt,mode)

  }

  ######################################################################
  # Sets the selection mode for the given text widget to the given value.
  # This will cause the selection bar to appear or disappear as needed.
  proc set_select_mode {txtt value} {

    variable data

    # Set the mode
    if {$data($txtt,mode) != $value} {

      # Set the mode to the given value
      set data($txtt,mode) $value

      # If we are enabled, do some initializing
      if {$value} {

        set data($txtt,anchor) [$txtt index insert]
        set data($txtt,moved)  0

        # If text was not previously selected, select it by word
        if {[set sel [$txtt tag ranges sel]] eq ""} {
          set_type $txtt "word" 1
        } elseif {$data($txtt,type) eq "none"} {
          set_type $txtt "char" 0
        }

        # Configure the cursor
        $txtt configure -cursor [ttk::cursor standard]

        # Use the selection background color
        set bg [$txtt cget -selectbackground]
        set fg [$txtt cget -selectforeground]

        # Display a help message
        gui::set_info_message [msgcat::mc "Type '?' for help.  Hit the ESCAPE key to exit selection mode"] 0

      # Otherwise, configure the cursor
      } else {

        $txtt configure -cursor ""

        # Clear the help message
        gui::set_info_message ""

      }

      # Make sure that the information bar is updated appropriately
      gui::update_position [winfo parent $txtt]

    }

  }

  ######################################################################
  # If we ever lose the selection, automatically exit selection mode.
  proc handle_selection {txtt} {

    variable data

    if {([$txtt tag ranges sel] eq "") && !$data($txtt,dont_close)} {
      set_select_mode $txtt 0
    }

    # Clear the dont_close indicator
    set data($txtt,dont_close) 0

    # Hide the help display if it is in view
    hide_help

  }

  ######################################################################
  # Handles a FocusOut event on the given text widget.
  proc handle_focusout {txtt} {

    # Hide the help window if we lose focus
    hide_help

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

    # Allow Vim to remember this selection
    vim::set_last_selection $txtt

    # Hide the help window if it is displayed
    hide_help

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

    # Clear the selection
    $txtt tag remove sel 1.0 end

    return 1

  }

  ######################################################################
  # Handles the BackSpace key when in selection mode.  Ends selection
  # mode and deletes the selected text.
  proc handle_backspace {txtt} {

    variable data

    if {$data($txtt,mode) == 0} {
      return 0
    }

    # Delete the text
    if {![multicursor::delete $txtt [list char -dir prev] ""]} {
      edit::delete $txtt {*}[lrange [$txtt tag ranges sel] 0 1] 1 1
    }

    # Disable selection mode
    set_select_mode $txtt 0

    # Hide the help window
    hide_help

    return 1

  }

  ######################################################################
  # Handles the BackSpace or Delete key when in selection mode.  Ends
  # selection mode and deletes the selected text.
  proc handle_delete {txtt} {

    variable data

    if {$data($txtt,mode) == 0} {
      return 0
    }

    # Delete the text
    if {![multicursor::delete $txtt [list char -dir next] ""]} {
      edit::delete $txtt {*}[lrange [$txtt tag ranges sel] 0 1] 1 1
    }

    # Disable selection mode
    set_select_mode $txtt 0

    # Hide the help window
    hide_help

    return 1

  }

  ######################################################################
  # Handle a single click event press event.
  proc handle_single_press {txtt x y} {

    variable data

    # Change the anchor end
    set data($txtt,anchorend) 0

    # Set the anchor
    set data($txtt,anchor) [$txtt index @$x,$y]

    # Set the insertion cursor
    $txtt mark set insert $data($txtt,anchor)

    return 0

  }

  ######################################################################
  # Handle a single click event release event.
  proc handle_single_release {txtt x y} {

    return 1

  }

  ######################################################################
  # Handles a double-click event within the editing buffer.
  proc handle_double_click {txtt x y} {

    # Set the selection type to inner word
    set_type $txtt word

    return 0

  }

  ######################################################################
  # Handles a double-click while the Control key is pressed.  Selects the
  # current sentence.
  proc handle_control_double_click {txtt x y} {

    # Set the selection type to sentence
    set_type $txtt sentence

    # Update the selection
    update_selection $txtt init -startpos [$txtt index @$x,$y]

    return 1

  }

  ######################################################################
  # Handles a double-click event while the Shift-Control keys are held.
  # Selects the current square, curly, paren, single, double, backtick or tag.
  proc handle_shift_control_double_click {txtt x y} {

    set type ""

    # If we are within a comment, return
    if {[ctext::inComment $txtt @$x,$y]} {
      return 0
    } elseif {[ctext::inString $txtt @$x,$y]} {
      if {[ctext::inSingleQuote $txtt @$x,$y]} {
        set type single
      } elseif {[ctext::inDoubleQuote $txtt @$x,$y]} {
        set type double
      } else {
        set type btick
      }
    } else {
      set closest ""
      foreach t [list square curly paren angled] {
        if {[lsearch -regexp [$txtt tag names @$x,$y] "_${t}\[LR\]"] != -1} {
          set type $t
          break
        } elseif {[set index [ctext::get_match_bracket [winfo parent $txtt] ${t}L [$txtt index @$x,$y]]] ne ""} {
          if {($closest eq "") || [$txtt compare $index > $closest]} {
            set type    $t
            set closest $index
          }
        }
      }
    }

    # If we found a type, select the block
    if {$type ne ""} {
      set_type $txtt $type
      update_selection $txtt init -startpos [$txtt index @$x,$y]
    }

    return 1

  }

  ######################################################################
  # Handles a triple-click event within the editing buffer.  Selects a
  # line of text.
  proc handle_triple_click {txtt x y} {

    # Set the selection type to inner line
    set_type $txtt line

    return 0

  }

  ######################################################################
  # Handles a triple-click when the Control key is down.  Selects a paragraph
  # of text.
  proc handle_control_triple_click {txtt x y} {

    # Set the selection type to paragraph
    set_type $txtt paragraph

    # Update the selection
    update_selection $txtt init -startpos [$txtt index @$x,$y]

    return 1

  }

  ######################################################################
  # Handles a triple-click while the Shift-Control keys are held.  Selects
  # the current XML node.
  proc handle_shift_control_triple_click {txtt x y} {

    variable data

    if {$data($txtt,mode) && ($data($txtt,type) eq "node")} {
      return 1
    }

    # Set the insertion cursor
    $txtt mark set insert @$x,$y

    # Enable selection mode
    set_select_mode $txtt 1

    # Set the selection type to node
    set_type $txtt node

    return 1

  }

  ######################################################################
  # Handles any B1-Motion events occurring inside the text widget.
  proc handle_motion {txtt x y} {

    variable data

    # If we are not in selection mode, return immediately
    if {$data($txtt,mode) == 0} {
      $txtt mark set insert @$x,$y
      set_select_mode $txtt 1
      set_type $txtt char
      return 1
    }

    # If we are not dragging a selection tag, return immediately
    if {![info exists data($txtt,drag)]} {
      if {[$txtt compare @$x,$y < $data($txtt,anchor)]} {
        update_selection $txtt prev -startpos [$txtt index @$x,$y]
      } else {
        update_selection $txtt next -startpos [$txtt index @$x,$y]
      }
      return 1
    }

    if {0} {
    # Get the last drag position
    lassign $data($txtt,drag) tag

    # Figure out which direction we are moving
    set left [$txtt compare @$x,$y < [lindex [$txtt tag ranges $tag] 0]]

    # Update the selection
    switch $tag {
      select_sel {
        update_selection $txtt [expr {$left ? "lshift" : "rshift"}]
      }
      select_begin {
        set data($txtt,anchorend) 1
        if {[$txtt compare @$x,$y < [lindex [$txtt tag ranges $tag] 0]]} {
          update_selection $txtt prev -startpos [$txtt index @$x,$y]
        } else {
          update_selection $txtt [expr {$left ? "prev" : "next"}] -startpos [$txtt index @$x,$y]
        }
      }
      select_end {
        set data($txtt,anchorend) 0
        update_selection $txtt [expr {$left ? "prev" : "next"}] -startpos [$txtt index @$x,$y]
      }
    }
    }

    return 1

  }

  ######################################################################
  # Performs the block selection.
  proc handle_block_selection {txtt anchor current} {

    # Get the anchor and current row/col, but if either is invalid, return immediately
    if {[set acol [lassign [split $anchor  .] arow]] eq ""} {
      return
    }
    if {[set ccol [lassign [split $current .] crow]] eq ""} {
      return
    }

    if {$arow < $crow} {
      set srow $arow
      set erow $crow
    } else {
      set srow $crow
      set erow $arow
    }

    if {$acol < $ccol} {
      set scol $acol
      set ecol $ccol
    } else {
      set scol $ccol
      set ecol $acol
    }

    # Set the selection
    clear_selection $txtt
    for {set i $srow} {$i <= $erow} {incr i} {
      $txtt tag add sel $i.$scol $i.$ecol
    }

  }

  ######################################################################
  # Performs a block selection.
  proc handle_alt_motion {txtt x y} {

    variable data

    handle_block_selection $txtt $data($txtt,anchor) [$txtt index @$x,$y]

    return 1

  }

  ######################################################################
  # Handles any other entered keys when in selection mode.
  proc handle_any {txtt keysym} {

    variable data

    if {$data($txtt,mode) == 0} {
      return 0
    }

    # Check to see if the selection window exists
    set help_existed [winfo exists .selhelp]

    # Handle the specified key, if a handler exists for it
    if {[info procs handle_$keysym] ne ""} {
      handle_$keysym $txtt
    }

    # Hide the help window if it is displayed
    if {$help_existed} {
      hide_help
    }

    return 1

  }

  ######################################################################
  # Sets the current selection type to character mode.
  proc handle_c {txtt} {

    # Make sure that char is selected
    set_type $txtt char

  }

  ######################################################################
  # Sets the current selection type to line mode.
  proc handle_e {txtt} {

    set_type $txtt line

  }

  ######################################################################
  # Sets the current selection type to block mode.
  proc handle_b {txtt} {

    set_type $txtt block

  }

  ######################################################################
  # Set the current selection type to word mode.
  proc handle_w {txtt} {

    set_type $txtt word

  }

  ######################################################################
  # Set the current selection type to sentence mode.
  proc handle_s {txtt} {

    set_type $txtt sentence

  }

  ######################################################################
  # Set the current selection type to paragraph mode.
  proc handle_p {txtt} {

    set_type $txtt paragraph

  }

  ######################################################################
  # Set the current selection type to node mode.
  proc handle_n {txtt} {

    set_type $txtt node

  }

  ######################################################################
  # Set the current selection type to curly mode.
  proc handle_braceleft {txtt} {

    set_type $txtt curly

  }

  ######################################################################
  # Set the current selection type to parenthesis mode.
  proc handle_parenleft {txtt} {

    set_type $txtt paren

  }

  ######################################################################
  # Set the current selection type to angled mode.
  proc handle_less {txtt} {

    set_type $txtt angled

  }

  ######################################################################
  # Set the current selection type to square mode.
  proc handle_bracketleft {txtt} {

    set_type $txtt square

  }

  ######################################################################
  # Set the current selection type to double quote mode.
  proc handle_quotedbl {txtt} {

    set_type $txtt double

  }

  ######################################################################
  # Set the current selection type to single quote mode.
  proc handle_quoteright {txtt} {

    set_type $txtt single

  }

  ######################################################################
  # Set the current selection type to backtick mode.
  proc handle_quoteleft {txtt} {

    set_type $txtt btick

  }

  ######################################################################
  # Handles moving the selection back by the selection type amount.
  proc handle_H {txtt} {

    variable data

    switch $data($txtt,type) {
      line    {}
      node    { update_selection $txtt parent }
      default { update_selection $txtt lshift }
    }

  }

  ######################################################################
  # Handles moving the selection forward by the selection type amount.
  proc handle_L {txtt} {

    variable data

    switch $data($txtt,type) {
      line    {}
      node    { update_selection $txtt child }
      default { update_selection $txtt rshift }
    }

  }

  ######################################################################
  # Handles moving the entire selection to include the parent of the
  # currently selected text.
  proc handle_K {txtt} {

    variable data

    switch $data($txtt,type) {
      char  -
      block -
      node  -
      line  { update_selection $txtt ushift }
    }

  }

  ######################################################################
  # Handles moving the entire selection to include just the first child
  # of the currently selected text.
  proc handle_J {txtt} {

    variable data

    switch $data($txtt,type) {
      char  -
      block -
      node  -
      line  { update_selection $txtt dshift }
    }

  }

  ######################################################################
  # Handles moving the entire selection to the left by the current type.
  proc handle_h {txtt} {

    variable data

    switch $data($txtt,type) {
      node    { update_selection $txtt parent }
      block   { update_selection $txtt left }
      default { update_selection $txtt prev }
    }

  }

  ######################################################################
  # Handles moving the entire selection to the right by the current type.
  proc handle_l {txtt} {

    variable data

    switch $data($txtt,type) {
      node    { update_selection $txtt child }
      block   { update_selection $txtt right }
      default { update_selection $txtt next }
    }

  }

  ######################################################################
  # If the selection mode is char or block, handles moving the cursor up
  # a line (carries the selection with it).
  proc handle_k {txtt} {

    variable data

    switch $data($txtt,type) {
      char  -
      block { update_selection $txtt up }
      node  -
      line  { update_selection $txtt prev }
    }

  }

  ######################################################################
  # If the selection mode is char or block, handles moving the cursor
  # down a line (carries the selection with it).
  proc handle_j {txtt} {

    variable data

    switch $data($txtt,type) {
      char  -
      block { update_selection $txtt down }
      node  -
      line  { update_selection $txtt next }
    }

  }

  ######################################################################
  # Changes the selection anchor to the other side of the selection.
  proc handle_a {txtt} {

    variable data

    # Get the selected ranges (if none is set, return immediately)
    if {[set sel [$txtt tag ranges sel]] eq ""} {
      return
    }

    # Change the anchor end
    set data($txtt,anchorend) [expr $data($txtt,anchorend) ^ 1]

    # Set the anchor
    if {$data($txtt,anchorend)} {
      set data($txtt,anchor) [lindex $sel end]
      set cursor             [lindex $sel 0]
    } else {
      set data($txtt,anchor) [lindex $sel 0]
      set cursor             [lindex $sel end]
    }

    # Move the insertion cursor to the new anchor position
    $txtt mark set insert $cursor
    $txtt see $cursor

  }

  ######################################################################
  # Displays the cheatsheet.
  proc handle_question {txtt} {

    show_help $txtt

  }

  ######################################################################
  # Handles a button press on a given tag.
  proc press {txtt tag} {

    variable data

    set data($txtt,drag) $tag

  }

  ######################################################################
  # Handles a button release on a given tag.
  proc release {txtt} {

    variable data

    unset -nocomplain data($txtt,drag)

  }

  ######################################################################
  # Handles an enter event when the user enters the given tag.
  proc handle_enter {txtt tag} {

    # Get the base color of the selection
    set color [$txtt tag cget sel -background]

    # Set the color of the start/end tag to an adjusted color from the selection color
    $txtt tag configure $tag -background [utils::auto_adjust_color $color 40]

  }

  ######################################################################
  # Handles a leave event when the user leaves the given tag.
  proc handle_leave {txtt tag} {

    # Remove the background color of the tag
    $txtt tag configure $tag -background ""

  }

}
