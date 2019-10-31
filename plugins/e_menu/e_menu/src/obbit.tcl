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
#   someobj set Prop1 100
#
# Call of getter:
#   oo::define SomeClass {
#     mixin ObjectProperty
#   }
#   SomeClass create someobj
#   ...
#   someobj get Alter 10
#   someobj get Alter

oo::class create ObjectProperty {

  variable _Object_Properties

  constructor {args} {
    array set _Object_Properties {}
    # ObjectProperty can play solo or be a mixin
    catch {set res [next {*}$args]}
  }

  method set {name args} {
    switch [llength $args] {
      0 {return [my get $name]}
      1 {return [set _Object_Properties($name) $args]}
    }
    puts -nonewline stderr \
      "Wrong # args: should be \"[namespace current] set propertyname ?value?\""
    return -code error
  }

  method get {name {defvalue ""}} {
    if [info exists _Object_Properties($name)] {
      return $_Object_Properties($name)
    }
    return $defvalue
  }

}

###########################################################################
# Another bit - manager for theming (might be enhanced a lot)

oo::class create ObjectTheming {

  variable _Object_Theming_Opts
  variable _Object_Theming_OldOpts
  constructor {args} {
    array set _Object_Theming_Opts {}
    set _Object_Theming_OldOpts {}
    # ObjectTheming can play solo or be a mixin
    catch {set res [next {*}$args]}
  }
  destructor {
    catch {next}
  }

  # Set the new style options
  method Ttk_style {oper ts opt val} {
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
      if {$oldval!="" || $oper=="map"} {
        lappend _Object_Theming_OldOpts $oper $ts $opt $oldval
      }
    }
  }

  #--------------------------------------------------------------------------
  # Change a style (theming a bit)
  # Input:
  # tfg1 tbg1 - fore/background for themed widgets (main stock)
  # tfg2 tbg2 - fore/background for themed widgets (enter data stock)
  # tfgS tbgS - fore/background for selection
  # tfgD tbgD - fore/background for disabled themed widgets
  # tcur      - insertion cursor color
  # bclr      - border color
  # args      - other options

  method themingWindow {win tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr args} {
    if {$win=="."} {
      foreach arg {tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr args} {
        set _Object_Theming_Opts($win,$arg) [set $arg]
      }
    }
    set _Object_Theming_OldOpts [list]
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
      set _Object_Theming_Opts($ts,0) 2
      set _Object_Theming_Opts($ts,1) "-background $tbg1"
      set _Object_Theming_Opts($ts,2) "-foreground $tfg1"
      switch -- $ts {
        "checkbutton" - "radiobutton" {
          set _Object_Theming_Opts($ts,0) 4
          set _Object_Theming_Opts($ts,3) "-selectcolor $tbg1"
          set _Object_Theming_Opts($ts,4) "-highlightbackground $tbg1"
        }
        "frame" - "scrollbar" {
          set _Object_Theming_Opts($ts,0) 1
        }
      }
    }
    foreach ts [my NonThemedWidgets entry] {
      set _Object_Theming_Opts($ts,0) 2
      set _Object_Theming_Opts($ts,1) "-foreground $tfg2"
      set _Object_Theming_Opts($ts,2) "-background $tbg2"
      switch -- $ts {
        "text" - "entry"  {
          set _Object_Theming_Opts($ts,0) 7
          set _Object_Theming_Opts($ts,3) "-insertbackground $tcur"
          set _Object_Theming_Opts($ts,4) "-selectforeground $tfgS"
          set _Object_Theming_Opts($ts,5) "-selectbackground $tbgS"
          set _Object_Theming_Opts($ts,6) "-disabledforeground $tfgD"
          set _Object_Theming_Opts($ts,7) "-disabledbackground $tbgD"
        }
        "spinbox" - "listbox" {
          set _Object_Theming_Opts($ts,0) 8
          set _Object_Theming_Opts($ts,3) "-insertbackground $tcur"
          set _Object_Theming_Opts($ts,4) "-buttonbackground $tbg2"
          set _Object_Theming_Opts($ts,5) "-selectforeground $tfgS"
          set _Object_Theming_Opts($ts,6) "-selectbackground $tbgS"
          set _Object_Theming_Opts($ts,7) "-disabledforeground $tfgD"
          set _Object_Theming_Opts($ts,8) "-disabledbackground $tbgD"
        }
      }
    }
    foreach ts {disabled} {
      set _Object_Theming_Opts($ts,0) 4
      set _Object_Theming_Opts($ts,1) "-foreground $tfgD"
      set _Object_Theming_Opts($ts,2) "-background $tbgD"
      set _Object_Theming_Opts($ts,3) "-disabledforeground $tfgD"
      set _Object_Theming_Opts($ts,4) "-disabledbackground $tbgD"
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
        set ind [incr _Object_Theming_Opts($v1,0)]
        set _Object_Theming_Opts($v1,$ind) "$v2"
      } else {
        # style maps of themed widgets
        my Ttk_style map $typ $v1 [list {*}$v2]
      }
    }
    # at last, separate widget types
    ttk::style configure TButton \
      -anchor center -width -11 -padding 3 -relief raised -borderwidth 2

  }

  #--------------------------------------------------------------------------
  # Restore the appearance options saved in themingWindow

  method themingRestore {} {

    foreach {oper ts opt val} $_Object_Theming_OldOpts {
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
  }

  #--------------------------------------------------------------------------
  # Updating the appearances of currently used widgets (non-themed)
  # Input:
  #   win - window path, supposedly passed as [winfo uplevel $w]
  #   setting - 1, if the widgets should be configured

  method themingNonThemed {win setting} {

    set wtypes [my NonThemedWidgets all]
    foreach w1 [winfo children $win] {
      my themingNonThemed $w1 $setting
      set ts [string tolower [winfo class $w1]]
      if {[lsearch -exact $wtypes $ts]>-1} {
        set i 0
        while {[incr i] <= $_Object_Theming_Opts($ts,0)} {
          lassign $_Object_Theming_Opts($ts,$i) opt val
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
            lappend _Object_Theming_OldOpts $w1 $ts $opt $oldval
          }
        }
      }
    }
    return

  }

  #--------------------------------------------------------------------------
  # List the non-themed widgets to process here

  method NonThemedWidgets {selector} {

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

    if {[info exists _Object_Theming_Opts(.,tfg1)]} {
      my themingWindow $win \
         $_Object_Theming_Opts(.,tfg1) \
         $_Object_Theming_Opts(.,tbg1) \
         $_Object_Theming_Opts(.,tfg2) \
         $_Object_Theming_Opts(.,tbg2) \
         $_Object_Theming_Opts(.,tfgS) \
         $_Object_Theming_Opts(.,tbgS) \
         $_Object_Theming_Opts(.,tfgD) \
         $_Object_Theming_Opts(.,tbgD) \
         $_Object_Theming_Opts(.,tcur) \
         $_Object_Theming_Opts(.,bclr) \
         {*}$_Object_Theming_Opts(.,args)
    }

  }

  #--------------------------------------------------------------------------
  #
  # Style for non-ttk widgets
  # Input: "typ" is the same as in "PaveMe GetWidgetType" method

  method NonTtkStyle {typ {dsbl 0}} {

    if {$dsbl} {
      set disopt ""
      if {[info exist _Object_Theming_Opts(disabled,0)]} {
        set typ [string range [lindex [split $typ .] end] 0 2]
        switch $typ {
          frA - lfR {
            append disopt " " $_Object_Theming_Opts(disabled,2)
          }
          enT - spX {
            append disopt " " $_Object_Theming_Opts(disabled,1) \
                          " " $_Object_Theming_Opts(disabled,2) \
                          " " $_Object_Theming_Opts(disabled,3) \
                          " " $_Object_Theming_Opts(disabled,4)
          }
          laB - tex - chB - raD - lbx - scA {
            append disopt " " $_Object_Theming_Opts(disabled,1) \
                          " " $_Object_Theming_Opts(disabled,2)
          }
        }
      }
      return $disopt
    }
    set opts {-foreground -foreground -background -background}
    set ts2 [set ts3 [set opts2 [set opts3 ""]]]
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

#% doctest ObjectParsingUtils
###########################################################################
#
# Another bit: Parsing utilities.

oo::class create ObjectParsingUtils {

  variable _PU_opts

  constructor {args} {

    # Initializes _PU_opts variable.
    #   args - passed arguments
    #
    # When ObjectParsingUtils used as a separate class and args[0]
    # equals to "-NONE", args[1] means the new -NONE constant.
    #
    # The -NONE constant is a "default value" for single options
    # and equals to "=NONE=" by default.
    #
    # Examples:
    #   ObjectParsingUtils create obj1
    #   ObjectParsingUtils create obj2 -NONE <NONE>
    #
    # When ObjectParsingUtils used as mixin, the constructor
    # would pass its arguments to the next constructor.

    array set _PU_opts {-NONE =NONE=}
    if {[llength [self next]]} {
      next {*}$args
    } elseif {[llength $args]>1 && [lindex $args 0]=="-NONE"} {
      set _PU_opts(-NONE) [lindex $args 1]
    }

  }

  method parseOptionsFile {strict passedargs args} {

    # Parses argument list containing options and file name.
    #   strict - if 0, 'args' options will be counted for,
    #              other options are skipped
    #   strict - if 1, only 'args' options are allowed,
    #              all the rest are considered as file name parts
    #          - if 2, the 'args' options will replace the
    #              options of 'passedargs'
    #   passedargs - list of options, values and a file name
    #   args - option names and defaults
    #
    # The passedargs list contains:
    #   - option names beginning with "-"
    #   - option values following their names (may be missing)
    #   - "--" denoting the end of options
    #   - file name following the options and their values
    #
    # The args parameter contains the pairs:
    #   - option name (e.g., "-dir")
    #   - option default value
    # If the option default value is equal to =NONE=, the
    # option is considered as a single option without a value.
    #
    # Returns an options/values list and a file name.
    # The options/values list contains the pairs:
    #   - option name (according to args)
    #   - option value
    # For a single =NONE= option, the returned value is not
    # equal to =NONE=, if the option is specified in passedargs.
    #
    # If any option of passedargs is absent in args and strict==1,
    # the rest of passedargs is considered to be a file name.
    #
    # Example:
    #   lassign [obj parseOptionsFile true {-d mydir -all myfile} \
    #     -d /home/me -opt some -all =NONE=] optvals filename
    #   lassign optvals - dir - opt - all
    #   puts "dir:$dir  opt:$opt  all:$all"
    #     # or this way:
    #   array set opts $optvals
    #   puts "dir:$opts(-d)  opt:$opts(-opt)  all:$opts(-all)"

    set actopts true
    array set argarray $args
    if {$strict==2} {
      set retlist $passedargs
    } else {
      set retlist $args
    }
    set retfile ""
    for {set i 0} {$i < [llength $passedargs]} {incr i} {
      set parg [lindex $passedargs $i]
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
            incr i
          } else {
            if {$defval == $_PU_opts(-NONE)} {
              set defval yes
            } else {
              set defval [lindex $passedargs [incr i]]
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
}

# DOCTEST OF ObjectParsingUtils
#
#% ObjectParsingUtils create obj -NONE <NONE>
#%
#% lassign [obj parseOptionsFile 1 {-d mydir -all myfile with spaces} \
#%     -d /home/me -opt some -all <NONE>] optvals1 filename1
#% array set opts $optvals1
#%
#% lassign [obj parseOptionsFile 1 \
#%   {-opt new -d "dir with spases and \"" -- -all the rest} \
#%     -d /home/me -opt some -all =NONE=] optvals2 filename2
#%
#% lassign [obj parseOptionsFile 0 \
#%   {-opt new -d "dir with spases and \"" -f myfile} -d some] optvals3
#%
#% lassign [obj parseOptionsFile 2 \
#%   {-opt new -d "dir with spases and \"" -f myfile} -d some] optvals4
#% obj destroy
#%
#% set a "$opts(-d) $opts(-opt) $opts(-all) FILE1=$filename1 \n \
#%  " $optvals2 FILE2=$filename2 \n  OPT3=$optvals3  OPT4=$optvals4""
#> "mydir some yes FILE1=myfile with spaces "
#> "  -d {dir with spases and "} -opt new -all =NONE= FILE2=-all the rest "
#> "  OPT3=-d {dir with spases and "}  OPT4=-opt new -d some -f myfile"
#
#> doctest

################################# EOF #####################################
