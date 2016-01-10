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

  variable default_font

  array set data {}

  # Set the current default font
  set default_font [[ttk::entry .___e] cget -font]
  destroy .___e

  ######################################################################
  # Creates and configures a fontchooser widget and returns the pathname.
  proc create {w args} {

    variable data

    array set opts {
      -default   ""
      -mono      ""
      -effects   0
      -sizes     ""
      -styles    ""
      -highlight ""
    }
    array set opts $args

    # Initialize variables
    switch $opts(-mono) {
      0       { set data($w,fonts) [lsort [find_font_class variable]] }
      1       { set data($w,fonts) [lsort [find_font_class mono]] }
      default { set data($w,fonts) [lsort [font families]] }
    }
    set data($w,styles) [expr {($opts(-styles) eq "") ? {Regular Italic Bold "Bold Italic"} : $opts(-styles)}]
    set data($w,sizes)  [expr {($opts(-sizes)  eq "") ? {6 7 8 9 10 11 12 14 16 18 20 22 24 26 28} : $opts(-sizes)}]

    set data($w,font)   ""
    set data($w,style)  ""
    set data($w,size)   ""
    set data($w,strike) 0
    set data($w,under)  0

    set data($w,fonts,lcase)  [string tolower $data($w,fonts)]
    set data($w,styles,lcase) [string tolower $data($w,styles)]
    set data($w,sizes,lcase)  $data($w,sizes)

    ttk::frame $w
    ttk::label $w.font   -text "Font:"
    ttk::label $w.style  -text "Font style:"
    ttk::label $w.size   -text "Size:"
    ttk::entry $w.efont  -textvariable fontchooser::data($w,font)
    ttk::entry $w.estyle -textvariable fontchooser::data($w,style)
    ttk::entry $w.esize  -textvariable fontchooser::data($w,size) -width 0 \
        -validate key -validatecommand {string is double %P}

    listbox $w.lfonts -listvariable fontchooser::data($w,fonts) -height 7 \
        -yscrollcommand [list $w.sbfonts set] -height 7 -exportselection 0
    ttk::scrollbar $w.sbfonts -command [list $w.lfonts yview]
    listbox $w.lstyles -listvariable fontchooser::data($w,styles) -height 7 -exportselection 0
    listbox $w.lsizes  -listvariable fontchooser::data($w,sizes) \
        -yscroll [list $w.sbsizes set] -width 6 -height 7 -exportselection 0
    ttk::scrollbar $w.sbsizes -command [list $w.lsizes yview]

    bind $w.lfonts  <<ListboxSelect>> [list fontchooser::click $w font]
    bind $w.lstyles <<ListboxSelect>> [list fontchooser::click $w style]
    bind $w.lsizes  <<ListboxSelect>> [list fontchooser::click $w size]

    grid columnconfigure $w {0 3 6 9} -minsize 10
    grid columnconfigure $w {1 4 7}   -weight 1
    grid x $w.font  - x $w.style  - x $w.size  - x -sticky w
    grid x $w.efont - x $w.estyle - x $w.esize - x -sticky ew
    grid x $w.lfonts $w.sbfonts x $w.lstyles - x $w.lsizes $w.sbsizes x -sticky news

    if {$opts(-effects)} {

      ttk::labelframe $w.effects -text "Effects"
      ttk::checkbutton $w.effects.strike -variable fontchooser::data($w,strike) \
          -text " Strikeout" -command [list fontchooser::show $w]
      ttk::checkbutton $w.effects.under -variable fontchooser::data($w,under) \
          -text " Underline" -command [list fontchooser::show $w]

      grid columnconfigure $w.effects 1 -weight 1
      grid $w.effects.strike -sticky w -padx 10
      grid $w.effects.under  -sticky w -padx 10

      grid $w.effects - x -sticky news -row 100 -column 1

    }

    ttk::labelframe $w.sample -text "Sample"
    ttk::label      $w.sample.fsample -relief sunken
    set data($w,sample) [ttk::label $w.sample.fsample.sample -text "AaBbYyZz"]
    pack $w.sample.fsample -fill both -expand 1 -padx 10 -pady 10 -ipady 15
    pack $w.sample.fsample.sample -fill both -expand 1
    pack propagate $w.sample.fsample 0

    grid rowconfigure $w 2  -weight 1
    grid rowconfigure $w 99 -minsize 30
    grid $w.sample - - - - -sticky news -row 100 -column 4
    grid rowconfigure $w 101 -minsize 30

    trace variable fontchooser::data($w,size)  w fontchooser::tracer
    trace variable fontchooser::data($w,style) w fontchooser::tracer
    trace variable fontchooser::data($w,font)  w fontchooser::tracer

    configure $w $opts(-default)

    if {$opts(-mono) eq ""} {
      highlight $w $opts(-highlight)
    }

    bind $w <Destroy> [list fontchooser::destroy $w]

    return $w

  }

  ######################################################################
  # Configures the font chooser widget.
  proc configure {w {defaultFont ""}} {

    variable data

    # Figure out the default font if one was not specified
    if {$defaultFont eq ""} {
      set defaultFont [[ttk::entry .___e] cget -font]
      ::destroy .___e
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

    # Update the UI
    foreach var [list font style size] {
      tracer data $w,$var w
    }

    # Display the result
    show $w

  }

  ######################################################################
  # Highlights the fonts in the font list that are of a specific type.
  proc highlight {w highlight} {

    variable data

    if {$highlight ne ""} {

      set hfonts [find_font_class $highlight]
      set i      0

      foreach f $data($w,fonts) {
        if {[lsearch $hfonts $f] != -1} {
          $w.lfonts itemconfigure $i -foreground blue
        }
        incr i
      }

    }

  }

  ######################################################################
  # Called when the widget is destroyed.
  proc destroy {w} {

    variable data

    array unset data $w,*

    trace remove variable fontchooser::data($w,size)  write fontchooser::tracer
    trace remove variable fontchooser::data($w,style) write fontchooser::tracer
    trace remove variable fontchooser::data($w,font)  write fontchooser::tracer

  }

  ######################################################################
  # Called when one of the listboxes are clicked.
  proc click {w who} {

    variable data

    # Update the setting
    set data($w,$who) [$w.l${who}s get [$w.l${who}s curselection]]

  }

  ######################################################################
  # Called when one of the font variables are written to.  Updates the UI.
  proc tracer {var1 var2 op} {

    variable data

    lassign [split $var2 ,] w var

    set bad 0

    # Make selection in each listbox
    set value [string tolower $data($w,$var)]
    $w.l${var}s selection clear 0 end
    set n [lsearch -exact $data($w,${var}s,lcase) $value]
    $w.l${var}s selection set $n
    if {$n != -1} {
      set data($w,$var) [lindex $data($w,${var}s) $n]
      $w.e$var icursor end
      $w.e$var selection clear
    } else {                                ;# No match, try prefix
      # Size is weird: valid numbers are legal but don't display
      # unless in the font size list
      set n   [lsearch -glob $data($w,${var}s,lcase) "$value*"]
      set bad 1
    }
    $w.l${var}s see $n

    if {!$bad} {
      show $w
    }

  }

  ######################################################################
  # Displays a sample of the selection options and generates the
  # <<FontChanged>> virtual event.
  proc show {w} {

    variable data

    set result [list -family $data($w,font) -size $data($w,size)]

    switch $data($w,style) {
      "Bold"        { lappend result -weight bold }
      "Italic"      { lappend result -slant italic }
      "Bold Italic" { lappend result -weight bold -slant italic }
    }

    if {$data($w,strike)} { lappend result -overstrike 1 }
    if {$data($w,under)}  { lappend result -underline 1 }

    # Display the sampled result and generate the FontChanged event
    if {![catch { $data($w,sample) config -font $result }]} {
      event generate $w <<FontChanged>> -data $result
    }

  }

  ######################################################################
  # Returns the font families that match the given type.
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

######################################################################
# Creates a font chooser window.
proc fontchooser {args} {

  array set opts [list \
    -parent      . \
    -initialfont $fontchooser::default_font \
    -title       "" \
  ]
  array set opts $args

  set ::fontchooser_value ""

  toplevel     .fontwin
  wm title     .fontwin $opts(-title)
  wm transient .fontwin $opts(-parent)
  wm resizable .fontwin 0 0

  fontchooser::create .fontwin.fc -effects 1 -default $opts(-initialfont) -highlight mono

  bind .fontwin.fc <<FontChanged>> {
    set ::fontchooser_value %d
    .fontwin.bf.choose configure -state normal
  }

  ttk::frame  .fontwin.bf
  ttk::button .fontwin.bf.choose -style BButton -text "Choose" -width 6 -command {
    destroy .fontwin
  } -state disabled
  ttk::button .fontwin.bf.cancel -style BButton -text "Cancel" -width 6 -command {
    set ::fontchooser_value ""
    destroy .fontwin
  }

  pack .fontwin.bf.cancel -side right -padx 2 -pady 2
  pack .fontwin.bf.choose -side right -padx 2 -pady 2

  pack .fontwin.fc -fill both -expand yes
  pack .fontwin.bf -fill x

  fontchooser::show .fontwin.fc

  tkwait window .fontwin

  return $::fontchooser_value

}
