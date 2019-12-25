###########################################################################
#
# This script contains a bunch of oo::classes. A bit of it.
#
# The ObjectProperty class allows to mix-in into
# an object the getter and setter of properties.
#
# The ThemingManager class allows to change the ttk widgets' style.
# For now it's only a bit of what should be, it needs to be enhanced a lot.
#
# The ObjectUtils class provides methods to extract option values... and 
# other useful methods.
#
###########################################################################

# static class variables
# made by DKF, see https://wiki.tcl-lang.org/page/TclOO+Tricks

proc ::oo::Helpers::classvar {name args} {
    # Get reference to class’s namespace
    set ns [info object namespace [uplevel 1 {self class}]]

    # Double up the list of varnames
    set vs [list $name $name]
    foreach v $args {lappend vs $v $v}

    # Link the caller’s locals to the class’s variables
    tailcall namespace upvar $ns {*}$vs
}

namespace eval pave {
}

###########################################################################
#
# 1st bit: Set/Get properties of object.
#
# Call of setter:
#   oo::define SomeClass {
#     mixin ObjectProperty
#   }
#   SomeClass create someobj
#   ...
#   someobj setProperty Prop1 100
#
# Call of getter:
#   oo::define SomeClass {
#     mixin ObjectProperty
#   }
#   SomeClass create someobj
#   ...
#   someobj getProperty Alter 10
#   someobj getProperty Alter

oo::class create pave::ObjectProperty {

  variable _OP_Properties

  constructor {args} {
    array set _OP_Properties {}
    # ObjectProperty can play solo or be a mixin
    if {[llength [self next]]} { next {*}$args }
  }

  method setProperty {name args} {
    switch [llength $args] {
      0 {return [my getProperty $name]}
      1 {return [set _OP_Properties($name) $args]}
    }
    puts -nonewline stderr \
      "Wrong # args: should be \"[namespace current] setProperty propertyname ?value?\""
    return -code error
  }

  method getProperty {name {defvalue ""}} {
    if [info exists _OP_Properties($name)] {
      return $_OP_Properties($name)
    }
    return $defvalue
  }

}

###########################################################################
# Another bit - manager for theming (might be enhanced a lot)

oo::class create pave::ObjectTheming {

  mixin pave::ObjectProperty

  constructor {args} {
    # _OT_Init _OT_Opts _OT_OldOpts must be static in ObjectTheming class
    # because they are applied to a whole application, not to a widget
    classvar _OT_Init _OT_Opts _OT_OldOpts
    array set _OT_Opts {}
    set _OT_OldOpts {}
    set _OT_Opts(expo,tfg1) "-"
    set _OT_Init 1
    # ObjectTheming can play solo or be a mixin
    if {[llength [self next]]} { next {*}$args }
  }

  # Set the new style options
  method Ttk_style {oper ts opt val} {

    classvar _OT_Init _OT_Opts _OT_OldOpts
    if {![catch {set oldval [ttk::style $oper $ts $opt]}]} {
      catch {ttk::style $oper $ts $opt $val}
      if {$oldval=="" && $oper=="configure"} {
        switch $opt {
          -foreground - -background {
            set oldval [ttk::style $oper . $opt]
          }
          -fieldbackground {
            set oldval white
          }
          -insertcolor {
            set oldval black
          }
        }
      }
      if {$_OT_Init && ($oldval!="" || $oper=="map")} {
        lappend _OT_OldOpts $oper $ts $opt $oldval
      }
    }
  }

  #--------------------------------------------------------------------------
  # The combobox widget leverages the pre-ttk Listbox for its dropdown
  # element and as such the 'option' command is currently required to set
  # the listbox options.
  # See also: https://wiki.tcl-lang.org/page/Changing+Widget+Colors

  method Combobox_Dropdown_Colors { args } {

    classvar _OT_Init _OT_Opts _OT_OldOpts
    set optkey "_combo_color_"
    catch {
      if {[llength $args] && $_OT_Opts(expo,tfg1) ne "-"} {
        # no ttk::style for listbox,
        # so a listbox widget is necessary to get its colors
        listbox [set l .lbx$optkey]
        foreach clrnam {back fore selectBack selectFore} {
          set _OT_Opts($optkey,$clrnam) \
           [lindex [$l conf -[string tolower $clrnam]ground] 3]
        }
        destroy $l
      }
      foreach {i clrnam} {0 back 1 fore 2 selectBack 3 selectFore} {
        if {[llength $args] && $_OT_Opts(expo,tfg1) ne "-"} {
          set clr [lindex $args $i]
        } else {
          set clr [set _OT_Opts($optkey,$clrnam)]
        }
        # regretfully, no removing/updating option
        # so, it wouldn't work at restoring original theme
        option add *TCombobox*Listbox.${clrnam}ground $clr userDefault
      }
    }
  }

  #--------------------------------------------------------------------------
  method exportTheme {} {

    classvar _OT_Init _OT_Opts _OT_OldOpts
    set theme ""
    foreach arg {tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr args} {
      if {[catch {set a "$_OT_Opts(expo,$arg)"}] || $a==""} {
        break
      }
      append theme " $a"
    }
    return $theme

  }

  #--------------------------------------------------------------------------
  # Change a Tk style (theming a bit)
  # Input:
  # tfg1 tbg1 - fore/background for themed widgets (main stock)
  # tfg2 tbg2 - fore/background for themed widgets (enter data stock)
  # tfgS tbgS - fore/background for selection
  # tfgD tbgD - fore/background for disabled themed widgets
  # tcur      - insertion cursor color
  # bclr      - border color
  # args      - other options

  method themingWindow {win {tfg1 ""} {tbg1 ""} {tfg2 ""} {tbg2 ""}
    {tfgS ""} {tbgS ""} {tfgD ""} {tbgD ""} {tcur ""} {bclr ""} args} {

    classvar _OT_Init _OT_Opts _OT_OldOpts
    if {$tfg1 eq "-"} return
    foreach arg {tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr args} {
      if {$win eq "."} {
        set _OT_Opts($win,$arg) [set $arg]
      }
      set _OT_Opts(expo,$arg) [set $arg]
    }
    # save old colors, set new ones for combobox
    my Combobox_Dropdown_Colors $tbg2 $tfg2 $tbgS $tfgS
    # configuring themed widgets
    foreach ts {TLabel TButton TCheckbutton TProgressbar TRadiobutton \
    TScale TScrollbar TSeparator TSizegrip} {
      my Ttk_style configure $ts -foreground $tfg1
      my Ttk_style configure $ts -background $tbg1
      my Ttk_style map $ts -background [list active $tbg2 pressed $tbg2 alternate $tbg2 focus $tbg2 selected $tbg2]
      my Ttk_style map $ts -foreground [list disabled grey active $tfg2 pressed $tfg2 alternate $tfg2 focus $tfg2 selected $tfg2]
      my Ttk_style map $ts -bordercolor [list focus $bclr pressed $bclr]
      my Ttk_style map $ts -lightcolor [list focus $bclr]
      my Ttk_style map $ts -darkcolor [list focus $bclr]
      my Ttk_style configure $ts -fieldforeground $tfg2
      my Ttk_style configure $ts -fieldbackground $tbg2
    }
    foreach ts {TLabelframe TNotebook TPanedwindow TFrame} {
      my Ttk_style configure $ts -foreground $tfg1
      my Ttk_style configure $ts -background $tbg1
    }
    foreach ts {TNotebook.Tab} {
      my Ttk_style configure $ts -foreground $tfg1
      my Ttk_style configure $ts -background $tbg1
      my Ttk_style map $ts -foreground \
        [list selected $tfgS active $tfg2 disabled $tfgD]
      my Ttk_style map $ts -background \
        [list selected $tbgS active $tbg2 disabled $tbgD]
    }

    foreach ts {TEntry Treeview TSpinbox TCombobox} {
      my Ttk_style configure $ts -selectforeground $tfgS
      my Ttk_style configure $ts -selectbackground $tbgS
      my Ttk_style configure $ts -fieldforeground $tfg2
      my Ttk_style configure $ts -fieldbackground $tbg2
      my Ttk_style configure $ts -insertcolor $tcur
      my Ttk_style map $ts -bordercolor [list focus $bclr active $bclr]
      my Ttk_style map $ts -lightcolor [list focus $bclr]
      my Ttk_style map $ts -darkcolor [list focus $bclr]
      if {$ts=="TCombobox"} {
        # combobox is sort of individual
        my Ttk_style configure $ts -foreground $tfg1
        my Ttk_style configure $ts -background $tbg1
        my Ttk_style map $ts -foreground [list readonly black]
      } else {
        my Ttk_style configure $ts -foreground $tfg2
        my Ttk_style configure $ts -background $tbg2
        my Ttk_style map $ts -foreground [list disabled $tfgD readonly $tfgD selected $tfgS]
        my Ttk_style map $ts -background [list disabled $tbgD readonly $tbgD selected $tbgS]
      }
    }
    # non-themed widgets of button and entry types
    foreach ts [my NonThemedWidgets button] {
      set _OT_Opts($ts,0) 2
      set _OT_Opts($ts,1) "-background $tbg1"
      set _OT_Opts($ts,2) "-foreground $tfg1"
      switch -- $ts {
        "checkbutton" - "radiobutton" {
          set _OT_Opts($ts,0) 4
          set _OT_Opts($ts,3) "-selectcolor $tbg1"
          set _OT_Opts($ts,4) "-highlightbackground $tbg1"
        }
        "frame" - "scrollbar" {
          set _OT_Opts($ts,0) 1
        }
      }
    }
    foreach ts [my NonThemedWidgets entry] {
      set _OT_Opts($ts,0) 2
      set _OT_Opts($ts,1) "-foreground $tfg2"
      set _OT_Opts($ts,2) "-background $tbg2"
      switch -- $ts {
        "text" - "entry"  {
          set _OT_Opts($ts,0) 7
          set _OT_Opts($ts,3) "-insertbackground $tcur"
          set _OT_Opts($ts,4) "-selectforeground $tfgS"
          set _OT_Opts($ts,5) "-selectbackground $tbgS"
          set _OT_Opts($ts,6) "-disabledforeground $tfgD"
          set _OT_Opts($ts,7) "-disabledbackground $tbgD"
        }
        "spinbox" - "listbox" {
          set _OT_Opts($ts,0) 8
          set _OT_Opts($ts,3) "-insertbackground $tcur"
          set _OT_Opts($ts,4) "-buttonbackground $tbg2"
          set _OT_Opts($ts,5) "-selectforeground $tfgS"
          set _OT_Opts($ts,6) "-selectbackground $tbgS"
          set _OT_Opts($ts,7) "-disabledforeground $tfgD"
          set _OT_Opts($ts,8) "-disabledbackground $tbgD"
        }
      }
    }
    foreach ts {disabled} {
      set _OT_Opts($ts,0) 4
      set _OT_Opts($ts,1) "-foreground $tfgD"
      set _OT_Opts($ts,2) "-background $tbgD"
      set _OT_Opts($ts,3) "-disabledforeground $tfgD"
      set _OT_Opts($ts,4) "-disabledbackground $tbgD"
    }
    # for branched items (menu e.g.):
    # at first saving the current options, then setting the new ones
    # as parents' options define children's
    my themingNonThemed $win 0
    my themingNonThemed $win 1
    # other options per widget type
    foreach {typ v1 v2} $args {
      if {$typ=="-"} {
        # config of non-themed widgets
        set ind [incr _OT_Opts($v1,0)]
        set _OT_Opts($v1,$ind) "$v2"
      } else {
        # style maps of themed widgets
        my Ttk_style map $typ $v1 [list {*}$v2]
      }
    }
    # at last, separate widget types
    ttk::style configure TButton \
      -anchor center -width -11 -padding 3 -relief raised -borderwidth 2
    set _OT_Init 0

  }

  #--------------------------------------------------------------------------
  # Restore the appearance options saved in themingWindow

  method themingRestore {} {

    classvar _OT_Init _OT_Opts _OT_OldOpts
    foreach {oper ts opt val} $_OT_OldOpts {
      switch $oper {
        map -
        configure {
          ttk::style $oper $ts $opt $val
        }
        default {
          catch { $oper configure $opt $val }
        }
      }
    }
    my Combobox_Dropdown_Colors  ;# restore old colors for combobox
    set _OT_Opts(expo,tfg1) "-"
  }

  #--------------------------------------------------------------------------
  # Updating the appearances of currently used widgets (non-themed)
  # Input:
  #   win - window path, supposedly passed as [winfo uplevel $w]
  #   setting - 1, if the widgets should be configured

  method themingNonThemed {win setting} {

    classvar _OT_Init _OT_Opts _OT_OldOpts
    set wtypes [my NonThemedWidgets all]
    foreach w1 [winfo children $win] {
      my themingNonThemed $w1 $setting
      set ts [string tolower [winfo class $w1]]
      if {[lsearch -exact $wtypes $ts]>-1} {
        set i 0
        while {[incr i] <= $_OT_Opts($ts,0)} {
          lassign $_OT_Opts($ts,$i) opt val
          if {$setting} {
            catch {
              $w1 configure $opt $val
              if {[$w1 cget -state]=="disabled"} {
                $w1 configure {*}[my NonTtkStyle $w1 1]
              }
            }
          } else {
            if {[catch {set oldval [$w1 cget $opt]}]} {
              switch -- $opt {
                -background - -foreground { set oldval [. cget $opt] }
                default continue
              }
            }
            if {$_OT_Init} {
              lappend _OT_OldOpts $w1 $ts $opt $oldval
            }
          }
        }
      }
    }
    return

  }

  #--------------------------------------------------------------------------
  # List the non-themed widgets to process here

  method NonThemedWidgets {selector} {

    classvar _OT_Init _OT_Opts _OT_OldOpts
    switch $selector {
      entry {
        return [list entry text listbox spinbox]
      }
      button {
        return [list label button menu menubutton checkbutton radiobutton frame labelframe scale scrollbar]
      }
    }
    return [list entry text listbox spinbox label button menu menubutton checkbutton radiobutton frame labelframe scale scrollbar]

  }

  #--------------------------------------------------------------------------
  #
  # Theme for non-ttk widgets

  method NonTtkTheme {win} {

    classvar _OT_Init _OT_Opts _OT_OldOpts
    if {[info exists _OT_Opts(.,tfg1)] &&
    $_OT_Opts(expo,tfg1) ne "-"} {
      my themingWindow $win \
         $_OT_Opts(.,tfg1) \
         $_OT_Opts(.,tbg1) \
         $_OT_Opts(.,tfg2) \
         $_OT_Opts(.,tbg2) \
         $_OT_Opts(.,tfgS) \
         $_OT_Opts(.,tbgS) \
         $_OT_Opts(.,tfgD) \
         $_OT_Opts(.,tbgD) \
         $_OT_Opts(.,tcur) \
         $_OT_Opts(.,bclr) \
         {*}$_OT_Opts(.,args)
    }

  }

  #--------------------------------------------------------------------------
  #
  # Style for non-ttk widgets
  # Input: "typ" is the same as in "PaveMe GetWidgetType" method

  method NonTtkStyle {typ {dsbl 0}} {

    classvar _OT_Init _OT_Opts _OT_OldOpts
    if {$dsbl} {
      set disopt ""
      if {[info exist _OT_Opts(disabled,0)]} {
        set typ [string range [lindex [split $typ .] end] 0 2]
        switch $typ {
          frA - lfR {
            append disopt " " $_OT_Opts(disabled,2)
          }
          enT - spX {
            append disopt " " $_OT_Opts(disabled,1) \
                          " " $_OT_Opts(disabled,2) \
                          " " $_OT_Opts(disabled,3) \
                          " " $_OT_Opts(disabled,4)
          }
          laB - tex - chB - raD - lbx - scA {
            append disopt " " $_OT_Opts(disabled,1) \
                          " " $_OT_Opts(disabled,2)
          }
        }
      }
      return $disopt
    }
    set opts {-foreground -foreground -background -background}
    lassign "" ts2 ts3 opts2 opts3
    switch -- $typ {
      "buT" {set ts TButton}
      "chB" {set ts TCheckbutton
        lappend opts -background -selectcolor
      }
      "enT" {
        set ts TEntry
        set opts  {-foreground -foreground -fieldbackground -background \
          -insertbackground -insertcolor}
      }
      "tex" {
        set ts TEntry
        set opts {-foreground -foreground -fieldbackground -background \
          -insertcolor -insertbackground \
          -selectforeground -selectforeground -selectbackground -selectbackground
        }
      }
      "frA" {set ts TFrame; set opts {-background -background}}
      "laB" {set ts TLabel}
      "lbx" {set ts TLabel}
      "lfR" {set ts TLabelframe}
      "raD" {set ts TRadiobutton}
      "scA" {set ts TScale}
      "sbH" -
      "sbV" {set ts TScrollbar; set opts {-background -background}}
      "spX" {set ts TSpinbox}
      default {
        return ""
      }
    }
    set att ""
    for {set i 1} {$i<=3} {incr i} {
      if {$i>1} {
        set ts [set ts$i]
        set opts [set opts$i]
      }
      foreach {opt1 opt2} $opts {
        if {[catch {set val [ttk::style configure $ts $opt1]}]} {
          return $att
        }
        if {$val==""} {
          catch { set val [ttk::style $oper . $opt2] }
        }
        if {$val!=""} {
          append att " $opt2 $val"
        }
      }
    }
    return $att

  }

}

###########################################################################
#
# Another bit: Parsing utilities.

oo::class create pave::ObjectUtils {

  variable _PU_opts

  constructor {args} {

    # Initializes _PU_opts variable.
    #   args - passed arguments
    #
    # When ObjectUtils used as a separate class and args[0]
    # equals to "-NONE", args[1] means the new -NONE constant.
    #
    # The -NONE constant is a "default value" for single options
    # and equals to "=NONE=" by default.
    #
    # Examples:
    #   ObjectUtils create obj1
    #   ObjectUtils create obj2 -NONE <NONE>
    #
    # When ObjectUtils used as mixin, the constructor
    # would pass its arguments to the next constructor.

    array set _PU_opts {-NONE =NONE=}
    if {[llength [self next]]} {
      next {*}$args
    } elseif {[llength $args]>1 && [lindex $args 0]=="-NONE"} {
      set _PU_opts(-NONE) [lindex $args 1]
    }

  }

  method parseOptionsFile {strict args1 args} {

    # Parses argument list containing options and (possibly) a file name.
    #   strict - if 0, 'args' options will be only counted for,
    #              other options are skipped
    #   strict - if 1, only 'args' options are allowed,
    #              all the rest of args1 to be a file name
    #          - if 2, the 'args' options replace the
    #              appropriate options of 'args1'
    #   args1 - list of options, values and a file name
    #   args  - list of default options
    #
    # The args1 list contains:
    #   - option names beginning with "-"
    #   - option values following their names (may be missing)
    #   - "--" denoting the end of options
    #   - file name following the options (may be missing)
    #
    # The args parameter contains the pairs:
    #   - option name (e.g., "-dir")
    #   - option default value
    # If the args option value is equal to =NONE=, the args1 option
    # is considered to be a single option without a value and,
    # if present in args1, its value is returned as "yes".
    #
    # Returns a list of two items:
    #   - an option list got from args/args1 according to 'strict'
    #   - a file name from args1 or {} if absent
    #
    # If any option of args1 is absent in args and strict==1,
    # the rest of args1 is considered to be a file name.
    #
    # Examples see in tests/obbit.test.

    set actopts true
    array set argarray "$args yes yes" ;# maybe, tail option without value
    if {$strict==2} {
      set retlist $args1
    } else {
      set retlist $args
    }
    set retfile {}
    for {set i 0} {$i < [llength $args1]} {incr i} {
      set parg [lindex $args1 $i]
      if {$actopts} {
        if {$parg=="--"} {
          set actopts false
        } elseif {[catch {set defval $argarray($parg)}]} {
          if {$strict==1} {
            set actopts false
            append retfile $parg " "
          } else {
            incr i
          }
        } else {
          if {$strict==2} {
            if {$defval == $_PU_opts(-NONE)} {
              set defval yes
            }
            incr i
          } else {
            if {$defval == $_PU_opts(-NONE)} {
              set defval yes
            } else {
              set defval [lindex $args1 [incr i]]
            }
          }
          set ai [lsearch -exact $retlist $parg]
          incr ai
          set retlist [lreplace $retlist $ai $ai $defval]
        }
      } else {
        append retfile $parg " "
      }
    }
    return [list $retlist [string trimright $retfile]]

  }

  method getOption {optname args} {

    # Extracts one option from an option list.
    #   optname - option name
    #   args - option list
    # Returns an option value or "".
    # Example:
    #   set options [list -name some -value "any value" -tooltip "some tip"]
    #   set optvalue [my getOption -tooltip {*}$options]

    lassign [my parseOptionsFile 0 $args $optname ""] options
    lassign $options -> optvalue
    return $optvalue

  }

  method putOption {optname optvalue args} {

    # Replaces or adds one option to an option list.
    #   optname - option name
    #   optvalue - option value
    #   args - option list
    # Returns an updated option list.

    set optlist {}
    set doadd true
    foreach {a v} $args {
      if {$a eq $optname} {
        set v $optvalue
        set doadd false
      }
      lappend optlist $a $v
    }
    if {$doadd} {lappend optlist $optname $optvalue}
    return $optlist

  }

  #########################################################################
  #
  # Remove some options from the options
  # Input:
  #   options - string of all options
  #   args - list of removed options
  # Prerequisite:
  #   options are set as a list of pairs (key value)

  method RemoveSomeOptions {options args} {

    foreach key $args {
      if {[set i [lsearch -exact $options $key]]>-1} {
        set optorig $options
        catch {
          set options [lreplace $options $i $i]
          set options [lreplace $options $i $i]
        }
      }
    }
    return $options

  }

  #########################################################################
  #
  # Read a text file
  #   fileName - file name
  #   varName - variable name for file content or ""
  #   doErr - if 'true', exit at errors with error message
  # Returns file contents or "".

  method readTextFile {fileName {varName ""} {doErr 0}} {

    if {$varName ne ""} {upvar $varName fvar}
    if {[catch {set chan [open $fileName]}]} {
      if {$doErr} {
        error "\npaveme.tcl: can't open \"$fileName\"\n"
      }
      set fvar ""
    } else {
      set fvar [read $chan]
      close $chan
    }
    return $fvar

  }

}

  #%   DOCTEST   SOURCE   tests/obbit_1.test

################################# EOF #####################################
