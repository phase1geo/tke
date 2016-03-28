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

  array set pref_complete    {}
  array set complete         {}
  array set lang_match_chars {}

  trace add variable [ns preferences]::prefs(Editor/AutoMatchChars) write [ns completer]::handle_auto_match_chars

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

    bind comp$txt <Key-bracketleft>  "[ns completer]::add_square %W left"
    bind comp$txt <Key-bracketright> "if {\[[ns completer]::add_square %W right\]} { break }"
    bind comp$txt <Key-braceleft>    "[ns completer]::add_curly %W left"
    bind comp$txt <Key-braceright>   "if {\[[ns completer]::add_curly %W right\]} { break }"
    bind comp$txt <Key-less>         "[ns completer]::add_angled %W left"
    bind comp$txt <Key-greater>      "if {\[[ns completer]::add_angled %W right\]} { break }"
    bind comp$txt <Key-parenleft>    "[ns completer]::add_paren %W left"
    bind comp$txt <Key-parenright>   "if {\[[ns completer]::add_paren %W right\]} { break }"
    bind comp$txt <Key-quotedbl>     "if {\[[ns completer]::add_double %W\]} { break }"
    bind comp$txt <Key-quoteright>   "if {\[[ns completer]::add_single %W\]} { break }"
    bind comp$txt <BackSpace>        "[ns completer]::handle_delete %W"

    # Add the bindings
    set text_index [lsearch [bindtags $txt.t] Text]
    bindtags $txt.t [linsert [bindtags $txt.t] $text_index comp$txt]

    # Make sure that the complete array is initialized for the text widget
    # in case there is no language
    set_auto_match_chars $txt.t {} {}

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
          ctext::matchPair [winfo parent $txtt] squareL
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
          ctext::matchPair [winfo parent $txtt] curlyL
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
          ctext::matchPair [winfo parent $txtt] angledL
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
          ctext::matchPair [winfo parent $txtt] parenL
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
          ctext::matchQuote [winfo parent $txtt]
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
  # Handles a deletion.
  proc handle_delete {txtt} {

    variable complete

    if {![ctext::inComment $txtt insert-2c]} {
      set lang [ctext::get_lang $txtt insert]
      switch [$txtt get insert-1c insert+1c] {
        "\[\]" {
          if {$complete($txtt,$lang,square)} {
            $txtt delete insert
          }
        }
        "\{\}" {
          if {$complete($txtt,$lang,curly)} {
           $txtt delete insert
          }
        }
        "<>" {
          if {$complete($txtt,$lang,angled)} {
            $txtt delete insert
          }
        }
        "()" {
          if {$complete($txtt,$lang,paren)} {
            $txtt delete insert
          }
        }
        "\"\"" {
          if {$complete($txtt,$lang,double)} {
            $txtt delete insert
          }
        }
        "''" {
          if {$complete($txtt,$lang,single)} {
            $txtt delete insert
          }
        }
      }
    }

  }

}
