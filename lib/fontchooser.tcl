######################################################################
# Name:    fontchooser.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    01/07/2016
# Brief:   Provides a UI and associated functionality for choosing a
#          font.
# Attributions:
#          This code mainly comes from the ChooseFont package created
#          by Keith Vetter (June 2006).
######################################################################

namespace eval fontchooser {

  array set data {}

  ######################################################################
  # Creates and initializes a fontchooser widget and returns the pathname.
  proc create {w args} {

    variable data

    array set opts {
      -default ""
      -mono    ""
      -effects 0
    }
    array set opts $args

    # Initialize variables
    switch $opts(-mono) {
      0       { set data(fonts) [find_font_class variable] }
      1       { set data(fonts) [find_font_class mono] }
      default { set data(fonts) [font families] }
    }
    set data(styles) {Regular Italic Bold "Bold Italic"}
    set data(sizes)  {8 9 10 11 12 14 16 18 20 22 24 26 28 36 48 72}

    set data($w,font)   ""
    set data($w,style)  ""
    set data($w,size)   ""
    set data($w,strike) 0
    set data($w,under)  0

    set data(fonts,lcase) [list]
    foreach font $data(fonts) {
      lappend data(fonts,lcase) [string tolower $font]
    }
    set data(styles,lcase) {regular italic bold "bold italic"}
    set data(sizes,lcase)  $data(sizes)

    ttk::frame $w
    ttk::label $w.font   -text "Font:"
    ttk::label $w.style  -text "Font style:"
    ttk::label $w.size   -text "Size:"
    ttk::entry $w.efont  -textvariable fontchooser::data($w,font)
    ttk::entry $w.estyle -textvariable fontchooser::data($w,style)
    ttk::entry $w.esize  -textvariable fontchooser::data($w,size) -width 0 \
        -validate key -validatecommand {string is double %P}

    listbox $w.lfonts -listvariable fontchooser::data(fonts) -height 7 \
        -yscrollcommand [list $w.sbfonts set] -height 7 -exportselection 0
    ttk::scrollbar $w.sbfonts -command [list $w.lfonts yview]
    listbox $w.lstyles -listvariable fontchooser::data(styles) -height 7 -exportselection 0
    listbox $w.lsizes  -listvariable fontchooser::data(sizes) \
        -yscroll [list $w.sbsizes set] -width 6 -height 7 -exportselection 0
    ttk::scrollbar $w.sbsizes -command [list $w.lsizes yview]

    bind $w.lfonts  <<ListboxSelect>> [list fontchooser::click $w font]
    bind $w.lstyles <<ListboxSelect>> [list fontchooser::click $w style]
    bind $w.lsizes  <<ListboxSelect>> [list fontchooser::click $w size]

    if {$opts(-effects)} {

      ttk::labelframe $w.effects -text "Effects"
      ttk::checkbutton $w.effects.strike -variable fontchooser::data($w,strike) \
          -text Strikeout -command [list fontchooser::click $w strike]
      ttk::checkbutton $w.effects.under -variable fontchooser::data($w,under) \
          -text Underline -command [list fontchooser::click $w under]

      grid columnconfigure $w.effects 1 -weight 1
      grid $w.effects.strike -sticky w -padx 10
      grid $w.effects.under  -sticky w -padx 10

    }

    grid columnconfigure $w {2 5 8} -minsize 10
    grid columnconfigure $w {0 3 6} -weight 1
    grid $w.font  - x $w.style  - x $w.size  - x -sticky w
    grid $w.efont - x $w.estyle - x $w.esize - x -sticky ew
    grid $w.lfonts $w.sbfonts x $w.lstyles - x $w.lsizes $w.sbsizes x -sticky news

    ttk::labelframe $w.sample -text "Sample"
    ttk::label      $w.sample.fsample -relief sunken
    set data($w,sample) [ttk::label $w.sample.fsample.sample -text "AaBbYyZz"]
    pack $w.sample.fsample -fill both -expand 1 -padx 10 -pady 10 -ipady 15
    pack $w.sample.fsample.sample -fill both -expand 1
    pack propagate $w.sample.fsample 0

    grid rowconfigure $w 2  -weight 1
    grid rowconfigure $w 99 -minsize 30
    grid $w.sample - - - - -sticky news -row 100 -column 3
    grid rowconfigure $w 101 -minsize 30

    trace variable fontchooser::data($w,size)  w [list fontchooser::tracer $w]
    trace variable fontchooser::data($w,style) w [list fontchooser::tracer $w]
    trace variable fontchooser::data($w,font)  w [list fontchooser::tracer $w]

    initialize $w $opts(-default)

    bind $w <Destroy> [list fontchooser::destroy $w]

    return $w

  }

  proc initialize {w {defaultFont ""}} {

    variable data

    # Figure out the default font if one was not specified
    if {$defaultFont eq ""} {
      set defaultFont [[ttk::entry .___e] cget -font]
      destroy .___e
    }

    array set F [font actual $defaultFont]

    set data($w,font)   $F(-family)
    set data($w,size)   $F(-size)
    set data($w,strike) $F(-overstrike)
    set data($w,under)  $F(-underline)
    set data($w,style) "Regular"
    if {($F(-weight) eq "bold") && ($F(-slant) eq "italic")} {
      set data($w,style) "Bold Italic"
    } elseif {$F(-weight) eq "bold"} {
      set data($w,style) "Bold"
    } elseif {$F(-slant) eq "italic"} {
      set data($w,style) "Italic"
    }

    tracer $w a b c
    show $w

  }

  proc destroy {w} {

    variable data

    array unset data $w,*

    trace remove variable fontchooser::data($w,size)  write [list fontchooser::tracer $w]
    trace remove variable fontchooser::data($w,style) write [list fontchooser::tracer $w]
    trace remove variable fontchooser::data($w,font)  write [list fontchooser::tracer $w]

  }

  proc click {w who} {

    variable data

    if {$who eq "font"} {
      set data($w,font)  [$w.lfonts  get [$w.lfonts  curselection]]
    } elseif {$who eq "style"} {
      set data($w,style) [$w.lstyles get [$w.lstyles curselection]]
    } elseif {$who eq "size"} {
      set data($w,size)  [$w.lsizes  get [$w.lsizes  curselection]]
    }

    show $w

  }

  proc tracer {w var1 var2 op} {

    variable data

    set bad 0

    # Make selection in each listbox
    foreach var {font style size} {
      set value [string tolower $data($w,$var)]
      $w.l${var}s selection clear 0 end
      set n [lsearch -exact $data(${var}s,lcase) $value]
      $w.l${var}s selection set $n
      if {$n != -1} {
        set data($w,$var) [lindex $data(${var}s) $n]
        $w.e$var icursor end
        $w.e$var selection clear
      } else {                                ;# No match, try prefix
        # Size is weird: valid numbers are legal but don't display
        # unless in the font size list
        set n   [lsearch -glob $data(${var}s,lcase) "$value*"]
        set bad 1
      }
      $w.l${var}s see $n
    }

    if {!$bad} {
      show $w
    }

  }

  proc show {w} {

    variable data

    set result [list $data($w,font) $data($w,size)]

    if {$data($w,style) eq "Bold"}        { lappend result bold }
    if {$data($w,style) eq "Italic"}      { lappend result italic }
    if {$data($w,style) eq "Bold Italic"} { lappend result bold italic}
    if {$data($w,strike)}                 { lappend result overstrike}
    if {$data($w,under)}                  { lappend result underline}

    $data($w,sample) config -font $result

    # Tell the world about it
    event generate $w <<FontChanged>> -data $result

  }

  proc find_font_class {{type mono}} {

    set fm [list]
    set fv [list]
    foreach f [font families] {
      if {[font measure "{$f} 8" "A"] == [font measure "{$f} 8" "."]} {
        lappend fm $f
      } else {
        lappend fv $f
      }
    }

    return [expr {($type eq "mono") ? $fm : $fv}]

  }

}
