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

  array set motions   {}
  array set data      {}
  array set positions {
    char      {dchar     dchar}
    block     {dchar     dchar}
    line      {linestart lineend}
    word      {wordstart {wordend   -forceadjust "+1 display chars"}}
    sentence  {sentence  sentence}
    paragraph {paragraph paragraph}
    tag       {tagstart  {tagend    -forceadjust "+1 display chars"}}
    square    {{char -char \[} {char -char \]}}
    curly     {{char -char \{} {char -char \}}}
    paren     {{char -char \(} {char -char \)}}
    angled    {{char -char <}  {char -char >}}
    double    {{char -char \"} {char -char \"}}
    single    {{char -char \'} {char -char \'}}
    btick     {{char -char \`} {char -char \`}}
  }
  variable types [list \
    [msgcat::mc "Character"]       c  char \
    [msgcat::mc "Word"]            w  word \
    [msgcat::mc "Line"]            l  line \
    [msgcat::mc "Sentence"]        s  sentence \
    [msgcat::mc "Paragraph"]       p  paragraph \
    [msgcat::mc "Tag"]             t  tag \
    [msgcat::mc "Square Brackets"] \[ square \
    [msgcat::mc "Parenthesis"]     \( paren \
    [msgcat::mc "Curly Brackets"]  \{ curly \
    [msgcat::mc "Angled Brackets"] \< angled \
    [msgcat::mc "Double Quotes"]   \" double \
    [msgcat::mc "Single Quotes"]   \' single \
    [msgcat::mc "Backticks"]       \` btick \
    [msgcat::mc "Block"]           b  block \
  ]

  ######################################################################
  # Adds bindings for selection mode.  Returns the hierarchical reference
  # to the select mode bar widget which needs to be packed into a grid
  # controlled layout manager and hidden from view.
  proc add {txt frame} {

    variable data

    set data($txt.t,mode)      0
    set data($txt.t,type)      none
    set data($txt.t,anchor)    1.0
    set data($txt.t,anchorend) 0
    set data($txt.t,bar)       [create_bar $txt.t $frame]
    set data($txt.t,moved)     0

    bind select <<Selection>>             [list select::handle_selection %W]
    bind select <Key>                     "if {\[select::handle_any %W %K\]} break"
    bind select <Return>                  "if {\[select::handle_return %W\]} break"
    bind select <Escape>                  "if {\[select::handle_escape %W\]} break"
    # bind select <ButtonPress-1>           "if {\[select::handle_single_press %W %x %y\]} break"
    # bind select <ButtonRelease-1>         "if {\[select::handle_single_release %W %x %y\]} break"
    # bind select <B1-Motion>               "if {\[select::handle_motion %W %x %y\]} break"
    bind select <Double-Button-1>         "if {\[select::handle_double_click %W %x %y\]} break"
    bind select <Triple-Button-1>         "if {\[select::handle_triple_click %W %x %y\]} break"
    # bind select <Mod2-ButtonPress-1>      "if {\[select::handle_single_press %W %x %y\]} break"
    # bind select <Mod2-ButtonRelease-1>    "if {\[select::handle_single_release %W %x %y\]} break"
    # bind select <Mod2-B1-Motion>          "if {\[select::handle_alt_motion %W %x %y\]} break"
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
  proc create_bar {txtt w} {

    variable motions
    variable types
    variable data
    
    # Create the UI
    ttk::frame      $w
    ttk::label      $w.l    -text [msgcat::mc "SELECT MODE"]
    ttk::menubutton $w.type -text "" -menu [menu $w.typeMenu -tearoff 0]
    ttk::label      $w.help -text ""
    ttk::button     $w.close -style BButton -image form_close
    
    pack $w.l     -side left -padx 2 -pady 2
    pack $w.type  -side left -padx 2 -pady 2
    pack $w.help  -side left -padx 2 -pady 2 -fill x
    pack $w.close -side right -padx 2 -pady 2
    
    # Populate the type menu
    $w.typeMenu add command -label [msgcat::mc "Selection Modes"] -state disabled
    $w.typeMenu add separator
    foreach {lbl accel value} $types {
      $w.typeMenu add radiobutton -label $lbl -accelerator $accel \
        -variable select::data($txtt,type) -value $value -command [list select::set_type $txtt $value]
    }
    
    set left   [list [msgcat::mc "Left"]        "j"]
    set right  [list [msgcat::mc "Right"]       "k"]
    set up     [list [msgcat::mc "Up"]          "i"]
    set down   [list [msgcat::mc "Down"]        "m"]
    set lshift [list [msgcat::mc "Shift Left"]  "\u2190"]
    set rshift [list [msgcat::mc "Shift Right"] "\u2192"]
    set ushift [list [msgcat::mc "Shift Up"]    "\u2191"]
    set dshift [list [msgcat::mc "Shift Down"]  "\u2193"]
    set next   [list [msgcat::mc "Next"]        "k"]
    set prev   [list [msgcat::mc "Previous"]    "j"]
    set parent [list [msgcat::mc "Parent"]      "i"]
    set child  [list [msgcat::mc "FirstChild"]  "m"]
    
    # Create motion help
    set motions(char)      [create_help $left $right $up $down $lshift $rshift $ushift $dshift]
    set motions(word)      [create_help $next $prev $lshift $rshift]
    set motions(line)      [create_help $next $prev $ushift $dshift]
    set motions(sentence)  $motions(word)
    set motions(paragraph) $motions(word)
    set motions(curly)     ""
    set motions(square)    ""
    set motions(paren)     ""
    set motions(angled)    ""
    set motions(single)    ""
    set motions(double)    ""
    set motions(btick)     ""
    set motions(tag)       [create_help $next $prev $parent $child]
    set motions(block)     $motions(char)

    return $w

  }
  
  ######################################################################
  # Creates a help string.
  proc create_help {args} {
    
    set help ""
    
    foreach item $args {
      lassign $item lbl shortcut
      append help [format " \[%s\] %s, " $shortcut $lbl]
    }
    
    append help [format " \[%s\] %s" "a" [msgcat::mc "Swap Anchor"]]
    
    return $help
    
  }
  
  ######################################################################
  # Set the type information
  proc set_type {txtt value {init 1}} {
    
    variable motions
    variable data
    variable types
    
    # Find the matching label
    set lbl [lindex $types [expr [lsearch $types $value] - 2]]
    
    # Update the bar UI
    $data($txtt,bar).type configure -text $lbl
    $data($txtt,bar).help configure -text $motions($value)
    
    # Set the type
    set data($txtt,type) $value
    
    # Update the selection
    if {$data($txtt,mode) && $init} {
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
          paragraph { set range [edit::get_range $txtt [list $data($txtt,type) 1] [list] o 0] }
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
          set trange $range
          set range  [list]
          foreach {pos} $trange {
            lappend range [$txtt index "$pos-1 display lines"]
          }
        }
      }
      dshift {
        if {[$txtt compare "[lindex $range end]+1 display lines" > "[lindex $range end] lineend"]} {
          set trange $range
          set range  [list]
          foreach {pos} $trange {
            lappend range [$txtt index "$pos+1 display lines"]
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
        # TBD
      }
      child {
        # TBD
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
  # Open the bar for view.  This should only be called by the
  # set_select_mode internal procedure.
  proc open_bar {txtt} {

    variable data

    # Make the bar visible
    place $data($txtt,bar) -in [winfo parent $data($txtt,bar)] -relx 0.0 -rely 1.0 -relwidth 1.0 -anchor sw

  }

  ######################################################################
  # Closes the selection mode bar from view.  This should only be
  # called by the set_select_mode internal procedure.
  proc close_bar {txtt} {

    variable data

    # Hide the bar
    place forget $data($txtt,bar)

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
  proc set_select_mode {txtt value args} {

    variable data

    # Set the mode
    if {$data($txtt,mode) != $value} {

      array set opts {
        -bar 1
      }
      array set opts $args

      # Set the mode to the given value
      set data($txtt,mode) $value

      # Show/Hide the bar
      if {$value == 0} {
        close_bar $txtt
      } elseif {$opts(-bar)} {
        open_bar $txtt
      }

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

      # Otherwise, configure the cursor
      } else {

        $txtt configure -cursor ""

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

    variable data

    # If selection mode is enabled, display the bar
    if {$data($txtt,mode)} {
      open_bar $txtt
    }

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
      return
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
      set_select_mode $txtt 1 -bar 0
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

    # Handle the specified key, if a handler exists for it
    if {[info procs handle_$keysym] ne ""} {
      handle_$keysym $txtt
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
  proc handle_l {txtt} {

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
  # Set the current selection type to tag mode.
  proc handle_t {txtt} {

    set_type $txtt tag

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
  proc handle_Left {txtt} {

    variable data

    if {$data($txtt,type) ne "line"} {
      update_selection $txtt lshift
    }

  }

  ######################################################################
  # Handles moving the selection forward by the selection type amount.
  proc handle_Right {txtt} {

    variable data

    if {$data($txtt,type) ne "line"} {
      update_selection $txtt rshift
    }

  }

  ######################################################################
  # Handles moving the entire selection to include the parent of the
  # currently selected text.
  proc handle_Up {txtt} {

    variable data

    if {[lsearch [list char block] $data($txtt,type)] != -1} {
      update_selection $txtt ushift
    }

  }

  ######################################################################
  # Handles moving the entire selection to include just the first child
  # of the currently selected text.
  proc handle_Down {txtt} {

    variable data

    if {[lsearch [list char block] $data($txtt,type)] != -1} {
      update_selection $txtt dshift
    }

  }

  ######################################################################
  # Handles moving the entire selection to the left by the current type.
  proc handle_j {txtt} {

    variable data

    if {$data($txtt,type) eq "block"} {
      update_selection $txtt left
    } else {
      update_selection $txtt prev
    }

  }

  ######################################################################
  # Handles moving the entire selection to the right by the current type.
  proc handle_k {txtt} {

    variable data

    if {$data($txtt,type) eq "block"} {
      update_selection $txtt right
    } else {
      update_selection $txtt next
    }

  }

  ######################################################################
  # If the selection mode is char or block, handles moving the cursor up
  # a line (carries the selection with it).  If the selection mode is
  # tag, sets the selection to the parent tag.
  proc handle_i {txtt} {

    variable data

    if {$data($txtt,type) eq "tag"} {
      update_selection $txtt parent
    } elseif {[lsearch [list char block] $data($txtt,type)] != -1} {
      update_selection $txtt up
    }

  }

  ######################################################################
  # If the selection mode is char or block, handles moving the cursor
  # down a line (carries the selection with it).  If the selection mode
  # is tag, sets the selection to the first child tag.
  proc handle_m {txtt} {

    variable data

    if {$data($txtt,type) eq "tag"} {
      update_selection $txtt child
    } elseif {[lsearch [list char block] $data($txtt,type)] != -1} {
      update_selection $txtt down
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
