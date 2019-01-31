###########################################################################
#
# This script contains the PaveMe class, sort of wrapper around the grid
# geometry manager.
#
# Use:
#    source paveme.tcl
#    ...
#    PaveMe create pave
#    catch {destroy .win}
#    pave makeWindow .win "TITLE"
#    pave window .win LISTW
#    pave showModal .win FOCUSED GEOMETRY
#
# where:
#    TITLE - title of window
#    LISTW - list of widgets and their options
#    FOCUSEDW - name of widgets to be focused (optional)
#    GEOMETRY - geometry of widgets (optional)
#
# LISTW's entries have the following structure:
#   {NAME NEIGHBOR POSN RSPAN CSPAN OPTGRID OPTWIDG}
#
# where:
#   NAME     - name of current widget that can begin with letters
#              defining the type of widget (see getWidgetType below)
#   NEIGHBOR - name of neighboring widget
#   POSN     - position of neighboring widget: T or L (top or left)
#   RSPAN    - rowspan of current widget
#   CSPAN    - columnspan of current widget
#   OPTGRID  - options of grid command
#   OPTWIDG  - options of widget's command
# If NAME begins with others letters than noted above, the widget should
# be created before calling "pave window" command.
#
# Example:
#   {ch2 ch1 T 1 5 {-st w} {-t "Match case" -var t::c2}}
#   means the widget's options:
#   ch2 - name of current widget (checkbox)
#   ch1 - name of neighboring widget (checkbox)
#   T   - position of neighboring widget is TOP
#   1   - rowspan of current widget
#   5   - columnspan of current widget
#   {-st w} - option "-sticky" of grid command
#   {-t ...} - option "-text" of widget's (checkbox's) command
#
# See test_pave.tcl for the detailed examples of use.
#
###########################################################################

######################################################################
# for debugging
# proc d {args} {tk_messageBox -title "INFO" -icon info -message "$args"}

package require Tk

oo::class create PaveMe {

  variable nsp

  constructor {args} {

    set nsp [namespace current]::
    namespace eval ${nsp}paveN {}
    array set ${nsp}paveN::PaveRes {}
  }

  #########################################################################
  #
  # Check the platform

  method iswindows {} {

    return [expr {$::tcl_platform(platform) == "windows"} ? 1: 0]

  }

  #########################################################################
  #
  # Get the coordinates of centered window (against its parent)

  method CenteredXY {rw rh rx ry w h} {

    set x [expr {max(0, $rx + ($rw - $w) / 2)}]
    set y [expr {max(0,$ry + ($rh - $h) / 2)}]
    # check for left/right edge of screen (accounting decors)
    set scrw [expr [winfo screenwidth .] - 12]
    set scrh [expr {[winfo screenheight .] - 36}]
    if {($x + $w) > $scrw } {
      set x [expr {$scrw - $w}]
    }
    if {($y + $h) > $scrh } {
      set y [expr {$scrh - $h}]
    }
    return +$x+$y

  }

  #########################################################################
  #
  # Get root name of widget's name

  method rootwname {name} {

    return [lindex [split $name .] end]

  }

  #########################################################################
  #
  # Some options may be cut down, so we must expand them

  method ExpandOptions {options} {

    set options [string map {
      " - "     ""
      " -st "   " -sticky "
      " -com "  " -command "
      " -t "    " -text "
      " -w "    " -width "
      " -h "    " -height "
      " -var "  " -variable "
      " -tvar " " -textvariable "
      " -lvar " " -listvariable "
    } " $options"]
    return $options

  }

  #########################################################################
  #
  # Get the widget type based on 2 initial letters of its name

  method GetWidgetType {name options attrs} {

    set pack $options
    switch -glob $name {
      "bit*" {set widget "bitmap"}
      "but*" {set widget "ttk::button"}
      "buT*" {set widget "button"}
      "can*" {set widget "canvas"}
      "chb*" {set widget "ttk::checkbutton"}
      "chB*" {set widget "checkbutton"}
      "cbx*" {set widget "ttk::combobox"}
      "ent*" {set widget "ttk::entry"}
      "enT*" {set widget "entry"}
      "fil*" -
      "fis*" -
      "dir*" -
      "clr*" -
      "fra*" { ;# + frame for choosers (of file, directory, color, font)
        set widget "ttk::frame"
      }
      "frA*" {set widget "frame"}
      "lab*" {set widget "ttk::label"; set options "-st w $options"}
      "laB*" {set widget "label";      set options "-st w $options"}
      "lfr*" {set widget "ttk::labelframe"}
      "lfR*" {set widget "labelframe"}
      "lbx*" {set widget "listbox"}
      "meb*" {set widget "ttk::menubutton"}
      "meB*" {set widget "menubutton"}
      "men*" {set widget "menu"}
      "not*" {set widget "ttk::notebook"}
      "pan*" {set widget "ttk::panedwindow"}
      "pro*" {set widget "ttk::progressbar"}
      "rad*" {set widget "ttk::radiobutton"}
      "raD*" {set widget "radiobutton"}
      "sca*" {set widget "ttk::scale"}
      "scA*" {set widget "scale"}
      "sbh*" {
        set widget "ttk::scrollbar";
        set options "-st ew $options"
        set attrs "-orient horizontal $attrs"
      }
      "sbH*" {
        set widget "scrollbar"
        set options "-st ew $options"
        set attrs "-orient horizontal $attrs"
      }
      "sbv*" {
        set widget "ttk::scrollbar"
        set options "-st ns $options"
        set attrs "-orient vertical $attrs"
      }
      "sbV*" {
        set widget "scrollbar"
        set options "-st ns $options"
        set attrs "-orient vertical $attrs"
      }
      "seh*" { ;# horizontal separator
        set widget "ttk::separator"
        set options "-st ew $options"
        set attrs "-orient horizontal $attrs"
      }
      "sev*" { ;# vertical separator
        set widget "ttk::separator"
        set options "-st ns $options"
        set attrs "-orient vertical $attrs"
      }
      "siz*" {set widget "ttk::sizegrip"}
      "spx*" {set widget "ttk::spinbox"}
      "spX*" {set widget "spinbox"}
      "tex*" {set widget "text"}
      "tre*" {set widget "ttk::treeview"}
      "h_*" { ;# horizontal spacer
        set widget "frame"
        set options "-st ew -csz 3 -padx 3 $options"
      }
      "v_*" { ;# vertical spacer
        set widget "frame"
        set options "-st ns -rsz 3 -pady 3 $options"
      }
      default {set widget ""}
    }
    if {[string first "pack " [string trimleft $pack]]==0} {
      set options $pack
    }
    set options [string trim $options]
    set attrs   [string trim $attrs]
    return [list $widget $options $attrs]

  }

  #########################################################################
  #
  # Get -weight/-minsize options for row/column
  # They are set in grid options as "-rw <int>", "-cw <int>"

  method GetOptions {w options row rowspan col colspan} {

    set opts ""
    foreach {opt val} [list {*}$options] {
      switch $opt {
        -rw  { my SpanConfig $w row $row $rowspan -weight $val }
        -cw  { my SpanConfig $w column $col $colspan -weight $val }
        -rsz { my SpanConfig $w row $row $rowspan -minsize $val}
        -csz { my SpanConfig $w column $col $colspan -minsize $val }
        default {append opts " $opt $val"}
      }
    }
    # Get other grid options
    return [my ExpandOptions $opts]

  }

  method SpanConfig {w rcnam rc rcspan opt val} {

    for {set i $rc} {$i < ($rc + $rcspan)} {incr i} {
      eval [grid ${rcnam}configure $w $i $opt $val]
    }
    return

  }

  #########################################################################
  #
  # Chooser (for all available types)

  method chooser {nameofchooser tvar args} {

    set res [$nameofchooser {*}$args]
    if {$res!="" && $tvar!=""} {
      set $tvar $res
    }

  }

  #########################################################################
  #
  # Transfrom 'name' by adding 'typ'

  method transname {typ name} {

    if {[set pp [string last . $name]]>-1} {
      set name [string range $name 0 $pp]$typ[string range $name $pp+1 end]
    } else {
      set name $typ$name
    }
    return $name

  }

  #########################################################################
  #
  # Choosers should contain 2 fields: entry + button
  # Here every chooser is replaced with these two widgets

  method replace_chooser {r0 r1 r2 r3 args} {

    upvar 1 $r0 w $r1 i $r2 lwlen $r3 lwidgets
    lassign $args name neighbor posofnei rowspan colspan options1 attrs1
    switch -glob [my rootwname $name] {
      "fil*" {
        set chooser "tk_getOpenFile"
        set title "Choose File to Open"
      }
      "fis*" {
        set chooser "tk_getSaveFile"
        set title "Choose File to Save"
      }
      "dir*" {
        set chooser "tk_chooseDirectory"
        set title "Choose Directory"
      }
      "clr*" {
        set chooser "tk_chooseColor"
        set title "Choose Color"
      }
      default {
        return $args
      }
    }
    set tvar [set vv ""]
    set attmp [list]
    foreach {nam val} $attrs1 {
      if {$nam=="-title"} {
        set title $val
      } else {
        lappend attmp $nam $val
      }
    }
    set attrs1 $attmp
    catch {array set a $attrs1; set tvar "-tvar [set vv $a(-tvar)]"}
    catch {array set a $attrs1; set tvar "-tvar [set vv $a(-textvariable)]"}
    if {$vv==""} {
      set vv [namespace current]::$name
      set tvar "-tvar $vv"
    }
    set com "[self] chooser $chooser \{$vv\} -title \{$title\} -parent $w"
    # make a frame in the list
    set ispack 0
    if {![catch {set gm [lindex [lindex $lwidgets $i] 5]}]} {
      set ispack [expr [string first "pack " $gm]==0]
    }
    if {$ispack} {
      set args [list $name - - - - "pack -expand 1 -fill x"]
    } else {
      set args [list $name $neighbor $posofnei $rowspan $colspan "-st ew"]
    }
    lset lwidgets $i $args
    set entf [list [my transname ent $name] - - - - "pack -side left -expand 1 -fill x -in $w.$name" "$attrs1 $tvar"]
    set butf [list [my transname buT $name] - - - - "pack -side right -in $w.$name -padx 3" "-com \{\{$com\}\} -t ... -font \{\{-weight bold -size 5\}\}"]
    set lwidgets [linsert $lwidgets [expr {$i+1}] $entf $butf]
    incr lwlen 2
    return $args

  }

  #########################################################################
  #
  # Pave the window with widgets

  method window {w lwidgets} {

    set lused {}
    set lwlen [llength $lwidgets]
    set BS "I-am-BACKSPACE"
    for {set i 0} {$i < $lwlen} {} {
      # List of widgets contains data per widget:
      #   widget's name,
      #   neighbor widget, position of neighbor (T, L),
      #   widget's rowspan and columnspan (both optional),
      #   grid options, widget's attributes (both optional)
      set lst1 [lindex $lwidgets $i]
      set lst1 [my replace_chooser w i lwlen lwidgets {*}$lst1]
      lassign $lst1 name neighbor posofnei rowspan colspan options1 attrs1
      set prevw $name
      if {$colspan=={} || $colspan=={-}} {
        set colspan 1
        if {$rowspan=={} || $rowspan=={-}} {
          set rowspan 1
        }
      }
      set name [string tolower [string index $name 0]][string range $name 1 end]
      set options [uplevel 1 subst -nobackslashes [list $options1]]
      set attrs [uplevel 1 subst -nobackslashes [list $attrs1]]
      set ${nsp}paveN::wn $w.$name
      lassign [my GetWidgetType [my rootwname $name] \
        $options $attrs] widget options attrs
      # The type of widget (if defined) means its creation
      # (if not defined, it was created after "makewindow" call
      # and before "window" call)
      if { !($widget == "" || [winfo exists $widget])} {
        set attrs [string map [list \\ $BS] $attrs]
        set attrs [string map {\" \\\"} [my ExpandOptions $attrs]]
        # for scrollbars - set up the scrolling commands
        if {$widget in {"ttk::scrollbar" "scrollbar"}} {
          if {$posofnei=="L"} {
            $w.$neighbor config -yscrollcommand "$w.$name set"
            set attrs "$attrs -com \\\{$w.$neighbor yview\\\}"
            append options " -side right -fill y -after $w.$neighbor"
          } elseif {$posofnei=="T"} {
            $w.$neighbor config -xscrollcommand "$w.$name set"
            set attrs "$attrs -com \\\{$w.$neighbor xview\\\}"
            append options " -side bottom -fill x -before $w.$neighbor"
          }
        }
        # it needs expand \\, \{, \} because eval..{*}.. cuts them down
        # use doctest plugin of TKE editor to make sure:
        #
        #% doctest 1
        #%   set a "123 \\\\\\\\ 45"
        #%   eval append b {*}$a
        #%   set b
        #>   123\45
        #> doctest
        set attrs [string map [list $BS "\\\\\\\\"] $attrs]
        eval $widget [set ${nsp}paveN::wn] {*}$attrs
        # for buttons and entries - set up the hotkeys (Up/Down etc.)
        if {($widget in {"ttk::entry" $widget=="entry"}) && \
        [string first "STD" [set ${nsp}paveN::wn]]==-1} {
          # STD in $w or $name prevents it:
          bind [set ${nsp}paveN::wn] <Up> [list \
            if {$::tcl_platform(platform) == "windows"} [list \
              event generate [set ${nsp}paveN::wn] <Shift-Tab> \
            ] else [list \
              event generate [set ${nsp}paveN::wn] <Key> -keysym ISO_Left_Tab] \
            ]
          foreach k {<Down> <Return> <KP_Enter>} {
            bind [set ${nsp}paveN::wn] $k \
              [list event generate [set ${nsp}paveN::wn] <Key> -keysym Tab]
          }
        }
        if {$widget in {ttk::button button ttk::checkbutton checkbutton \
                        ttk::radiobutton radiobutton}} {
          foreach k {<Up> <Left>} {
            bind [set ${nsp}paveN::wn] $k [list \
              if {$::tcl_platform(platform) == "windows"} [list \
                event generate [set ${nsp}paveN::wn] <Shift-Tab> \
              ] else [list \
                event generate [set ${nsp}paveN::wn] <Key> -keysym ISO_Left_Tab] \
              ]
          }
          foreach k {<Down> <Right>} {
            bind [set ${nsp}paveN::wn] $k \
              [list event generate [set ${nsp}paveN::wn] <Key> -keysym Tab]
          }
          foreach k {<Return> <KP_Enter>} {
            bind [set ${nsp}paveN::wn] $k \
            [list event generate [set ${nsp}paveN::wn] <Key> -keysym space]
          }
        }
      }
      if {$neighbor eq "-" || $row < 0} {
        set row [set col 0]
      }
      set options [my GetOptions $w $options $row $rowspan $col $colspan]
      set pack [string trim $options]
      if {[string first "pack" $pack]==0} {
        pack [set ${nsp}paveN::wn] {*}[string range $pack 5 end]
      } else {
        grid [set ${nsp}paveN::wn] -row $row -column $col -rowspan $rowspan \
           -columnspan $colspan -padx 1 -pady 1 {*}$options
      }
      lappend lused [list $name $row $col $rowspan $colspan]
      if {[incr i] < $lwlen} {
        lassign [lindex $lwidgets $i] name neighbor posofnei
        if {$neighbor=="+"} {
          set neighbor $prevw
        }
        set row -1
        foreach cell $lused {
          lassign $cell uname urow ucol urowspan ucolspan
          if {$uname eq $neighbor} {
            set col $ucol
            set row $urow
            if {$posofnei == "T" || $posofnei == ""} {
              incr row $urowspan
            } elseif {$posofnei == "L"} {
              incr col $ucolspan
            }
          }
        }
      }
    }
    return $lwidgets

  }

  #########################################################################
  #
  # Show a window as modal
  # win - window's name
  # args - attributes of window set with pairs "-name value":
  #  -focus NAME sets the name of focused widget
  #  -onclose PROC sets the name of procedure being called
  #                at closing window by [X]; the procedure gets
  #                the variable name that can be changed to 0
  #                in order to close the window indeed
  #  -geometry GEOMETRY sets the geometry of window
  #  -decor DECOR sets the decorative buttons of window (if DECOR=1)

  method showModal {win args} {

    if {[my iswindows]} { ;# maybe nice to hide all windows manipulations
      wm attributes $win -alpha 0.0
    } else {
      wm withdraw $win
    }
    set root [winfo parent $win]
    array set opt \
      [list -focus "" -onclose "" -geometry "" -decor 0 -root $root {*}$args]
    lassign [split [winfo geometry $root] x+] rw rh rx ry
    if {! $opt(-decor)} {
      wm transient $win $root
    }
    if {$opt(-onclose) == ""} {
      set opt(-onclose) [list set ${nsp}paveN::PaveRes($win) 0]
    } else {
      set opt(-onclose) [list $opt(-onclose) ${nsp}paveN::PaveRes($win)]
    }
    wm protocol $win WM_DELETE_WINDOW $opt(-onclose)
    # get the window's geometry from its requested sizes
    set inpgeom $opt(-geometry)
    if {$inpgeom == ""} {
      # this is for less blinking:
      set opt(-geometry) [my CenteredXY $rw $rh $rx $ry \
        [winfo reqwidth $win] [winfo reqheight $win]]
    }
    if {[set pp [string first + $opt(-geometry)]]>=0} {
      wm geometry $win [string range $opt(-geometry) $pp end]
    }
    grab $win
    if {$opt(-focus) == ""} {
      set opt(-focus) $win
    }
    set ${nsp}paveN::PaveRes($win) "-"
    bind $win <Escape> $opt(-onclose)
    update
    if {[my iswindows]} {
      if {[wm attributes $win -alpha] < 0.1} {wm attributes $win -alpha 1.0}
    } else {
      catch {wm deiconify $win ; raise $win}
    }
    wm minsize $win [set w [winfo width $win]] [set h [winfo height $win]]
    if {$inpgeom == ""} {  ;# final geometrizing with actual sizes
      if {$root == "."} {
        ::tk::PlaceWindow $win widget $root
      } else {
        # this is for less blinking:
        wm geometry $win [my CenteredXY $rw $rh $rx $ry $w $h]
      }
    } else {
      wm geometry $win $inpgeom
    }
    after 50 [list focus $opt(-focus)]
    tkwait variable ${nsp}paveN::PaveRes($win)
    grab release $win
    return [set [set _ ${nsp}paveN::PaveRes($win)]]

  }

  #########################################################################
  #
  # This method is useful to get or set the variable value that rules
  # the closing

  method res {win {r "get"}} {

    if {$r == "get"} {
      return [set ${nsp}paveN::PaveRes($win)]
    }
    set ${nsp}paveN::PaveRes($win) $r
    return

  }

  #########################################################################
  #
  # Create a toplevel window with "w" name and "ttl" title

  method makeWindow {w ttl} {

    set w [string trimright $w .]
    catch {destroy $w}
    set w [toplevel $w]
    wm title $w $ttl
    return $w

  }

  #########################################################################
  #
  # Get the tag positions in the contsName text and display it in w text
  # widget. The lines in contsName are divided by \n. The tags in tags
  # variable are "pure" ones i.e. for <b>..</b> the tags list contains "b".
  # Also the tags list contains the tagging options (-font etc.).
  # The contsName is a varname of contents variable.

  method displayTaggedText {w contsName tags} {

    upvar $contsName conts
    set taglist [set tagpos [set taglen [list]]]
    foreach tagi $tags {
      lassign $tagi tag
      lappend tagpos 0
      lappend taglen [string length $tag]
    }
    set tLen [llength $tags]
    set disptext ""
    set irow 1
    foreach line [split $conts \n] {
      if {$irow > 1} {
        append disptext \n
      }
      set newline ""
      while 1 {
        set p [string first \< $line]
        if {$p < 0} {
          break
        }
        append newline [string range $line 0 $p-1]
        set line [string range $line $p end]
        set i 0
        set nrnc $irow.[string length $newline]
        foreach tagi $tags pos $tagpos len $taglen {
          lassign $tagi tag
          if {[string first "\<$tag\>" $line]==0} {
            if {$pos != "0"} { error "Mismatched \<$tag\> in line $irow." }
            lset tagpos $i $nrnc
            set line [string range $line $len+2 end]
            break
          } elseif {[string first "\</$tag\>" $line]==0} {
            if {$pos == "0"} { error "Mismatched \</$tag\> in line $irow." }
            lappend taglist [list $i $pos $nrnc]
            lset tagpos $i 0
            set line [string range $line $len+3 end]
            break
          }
          incr i
        }
        if {$i == $tLen} {
          # tag not found after "<" - shift by 1 character
          append newline [string index $line 0]
          set line [string range $line 1 end]
        }
      }
      append disptext $newline $line
      incr irow
    }
    $w replace 1.0 end $disptext
    foreach tagi $tags {
      lassign $tagi tag opts
      $w tag config $tag {*}$opts
    }
    foreach tagli $taglist {
      lassign $tagli i p1 p2
      lassign [lindex $tags $i] tag opts
      $w tag add $tag $p1 $p2
    }

  }

}

