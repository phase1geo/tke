# Name:     completer.tcl
# Author:   Trevor Williams  (phase1geo@gmail.com)
# Date:     11/4/2014
# Brief:    Contains namespace handling bracket/string completion.

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
    foreach txt [array names lang_match_chars] {
      set_auto_match_chars $txt $lang_match_chars($txt)
    }

  }
  
  ######################################################################
  # Sets the auto-match characters based on the current language.
  proc set_auto_match_chars {txt matchchars} {
    
    variable lang_match_chars
    variable pref_complete
    variable complete

    # Save the language-specific match characters
    set lang_match_chars($txt) $matchchars
    
    # Initialize the complete array for the given text widget
    array set complete [list \
      $txt,square 0 \
      $txt,curly  0 \
      $txt,angled 0 \
      $txt,paren  0 \
      $txt,double 0 \
      $txt,single 0 \
    ]
      
    # Combine the language-specific match chars with preference chars
    foreach match_char $lang_match_chars($txt) {
      if {$pref_complete($match_char)} {
        set complete($txt,$match_char) 1
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
    
  }
  
  ######################################################################
  # Handles a square bracket.
  proc add_square {txt side} {
    
    variable complete

    if {$complete($txt,square) && ![ctext::inCommentString $txt insert-1c]} {
      if {$side eq "right"} {
        if {[$txt get insert] eq "\]"} {
          $txt mark set insert "insert+1c"
          return 1
        }
      } else {
        set ins [$txt index insert]
        $txt insert insert "\]"
        $txt mark set insert $ins
      }
    }
    
    return 0
    
  }
  
  ######################################################################
  # Handles a curly bracket.
  proc add_curly {txt side} {

    variable complete
    
    if {$complete($txt,curly) && ![ctext::inCommentString $txt insert-1c]} {
      if {$side eq "right"} {
        if {[$txt get insert] eq "\}"} {
          $txt mark set insert "insert+1c"
          return 1
        }
      } else {
        set ins [$txt index insert]
        $txt insert insert "\}"
        $txt mark set insert $ins
      }
    }

    return 0

  }
  
  ######################################################################
  # Handles an angled bracket.
  proc add_angled {txt side} {

    variable complete
    
    if {$complete($txt,angled) && ![ctext::inCommentString $txt insert-1c]} {
      if {$side eq "right"} {
        if {[$txt get insert] eq ">"} {
          $txt mark set insert "insert+1c"
          return 1
        }
      } else {
        set ins [$txt index insert]
        $txt insert insert ">"
        $txt mark set insert $ins
      }
    }

    return 0
    
  }
  
  ######################################################################
  # Handles a parenthesis.
  proc add_paren {txt side} {

    variable complete
    
    if {$complete($txt,paren) && ![ctext::inCommentString $txt insert-1c]} {
      if {$side eq "right"} {
        if {[$txt get insert] eq ")"} {
          $txt mark set insert "insert+1c"
          return 1
        }
      } else {
        set ins [$txt index insert]
        $txt insert insert ")"
        $txt mark set insert $ins
      }
    }
    
    return 0

  }
  
  ######################################################################
  # Handles a double-quote character.
  proc add_double {txt} {

    variable complete

    if {$complete($txt,double)} {
      if {[ctext::inCommentString $txt insert]} {
        if {[$txt get insert] eq "\""} {
          $txt mark set insert "insert+1c"
          return 1
        }
      } else {
        set ins [$txt index insert]
        $txt insert insert "\""
        $txt mark set insert $ins
      }
    }

    return 0
    
  }
  
  ######################################################################
  # Handles a single-quote character.
  proc add_single {txt} {

    variable complete

    if {$complete($txt,single)} {
      if {[ctext::inCommentString $txt insert]} {
        if {[$txt get insert] eq "'"} {
          $txt mark set insert "insert+1c"
          return 1
        }
      } else {
        set ins [$txt index insert]
        $txt insert insert "'"
        $txt mark set insert $ins
      }
    }

    return 0

  }

  ######################################################################
  # Handles a deletion.
  proc handle_delete {txt} {

    variable complete

    if {![ctext::inCommentString $txt insert-2c]} {
      switch [$txt get insert-1c insert+1c] {
        "\[\]" {
          if {$complete($txt,square)} {
            $txt delete insert
          }
        }
        "\{\}" {
          if {$complete($txt,curly)} {
           $txt delete insert
          }
        }
        "<>" {
          if {$complete($txt,angled)} {
            $txt delete insert
          }
        }
        "()" {
          if {$complete($txt,paren)} {
            $txt delete insert
          }
        }
        "\"\"" {
          if {$complete($txt,double)} {
            $txt delete insert
          }
        }
        "''" {
          if {$complete($txt,single)} {
            $txt delete insert
          }
        }
      }
    }

  }
  
}
