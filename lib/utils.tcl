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
# Name:    utils.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    5/11/2013
# Brief:   Namespace for general purpose utility procedures
######################################################################

namespace eval utils {

  variable bin_rx {[\x00-\x08\x0b\x0e-\x1f]}
  variable eol_rx {\r\n|\n|\r}

  array set xignore    {}
  array set xignore_id {}
  array set vars       {}

  array set c2k_map {
    { } space
    !   exclam
    \"  quotedbl
    \#  numbersign
    \$  dollar
    %   percent
    &   ampersand
    '   quoteright
    (   parenleft
    )   parenright
    *   asterisk
    +   plus
    ,   comma
    -   minus
    .   period
    /   slash
    :   colon
    \;  semicolon
    <   less
    =   equal
    >   greater
    ?   question
    @   at
    \[  bracketleft
    \\  backslash
    \]  bracketright
    ^   asciicircum
    _   underscore
    `   quoteleft
    \{  braceleft
    |   bar
    \}  braceright
    ~   asciitilde
    \n  Return
  }

  array set code2sym {
    32 space
    33 exclam
    34 quotedbl
    35 numbersign
    36 dollar
    37 percent
    38 ampersand
    39 quoteright
    40 parenleft
    41 parenright
    42 asterisk
    43 plus
    44 comma
    45 minus
    46 period
    47 slash
    48 0
    49 1
    50 2
    51 3
    52 4
    53 5
    54 6
    55 7
    56 8
    57 9
    58 colon
    59 semicolon
    60 less
    61 equal
    62 greater
    63 question
    64 at
    65 A
    66 B
    67 C
    68 D
    69 E
    70 F
    71 G
    72 H
    73 I
    74 J
    75 K
    76 L
    77 M
    78 N
    79 O
    80 P
    81 Q
    82 R
    83 S
    84 T
    85 U
    86 V
    87 W
    88 X
    89 Y
    90 Z
    91 bracketleft
    92 backslash
    93 bracketright
    94 asciicircum
    95 underscore
    96 quoteleft
    97 a
    98 b
    99 c
    100 d
    101 e
    102 f
    103 g
    104 h
    105 i
    106 j
    107 k
    108 l
    109 m
    110 n
    111 o
    112 p
    113 q
    114 r
    115 s
    116 t
    117 u
    118 v
    119 w
    120 x
    121 y
    122 z
    123 braceleft
    124 bar
    125 braceright
    126 asciitilde
    65288 BackSpace
    65289 Tab
    65293 Return
    65307 Escape
    65360 Home
    65361 Left
    65362 Up
    65363 Right
    65364 Down
    65365 Prior
    65366 Next
    65367 End
    65535 Delete
  }

  if {[tk windowingsystem] eq "aqua"} {
    array set code2sym {
      127   BackSpace
      9     Tab
      13    Return
      27    Escape
      63273 Home
      63234 Left
      63232 Up
      63235 Right
      63233 Down
      63276 Prior
      63277 Next
      63275 End
      63272 Delete
    }
  }

  array set tablelistopts {
    selectbackground   RoyalBlue1
    selectforeground   white
    stretch            all
    stripebackground   #EDF3FE
    relief             flat
    border             0
    showseparators     yes
    takefocus          0
    setfocus           1
    activestyle        none
  }

  ##########################################################
  # Useful process for debugging.
  proc stacktrace {} {

    set stack "Stack trace:\n"

    catch {
      for {set i 1} {$i < [info level]} {incr i} {
        set lvl [info level -$i]
        set pname [lindex $lvl 0]
        if {[namespace which -command $pname] eq ""} {
          for {set j [expr $i + 1]} {$j < [info level]} {incr j} {
            if {[namespace which -command [lindex [info level -$j] 0]] ne ""} {
              set pname "[namespace qualifiers [lindex [info level -$j] 0]]::$pname"
              break
            }
          }
        }
        append stack [string repeat " " $i]$pname
        foreach value [lrange $lvl 1 end] arg [info args $pname] {
          if {$value eq ""} {
            info default $pname $arg value
          }
          append stack " $arg='$value'"
        }
        append stack \n
      }
    }

    return $stack

  }

  ######################################################################
  # Looks up the given keycode value based on the provided keysym.
  proc sym2code {sym} {

    variable code2sym

    set code2sym_list [array get code2sym]

    if {[set index [lsearch -exact $code2sym_list $sym]] != -1} {
      return [lindex $code2sym_list [expr $index - 1]]
    }

  }

  ######################################################################
  # Configure global tablelist options.
  proc tablelist_configure {w} {

    variable tablelistopts

    foreach {key value} [array get tablelistopts] {
      $w configure -$key $value
    }

  }

  ###########################################################################
  # Performs the set operation on a given yscrollbar.
  proc set_yscrollbar {sb first last} {

    # If everything is displayed, hide the scrollbar
    if {($first == 0) && (($last == 1) || ($last == 0))} {
      grid remove $sb
    } else {
      grid $sb
      $sb set $first $last
    }

  }

  ######################################################################
  # Performs the set operation on a given xscrollbar.
  proc set_xscrollbar {sb first last} {

    variable xignore
    variable xignore_id

    if {($first == 0) && ($last == 1)} {
      grid remove $sb
      set_xignore $sb 1 0
      set xignore_id($sb) [after 1000 [list utils::set_xignore $sb 0 1]]
    } else {
      if {![info exists xignore($sb)] || !$xignore($sb)} {
        grid $sb
        $sb set $first $last
      }
      set_xignore $sb 0 0
    }

  }

  ######################################################################
  # Clears the xignore and xignore_id values.
  proc set_xignore {sb value auto} {

    variable xignore
    variable xignore_id

    # Clear the after (if it exists)
    if {[info exists xignore_id($sb)]} {
      after cancel $xignore_id($sb)
      unset xignore_id($sb)
    }

    # Set the xignore value to the specified value
    set xignore($sb) $value

  }

  ######################################################################
  # Returns the mark of the anchor.
  proc text_anchor {w} {

    if {[info procs ::tk::TextAnchor] ne ""} {
      return [::tk::TextAnchor $w]
    } else {
      return tk::anchor$w
    }

  }

  ######################################################################
  # Parses the given string for any variables and substitutes those
  # variables with their respective values.  If a variable was found that
  # has not been defined, no substitution occurs for it.  The fully
  # substituted string is returned.
  proc perform_substitutions {str} {

    variable vars

    return [subst [regsub -all {\$([a-zA-Z0-9_]+)} $str {[expr {[info exists vars(\1)] ? $vars(\1) : {&}}]}]]

  }

  ######################################################################
  # Adds the given environment variables to the environment.
  proc set_environment {var_list} {

    variable vars

    array unset vars

    # Pre-load the vars with the environment variables
    array set vars [array get ::env]

    # Load the var_list into vars
    foreach var_pair $var_list {
      set vars([string toupper [lindex $var_pair 0]]) [perform_substitutions [lindex $var_pair 1]]
    }

    # Set the environment
    array set ::env [array get vars]

  }

  ######################################################################
  # Returns true if the specified URL returns a status of ok and an ncode
  # value of 200; otherwise, returns a value of false;
  proc test_url {url} {

    # Attempt to open the URL
    if {[catch { http::geturl $url -validate 1 } token]} {
      return 0
    }

    # Check the return status
    set retval [expr {([http::status $token] eq "ok") && ([http::ncode $token] == 200)}]

    # Cleanup the token
    http::cleanup $token

    return $retval

  }

  ######################################################################
  # Downloads the file specified by the given URL to a temporary file
  # which is returned.  If there is any error downloading the URL file,
  # returns the empty string.
  proc download_url {url} {

    # Get the URL type
    if {![regexp {^(ftp|https?)://} $url -> type]} {
      return ""
    }

    # Create a temporary file that will store binary data
    if {[catch { open [set fname [exec mktemp]] w } rc]} {
      return ""
    }

    fconfigure $rc -encoding binary

    # Attempt to open the URL
    if {[catch { http::geturl $url -channel $rc } token]} {
      close $rc
      file delete -force $fname
      return ""
    }

    # Closes temporary file
    close $rc

    # Check the return status
    if {([http::status $token] eq "ok") && ([http::ncode $token] == 200)} {
      return $fname
    } else {
      file delete -force $fname
      return ""
    }

  }

  ######################################################################
  # Opens the given filename in an external application, using one of the
  # open terminal commands to determine the proper application to use.
  # Returns true if the file/command failed to open; otherwise, returns 0.
  proc open_file_externally {fname {in_background 0}} {

    set opts ""

    # If the file to be viewed is located in the installation file system in freewrap,
    # unpack the file so that we can act on it via exec.
    if {[namespace exists ::freewrap] && [zvfs::exists $fname]} {
      set fname [freewrap::unpack $fname]
    }

    switch -glob $::tcl_platform(os) {
      Darwin {
        if {$in_background} {
          set opts "-g"
        }
        return [catch { exec open {*}$opts $fname }]
      }
      Linux* {
        if {$in_background} {
          return [catch { exec -ignorestderr xdg-open $fname & }]
        } else {
          return [catch { exec -ignorestderr xdg-open $fname }]
        }
      }
      *Win* {
        if {[string range $fname 0 3] eq "http"} {
          return [catch { exec {*}[auto_execok start] {} $fname }]
        } else {
          return [catch { exec {*}[auto_execok start] {} [file nativename $fname] }]
        }
      }
    }

  }

  ######################################################################
  # Get relative path to target file from current path
  # First argument is a file name, second a directory name (not checked)
  proc relative_to {targetfile currentpath} {
    set cc [file split [file normalize $currentpath]]
    set tt [file split [file normalize $targetfile]]
    if {![string equal [lindex $cc 0] [lindex $tt 0]]} {
      return $targetfile
    }
    while {[string equal [lindex $cc 0] [lindex $tt 0]] && ([llength $cc] > 0)} {
      # discard matching components from the front
      set cc [lreplace $cc 0 0]
      set tt [lreplace $tt 0 0]
    }
    set prefix ""
    if {[llength $cc] == 0} {
      # just the file name, so targetfile is lower down (or in same place)
      set prefix "."
    }
    # step up the tree
    for {set i 0} {$i < [llength $cc]} {incr i} {
      append prefix " .."
    }
    # stick it all together (the eval is to flatten the targetfile list)
    return [eval file join $prefix $tt]
  }

  ######################################################################
  # Returns the default foreground color.
  proc get_default_foreground {} {

    return [ttk::style configure "." -foreground]

  }

  ######################################################################
  # Returns the default background color.
  proc get_default_background {} {

    return [ttk::style configure "." -background]

  }

  ######################################################################
  # Converts the given color to an RGB list.
  proc color_to_rgb {color} {

    lassign [winfo rgb . $color] r g b

    return [list [expr $r >> 8] [expr $g >> 8] [expr $b >> 8]]

  }

  ######################################################################
  # Returns the color black or white such that the returned color
  # will be visible next to the given color (the given color does not
  # need to be monochrome).
  proc get_complementary_mono_color {color} {

    lassign [color_to_rgb $color] r g b

    # Calculate lightness (adjust the blue value to get a better result)
    set sorted [lsort -real [list $r $g [expr $b & 0xfc]]]

    return [expr {((([lindex $sorted 0] + [lindex $sorted 2]) / 2) < 127) ? "white" : "black"}]

  }

  ######################################################################
  # Converts an RGB value into an HSV value.
  proc rgb_to_hsv {r g b} {

    set sorted [lsort -real [list $r $g $b]]
    set temp   [lindex $sorted 0]
    set v      [lindex $sorted 2]

    set bottom [expr {$v-$temp}]
    if {$bottom == 0} {
      set h 0
      set s 0
      set v $v
    } else {
      if {$v == $r} {
        set top [expr {$g-$b}]
        if {$g >= $b} {
          set angle 0
        } else {
          set angle 360
        }
      } elseif {$v == $g} {
        set top [expr {$b-$r}]
        set angle 120
      } elseif {$v == $b} {
        set top [expr {$r-$g}]
        set angle 240
      }
      set h [expr { round( 60 * ( double($top) / $bottom ) + $angle ) }]
    }

    if {$v == 0} {
      set s 0
    } else {
      set s [expr { round( 255 - 255 * ( double($temp) / $v ) ) }]
    }

    return [list $h $s $v]

  }

  ######################################################################
  # Converts an HSV value into an RGB value.
  proc hsv_to_rgb {h s v} {

    set hi [expr { int( double($h) / 60 ) % 6 }]
    set f  [expr { double($h) / 60 - $hi }]
    set s  [expr { double($s)/255 }]
    set v  [expr { double($v)/255 }]
    set p  [expr { double($v) * (1 - $s) }]
    set q  [expr { double($v) * (1 - $f * $s) }]
    set t  [expr { double($v) * (1 - (1 - $f) * $s) }]

    switch -- $hi {
      0 {
        set r $v
        set g $t
        set b $p
      }
      1 {
        set r $q
        set g $v
        set b $p
      }
      2 {
        set r $p
        set g $v
        set b $t
      }
      3 {
        set r $p
        set g $q
        set b $v
      }
      4 {
        set r $t
        set g $p
        set b $v
      }
      5 {
        set r $v
        set g $p
        set b $q
      }
      default {
        error "Wrong hi value in hsv_to_rgb procedure! This should never happen!"
      }
    }

    set r [expr {round($r*255)}]
    set g [expr {round($g*255)}]
    set b [expr {round($b*255)}]

    return [list $r $g $b]

  }

  ######################################################################
  # Converts an RGB value into an HSL value.
  proc rgb_to_hsl {r g b} {

    set r [expr double($r) / 255]
    set g [expr double($g) / 255]
    set b [expr double($b) / 255]

    lassign [lsort -real [list $r $g $b]] m unused M
    set C [expr $M - $m]

    # Calculate hue
    if {$C == 0.0} {
      set h 0
    } elseif {$M == $r} {
      set h [expr round( fmod( (($g - $b) / $C), 6.0 ) * 60 )]
    } elseif {$M == $g} {
      set h [expr round( ((($b - $r) / $C) + 2.0) * 60 )]
    } else {
      set h [expr round( ((($r - $g) / $C) + 4.0) * 60 )]
    }

    # Calculate light
    set l [expr ($M + $m) / 2]

    # Calculate saturation
    if {$C == 0.0} {
      set s 0
    } else {
      set s [expr $C / (1.0 - abs( (2 * $l) - 1 ))]
    }

    return [list $h $s $l]

  }

  ######################################################################
  # Converts an HSL value into an RGB value.
  proc hsl_to_rgb {h s l} {

    set s [expr $s / 100.0]
    set l [expr $l / 100.0]
    set c [expr (1 - abs( (2 * $l) - 1 )) * $s]
    set m [expr ($l - ($c / 2)) * 255]
    set x [expr $c * (1 - abs( fmod( ($h / 60.0), 2 ) - 1))]

    if {$h <  60} {
      lassign [list [expr ($c * 255) + $m] [expr ($x * 255) + $m] $m] r g b
    } elseif {$h < 120} {
      lassign [list [expr ($x * 255) + $m] [expr ($c * 255) + $m] $m] r g b
    } elseif {$h < 180} {
      lassign [list $m [expr ($c * 255) + $m] [expr ($x * 255) + $m]] r g b
    } elseif {$h < 240} {
      lassign [list $m [expr ($x * 255) + $m] [expr ($c * 255) + $m]] r g b
    } elseif {$h < 300} {
      lassign [list [expr ($x * 255) + $m] $m [expr ($c * 255) + $m]] r g b
    } else {
      lassign [list [expr ($c * 255) + $m] $m [expr ($x * 255) + $m]] r g b
    }

    return [list [expr round( $r )] [expr round( $g )] [expr round( $b )]]

  }

  ######################################################################
  # Returns the value of the given color
  proc get_color_values {color} {

    lassign [rgb_to_hsv {*}[set rgb [color_to_rgb $color]]] hue saturation value

    return [list $value {*}$rgb [format "#%02x%02x%02x" {*}$rgb]]

  }

  ######################################################################
  # Automatically adjusts the given color by a value equal to diff such
  # that if color is a darker color, the value will be lightened and if
  # color is a lighter color, the value will be darkened.
  proc auto_adjust_color {color diff {mode "auto"}} {

    lassign [rgb_to_hsv {*}[color_to_rgb $color]] hue saturation value

    switch $mode {
      "auto"   { set value [expr ($value < 128) ? ($value + $diff) : ($value - $diff)] }
      "manual" { set value [expr $value + $diff] }
    }

    return [format {#%02x%02x%02x} {*}[hsv_to_rgb $hue $saturation $value]]

  }

  ######################################################################
  # Adjusts the hue of the given color by the value of difference.
  proc auto_mix_colors {color type diff} {

    # Create the lighter version of the primary color
    lassign [color_to_rgb $color] r g b

    switch $type {
      r {
        if {[set odiff [expr 255 - ($r + $diff)]] >= 0} {
          incr r $diff
        } else {
          set d [expr abs($odiff) / 2]
          set r 255
          set g [expr (($g - $d) > 0) ? ($g - $d) : 0]
          set b [expr (($b - $d) > 0) ? ($b - $d) : 0]
        }
      }
      g {
        if {[set odiff [expr 255 - ($g + $diff)]] >= 0} {
          incr g $diff
        } else {
          set d [expr abs($odiff) / 2]
          set g 255
          set r [expr (($r - $d) > 0) ? ($r - $d) : 0]
          set b [expr (($b - $d) > 0) ? ($b - $d) : 0]
        }
      }
      b {
        if {[set odiff [expr 255 - ($b + $diff)]] >= 0} {
          incr b $diff
        } else {
          set d [expr abs($odiff) / 2]
          set b 255
          set r [expr (($r - $d) > 0) ? ($r - $d) : 0]
          set g [expr (($g - $d) > 0) ? ($g - $d) : 0]
        }
      }
    }

    return [format {#%02x%02x%02x} $r $g $b]

  }

  ######################################################################
  # Returns the RGB color which is between the two specified colors.
  proc color_difference {color1 color2} {

    lassign [color_to_rgb $color1] r1 g1 b1
    lassign [color_to_rgb $color2] r2 g2 b2

    return [format {#%02x%02x%02x} [expr ($r1 + $r2) / 2] [expr ($g1 + $g2) / 2] [expr ($b1 + $b2) / 2]]

  }

  ######################################################################
  # Converts a character to its associated keysym.  Note:  Only printable
  # string values are supported.
  proc string_to_keysym {str} {

    variable c2k_map

    return [string map [array get c2k_map] $str]

  }

  ######################################################################
  # Convers a keysym to a character.
  proc sym2char {sym} {

    variable c2k_map

    set map_list [array get c2k_map]

    if {[set index [lsearch -exact $map_list $sym]] != -1} {
      return [lindex $map_list [expr $index - 1]]
    } elseif {[string length $sym] == 1} {
      return $sym
    } else {
      return ""
    }

  }

  ######################################################################
  # Helper procedure for the egrep utility procedure.  Performs the equivalent
  # of a POSIX egrep command with the given information.
  proc egrep_file {pattern fname context opts} {

    set result ""

    # If the file cannot be read, skip the file grep
    if {[catch { open $fname r } rc]} {
      return ""
    }

    # Grab the file contents
    set lines [split [read $rc] \n]
    close $rc

    # Initialize some variables
    set i           0
    set last_output -1
    set last_match  -1

    foreach line $lines {
      if {[regexp {*}$opts -- $pattern $line]} {
        if {($last_output != -1) && (($i - $last_output) < $context)} {
          set j [expr $last_output + 1]
        } else {
          append result "--\n--\n"
          set j [expr $i - $context]
        }
        foreach cline [lrange $lines $j [expr $i - 1]] {
          append result "$fname-[expr $j + 1]-$cline\n"
          incr j
        }
        append result "$fname:[expr $i + 1]:$line\n"
        set last_match  $i
        set last_output $i
      } elseif {($last_match != -1) && (($i - $last_match) <= $context)} {
        append result "$fname-[expr $i + 1]-$line\n"
        set last_output $i
      }
      incr i
    }

    return $result

  }

  ######################################################################
  # Takes a list of files and performs the equivalent of a POSIX egrep
  # with the given pattern, options and context information.
  proc egrep {pattern paths context opts} {

    set result ""

    foreach path $paths {
      append result [egrep_file $pattern $path $context $opts]
    }

    return $result

  }

  ######################################################################
  # Returns true if the given filename is a binary file; otherwise,
  # returns false to indicate that the file is a text file.  This code
  # is lifted from the fileutil::fileType procedure, but should perform
  # better since we are not interested in all of the file information.
  proc is_binary {fname} {

    variable bin_rx

    # Open the file for reading
    if {[catch { open $fname r } rc]} {
      return -code error "utils::is_binary: $rc"
    }

    # Read the first 1024 bytes
    fconfigure $rc -translation binary -buffersize 1024 -buffering full
    set test [read $rc 1024]
    close $rc

    # If the code segment contains any of the characters in bin_rx, indicate that it is a binary file
    return [regexp $bin_rx $test]

  }

  ######################################################################
  # Returns crlf, lf or cr to specify which EOL character was used for the
  # given file.
  proc get_eol_char {fname} {

    variable eol_rx

    if {[catch { open $fname r } rc]} {
      return -code error "utils::get_eol_char: $rc"
    }

    # Read the first 1024 bytes
    fconfigure $rc -translation binary -buffersize 1024 -buffering full
    set test [read $rc 1024]
    close $rc

    return [string map {\{ {} \} {} \r\n crlf \n lf \r cr} [regexp -inline $eol_rx $test]]

  }

  ######################################################################
  # Performs a glob command for files within the installation in
  # the given directory with the given pattern.  Takes into account
  # whether we are running within freewrap or not.
  proc glob_install {path pattern {tails 0}} {

    if {[namespace exists ::freewrap]} {
      if {$tails} {
        return [lmap item [zvfs::list [file join $path $pattern]] { file tail $item }]
      } else {
        return [zvfs::list [file join $path $pattern]]
      }
    } else {
      if {$tails} {
        return [glob -nocomplain -directory $path -tails $pattern]
      } else {
        return [glob -nocomplain -directory $path $pattern]
      }
    }

  }

  ######################################################################
  # Returns the full language name at the current insertion index.
  proc get_current_lang {txt} {

    if {[set lang [ctext::get_lang $txt insert]] eq ""} {
      set lang [syntax::get_language $txt]
    }

    return $lang

  }

  ######################################################################
  # Centers the specified window on the screen.
  proc center_on_screen {win} {

    set screenwidth  [winfo screenwidth  $win]
    set screenheight [winfo screenheight $win]
    set width        [winfo width        $win]
    set height       [winfo height       $win]

    # Place the window in the middle of the screen
    wm geometry $win +[expr ($screenwidth / 2) - ($width / 2)]+[expr ($screenheight / 2) - ($height / 2)]

  }

  ######################################################################
  # Returns a list containing the character range of the basename within
  # the given filename.
  proc basename_range {fname} {

    if {[regexp -indices "^.*([file tail $fname])\$" $fname -> range]} {
      return [list [lindex $range 0] [expr [lindex $range 1] + 1]]
    }

    return [list]

  }

  ######################################################################
  # Returns a string giving the size of the given file using B, KB, MB, etc.
  proc get_file_size {fname} {

    set size [file size $fname]

    if {$size < 1024} {
      return "$size bytes"
    } elseif {$size < pow(1024, 2)} {
      return [format {%0.1f KB} [expr $size.0 / 1024]]
    } elseif {$size < pow(1024, 3)} {
      return [format {%0.1f MB} [expr $size.0 / pow(1024, 2)]]
    } else {
      return [format {%0.1f GB} [expr $size.0 / pow(1024, 3)]]
    }

  }

  ######################################################################
  # Returns the file permissions a string in the form of "rwxrwxrwx".
  proc get_file_permissions {fname} {

    if {$::tcl_platform(platform) eq "windows"} {
      append str [expr {[file readable   $fname] ? "r" : "-"}]
      append str [expr {[file writable   $fname] ? "w" : "-"}]
      append str [expr {[file executable $fname] ? "x" : "-"}]
      return [string repeat $str 3]
    }

    array set perms [list 0 "---" 1 "--x" 2 "-w-" 3 "-wx" 4 "r--" 5 "r-x" 6 "rw-" 7 "rwx"]

    set perm [file attributes $fname -permissions]

    return "$perms([string index $perm end-2])$perms([string index $perm end-1])$perms([string index $perm end])"

  }

  ######################################################################
  # Returns the owner of the given file.
  proc get_file_owner {fname} {

    array set attrs [file attributes $fname]

    return [expr {[info exists attrs(-owner)] ? $attrs(-owner) : ""}]

  }

  ######################################################################
  # Returns the group associated with the given file.
  proc get_file_group {fname} {

    array set attrs [file attributes $fname]

    return [expr {[info exists attrs(-group)] ? $attrs(-group) : ""}]

  }

}
