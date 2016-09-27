# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
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
# Name:     completer.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     11/4/2014
# Brief:    Contains namespace handling bracket/string completion.
######################################################################

namespace eval completer {

  source [file join $::tke_dir lib ns.tcl]

  variable delete_check ""

  array set pref_complete    {}
  array set complete         {}
  array set lang_match_chars {}

  trace add variable [ns preferences]::prefs(Editor/AutoMatchChars)           write [ns completer]::handle_auto_match_chars
  trace add variable [ns preferences]::prefs(Editor/HighlightMismatchingChar) write [ns completer]::handle_bracket_audit

  ######################################################################
  # Handles any changes to the Editor/AutoMatchChars preference value.
  proc handle_auto_match_chars {name1 name2 op} {

    variable pref_complete
    variable lang_match_chars

    # Populate the pref_complete array with the values from the preferences file
    array set pref_complete {
      square 0
      curly  0
      angled 0
      paren  0
      double 0
      single 0
      btick  0
    }

    foreach value [[ns preferences]::get Editor/AutoMatchChars] {
      set pref_complete($value) 1
    }

    # Update all text widgets
    foreach key [array names lang_match_chars] {
      lassign [split $key ,] txtt lang
      set_auto_match_chars $txtt $lang $lang_match_chars($key)
    }

  }

  ######################################################################
  # Handle any changes to the bracket auditing preference value.
  proc handle_bracket_audit {name1 name2 op} {

    variable lang_match_chars

    # Update all text widgets
    foreach key [array names lang_match_chars] {
      check_all_brackets [lindex [split $key ,] 0]
    }

  }

  ######################################################################
  # Sets the auto-match characters based on the current language.
  proc set_auto_match_chars {txtt lang matchchars} {

    variable lang_match_chars
    variable pref_complete
    variable complete

    # Save the language-specific match characters
    set lang_match_chars($txtt,$lang) $matchchars

    # Initialize the complete array for the given text widget
    array set complete [list \
      $txtt,$lang,square 0 \
      $txtt,$lang,curly  0 \
      $txtt,$lang,angled 0 \
      $txtt,$lang,paren  0 \
      $txtt,$lang,double 0 \
      $txtt,$lang,single 0 \
      $txtt,$lang,btick  0 \
    ]

    # Combine the language-specific match chars with preference chars
    foreach match_char $lang_match_chars($txtt,$lang) {
      if {$pref_complete($match_char)} {
        set complete($txtt,$lang,$match_char) 1
      }
    }

  }

  ######################################################################
  # Adds bindings to the given text widget.
  proc add_bindings {txt} {

    bind precomp$txt <Key-bracketleft>  "[ns completer]::add_square %W left"
    bind precomp$txt <Key-bracketright> "if {\[[ns completer]::add_square %W right\]} { break }"
    bind precomp$txt <Key-braceleft>    "[ns completer]::add_curly %W left"
    bind precomp$txt <Key-braceright>   "if {\[[ns completer]::add_curly %W right\]} { break }"
    bind precomp$txt <Key-less>         "[ns completer]::add_angled %W left"
    bind precomp$txt <Key-greater>      "if {\[[ns completer]::add_angled %W right\]} { break }"
    bind precomp$txt <Key-parenleft>    "[ns completer]::add_paren %W left"
    bind precomp$txt <Key-parenright>   "if {\[[ns completer]::add_paren %W right\]} { break }"
    bind precomp$txt <Key-quotedbl>     "if {\[[ns completer]::add_double %W\]} { break }"
    bind precomp$txt <Key-quoteright>   "if {\[[ns completer]::add_single %W\]} { break }"
    bind precomp$txt <Key-quoteleft>    "if {\[[ns completer]::add_btick %W\]} { break }"
    bind precomp$txt <BackSpace>        "[ns completer]::handle_delete %W"

    bind postcomp$txt <Key-bracketleft>  [list [ns completer]::check_brackets %W square]
    bind postcomp$txt <Key-bracketright> [list [ns completer]::check_brackets %W square]
    bind postcomp$txt <Key-braceleft>    [list [ns completer]::check_brackets %W curly]
    bind postcomp$txt <Key-braceright>   [list [ns completer]::check_brackets %W curly]
    bind postcomp$txt <Key-less>         [list [ns completer]::check_brackets %W angled]
    bind postcomp$txt <Key-greater>      [list [ns completer]::check_brackets %W angled]
    bind postcomp$txt <Key-parenleft>    [list [ns completer]::check_brackets %W paren]
    bind postcomp$txt <Key-parenright>   [list [ns completer]::check_brackets %W paren]
    bind postcomp$txt <BackSpace>        [list [ns completer]::check_delete %W]

    # Add the bindings
    set text_index [lsearch [bindtags $txt.t] Text]
    bindtags $txt.t [linsert [bindtags $txt.t] [expr $text_index + 1] postcomp$txt]
    bindtags $txt.t [linsert [bindtags $txt.t] $text_index precomp$txt]

    # Make sure that the complete array is initialized for the text widget
    # in case there is no language
    set_auto_match_chars $txt.t {} {}

    # Create the tag for missing brackets
    foreach tag [list square curly paren angled] {
      $txt tag configure missing:$tag -foreground red
    }

  }

  ######################################################################
  # Returns true if a closing character should be automatically added.
  # This is called when an opening character is detected.
  proc add_closing {txtt} {

    # Get the character at the insertion cursor
    set ch [$txtt get insert]

    if {[string is space $ch] || ($ch eq "\}") || ($ch eq "\)") || ($ch eq ">") || ($ch eq "]")} {
      return 1
    }

    return 0

  }

  ######################################################################
  # Returns true if a closing character should be omitted from insertion.
  # This is called when a closing character is detected.
  proc skip_closing {txtt type} {

    return [expr [lsearch [$txtt tag names insert] _${type}R] != -1]

  }

  ######################################################################
  # Handles a square bracket.
  proc add_square {txtt side} {

    variable complete

    if {$complete($txtt,[ctext::get_lang $txtt "insert-1c"],square) && ![ctext::inComment $txtt "insert-1c"]} {
      if {$side eq "right"} {
        if {[skip_closing $txtt square]} {
          ::tk::TextSetCursor $txtt "insert+1c"
          return 1
        }
      } else {
        set ins [$txtt index insert]
        if {[add_closing $txtt]} {
          $txtt insert insert "\]"
        }
        ::tk::TextSetCursor $txtt $ins
      }
    }

    return 0

  }

  ######################################################################
  # Handles a curly bracket.
  proc add_curly {txtt side} {

    variable complete

    if {$complete($txtt,[ctext::get_lang $txtt "insert-1c"],curly) && ![ctext::inComment $txtt "insert-1c"]} {
      if {$side eq "right"} {
        if {[skip_closing $txtt curly]} {
          ::tk::TextSetCursor $txtt "insert+1c"
          return 1
        }
      } else {
        set ins [$txtt index insert]
        if {[add_closing $txtt]} {
          $txtt insert insert "\}"
        }
        ::tk::TextSetCursor $txtt $ins
      }
    }

    return 0

  }

  ######################################################################
  # Handles an angled bracket.
  proc add_angled {txtt side} {

    variable complete

    if {$complete($txtt,[ctext::get_lang $txtt "insert-1c"],angled) && ![ctext::inComment $txtt "insert-1c"]} {
      if {$side eq "right"} {
        if {[skip_closing $txtt angled]} {
          ::tk::TextSetCursor $txtt "insert+1c"
          return 1
        }
      } else {
        set ins [$txtt index insert]
        if {[add_closing $txtt]} {
          $txtt insert insert ">"
        }
        ::tk::TextSetCursor $txtt $ins
      }
    }

    return 0

  }

  ######################################################################
  # Handles a parenthesis.
  proc add_paren {txtt side} {

    variable complete

    if {$complete($txtt,[ctext::get_lang $txtt "insert-1c"],paren) && ![ctext::inComment $txtt "insert-1c"]} {
      if {$side eq "right"} {
        if {[skip_closing $txtt paren]} {
          ::tk::TextSetCursor $txtt "insert+1c"
          return 1
        }
      } else {
        set ins [$txtt index insert]
        if {[add_closing $txtt]} {
          $txtt insert insert ")"
        }
        ::tk::TextSetCursor $txtt $ins
      }
    }

    return 0

  }

  ######################################################################
  # Handles a double-quote character.
  proc add_double {txtt} {

    variable complete

    if {$complete($txtt,[ctext::get_lang $txtt "insert-1c"],double)} {
      if {[ctext::inDoubleQuote $txtt insert]} {
        if {([$txtt get insert] eq "\"") && ![ctext::isEscaped $txtt insert]} {
          ::tk::TextSetCursor $txtt "insert+1c"
          return 1
        }
      } elseif {[ctext::inDoubleQuote $txtt end-1c]} {
        return 0
      } else {
        set ins [$txtt index insert]
        if {![ctext::inCommentString $txtt "insert-1c"]} {
          $txtt insert insert "\""
        }
        ::tk::TextSetCursor $txtt $ins
      }
    }

    return 0

  }

  ######################################################################
  # Handles a single-quote character.
  proc add_single {txtt} {

    variable complete

    if {$complete($txtt,[ctext::get_lang $txtt "insert-1c"],single)} {
      if {[ctext::inSingleQuote $txtt insert]} {
        if {([$txtt get insert] eq "'") && ![ctext::isEscaped $txtt insert]} {
          ::tk::TextSetCursor $txtt "insert+1c"
          return 1
        }
      } elseif {[ctext::inSingleQuote $txtt end-1c]} {
        return 0
      } else {
        set ins [$txtt index insert]
        if {![ctext::inCommentString $txtt "insert-1c"]} {
          $txtt insert insert "'"
        }
        ::tk::TextSetCursor $txtt $ins
      }
    }

    return 0

  }

  ######################################################################
  # Handles a backtick character.
  proc add_btick {txtt} {

    variable complete

    if {$complete($txtt,[ctext::get_lang $txtt "insert-1c"],btick)} {
      if {[ctext::inBackTick $txtt insert]} {
        if {([$txtt get insert] eq "`") && ![ctext::isEscaped $txtt insert]} {
          ::tk::TextSetCursor $txtt "insert+1c"
          return 1
        }
      } elseif {[ctext::inBackTick $txtt end-1c]} {
        return 0
      } else {
        set ins [$txtt index insert]
        if {![ctext::inCommentString $txtt "insert-1c"]} {
          $txtt insert insert "`"
        }
        ::tk::TextSetCursor $txtt $ins
      }
    }

    return 0

  }

  ######################################################################
  # Handles a deletion.
  proc handle_delete {txtt} {

    variable complete
    variable delete_check

    if {![ctext::inComment $txtt insert-2c]} {
      set lang [ctext::get_lang $txtt insert]
      switch [$txtt get insert-1c insert+1c] {
        "\[\]" {
          if {$complete($txtt,$lang,square)} {
            $txtt delete insert
            return
          }
        }
        "\{\}" {
          if {$complete($txtt,$lang,curly)} {
            $txtt delete insert
            return
          }
        }
        "<>" {
          if {$complete($txtt,$lang,angled)} {
            $txtt delete insert
            return
          }
        }
        "()" {
          if {$complete($txtt,$lang,paren)} {
            $txtt delete insert
            return
          }
        }
        "\"\"" {
          if {$complete($txtt,$lang,double)} {
            $txtt delete insert
            return
          }
        }
        "''" {
          if {$complete($txtt,$lang,single)} {
            $txtt delete insert
            return
          }
        }
        "``" {
          if {$complete($txtt,$lang,btick)} {
            $txtt delete insert
            return
          }
        }
      }
      switch [$txtt get insert-1c] {
        "\[" -
        "\]" { set delete_check square }
        "\{" -
        "\}" { set delete_check curly  }
        "<"  -
        ">"  { set delete_check angled }
        "("  -
        ")"  { set delete_check paren  }
      }
    }

  }

  ######################################################################
  # This should be called after a bracket is inserted or deleted.
  proc check_match {txtt stype} {

    variable delete_check

    # If the mismcatching char option is cleared, don't continue
    if {![[ns preferences]::get Editor/HighlightMismatchingChar]} {
      return
    }

    # If we deleted a character, set the stype and index
    if {$stype eq "del"} {
      set stype $delete_check
      if {[string index $stype end] eq "L"} {
        set index [ctext::get_prev_bracket $txtt $stype insert]
      } else {
        set index [ctext::get_next_bracket $txtt $stype insert]
      }
      if {$index eq ""} { return }

    # Otherwise, set the index
    } else {
      set index [$txtt index "insert-1c"]
    }

    # Search for the opposite bracket
    set dir [string index $stype end]
    set cmd [expr {($dir eq "L") ? "prev" : "next"}]

    # Get the other bracket type
    set other_index [ctext::get_${cmd}_bracket $txtt $other($stype) $index]

    # Attempt to find the matching index
    while {($index ne "") && \
           ([set match_index [ctext::get_match_bracket $txtt $other($stype) $index]] ne "") && \
           (($other_index eq "") || ([$txtt compare $other_index < $index]))} {
      $txtt tag remove missing $match_index
      set index [ctext::get_${cmd}_bracket $txtt $stype $index]
    }

    if {$match_index eq ""} {
      $txtt tag add missing $index "$index+1c"
    }

  }

  ######################################################################
  # Checks all of the matches.
  proc check_all_brackets {txtt {str ""}} {

    # If a string was supplied, only perform bracket check for brackets found in string
    if {$str ne ""} {
      if {[string map {\{ {} \} {}} $str] ne $str} { check_brackets $txtt curly  }
      if {[string map {\[ {} \] {}} $str] ne $str} { check_brackets $txtt square }
      if {[string map {( {} ) {}}   $str] ne $str} { check_brackets $txtt paren  }
      if {[string map {< {} > {}}   $str] ne $str} { check_brackets $txtt angled }

    # Otherwise, check all of the brackets
    } else {
      foreach type [list square curly paren angled] {
        check_brackets $txtt $type
      }
    }

  }

  ######################################################################
  # Called when a bracket character is deleted.
  proc check_delete {txtt} {

    variable delete_check

    if {$delete_check ne ""} {
      check_brackets $txtt $delete_check
      set delete_check ""
    }

  }

  ######################################################################
  # Checks all matches in the editing buffer.
  proc check_brackets {txtt stype} {

    # Clear missing
    $txtt tag remove missing:$stype 1.0 end

    # If the mismcatching char option is cleared, don't continue
    if {![[ns preferences]::get Editor/HighlightMismatchingChar]} {
      return
    }

    set count   0
    set other   ${stype}R
    set olist   [lassign [$txtt tag ranges _$other] ofirst olast]
    set missing [list]

    # Perform count for all code containing left stypes
    foreach {sfirst slast} [$txtt tag ranges _${stype}L] {
      while {($ofirst ne "") && [$txtt compare $sfirst > $ofirst]} {
        if {[incr count -[$txtt count -chars $ofirst $olast]] < 0} {
          lappend missing "$olast+${count}c" $olast
          set count 0
        }
        set olist [lassign $olist ofirst olast]
      }
      if {$count == 0} {
        set start $sfirst
      }
      incr count [$txtt count -chars $sfirst $slast]
    }

    # Perform count for all right types after the above code
    while {$ofirst ne ""} {
      if {[incr count -[$txtt count -chars $ofirst $olast]] < 0} {
        lappend missing "$olast+${count}c" $olast
        set count 0
      }
      set olist [lassign $olist ofirst olast]
    }

    # Highlight all brackets that are missing right stypes
    while {$count > 0} {
      lappend missing $start "$start+1c"
      set start [ctext::get_next_bracket $txtt ${stype}L]
      incr count -1
    }

    # Highlight all brackets that are missing left stypes
    catch { $txtt tag add missing:$stype {*}$missing }

  }

}
