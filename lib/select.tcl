# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
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
    lineto    {linestart lineend}
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
    [list [msgcat::mc "Line To"]         E  lineto] \
    [list [msgcat::mc "Sentence"]        s  sentence] \
    [list [msgcat::mc "Paragraph"]       p  paragraph] \
    [list [msgcat::mc "Node"]            n  node] \
    [list [msgcat::mc "Square Brackets"] \[ square] \
    [list [msgcat::mc "Parenthesis"]     \( paren] \
    [list [msgcat::mc "Curly Brackets"]  \{ curly] \
    [list [msgcat::mc "Angled Brackets"] \< angled] \
    [list [msgcat::mc "Comment"]         #  comment] \
    [list [msgcat::mc "Double Quotes"]   \" double] \
    [list [msgcat::mc "Single Quotes"]   \' single] \
    [list [msgcat::mc "Backticks"]       \` btick] \
    [list [msgcat::mc "Block"]           b  block] \
    [list [msgcat::mc "All"]             *  all] \
    [list [msgcat::mc "All To"]          .  allto] \
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
    set data($txt.t,dont_close) 0
    set data($txt.t,inner)      1
    set data($txt.t,number)     ""
    set data($txt.t,undo)       [list]

    set alt [expr {([tk windowingsystem] eq "aqua") ? "Mod2" : "Alt"}]

    bind select <<Selection>>                   [list select::handle_selection %W]
    bind select <FocusOut>                      [list select::handle_focusout %W]
    bind select <Key>                           "if {\[select::handle_any %W %K\]} break"
    bind select <Return>                        "if {\[select::handle_return %W\]} break"
    bind select <Escape>                        "if {\[select::handle_escape %W\]} break"
    bind select <BackSpace>                     "if {\[select::handle_backspace %W\]} break"
    bind select <Delete>                        "if {\[select::handle_delete %W\]} break"
    bind select <Double-Button-1>               "if {\[select::handle_double_click %W %x %y\]} break"
    bind select <Triple-Button-1>               "if {\[select::handle_triple_click %W %x %y\]} break"
    bind select <$alt-ButtonPress-1>            "if {\[select::handle_single_press %W %x %y\]} break"
    bind select <$alt-ButtonRelease-1>          "if {\[select::handle_single_release %W %x %y\]} break"
    bind select <$alt-B1-Motion>                "if {\[select::handle_alt_motion %W %x %y\]} break"
    bind select <Control-Double-Button-1>       "if {\[select::handle_control_double_click %W %x %y\]} break"
    bind select <Control-Triple-Button-1>       "if {\[select::handle_control_triple_click %W %x %y\]} break"
    bind select <Shift-Control-Double-Button-1> "if {\[select::handle_shift_control_double_click %W %x %y\]} break"
    bind select <Shift-Control-Triple-Button-1> "if {\[select::handle_shift_control_triple_click %W %x %y\]} break"

    bindtags $txt.t [linsert [bindtags $txt.t] [expr [lsearch [bindtags $txt.t] $txt.t] + 1] select]

  }

  ######################################################################
  # Performs an undo of the selection buffer.
  proc undo {txtt} {

    variable data

    if {[llength $data($txtt,undo)] > 1} {

      lassign [lindex $data($txtt,undo) end-1] type anchorend ranges

      # Set variables
      set data($txtt,undo)       [lrange $data($txtt,undo) 0 end-1]
      set data($txtt,dont_close) 1
      set data($txtt,type)       $type
      set data($txtt,anchorend)  $anchorend

      # Calculate the insertion cursor index in the ranges list
      set index [expr {$anchorend ? 0 : "end"}]

      # Clear the current selection and set the cursor
      $txtt cursor set [lindex $ranges $index]

      # Add the selection
      $txtt tag add sel {*}$ranges

    }

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
    set left   [list [msgcat::mc "Left"]                   "h"]
    set right  [list [msgcat::mc "Right"]                  "l"]
    set up     [list [msgcat::mc "Up"]                     "k"]
    set down   [list [msgcat::mc "Down"]                   "j"]
    set lshift [list [msgcat::mc "Shift Left"]             "H"]
    set rshift [list [msgcat::mc "Shift Right"]            "L"]
    set ushift [list [msgcat::mc "Shift Up"]               "K"]
    set dshift [list [msgcat::mc "Shift Down"]             "J"]
    set next   [list [msgcat::mc "Next"]                   "l"]
    set prev   [list [msgcat::mc "Previous"]               "h"]
    set parent [list [msgcat::mc "Parent"]                 "h"]
    set child  [list [msgcat::mc "Child"]                  "l"]
    set nsib   [list [msgcat::mc "Next Sibling"]           "j"]
    set psib   [list [msgcat::mc "Previous Sibling"]       "k"]
    set swap   [list [msgcat::mc "Swap Anchor"]            "a"]
    set undo   [list [msgcat::mc "Undo Last Change"]       "u"]
    set help   [list [msgcat::mc "Toggle Help"]            "?"]
    set ret    [list [msgcat::mc "Keep Selection"]         "\u21b5"]
    set esc    [list [msgcat::mc "Clear Selection"]        "Esc"]
    set del    [list [msgcat::mc "Delete Selected Text"]   "Del"]
    set inv    [list [msgcat::mc "Invert Selected Text"]   "~"]
    set find   [list [msgcat::mc "Add Selection Matches"]  "/"]
    set inc    [list [msgcat::mc "Toggle Quote Inclusion"] "i"]

    toplevel            .selhelp
    wm transient        .selhelp .
    wm overrideredirect .selhelp 1

    ttk::label     .selhelp.title -text  [msgcat::mc "Selection Mode Command Help"] -anchor center -padding 4
    ttk::label     .selhelp.close -image form_close -padding {8 0}
    ttk::separator .selhelp.sep -orient horizontal
    ttk::frame     .selhelp.f

    bind .selhelp.close <Button-1> [list select::hide_help]

    ttk::labelframe .selhelp.f.types -text [msgcat::mc "Modes"]
    create_list .selhelp.f.types $types $txtt

    ttk::labelframe .selhelp.f.motions -text [msgcat::mc "Motions"]
    switch $data($txtt,type) {
      char  -
      block {
        create_list .selhelp.f.motions [list $left $right $up $down $lshift $rshift $ushift $dshift]
      }
      word      -
      sentence  -
      paragraph {
        create_list .selhelp.f.motions [list $next $prev $lshift $rshift]
      }
      line   -
      lineto {
        create_list .selhelp.f.motions [list $down $up $dshift $ushift]
      }
      node   -
      curly  -
      square -
      paren  -
      angled {
        create_list .selhelp.f.motions [list $parent $child $nsib $psib $dshift $ushift]
      }
      all     -
      allto   -
      default {
        create_list .selhelp.f.motions [list $inc]
      }
    }

    ttk::labelframe .selhelp.f.anchors -text [msgcat::mc "Anchor"]
    create_list .selhelp.f.anchors [list $swap]

    ttk::labelframe .selhelp.f.help -text [msgcat::mc "Miscellaneous"]
    create_list .selhelp.f.help [list $undo $help]

    ttk::labelframe .selhelp.f.exit -text [msgcat::mc "Exit Selection Mode"]
    switch $data($txtt,type) {
      block   { create_list .selhelp.f.exit [list $ret $esc $del $inv] }
      default { create_list .selhelp.f.exit [list $ret $esc $del $inv $find] }
    }

    # Pack the labelframes
    grid .selhelp.f.types   -row 0 -column 0 -sticky news -padx 2 -pady 2 -rowspan 4
    grid .selhelp.f.motions -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid .selhelp.f.anchors -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid .selhelp.f.help    -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid .selhelp.f.exit    -row 3 -column 1 -sticky news -padx 2 -pady 2

    grid rowconfigure    .selhelp 2 -weight 1
    grid columnconfigure .selhelp 0 -weight 1
    grid .selhelp.title -row 0 -column 0 -sticky ew
    grid .selhelp.close -row 0 -column 1 -sticky news
    grid .selhelp.sep   -row 1 -column 0 -sticky ew   -columnspan 2
    grid .selhelp.f     -row 2 -column 0 -sticky news -columnspan 2

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
      update_selection $txtt init
    }

    # Update the position
    gui::update_position [winfo parent $txtt]

  }

  ######################################################################
  # Returns the current selection mode in use.  The selection mode is
  # remembered even after we exit selection mode (until the selection
  # forgotten.
  proc get_type {txtt} {

    variable data

    if {[info exists data($txtt,type)]} {
      return $data($txtt,type)
    }

    return "none"

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
    set range              [$txtt tag ranges sel]
    set number             [expr {($data($txtt,number) eq "") ? 1 : $data($txtt,number)}]
    set data($txtt,number) ""

    switch $motion {
      init {
        if {$opts(-startpos) ne ""} {
          $txtt mark set insert $opts(-startpos)
        } elseif {[llength $range] == 0} {
          $txtt mark set insert $data($txtt,anchor)
        } elseif {$data($txtt,anchorend) == 0} {
          $txtt mark set insert "insert-1 display chars"
        }
        switch $data($txtt,type) {
          char    -
          block   { set trange [list $data($txtt,anchor) "$data($txtt,anchor)+1 display chars"] }
          line    -
          lineto  {
            set trange [edit::get_range $txtt linestart lineend "" 0]
            if {$data($txtt,type) eq "lineto"} {
              lset trange $data($txtt,anchorend) $data($txtt,anchor)
            }
          }
          word    {
            if {[string is space [$txtt get insert]]} {
              $txtt mark set insert [$txtt index [list wordstart -dir [expr {($data($txtt,anchorend) == 0) ? "prev" : "next"}]]]
            }
            set trange [edit::get_range $txtt [list $data($txtt,type) 1] [list] i 0]
            puts "trange: $trange"
          }
          sentence -
          paragraph {
            set trange [edit::get_range $txtt [list $data($txtt,type) 1] [list] o 0]
          }
          node      { set trange [node_current [winfo parent $txtt] insert] }
          all       -
          allto     {
            set trange [list 1.0 end]
            if {$data($txtt,type) eq "allto"} {
              lset trange $data($txtt,anchorend) [lindex $range $data($txtt,anchorend)]
            }
          }
          comment   {
            if {[set ranges [ctext::commentCharRanges [winfo parent $txtt] insert]] ne ""} {
              if {$data($txtt,inner)} {
                set trange [lrange $ranges 1 2]
              } else {
                set trange [list [lindex $ranges 0] [lindex $ranges end]]
              }
            } else {
              set trange $range
            }
          }
          single    -
          double    -
          btick     { $txtt is in$data($txtt,type) insert [expr {$data($txtt,inner) ? "inner" : "outer"}] trange }
          default   { set trange [bracket_current $txtt $data($txtt,type) insert] }
        }
        if {[lsearch [list char line lineto word sentence paragraph] $data($txtt,type)] != -1} {
          if {$range eq ""} {
            set range $trange
          } else {
            if {[$txtt compare [lindex $trange 0] < [lindex $range 0]]} {
              lset range 0 [lindex $trange 0]
            }
            if {[$txtt compare [lindex $range  1] < [lindex $trange 1]]} {
              lset range 1 [lindex $trange 1]
            }
          }
        } else {
          set range $trange
        }
      }
      next -
      prev {
        set pos   $positions($data($txtt,type))
        set index [expr $data($txtt,anchorend) ^ 1]
        switch $data($txtt,type) {
          line   -
          lineto {
            set count ""
            if {[$txtt compare [lindex $range $index] == "[lindex $range $index] [lindex $pos $index]"]} {
              set count [expr {($motion eq "next") ? "+$number display lines" : "-$number display lines"}]
            }
            lset range $index [$txtt index "[lindex $range $index]$count [lindex $pos $index]"]
          }
          node {
            if {$data($txtt,anchorend) == 0} {
              if {[set node_range [node_${motion}_sibling [winfo parent $txtt] "[lindex $range 1]-1c"]] ne ""} {
                lset range 1 [lindex $node_range 1]
              }
            } else {
              if {[set node_range [node_${motion}_sibling [winfo parent $txtt] "[lindex $range 0]+1c"]] ne ""} {
                lset range 0 [lindex $node_range 0]
              }
            }
          }
          curly -
          square -
          paren  -
          angled {
            if {$data($txtt,anchorend) == 0} {
              if {[set bracket_range [bracket_${motion}_sibling $txtt $data($txtt,type) {*}$range]] ne ""} {
                lset range 1 [lindex $bracket_range 1]
              }
            } else {
              if {[set bracket_range [bracket_${motion}_sibling $txtt $data($txtt,type) {*}$range]] ne ""} {
                lset range 0 [lindex $bracket_range 0]
              }
            }
          }
          default {
            if {($index == 1) && ($motion eq "prev") && ($data($txtt,type) eq "word")} {
              lset range 1 [$txtt index "[lindex $range 1]-1 display chars"]
            }
            if {$opts(-startpos) ne ""} {
              lset range $index [$txtt index [list {*}[lindex $pos $index] -dir $motion -num $number -startpos $opts(-startpos)]]
            } else {
              lset range $index [$txtt index [list {*}[lindex $pos $index] -dir $motion -num $number -startpos [lindex $range $index]]]
            }
          }
        }
        if {([lindex $range $index] eq "") || [$txtt compare [lindex $range 0] >= [lindex $range 1]]} {
          return
        }
      }
      rshift -
      lshift {
        if {$data($txtt,type) eq "block"} {
          set trange $range
          if {$motion eq "rshift"} {
            set range [list]
            foreach {startpos endpos} $trange {
              lappend range [$txtt index "$startpos+$number display chars"]
              if {[$txtt compare "$endpos+$number display chars" < "$endpos lineend"]} {
                lappend range [$txtt index "$endpos+$number display chars"]
              } else {
                lappend range [$txtt index "$endpos lineend"]
              }
            }
          } elseif {[$txtt compare "[lindex $range 0]-$number display chars" >= "[lindex $range 0] linestart"]} {
            set range [list]
            foreach {startpos endpos} $trange {
              lappend range [$txtt index "$startpos-$number display chars"] [$txtt index "$endpos-$number display chars"]
            }
          }
        } else {
          set pos   $positions($data($txtt,type))
          set dir   [expr {($motion eq "rshift") ? "next" : "prev"}]
          if {($motion eq "lshift") && ([lsearch [list word tag] $data($txtt,type)] != -1)} {
            lset range 1 [$txtt index "[lindex $range 1]-1 display chars"]
          }
          foreach index {0 1} {
            lset range $index [$txtt index [list {*}[lindex $pos $index] -dir $dir -num $number -startpos [lindex $range $index]]]
          }
        }
      }
      ushift {
        switch $data($txtt,type) {
          line {
            if {[$txtt compare "[lindex $range 0]-$number display lines" < [lindex $range 0]]} {
              if {[$txtt compare [lindex $range 0] > 1.0]} {
                lset range 0 [$txtt index "[lindex $range 0]-$number display lines linestart"]
                lset range 1 [$txtt index "[lindex $range 1]-$number display lines lineend"]
              }
            }
          }
          node {
            if {[set node_range0 [node_prev_sibling [winfo parent $txtt] "[lindex $range 0]+1c"]] ne ""} {
              if {[set node_range1 [node_prev_sibling [winfo parent $txtt] "[lindex $range 1]-1c"]] ne ""} {
                lset range 0 [lindex $node_range0 0]
                lset range 1 [lindex $node_range1 1]
              }
            }
          }
          curly -
          square -
          paren  -
          angled {
            if {[set bracket_range0 [bracket_prev_sibling $txtt $data($txtt,type) {*}$range]] ne ""} {
              if {[set bracket_range1 [bracket_prev_sibling $txtt $data($txtt,type) {*}$range]] ne ""} {
                lset range 0 [lindex $bracket_range0 0]
                lset range 1 [lindex $bracket_range1 1]
              }
            }
          }
          default {
            if {[$txtt compare "[lindex $range 0]-$number display lines" < [lindex $range 0]]} {
              set trange $range
              set range  [list]
              foreach {pos} $trange {
                lappend range [$txtt index "$pos-$number display lines"]
              }
            }
          }
        }
      }
      dshift {
        switch $data($txtt,type) {
          line {
            if {[$txtt compare "[lindex $range end]+$number display lines" > "[lindex $range end] lineend"]} {
              if {[$txtt compare [lindex $range 1] < "end-1 display lines lineend"]} {
                lset range 1 [$txtt index "[lindex $range 1]+$number display lines lineend"]
                lset range 0 [$txtt index "[lindex $range 0]+$number display lines linestart"]
              }
            }
          }
          node {
            if {[set node_range1 [node_next_sibling [winfo parent $txtt] "[lindex $range 1]-1c"]] ne ""} {
              if {[set node_range0 [node_next_sibling [winfo parent $txtt] "[lindex $range 0]+1c"]] ne ""} {
                lset range 0 [lindex $node_range0 0]
                lset range 1 [lindex $node_range1 1]
              }
            }
          }
          curly -
          square -
          paren  -
          angled {
            if {[set bracket_range0 [bracket_next_sibling $txtt $data($txtt,type) {*}$range]] ne ""} {
              if {[set bracket_range1 [bracket_next_sibling $txtt $data($txtt,type) {*}$range]] ne ""} {
                lset range 0 [lindex $bracket_range0 0]
                lset range 1 [lindex $bracket_range1 1]
              }
            }
          }
          default {
            if {[$txtt compare "[lindex $range end]+$number display lines" > "[lindex $range end] lineend"]} {
              set trange $range
              set range  [list]
              foreach {pos} $trange {
                lappend range [$txtt index "$pos+$number display lines"]
              }
            }
          }
        }
      }
      left {
        if {$data($txtt,anchorend) == 1} {
          set i 0
          foreach {startpos endpos} $range {
            if {[$txtt compare "$startpos-$number display chars" >= "$startpos linestart"]} {
              lset range $i [$txtt index "$startpos-$number display chars"]
              incr i 2
            }
          }
        } else {
          set i 1
          foreach {startpos endpos} $range {
            if {[$txtt compare "$endpos-$number display chars" > $startpos]} {
              lset range $i [$txtt index "$endpos-$number display chars"]
            }
            incr i 2
          }
        }
      }
      right {
        if {$data($txtt,anchorend) == 1} {
          set i 0
          foreach {startpos endpos} $range {
            if {[$txtt compare "$startpos+$number display chars" < $endpos]} {
              lset range $i [$txtt index "$startpos+$number display chars"]
            }
            incr i 2
          }
        } else {
          set i 1
          foreach {startpos endpos} $range {
            if {[$txtt compare "$endpos+$number display chars" <= "$endpos lineend"]} {
              lset range $i [$txtt index "$endpos+$number display chars"]
            }
            incr i 2
          }
        }
      }
      up {
        if {$data($txtt,type) eq "block"} {
          if {$data($txtt,anchorend) == 1} {
            if {[$txtt compare "insert-$number display lines" < [lindex $range 0]]} {
              set nrow  [lindex [split [$txtt index "insert-$number display lines"] .] 0]
              set ocol1 [$txtt count -displaychars "[lindex $range end-1] linestart" [lindex $range end-1]]
              set ocol2 [$txtt count -displaychars "[lindex $range end]   linestart" [lindex $range end]]
              for {set i 0} {$i < $number} {incr i} {
                lappend trange $nrow.$ocol1 $nrow.$ocol2
                incr nrow
              }
              set range [list {*}$trange {*}$range]
            }
          } else {
            if {[$txtt compare "insert-$number display lines" >= [lindex $range 0]]} {
              set range [lreplace $range end-[expr ($number * 2) - 1] end]
            }
          }
        } else {
          if {$data($txtt,anchorend) == 1} {
            if {[$txtt compare "[lindex $range 0]-$number display lines" < [lindex $range 0]]} {
              lset range 0 [$txtt index "[lindex $range 0]-$number display lines"]
            }
          } else {
            if {[$txtt compare "[lindex $range 1]-$number display lines" > [lindex $range 0]]} {
              lset range 1 [$txtt index "[lindex $range 1]-$number display lines"]
            }
          }
        }
      }
      down {
        if {$data($txtt,type) eq "block"} {
          if {$data($txtt,anchorend) == 1} {
            if {[$txtt compare "insert+$number display lines" <= [lindex $range end-1]]} {
              set range [lreplace $range 0 [expr ($number * 2) - 1]]
            }
          } else {
            if {[$txtt compare "insert+$number display lines" < end]} {
              set nrow  [lindex [split [$txtt index "insert+$number display lines"] .] 0]
              set ocol1 [$txtt count -displaychars "[lindex $range 0] linestart" [lindex $range 0]]
              set ocol2 [$txtt count -displaychars "[lindex $range 1] linestart" [lindex $range 1]]
              for {set i 0} {$i < $number} {incr i} {
                lappend trange $nrow.$ocol2 $nrow.$ocol1
                incr nrow -1
              }
              lappend range {*}[lreverse $trange]
            }
          }
        } else {
          if {$data($txtt,anchorend) == 1} {
            if {[$txtt compare "[lindex $range 0]+$number display lines" < [lindex $range 1]]} {
              lset range 0 [$txtt index "[lindex $range 0]+$number display lines"]
            }
          } else {
            if {[$txtt compare "[lindex $range 1]+$number display lines" < end]} {
              lset range 1 [$txtt index "[lindex $range 1]+$number display lines"]
            }
          }
        }
      }
      parent {
        switch $data($txtt,type) {
          node    { set trange [node_parent [winfo parent $txtt] {*}$range] }
          default { set trange [bracket_parent $txtt $data($txtt,type) {*}$range] }
        }
        if {$trange ne ""} {
          set range $trange
        }
      }
      child {
        if {$data($txtt,anchorend) == 0} {
          switch $data($txtt,type) {
            node    { set trange [node_first_child [winfo parent $txtt] [lindex $range 0]] }
            default { set trange [bracket_first_child $txtt $data($txtt,type) {*}$range] }
          }
        } else {
          switch $data($txtt,type) {
            node    { set trange [node_last_child [winfo parent $txtt] [lindex $range 0]] }
            default { set trange [bracket_last_child $txtt $data($txtt,type) {*}$range] }
          }
        }
        if {$trange ne ""} {
          set range $trange
        }
      }
    }

    # If the range was not set to a valid range, return now
    if {[set cursor [lindex $range [expr {$data($txtt,anchorend) ? 0 : "end"}]]] eq ""} {
      return
    }

    # Set the cursor and selection
    set data($txtt,dont_close) 1
    set index                  [expr {($data($txtt,anchorend) == 0) ? 0 : "end"}]
    set data($txtt,anchor)     [lindex $range $index]
    $txtt cursor set $cursor
    foreach {startpos endpos} $range {
      $txtt tag add sel $startpos $endpos
    }

    # Add the information to the undo buffer
    lappend data($txtt,undo) [list $data($txtt,type) $data($txtt,anchorend) $range]

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
  proc in_select_mode {txtt ptype} {

    upvar $ptype type

    variable data

    if {![info exists data($txtt,mode)]} {
      return 0
    }

    set type $data($txtt,type)

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

        set data($txtt,anchor)    [$txtt index insert]
        set data($txtt,anchorend) 0
        set data($txtt,undo)      [list]

        # If text was not previously selected, select it by word
        if {[set sel [$txtt tag ranges sel]] eq ""} {
          set_type $txtt "word" 1
        } elseif {$data($txtt,type) eq "none"} {
          set_type $txtt "char" 0
        }

        # Configure the cursor
        $txtt configure -cursor [ttk::cursor standard]

        # Display a help message
        gui::set_info_message [msgcat::mc "Type '?' for help.  Hit the ESCAPE key to exit selection mode"] -win [winfo parent $txtt] -clear_delay 0

      # Otherwise, configure the cursor
      } else {

        $txtt configure -cursor ""

        # Clear the help message
        gui::set_info_message "" -win [winfo parent $txtt]

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
      set data($txtt,type) "none"
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

    # This is only necessary for BIST testing on MacOS, but it should not hurt
    # anything to clear the type anyways
    set data($txtt,type) "none"
    set_select_mode $txtt 0

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
    edit::delete $txtt {*}[lrange [$txtt tag ranges sel] 0 1] 1 1

    # Disable selection mode
    set_select_mode $txtt 0
    set data($txtt,type) "none"

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
    edit::delete $txtt {*}[lrange [$txtt tag ranges sel] 0 1] 1 1

    # Disable selection mode
    set_select_mode $txtt 0
    set data($txtt,type) "none"

    # Hide the help window
    hide_help

    return 1

  }

  ######################################################################
  # Inverts the current selection and ends selection mode.
  proc handle_asciitilde {txtt} {

    variable data

    if {$data($txtt,mode) == 0} {
      return 0
    }

    # Get the current selection
    set ranges [$txtt tag ranges sel]

    # Select everything and remove the given ranges
    $txtt tag add sel 1.0 end
    $txtt tag remove sel {*}$ranges

    # Disable selection mode
    set_select_mode $txtt 0
    set data($txtt,type)  "none"

    # Hide the help window
    hide_help

    return 1

  }

  ######################################################################
  # Selection mode completion command which finds all text that matches
  # currently selected text and includes those in the selection.
  proc handle_slash {txtt} {

    variable data

    if {$data($txtt,mode) == 0} {
      return 0
    }

    # Get the selection string to match against
    set str [$txtt get sel.first sel.last]

    # Find all text in the editing buffer that matches the selected text
    set i 0
    foreach index [$txtt search -all -count lengths -forward -- $str 1.0 end] {
      $txtt tag add sel $index "$index+[lindex $lengths $i]c"
      incr i
    }

    # Disable selection mode
    set_select_mode $txtt 0
    set data($txtt,type)  "none"

    # Hide the help window
    hide_help

    # Tell the user how many matches we found
    gui::set_info_message [format "%s %d %s" [msgcat::mc "Selected"] [expr $i - 1] [msgcat::mc "matching instances"]]

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
  # Returns the current bracket type based on the position of startpos.
  proc get_bracket_type {txtt startpos} {

    # If we are within a comment, return
    foreach type [list comment single double btick square curly paren angled] {
      if {[$txtt is in$type $startpos]} {
        return $type
      }
    }

    return ""

  }

  ######################################################################
  # Handles a double-click event while the Shift-Control keys are held.
  # Selects the current square, curly, paren, single, double, backtick or tag.
  proc handle_shift_control_double_click {txtt x y} {

    # Get the bracket type closest to the mouse cursor
    if {[set type [get_bracket_type $txtt [$txtt index @$x,$y]]] ne ""} {

      # Set the type
      set_type $txtt $type

      # Update the selection
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

    # Set the selection type to node
    set_type $txtt node

    # Update the selection
    update_selection $txtt init -startpos [$txtt index @$x,$y]

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

    # If the keysym is a number, append the number to the current one.
    if {[string is integer $keysym]} {
      if {($keysym ne "0") || ($data($txtt,number) ne "")} {
        append data($txtt,number) $keysym
      }

    # Handle the specified key, if a handler exists for it
    } elseif {[info procs handle_$keysym] ne ""} {
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
  # Sets the current selection type from anchor to beginning/end of line.
  proc handle_E {txtt} {

    set_type $txtt lineto

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
  # Set the current selection type to comment.
  proc handle_numbersign {txtt} {

    set_type $txtt comment

  }

  ######################################################################
  # Set the current selection type to all.
  proc handle_asterisk {txtt} {

    set_type $txtt all

  }

  ######################################################################
  # Set the current selection type to allto.
  proc handle_period {txtt} {

    set_type $txtt allto

  }

  ######################################################################
  # Handles moving the selection back by the selection type amount.
  proc handle_H {txtt} {

    variable data

    switch $data($txtt,type) {
      all     -
      allto   -
      line    -
      lineto  -
      single  -
      double  -
      btick   -
      comment {}
      node    -
      curly   -
      square  -
      paren   -
      angled  { update_selection $txtt parent }
      default { update_selection $txtt lshift }
    }

  }

  ######################################################################
  # Handles moving the selection forward by the selection type amount.
  proc handle_L {txtt} {

    variable data

    switch $data($txtt,type) {
      all     -
      allto   -
      line    -
      lineto  -
      single  -
      double  -
      btick   -
      comment {}
      node    -
      curly   -
      square  -
      paren   -
      angled  { update_selection $txtt child }
      default { update_selection $txtt rshift }
    }

  }

  ######################################################################
  # Handles moving the entire selection to include the parent of the
  # currently selected text.
  proc handle_K {txtt} {

    variable data

    switch $data($txtt,type) {
      char   -
      block  -
      node   -
      line   -
      lineto -
      curly  -
      square -
      paren  -
      angled { update_selection $txtt ushift }
    }

  }

  ######################################################################
  # Handles moving the entire selection to include just the first child
  # of the currently selected text.
  proc handle_J {txtt} {

    variable data

    switch $data($txtt,type) {
      char   -
      block  -
      node   -
      line   -
      lineto -
      curly  -
      square -
      paren  -
      angled { update_selection $txtt dshift }
    }

  }

  ######################################################################
  # Handles moving the entire selection to the left by the current type.
  proc handle_h {txtt} {

    variable data

    switch $data($txtt,type) {
      node      -
      square    -
      curly     -
      paren     -
      angled    { update_selection $txtt parent }
      block     { update_selection $txtt left }
      char      -
      line      -
      lineto    -
      word      -
      sentence  -
      paragraph { update_selection $txtt prev }
    }

  }

  ######################################################################
  # Handles moving the entire selection to the right by the current type.
  proc handle_l {txtt} {

    variable data

    switch $data($txtt,type) {
      node      -
      curly     -
      square    -
      paren     -
      angled    { update_selection $txtt child }
      block     { update_selection $txtt right }
      char      -
      line      -
      lineto    -
      word      -
      sentence  -
      paragraph { update_selection $txtt next }
    }

  }

  ######################################################################
  # If the selection mode is char or block, handles moving the cursor up
  # a line (carries the selection with it).
  proc handle_k {txtt} {

    variable data

    switch $data($txtt,type) {
      char   -
      block  { update_selection $txtt up }
      node   -
      line   -
      lineto -
      curly  -
      square -
      paren  -
      angled { update_selection $txtt prev }
    }

  }

  ######################################################################
  # If the selection mode is char or block, handles moving the cursor
  # down a line (carries the selection with it).
  proc handle_j {txtt} {

    variable data

    switch $data($txtt,type) {
      char   -
      block  { update_selection $txtt down }
      node   -
      line   -
      lineto -
      curly  -
      square -
      paren  -
      angled { update_selection $txtt next }
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
  # Causes the surrounding characters to be included/excluded from the
  # selection.  This is only valid for types which include surrounding
  # characters.
  proc handle_i {txtt} {

    variable data

    if {[lsearch [list single double btick comment] $data($txtt,type)] != -1} {
      set data($txtt,inner) [expr {$data($txtt,inner) ^ 1}]
      update_selection $txtt init
    }

  }

  ######################################################################
  # Undo selection.
  proc handle_u {txtt} {

    undo $txtt

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

  ######################################################################
  # Returns the range of the current DOM.
  proc node_current {txt startpos} {

    if {[set tag [emmet::inside_tag $txt -startpos $startpos -allow010 1]] eq ""} {
      return [emmet::get_inner [emmet::get_node_range $txt -startpos $startpos]]
    } elseif {[lindex $tag 3] eq "010"} {
      return [lrange $tag 0 1]
    } else {
      return [emmet::get_outer [emmet::get_node_range $txt -startpos $startpos]]
    }
  }

  ######################################################################
  # Returns the starting and ending positions of the parent HTML node given
  # the starting cursor position.
  proc node_parent {txt startpos endpos} {

    set within [emmet::get_node_range_within $txt -startpos $startpos]

    if {(([set tag [emmet::inside_tag $txt -startpos $startpos -allow010 1]] eq "") && ([lindex $tag 3] ne "010")) || \
        ([emmet::get_inner $within] eq [list $startpos $endpos])} {
      return [emmet::get_outer $within]
    } else {
      return [emmet::get_inner $within]
    }

  }

  ######################################################################
  # Returns the starting and ending positions of the first child node in the
  # DOM.  The startpos parameter should be the index of the start of the parent
  # node.
  proc node_first_child {txt startpos} {

    set parent_range [emmet::get_inner [emmet::get_node_range $txt -startpos $startpos]]

    if {[emmet::inside_tag $txt -startpos $startpos -allow010 1] eq ""} {
      if {[set tag [emmet::get_tag $txt -dir next -type ??0 -start [lindex $parent_range 0]]] ne ""} {
        if {[$txt compare [lindex $tag 0] < [lindex $parent_range 1]]} {
          if {[lindex $tag 3] eq "010"} {
            return [lrange $tag 0 1]
          } else {
            return [emmet::get_outer [emmet::get_node_range $txt -startpos [lindex $tag 0]]]
          }
        }
      }
    } elseif {($parent_range eq "") || [$txt compare [lindex $parent_range 0] == [lindex $parent_range 1]]} {
      return ""
    }

    return $parent_range

  }

  ######################################################################
  # Returns the starting and ending positions of the last child node in the
  # DOM.  The startpos parameter should be the index of the start of the
  # parent node.
  proc node_last_child {txt startpos} {

    set parent_range [emmet::get_inner [emmet::get_node_range $txt -startpos $startpos]]

    if {[emmet::inside_tag $txt -startpos $startpos -allow010 1] eq ""} {
      if {[set tag [emmet::get_tag $txt -dir prev -type ??0 -start [lindex $parent_range 1]]] ne ""} {
        if {[$txt compare [lindex $tag 0] > [lindex $parent_range 0]]} {
          if {[lindex $tag 3] eq "010"} {
            return [lrange $tag 0 1]
          } else {
            return [emmet::get_outer [emmet::get_node_range $txt -startpos [lindex $tag 0]]]
          }
        }
      }
    } elseif {($parent_range eq "") || [$txt compare [lindex $parent_range 0] == [lindex $parent_range 1]]} {
      return ""
    }

    return $parent_range

  }

  ######################################################################
  # Returns the starting and ending positions of the next sibling node of
  # the node containing the given starting position.
  proc node_next_sibling {txt startpos} {

    if {[set tag [emmet::inside_tag $txt -startpos $startpos -allow010 1]] eq ""} {
      return ""
    }

    if {[lindex $tag 3] eq "010"} {
      set current_range [lrange $tag 0 1]
    } else {
      set current_range [emmet::get_outer [emmet::get_node_range $txt -startpos $startpos]]
    }
    set parent_range [node_parent $txt {*}$current_range]

    if {[set tag [emmet::get_tag $txt -dir next -type ??0 -start [lindex $current_range 1]]] ne ""} {
      if {($parent_range eq "") || [$txt compare [lindex $tag 0] < [lindex $parent_range 1]]} {
        if {[lindex $tag 3] eq "010"} {
          return [lrange $tag 0 1]
        } else {
          return [emmet::get_outer [emmet::get_node_range $txt -startpos [lindex $tag 0]]]
        }
      }
    }

    return ""

  }

  ######################################################################
  # Returns the starting and ending positions of the next sibling node of
  # the node containing the given starting position.
  proc node_prev_sibling {txt startpos} {

    if {[set tag [emmet::inside_tag $txt -startpos $startpos -allow010 1]] eq ""} {
      return ""
    }

    if {[lindex $tag 3] eq "010"} {
      set current_range [lrange $tag 0 1]
    } else {
      set current_range [emmet::get_outer [emmet::get_node_range $txt -startpos $startpos]]
    }
    set parent_range [node_parent $txt {*}$current_range]

    if {[set tag [emmet::get_tag $txt -dir prev -type 0?? -start "[lindex $current_range 0]-1c"]] ne ""} {
      if {($parent_range eq "") || [$txt compare [lindex $tag 0] > [lindex $parent_range 0]]} {
        if {[lindex $tag 3] eq "010"} {
          return [lrange $tag 0 1]
        } else {
          return [emmet::get_outer [emmet::get_node_range $txt -startpos [lindex $tag 0]]]
        }
      }
    }

    return ""

  }

  ######################################################################
  # Returns the range of the specified bracket.
  proc bracket_current {txtt type startpos} {

    if {[$txtt is $type $startpos any]} {
      $txtt is in$type $startpos outer range
    } else {
      $txtt is in$type $startpos inner range
    }

    return $range

  }

  ######################################################################
  # Returns the range of the specified bracket's parent bracket.
  proc bracket_parent {txtt type startpos endpos} {

    if {[$txtt is $type $startpos left]} {
      set right [$txtt matchchar $startpos]
      if {[$txtt compare $right == $endpos-1c]} {
        if {[$txtt is $type $startpos-1c left]} {
          return [list $startpos [$txtt matchchar $startpos-1c]]
        } else {
          $txtt is in$type "$startpos-1c" inner range
          return $range
        }
      } elseif {[$txtt is $type $startpos-1c left]} {
        return [list [$txtt index $startpos-1c] [$txtt matchchar $startpos-1c]+1c]
      }
    }

    $txtt is in$type "$startpos-1c" outer range
    return $range

  }

  ######################################################################
  # Returns the range of the first child within the given parent range.
  proc bracket_first_child {txtt type startpos endpos} {

    if {[$txtt is $type $startpos left]} {
      if {[set right [$txtt matchchar $startpos]] ne ""} {
        if {[$txtt compare $right == $endpos-1c]} {
          return [list [$txtt index $startpos+1c] $right]
        } elseif {[$txtt compare $right < $endpos]} {
          return [list $startpos [$txtt index $right+1c]]
        }
      }
    } elseif {[set left [lindex [$txtt range next $type left $startpos] 0]] ne ""} {
      if {[set right [$txtt matchchar $left]] ne ""} {
        if {[$txtt compare $right < $endpos]} {
          return [list $left [$txtt index $right+1c]]
        }
      }
    }

    return ""

  }

  ######################################################################
  # Returns the range of the last child within the given parent range.
  proc bracket_last_child {txtt type startpos endpos} {

    if {[$txtt is $type $endpos-1c right]} {
      if {[set left [$txtt matchchar $endpos-1c]] ne ""} {
        if {[$txtt compare $left == $startpos]} {
          return [list [$txtt index $startpos+1c] [$txtt index $endpos-1c]]
        } elseif {[$txtt compare $startpos < $left]} {
          return [list $left $endpos]
        }
      }
    } elseif {[set right [lindex [$txtt range prev $type right $endpos] 0]] ne ""} {
      if {[set left [$txtt matchchar $right]] ne ""} {
        if {[$txtt compare $startpos < $left]} {
          return [list $left [$txtt index $right+1c]]
        }
      }
    }

    return ""

  }

  ######################################################################
  # Return the range of the next sibling bracket type.
  proc bracket_next_sibling {txtt type startpos endpos} {

    variable data

    if {[$txtt is $type $startpos left]} {
      set parent [bracket_parent $txtt $type $startpos $endpos]
      if {$data($txtt,anchorend) == 0} {
        set left [lindex [$txtt range next $type left $endpos] 0]
      } else {
        set left [lindex [$txtt range next $type left $startpos] 0]
      }
      if {($left ne "") && ([lindex $parent 1] ne "") && [$txtt compare $left < [lindex $parent 1]]} {
        return [list $left [$txtt matchchar $left]+1c]
      }
    }

    return ""

  }

  ######################################################################
  # Return the range of the previous sibling bracket type.
  proc bracket_prev_sibling {txtt type startpos endpos} {

    variable data

    if {[$txtt is $type $startpos left]} {
      set parent [bracket_parent $txtt $type $startpos $endpos]
      if {$data($txtt,anchorend) == 0} {
        set right [lindex [$txtt range prev $type right $endpos-1c] 0]
      } else {
        set right [lindex [$txtt range prev $type right $startpos] 0]
      }
      if {($right ne "") && ([lindex $parent 0] ne "") && [$txtt compare [lindex $parent 0] < $right]} {
        return [list [$txtt matchchar $right] $right+1c]
      }
    }

    return ""

  }

  ######################################################################
  # Quickly selects the given type of text for the current editing buffer.
  # This functionality is meant to allow us to provide similar functionality
  # to other editors via the menus.
  proc quick_select {type} {

    variable data

    set txtt [gui::current_txt].t

    # Make sure that we lose our current selection
    $txtt tag remove sel 1.0 end

    # If the type is brackets, figure out the closest bracket to the insertion cursor.  If we
    # are not detected to be within a bracket, return without doing anything
    if {($type eq "bracket") && ([set type [get_bracket_type $txtt [$txtt index insert]]] eq "")} {
      return
    }

    # Set the type
    set data($txtt,type) $type

    # Perform the selection
    update_selection $txtt init -startpos insert

  }

  ######################################################################
  # Quickly adds the line above/below the currently selected line to the
  # selection.  This meant to provide backward compatibility with other
  # editors via the menus.
  proc quick_add_line {dir} {

    variable data

    # Get the current editing buffer
    set txtt [gui::current_txt].t

    # Set the current selection type to line
    set data($txtt,type)      "line"
    set data($txtt,anchorend) [expr {($dir eq "next") ? 0 : 1}]

    # Add the given line
    update_selection $txtt $dir -startpos insert

  }

}
