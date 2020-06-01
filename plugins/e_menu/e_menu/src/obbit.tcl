###########################################################################
#
# This script contains a bunch of oo::classes. A bit of it.
#
# The ObjectProperty class allows to mix-in into
# an object the getter and setter of properties.
#
# The ObjectTheming class allows to change the ttk widgets' style.
# For now it's only a bit of what should be, it needs to be enhanced a lot.
#
# The ObjectUtils class provides methods to extract option values... and
# other useful methods.
#
###########################################################################

package require Tk

namespace eval ::apave {

    # variables global to apave objects:
    # - main color scheme data
    variable ::apave::_CS_; array set ::apave::_CS_ [list]
    # - current color scheme data
    variable ::apave::_C_; array set ::apave::_C_ [list]
    set ::apave::_CS_(initall) 1
    set ::apave::_CS_(initold) 1
    set ::apave::_CS_(initWM) 1
    set ::apave::_CS_(oldlist) [list]
    set ::apave::_CS_(!FG) #000000
    set ::apave::_CS_(!BG) #c3c3c3
    set ::apave::_CS_(expo,tfg1) "-"
    set ::apave::_CS_(ALL) {
{MildDark      #E8E8E8 #E7E7E7 #222A2F #2D435B #FEEFA8 #8CC6D9 #000000  #4EADAD grey    #4EADAD}
{Brown         #E8E8E8 #E7E7E7 #352927 #453528 #FEEC9A #B7A78C #000000  #E69800 grey    #E69800}
{Sky           #102433 #0A1D33 #D2EAF2 #AFDFEF #0D3239 #4D6B8A #FFFFFF  #2A8CBD grey    #2A8CBD}
{Rosy          #2B122A #000000 #FFFFFF #F6E6E9 #570957 #C5ADC8 #000000  #C84E91 grey    #C84E91}
{Magenta       #E8E8E8 #F0E8E8 #2B1137 #4A2A4A #FEEC9A #C09BDD #000000  #E69800 grey    #E69800}
{Red           white   #CECECB #340202 #440702 yellow  #F19F9F black    #D90505 #440701 #D90505}
{Blue          #08085D #030358 #FFFFFF #D2DEFA #562222 #3A3FC1 #FFFFFF  #B66425 grey    #B66425}
{LightGreen    #122B05 #091900 #FFFFFF #DEF8DE #562222 #A8CCA8 #000000  #B66425 grey    #B66425}
{Green         #E8E8E8 #EFEFEF #0F3F0A #274923 #FEEC9A #A4C2AD #000000  #E69800 grey    #E69800}
{Khaki         #E8E8E8 #FFFFFF #3C423C #4A564C #FEEFA8 #AEC8A6 #000000  #FF8A00 grey    #FF8A00}
{InverseGreen  #122B05 #091900 #FFFFFF #DEF8DE #562222 #567B56 #FFFFFF  #B66425 #DEF8D1 #B66425}
{Gray          #000000 #0D0D0D #FFFFFF #DADCE0 #362607 #AFAFAF #000000  #B66425 grey    #B66425}
{DarkGrey      #F0E8E8 #E7E7E7 #333333 #494949 #DCDC9B #AFAFAF #000000  #E69800 grey    #E69800}
{Dark          #E0D9D9 #C4C4C4 #232323 #303030 #CCCC90 #AFAFAF #000000  #E69800 grey    #E69800}
{InverseGrey   #121212 #1A1A1A #FFFFFF #DADCE0 #302206 #525252 #FFFFFF  #B66425 #DADCE1 #B66425}
{Sandy         #211D1C #27201F #FEFAEB #F7EEC5 #523A0A #82744F #FFFFFF  #B66425 grey    #B66425}
{Darcula #a6a6a6 #A1ACB6 #272727 #303030 #B09869 #2F5692 #EDC881 #a0a0a0 grey #f0a471 #B09869 #1e1e1e}
{Sleepy #daefd0 #D0D0D2 #43484a #2E3436 #CB956D #626D71 #f8f8f8 #ffffff grey #cbae70 #B09869 #1e1e1e}
{African black black #ffca8a #ffffb4 brown #855d4c #ffff9c red grey SaddleBrown SaddleBrown #f9b777}
{Florid black darkgreen lightgrey white brown green yellow red grey darkcyan darkgreen lightgreen}
{Inkpot #8888C9 #AFC2FF #11111a #1E1E27 #a4a4e5 #4E4E8F #fdfdfd #ffffff grey #545495 #fdfdfd #4E4E8F}
{TKE-Default white white black #282828 white blue white #9fa608 grey orange white black}
{TKE-AnatomyOfGrey #dfdfdf #ffffff #000000 #282828 #ffffff #b4b4b4 black #4e5044 grey orange #ffffff #000000}
{TKE-Aurora #ececec #ececec #302e40 #4e4b68 #ececec #908daa #24213e #ffffff grey orange #ececec #302e40}
{TKE-CoolGlow #e0e0e0 #e0e0e0 #06071d #0e1145 #e0e0e0 #7B789C #07081e #7600fe grey orange #e0e0e0 #06071d}
{TKE-FluidVision #000000 #000000 #f4f4f4 #cccccc #000000 #5e5e5e white #999999 grey orange #000000 #f4f4f4}
{TKE-Juicy #000000 #000000 #f1f1f1 #c9c9c9 #000000 #a5a5a5 black #a4cd52 grey orange #000000 #f1f1f1}
{TKE-LightVision #000000 #ffffff #fcfdfb #515753 #ffc2a1 #b1c2ab #000000 #0089f0 grey orange #ffc2a1 #2c322e}
{TKE-MadeOfCode #f8f8f8 #f8f8f8 #090a1b #00348c #f8f8f8 #73a7ff black #4c60ae grey orange #f8f8f8 #090a1b}
{TKE-MildDark #d2d2d2 #ffffff #181919 #4f637a #ffbe00 #95b4d2 #000000 #00a0f0 grey #ffbb6d #ffbe00 #364c64}
{TKE-MildDark2 #b4b4b4 #ffffff #0d0e0e #324864 #ffbe00 #8baac8 #000000 #00ffff grey #ffbb6d #ffbe00 #1e344c}
{TKE-MildDark3 #e2e2e2 #f1f1f1 #000000 #24384f #ffbe00 #84a3c1 #000000 #00ffff grey #ffbb6d #ffbe00 #041a32}
{TKE-Monokai #f8f8f2 #f8f8f2 #272822 #4e5044 #f8f8f2 #13140e #e0e0e0 #999d86 grey orange #f8f8f2 #272822}
{TKE-Notebook #000000 #000000 #beb69d #96907c #000000 #443e2a white #336e30 grey orange #000000 #beb69d}
{TKE-Quiverly #b6c1c1 #b6c1c1 #2b303b #333946 #fbffd7 #395472 white #ff9900 grey orange #fbffd7 #2b303b}
{TKE-RubyBlue #ffffff #ffffff #121e31 #213659 #ffffff #003f9e white #336e30 grey orange #ffffff #121e31}
{TKE-SourceForge #141414 #ffffff #ffffff #335b7e #f7cf00 #3175a7 #ffff00 #0089f0 grey #b3673b #f7cf00 #1d4568}
{TKE-StarLight #C0B6A8 #C0B6A8 #223859 #315181 #C0B6A8 #8cacdc #001141 #4e81ce grey orange #C0B6A8 #223859}
{TKE-TurnOfCentury #333333 #333333 #d6c4b6 #ae9f94 #333333 #56473c white #008700 grey orange #333333 #d6c4b6}
{TKE-Choco #c3be98 #c3be98 #180c0c #402020 #c3be98 #664D4D white #6c6c6c grey orange #c3be98 #180c0c}
{TKE-IdleFingers #ffffff #ffffff #323232 #5a5a5a #ffffff #afafaf black #d7e9c3 grey orange #ffffff #323232}
{TKE-Minimal #fcffe0 #ffffff #302d26 #5a5a5a #ffffff #c1beae black #ff9900 grey orange #ffffff #302d26}
{TKE-oscuro #f1f1f1 #f1f1f1 #344545 #526d6d #f1f1f1 #9aabab black #e87e88 grey orange #f1f1f1 #344545}
{TKE-YellowStone #0000ff #00003c #fdf9d0 #d5d2af #00003c #706d4a white #85836e grey orange #00003c #fdf9d0}
}
               # = text1   fg   item bg    bg   itemsHL  actbg   actfg     cc    greyed   hot
               # clrtitf clrinaf clrtitb clrinab clrhelp clractb clractf clrcurs clrgrey clrhotk

  set ::apave::_CS_(NOTCS) -2
  set ::apave::_CS_(MINCS) -1
  set ::apave::_CS_(STDCS) [expr {[llength $::apave::_CS_(ALL)] - 1}]
  set ::apave::_CS_(MAXCS) $::apave::_CS_(STDCS)
  set ::apave::_CS_(old) $::apave::_CS_(NOTCS)

  # Initialize system popup if possible
  proc initPOP {w} {
    bind $w <KeyPress> {
      if {"%K" eq "Menu"} {
        if {[winfo exists [set w [focus]]]} {
          event generate $w <Button-3> -rootx [winfo pointerx .] \
           -rooty [winfo pointery .]
        }
      }
    }
  }

  # Initialize wish session
  proc initWM {} {
    if {!$::apave::_CS_(initWM)} return
    set ::apave::_CS_(initWM) 0
    if {$::tcl_platform(platform) == "windows"} {
      wm attributes . -alpha 0.0
    } else {
      wm withdraw .
    }
    ttk::style map "." \
      -selectforeground [list !focus $::apave::_CS_(!FG)] \
      -selectbackground [list !focus $::apave::_CS_(!BG)]
    # configure separate widget types
    try {ttk::style theme use clam}
    ttk::style configure TButton \
      -anchor center -width -8 -relief raised -borderwidth 1 -padding 1
    ttk::style configure TLabel -borderwidth 0 -padding 1
    ttk::style configure TMenubutton -width 0 -padding 0
    catch { tooltip::tooltip fade true }
    initPOP .
    return
  }

  initWM

}

###########################################################################

# 0th bit: Little things

namespace eval ::apave {

  proc getN {sn {defn 0} {min ""} {max ""}} {

    # Gets a number from a string
    #   sn - string containing a number
    #   defn - default value when sn is not a number (optional)
    #   min - minimal value allowed (optional)
    #   max - maximal value allowed (optional)

    if {$sn eq "" || [catch {set sn [expr {$sn}]}]} {set sn $defn}
    if {$max ne ""} {
      set sn [expr {min($max,$sn)}]
    }
    if {$min ne ""} {
      set sn [expr {max($min,$sn)}]
    }
    return $sn
  }

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

oo::class create ::apave::ObjectProperty {

  variable _OP_Properties

  constructor {args} {
    array set _OP_Properties {}
    # ObjectProperty can play solo or be a mixin
    if {[llength [self next]]} { next {*}$args }
  }

  destructor {
    array unset _OP_Properties
    if {[llength [self next]]} next
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
#
# Another bit: Parsing utilities.

oo::class create ::apave::ObjectUtils {

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

    array set _PU_opts [list -NONE =NONE=]
    if {[llength [self next]]} {
      next {*}$args
    } elseif {[llength $args]>1 && [lindex $args 0]=="-NONE"} {
      set _PU_opts(-NONE) [lindex $args 1]
    }
    return
  }

  destructor {
    array unset _PU_opts
    if {[llength [self next]]} next
  }

  method parseOptions {inpargs args} {

    # Parses argument list containing options.
    #  inpargs - list of options and values
    #  args  - list of option/defaultvalue repeated pairs
    #
    # It's the same as parseOptionsFile, excluding the file name stuff.
    #
    # Returns a list of options' values, according to args.
    #
    # See also: parseOptionsFile

    lassign [my parseOptionsFile 0 $inpargs {*}$args] tmp
    foreach {nam val} $tmp {
      lappend retlist $val
    }
    return $retlist
  }

  method parseOptionsFile {strict inpargs args} {

    # Parses argument list containing options and (possibly) a file name.
    #   strict - if 0, 'args' options will be only counted for,
    #              other options are skipped
    #   strict - if 1, only 'args' options are allowed,
    #              all the rest of inpargs to be a file name
    #          - if 2, the 'args' options replace the
    #              appropriate options of 'inpargs'
    #   inpargs - list of options, values and a file name
    #   args  - list of default options
    #
    # The inpargs list contains:
    #   - option names beginning with "-"
    #   - option values following their names (may be missing)
    #   - "--" denoting the end of options
    #   - file name following the options (may be missing)
    #
    # The args parameter contains the pairs:
    #   - option name (e.g., "-dir")
    #   - option default value
    # If the args option value is equal to =NONE=, the inpargs option
    # is considered to be a single option without a value and,
    # if present in inpargs, its value is returned as "yes".
    #
    # Returns a list of two items:
    #   - an option list got from args/inpargs according to 'strict'
    #   - a file name from inpargs or {} if absent
    #
    # If any option of inpargs is absent in args and strict==1,
    # the rest of inpargs is considered to be a file name.
    #
    # Examples see in tests/obbit.test.

    set actopts true
    array set argarray "$args yes yes" ;# maybe, tail option without value
    if {$strict==2} {
      set retlist $inpargs
    } else {
      set retlist $args
    }
    set retfile {}
    for {set i 0} {$i < [llength $inpargs]} {incr i} {
      set parg [lindex $inpargs $i]
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
              set defval [lindex $inpargs [incr i]]
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

    lassign [my parseOptions $args $optname ""] optvalue
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

  method removeOptions {options args} {

    foreach key $args {
      if {[set i [lsearch -exact $options $key]]>-1} {
        catch {
          # remove a pair "option value"
          set options [lreplace $options $i $i]
          set options [lreplace $options $i $i]
        }
      } elseif {[string first * $key]>=0 && \
        [set i [lsearch -glob $options $key]]>-1} {
        # remove an option only
        set options [lreplace $options $i $i]
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

###########################################################################
# Another bit - manager for theming (might be enhanced a lot)

oo::class create ::apave::ObjectTheming {

  mixin ::apave::ObjectProperty ::apave::ObjectUtils

  constructor {args} {
    my InitCS
    # ObjectTheming can play solo or be a mixin
    if {[llength [self next]]} { next {*}$args }
  }

  destructor {
    if {[llength [self next]]} next
  }

  # --------------------------------------------------------------------

  method InitCS {} {

    if {$::apave::_CS_(initall)} {
      my basicFontSize 10 ;# initialize main font size
      my basicTextFont "Mono" ;# initialize main font for text
      my ColorScheme  ;# initialize default colors
      set ::apave::_CS_(initall) 0
    }
    return
  }

  method Main_Style {tfg1 tbg1 tfg2 tbg2 tfgS tbgS bclr tc fA bA bD} {

    # Sets main colors of application

    ttk::style configure "." \
      -background        $tbg1 \
      -foreground        $tfg1 \
      -bordercolor       $bclr \
      -darkcolor         $tbg1 \
      -troughcolor       $tc \
      -arrowcolor        $tfg1 \
      -selectbackground  $tbgS \
      -selectforeground  $tfgS \
      ;#-selectborderwidth 0
    ttk::style map "." \
      -background       [list disabled $bD active $bA] \
      -foreground       [list disabled grey active $fA]
  }

  # Set the new style options
  method Ttk_style {oper ts opt val} {

    if {![catch {set oldval [ttk::style $oper $ts $opt]}]} {
      catch {ttk::style $oper $ts $opt $val}
      if {$oldval=="" && $oper=="configure"} {
        switch -- $opt {
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
      if {$::apave::_CS_(initold) && ($oldval!="" || $oper=="map")} {
        lappend ::apave::_CS_(oldlist) $oper $ts $opt $oldval
      }
    }
    return
  }

  #--------------------------------------------------------------------------
  # The combobox widget leverages the pre-ttk Listbox for its dropdown
  # element and as such the 'option' command is currently required to set
  # the listbox options.
  # See also: https://wiki.tcl-lang.org/page/Changing+Widget+Colors

  method Combobox_Dropdown_Colors { args } {

    set optkey "_combo_color_"
    catch {
      if {[llength $args] && $::apave::_CS_(expo,tfg1) ne "-"} {
        # no ttk::style for listbox,
        # so a listbox widget is necessary to get its colors
        listbox [set l .lbx$optkey]
        foreach clrnam {back fore selectBack selectFore} {
          set ::apave::_C_($optkey,$clrnam) \
           [lindex [$l conf -[string tolower $clrnam]ground] 3]
        }
        destroy $l
      }
      foreach {i clrnam} {0 back 1 fore 2 selectBack 3 selectFore} {
        if {[llength $args] && $::apave::_CS_(expo,tfg1) ne "-"} {
          set clr [lindex $args $i]
        } else {
          set clr [set ::apave::_C_($optkey,$clrnam)]
        }
        # regretfully, no removing/updating option
        # so, it wouldn't work at restoring original theme
        option add *TCombobox*Listbox.${clrnam}ground $clr userDefault
      }
    }
    return
  }

  #--------------------------------------------------------------------------

  method csExport {} {

    # TODO

    set theme ""
    foreach arg {tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr args} {
      if {[catch {set a "$::apave::_CS_(expo,$arg)"}] || $a==""} {
        break
      }
      append theme " $a"
    }
    return $theme
  }

  #--------------------------------------------------------------------------

  method csMin {} {

    # Gets a minimum index of available color schemes

    return $::apave::_CS_(MINCS)
  }

  method csMax {} {

    # Gets a maximum index of available color schemes

    return $::apave::_CS_(MAXCS)
  }

  #--------------------------------------------------------------------------

  method csCurrent {} {

    # Gets an index of current color scheme

    return $::apave::_CS_(index)
  }

  #--------------------------------------------------------------------------

  method ColorScheme {{ncolor ""}} {

    # Gets a full record of color scheme from a list of available ones
    #  ncolor - index of color scheme

    if {"$ncolor" eq "" || $ncolor<0} {
      # basic color scheme: get colors from a current ttk::style colors
      if {[info exists ::apave::_CS_(def_fg)]} {
        set fg $::apave::_CS_(def_fg)
        set bg $::apave::_CS_(def_bg)
        set fS $::apave::_CS_(def_fS)
        set bS $::apave::_CS_(def_bS)
        set bA $::apave::_CS_(def_bA)
      } else {
        set ::apave::_CS_(index) $::apave::_CS_(NOTCS)
        lassign [my parseOptions [ttk::style configure .] \
          -foreground #000000 -background #d9d9d9 \
          -selectforeground #ffffff -selectbackground #4a6984 \
          -troughcolor #c3c3c3] fg bg fS bS tc
        lassign [my parseOptions [ttk::style map . -background] \
          disabled #d9d9d9 active #ececec] bD bA
        lassign [my parseOptions [ttk::style map . -foreground] \
          disabled #a3a3a3] fD
        lassign [my parseOptions [ttk::style map . -selectbackground] \
          !focus #9e9a91] bclr
        set ::apave::_CS_(def_fg) $fg
        set ::apave::_CS_(def_bg) $bg
        set ::apave::_CS_(def_fS) $fS
        set ::apave::_CS_(def_bS) $bS
        set ::apave::_CS_(def_fD) $fD
        set ::apave::_CS_(def_bD) $bD
        set ::apave::_CS_(def_bA) $bA
        set ::apave::_CS_(def_tc) $tc
        set ::apave::_CS_(def_bclr) $bclr
      }
      return [list default \
           $fg    $fg     $bA    $bg     $fg     $bS     $fS     $bS    grey    $bS]
      # clrtitf clrinaf clrtitb clrinab clrhelp clractb clractf clrcurs clrgrey clrhotk
    }
    return [lindex $::apave::_CS_(ALL) $ncolor]
  }

  #--------------------------------------------------------------------------

  method csGet {{ncolor ""}} {

    # Gets a color scheme's colors
    #  ncolor - index of color scheme

    if {$ncolor eq ""} {set ncolor [my csCurrent]}
    return [lrange [my ColorScheme $ncolor] 1 end]
  }

  #--------------------------------------------------------------------------

  method csGetName {{ncolor 0}} {

    # Gets a color scheme's name
    #  ncolor - index of color scheme
    if {$ncolor==$::apave::_CS_(MINCS)} {
      return "Basic"
    }
    return [lindex [my ColorScheme $ncolor] 0]
  }

  #--------------------------------------------------------------------------

  method csSet {{ncolor 0} {win .} args} {

    # Sets a color scheme and applies it to Tk/Ttk widgets.
    #  ncolor - index of color scheme (0 through $::apave::_CS_(MAXCS))

    # The clrtitf, clrinaf etc. had been designed for e_menu. And as such,
    # they can be used directly, outside of this "color scheming" UI.
    # They set pairs of related fb/bg:
    #   clrtitf/clrtitb is item's fg/bg
    #   clrinaf/clrinab is main fg/bg
    #   clractf/clractb is active (selection) fg/bg
    # and separate colors:
    #   clrhelp is "help" foreground
    #   clrcurs is "caret" background
    #   clrgrey is "shadowing" background
    #   clrhotk is "hotkey/border" foreground
    #
    # In color scheming, these colors are transformed to be consistent
    # with Tk/Ttk's color mechanics.
    # Additionally, "grey" color is used as "border color/disabled foreground".
    #
    # Returns a list of colors used by the color scheme.

    if {$ncolor eq ""} {
      lassign $args \
        clrtitf clrinaf clrtitb clrinab clrhelp clractb clractf clrcurs clrgrey clrhotk tfgI tbgI
    } else {
      foreach cs [list $ncolor $::apave::_CS_(MINCS)] {
        lassign [my csGet $cs] \
          clrtitf clrinaf clrtitb clrinab clrhelp clractb clractf clrcurs clrgrey clrhotk tfgI tbgI
        if {$clrtitf ne ""} break
        set ncolor $cs
      }
      set ::apave::_CS_(index) $ncolor
    }
    set fg $clrinaf  ;# main foreground
    set bg $clrinab  ;# main background
    set fE $clrtitf  ;# fieldforeground foreground
    set bE $clrtitb  ;# fieldforeground background
    set fS $clractf  ;# active/selection foreground
    set bS $clractb  ;# active/selection background
    set hh $clrhelp  ;# (not used in cs' theming) title color
    set gr $clrgrey  ;# (not used in cs' theming) shadowing color
    set cc $clrcurs  ;# caret's color
    set ht $clrhotk  ;# hotkey color
    set grey #808080
    if {$::apave::_CS_(old) != $ncolor || $args eq "-doit"} {
      set ::apave::_CS_(old) $ncolor
      my themeWindow $win $fg $bg $fE $bE $fS $bS $grey $bg $cc $ht $hh $tfgI $tbgI
    }
    return [list $fg $bg $fE $bE $fS $bS $hh $gr $cc $ht $tfgI $tbgI]
  }

  #--------------------------------------------------------------------------

  method configTooltip {fg bg args} {

    # Configurates colors and other attributes of tooltip
    #  fg - foreground
    #  bg - background
    #  args - other attributes

    if {[info exists ::tooltip::labelOpts]} {
	    # Undocumented feature of tooltip.tcl
	    catch {set ::tooltip::labelOpts [list -highlightthickness 1 \
        -relief solid -bd 1 -background $bg -fg $fg {*}$args]}
    }
    return
  }

  #--------------------------------------------------------------------------

  method csAdd {newcs {setnew true}} {

    # Registers new color scheme in the list of CS.
    #   newcs -  CS item
    #   setnew - if true, sets the CS as current
    #
    # Does not register the CS, if it is already registered.
    #
    # See also:
    #   themeWindow

    lassign $newcs name tfg2 tfg1 tbg2 tbg1 tfhh - - tcur grey bclr
    set found $::apave::_CS_(NOTCS)
    for {set i $::apave::_CS_(MINCS)} {$i<=$::apave::_CS_(MAXCS)} {incr i} {
      lassign [my csGet $i] cfg2 cfg1 cbg2 cbg1 cfhh - - ccur
      if {$cfg2==$tfg2 && $cfg1==$tfg1 && $cbg2==$tbg2 && $cbg1==$tbg1 && \
      $cfhh==$tfhh && $ccur==$tcur} {
        set found $i
        break
      }
    }
    if {$found == $::apave::_CS_(NOTCS)} {
      lappend ::apave::_CS_(ALL) $newcs
      set found [incr ::apave::_CS_(MAXCS)]
    }
    if {$setnew} {set ::apave::_CS_(index) [set ::apave::_CS_(old) $found]}
    return
  }
  #--------------------------------------------------------------------------

  method themeWindow {win {tfg1 ""} {tbg1 ""} {tfg2 ""} {tbg2 ""}
    {tfgS ""} {tbgS ""} {tfgD ""} {tbgD ""} {tcur ""} {bclr ""} {thlp ""}
     {tfgI ""} {tbgI ""}
    {isCS true} args} {

    # Changes a Tk style (theming a bit)
    #   tfg1/tbg1 - fore/background for themed widgets (main stock)
    #   tfg2/tbg2 - fore/background for themed widgets (enter data stock)
    #   tfgS/tbgS - fore/background for selection
    #   tfgD/tbgD - fore/background for disabled themed widgets
    #   tcur      - insertion cursor color
    #   bclr      - hotkey/border color
    #   thlp      - help color
    #   tfgI/tbgI - fore/background for external CS
    #   args      - other options
    #
    # The themeWindow can be used outside of "color scheme" UI.
    # E.g., in TKE editor, e_menu and add_shortcuts plugins use it to
    # be consistent with TKE theme.

    if {$tfg1 eq "-"} return
    if {!$isCS} {
      # if 'external  scheme' is used, register it in _CS_(ALL)
      # and set it as the current CS
      my csAdd [list CS-[expr {$::apave::_CS_(MAXCS)+1}] \
        $tfg2 $tfg1 $tbg2 $tbg1 $thlp $tbgS $tfgS $tcur grey $bclr $tfgI $tbgI]
    }
    my Main_Style $tfg1 $tbg1 $tfg2 $tbg2 $tfgS $tbgS $tfgD $tbg1 $tfg1 $tbg2 $tbg1
    foreach arg {tfg1 tbg1 tfg2 tbg2 tfgS tbgS tfgD tbgD tcur bclr \
    thlp tfgI tbgI args} {
      if {$win eq "."} {
        set ::apave::_C_($win,$arg) [set $arg]
      }
      set ::apave::_CS_(expo,$arg) [set $arg]
    }
    # save old colors, set new ones for combobox
    my Combobox_Dropdown_Colors $tbg2 $tfg2 $tbgS $tfgS
    # configuring themed widgets
    foreach ts {TLabel TButton TCheckbutton TProgressbar TRadiobutton \
    TScale TScrollbar TSeparator TSizegrip TMenubutton TNotebook.Tab} {
      my Ttk_style configure $ts -foreground $tfg1
      my Ttk_style configure $ts -background $tbg1
      my Ttk_style map $ts -background [list pressed $tbg1 active $tbg2 alternate $tbg2 focus $tbg2 selected $tbg2]
      my Ttk_style map $ts -foreground [list disabled $tfgD pressed $tfg1 active $tfg2 alternate $tfg2 focus $tfg2 selected $tfg2]
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
      my Ttk_style map $ts -foreground [list selected $tfgS active $tfg2]
      my Ttk_style map $ts -background [list selected $tbgS active $tbg2]
    }

    foreach ts {TEntry Treeview TSpinbox TCombobox TProgressbar} {
      my Ttk_style configure $ts -selectforeground $tfgS
      my Ttk_style configure $ts -selectbackground $tbgS
      my Ttk_style map $ts -selectforeground [list !focus $::apave::_CS_(!FG)]
      my Ttk_style map $ts -selectbackground [list !focus $::apave::_CS_(!BG)]
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
        my Ttk_style map $ts -foreground [list readonly $tfg1]
        my Ttk_style map $ts -background [list {readonly focus} $tbg1]
        my Ttk_style map $ts -fieldbackground [list readonly $tbg1]
        my Ttk_style map $ts -background [list active $tbg2]
      } else {
        my Ttk_style configure $ts -foreground $tfg2
        my Ttk_style configure $ts -background $tbg2
        my Ttk_style map $ts -foreground [list disabled $tfgD readonly $tfgD selected $tfgS]
        my Ttk_style map $ts -background [list disabled $tbgD readonly $tbgD selected $tbgS]
      }
    }
    # non-themed widgets of button and entry types
    foreach ts [my NonThemedWidgets button] {
      set ::apave::_C_($ts,0) 4
      set ::apave::_C_($ts,1) "-background $tbg1"
      set ::apave::_C_($ts,2) "-foreground $tfg1"
      set ::apave::_C_($ts,3) "-activeforeground $tfg2"
      set ::apave::_C_($ts,4) "-activebackground $tbg2"
      switch -- $ts {
        "checkbutton" - "radiobutton" {
          set ::apave::_C_($ts,0) 6
          set ::apave::_C_($ts,5) "-selectcolor $tbg1"
          set ::apave::_C_($ts,6) "-highlightbackground $tbg1"
        }
        "frame" - "scrollbar" {
          set ::apave::_C_($ts,0) 1
        }
      }
    }
    foreach ts [my NonThemedWidgets entry] {
      set ::apave::_C_($ts,0) 2
      set ::apave::_C_($ts,1) "-foreground $tfg2"
      set ::apave::_C_($ts,2) "-background $tbg2"
      switch -- $ts {
        "text" - "entry"  {
          set ::apave::_C_($ts,0) 8
          set ::apave::_C_($ts,3) "-insertbackground $tcur"
          set ::apave::_C_($ts,4) "-selectforeground $tfgS"
          set ::apave::_C_($ts,5) "-selectbackground $tbgS"
          set ::apave::_C_($ts,6) "-disabledforeground $tfgD"
          set ::apave::_C_($ts,7) "-disabledbackground $tbgD"
          set ::apave::_C_($ts,8) "-highlightcolor $bclr"
        }
        "spinbox" - "listbox" - "tablelist" {
          set ::apave::_C_($ts,0) 9
          set ::apave::_C_($ts,3) "-insertbackground $tcur"
          set ::apave::_C_($ts,4) "-buttonbackground $tbg2"
          set ::apave::_C_($ts,5) "-selectforeground $::apave::_CS_(!FG)" ;# $tfgS
          set ::apave::_C_($ts,6) "-selectbackground $::apave::_CS_(!BG)" ;# $tbgS
          set ::apave::_C_($ts,7) "-disabledforeground $tfgD"
          set ::apave::_C_($ts,8) "-disabledbackground $tbgD"
          set ::apave::_C_($ts,9) "-highlightcolor $bclr"
        }
      }
    }
    foreach ts {disabled} {
      set ::apave::_C_($ts,0) 4
      set ::apave::_C_($ts,1) "-foreground $tfgD"
      set ::apave::_C_($ts,2) "-background $tbgD"
      set ::apave::_C_($ts,3) "-disabledforeground $tfgD"
      set ::apave::_C_($ts,4) "-disabledbackground $tbgD"
    }
    # for branched items (menu e.g.):
    # at first saving the current options, then setting the new ones
    # as parents' options define children's
    my themeNonThemed $win 0
    my themeNonThemed $win 1
    # other options per widget type
    foreach {typ v1 v2} $args {
      if {$typ=="-"} {
        # config of non-themed widgets
        set ind [incr ::apave::_C_($v1,0)]
        set ::apave::_C_($v1,$ind) "$v2"
      } else {
        # style maps of themed widgets
        my Ttk_style map $typ $v1 [list {*}$v2]
      }
    }
    set ::apave::_CS_(initold) 0
    return
  }

  #--------------------------------------------------------------------------
  # Restore the appearance options saved in themeWindow
  # i.e. default colors

  method themeRestore {} {

    my Main_Style $::apave::_CS_(def_fg) $::apave::_CS_(def_bg) \
      $::apave::_CS_(def_fg) $::apave::_CS_(def_bg) \
      $::apave::_CS_(def_fS) $::apave::_CS_(def_bS) \
      $::apave::_CS_(def_bclr) $::apave::_CS_(def_tc) \
      $::apave::_CS_(def_fg) $::apave::_CS_(def_bA) $::apave::_CS_(def_bD)
    foreach {oper ts opt val} $::apave::_CS_(oldlist) {
      switch -- $oper {
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
    set ::apave::_CS_(expo,tfg1) "-"
    set ::apave::_CS_(index) [set ::apave::_CS_(old) $::apave::_CS_(NOTCS)]
    return
  }
  #--------------------------------------------------------------------------
  # some widgets (e.g. listbox) need a work-around to set
  # attributes for selection in run-time

  method UpdateSelectAttrs {w} {

    if { [string first "-selectforeground" [bind $w "<FocusIn>"]] < 0} {
      set com "lassign \[[self] parseOptions \[ttk::style configure .\] \
        -selectforeground $::apave::_CS_(!FG) \
        -selectbackground $::apave::_CS_(!BG)\] fS bS;"
      bind $w <FocusIn> "+ $com $w configure \
        -selectforeground \$fS -selectbackground \$bS"
      bind $w <FocusOut> "+ $w configure -selectforeground \
        $::apave::_CS_(!FG) -selectbackground $::apave::_CS_(!BG)"
    }
    return
  }

  #--------------------------------------------------------------------------
  # Updating the appearances of currently used widgets (non-themed)
  # Input:
  #   win - window path, supposedly passed as [winfo uplevel $w]
  #   setting - 1, if the widgets should be configured

  method themeNonThemed {win setting} {

    set wtypes [my NonThemedWidgets all]
    foreach w1 [winfo children $win] {
      my themeNonThemed $w1 $setting
      set ts [string tolower [winfo class $w1]]
      if {[lsearch -exact $wtypes $ts]>-1} {
        set i 0
        while {[incr i] <= $::apave::_C_($ts,0)} {
          lassign $::apave::_C_($ts,$i) opt val
          if {$setting} {
            catch {
              if {[string first __tooltip__.label $w1]<0} {
                $w1 configure $opt $val
                if {[$w1 cget -state]=="disabled"} {
                  $w1 configure {*}[my NonTtkStyle $w1 1]
                }
              }
              set nam3 [string range [my rootwname $w1] 0 2]
              if {$nam3 in {lbx tbl flb cbx fco enT spX tex}} {
                my UpdateSelectAttrs $w1
              }
            }
          } else {
            if {[catch {set oldval [$w1 cget $opt]}]} {
              switch -- $opt {
                -background - -foreground { set oldval [. cget $opt] }
                default continue
              }
            }
            if {$::apave::_CS_(initold)} {
              lappend ::apave::_CS_(oldlist) $w1 $ts $opt $oldval
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

    switch -- $selector {
      entry {
        return [list entry text listbox spinbox tablelist]
      }
      button {
        return [list label button menu menubutton checkbutton radiobutton frame labelframe scale scrollbar]
      }
    }
    return [list entry text listbox spinbox label button menu menubutton \
      "checkbutton" radiobutton frame labelframe scale scrollbar tablelist]
  }

  #--------------------------------------------------------------------------
  #
  # Theme for non-ttk widgets

  method NonTtkTheme {win} {

    if {[info exists ::apave::_C_(.,tfg1)] &&
    $::apave::_CS_(expo,tfg1) ne "-"} {
      my themeWindow $win \
         $::apave::_C_(.,tfg1) \
         $::apave::_C_(.,tbg1) \
         $::apave::_C_(.,tfg2) \
         $::apave::_C_(.,tbg2) \
         $::apave::_C_(.,tfgS) \
         $::apave::_C_(.,tbgS) \
         $::apave::_C_(.,tfgD) \
         $::apave::_C_(.,tbgD) \
         $::apave::_C_(.,tcur) \
         $::apave::_C_(.,bclr) \
         $::apave::_C_(.,thlp) \
         $::apave::_C_(.,tfgI) \
         $::apave::_C_(.,tbgI) \
         false {*}$::apave::_C_(.,args)
    }
    return
  }

  #--------------------------------------------------------------------------
  #
  # Style for non-ttk widgets
  # Input: "typ" is the same as in "APave GetWidgetType" method

  method NonTtkStyle {typ {dsbl 0}} {

    if {$dsbl} {
      set disopt ""
      if {[info exist ::apave::_C_(disabled,0)]} {
        set typ [string range [lindex [split $typ .] end] 0 2]
        switch -- $typ {
          frA - lfR {
            append disopt " " $::apave::_C_(disabled,2)
          }
          enT - spX {
            append disopt " " $::apave::_C_(disabled,1) \
                          " " $::apave::_C_(disabled,2) \
                          " " $::apave::_C_(disabled,3) \
                          " " $::apave::_C_(disabled,4)
          }
          laB - tex - chB - raD - lbx - scA {
            append disopt " " $::apave::_C_(disabled,1) \
                          " " $::apave::_C_(disabled,2)
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

  #--------------------------------------------------------------------------

  method ThemePopup {mnu args} {
    if {[set last [$mnu index end]] ne "none"} {
      for {set i 0} {$i <= $last} {incr i} {
        switch -- [$mnu type $i] {
          cascade {my ThemePopup [$mnu entrycget $i -menu] {*}$args}
          command {$mnu entryconfigure $i {*}$args}
        }
      }
    }
  }

  method themePopup {mnu} {

    if {[my csCurrent] == $::apave::_CS_(NOTCS)} return
    lassign [my csGet] itfg fg itbg bg
    $mnu configure -foreground $fg -background $bg
    my ThemePopup $mnu -foreground $fg -background $bg \
      -activeforeground $itfg -activebackground $itbg
  }

  #--------------------------------------------------------------------------

  method basicFontSize {{fs 0}} {

    # Gets/Sets a basic size of font used in apave
    #    fs - font size
    #
    # If 'fs' is omitted or ==0, this method gets it.
    # If 'fs' >0, this method sets it.

    if {$fs} {
      return [set ::apave::_CS_(fs) $fs]
    } else {
      return $::apave::_CS_(fs)
    }
  }

  #--------------------------------------------------------------------------

  method basicTextFont {{textfont ""}} {

    # Gets/Sets a basic font used in editing/viewing text widget
    #    textfont - font
    #
    # If 'textfont' is omitted or =="", this method gets it.
    # If 'textfont' is set, this method sets it.

    if {$textfont ne ""} {
      return [set ::apave::_CS_(textfont) $textfont]
    } else {
      return $::apave::_CS_(textfont)
    }
  }

}

# ------------------------------------------------------------------------

proc ::apave::themeObj {com args} {

  # Calls a command of ObjectTheming class.
  #   com - a command
  #   args - arguments of the command
  #
  # Returns the command's result.

  ::apave::ObjectTheming create tmpobj
  set res [tmpobj $com {*}$args]
  tmpobj destroy
  return $res
}

###########################################################################

  #%   DOCTEST   SOURCE   tests/obbit_1.test

################################# EOF #####################################
