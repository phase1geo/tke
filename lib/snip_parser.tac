%{
# TKE - Advanced Programmer's Editor
# Copyright (C) 2014  Trevor Williams (phase1geo@gmail.com)
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
# Name:    snip_parser.tac
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    8/10/2015
# Brief:   Parser for snippet syntax.
######################################################################

source [file join $::tke_dir lib snip_lexer.tcl]

set snip_txtt   ""
set snip_value  ""
set snip_errmsg ""
set snip_errstr ""
set snip_pos    0

proc get_retval {args} {
  return [join $args {}]
}

proc merge_values {val1 val2} {
  if {[lindex $val1 end] eq ""} {
    lset val1 end-1 "[lindex $val1 end-1][lindex $val2 0]"
    return "[lrange $val1 0 end-1] [list [lindex $val2 1]]"
  }
  return [concat $val1 $val2]
}

proc apply_tabstop {ts_val ts_tag} {
  set retval [list]
  foreach {val tag} $ts_val {
    lappend retval $val [concat $tag $ts_tag]
  }
  return $retval
}

proc parse_format {str matches} {

  FORMAT__FLUSH_BUFFER

  # Insert the string to scan
  format__scan_string $str

  # Initialize some values
  set ::format_txtt    $::snip_txtt
  set ::format_begpos  0
  set ::format_endpos  0
  set ::format_matches $matches

  # Parse the string
  if {[catch { format_parse } rc] || ($rc != 0)} {
    puts "ERROR-format: $::format_errmsg ($rc)"
    puts -nonewline "line: "
    puts [string map {\n {}} $str]
    puts "      $::format_errstr"
    return ""
  }

  return $::format_value

}

%}

%token DECIMAL DOLLAR_SIGN VARNAME CHAR LOWER UPPER LOWER_BLOCK UPPER_BLOCK END_BLOCK NEWLINE TAB
%token OPEN_BRACKET CLOSE_BRACKET OPEN_PAREN CLOSE_PAREN

%%

main: snippet {
        set ::snip_value $1
      }
      ;

snippet: snippet text {
           set _ [concat $1 [list $2 {}]]
         }
       | snippet variable {
           set _ [concat $1 [list $2 {}]]
         }
       | snippet transform {
           set _ [concat $1 $2]
         }
       | snippet tabstop {
           set _ [concat $1 $2]
         }
       | snippet shell {
           set _ [concat $1 [list $2 {}]]
         }
       | text {
           set _ [list $1 {}]
         }
       | variable {
           set _ [list $1 {}]
         }
       | transform {
           set _ $1
         }
       | tabstop {
           set _ $1
         }
       | shell {
           set _ [list $1 {}]
         }
         ;

tabstop: DOLLAR_SIGN DECIMAL {
           if {[set val [snippets::get_tabstop $::snip_txtt $2]] ne ""} {
             set _ [list $val {}]
           } else {
             set _ [list "\$$2" [snippets::set_tabstop $::snip_txtt $2]]
           }
         }
       | DOLLAR_SIGN OPEN_BRACKET DECIMAL ':' value CLOSE_BRACKET {
           set _ [apply_tabstop $5 [snippets::set_tabstop $::snip_txtt $3 $5]]
         }
         ;

transform: DOLLAR_SIGN OPEN_BRACKET DECIMAL '/' pattern '/' format '/' opts CLOSE_BRACKET {
             if {[set val [snippets::get_tabstop $::snip_txtt $3]] ne ""} {
               set regexp_opts [list]
               if {[string first g $9] != -1} {
                 lappend regexp_opts -all
               }
               set _ [list [parse_format $7 [regexp -inline {*}$regexp_opts -- $5 $val]] [list]]
             } else {
               set _ [list [get_retval $1 $2 $3 $4 $5 $6 $7 $8 $9 $10] [snippets::set_tabstop $::snip_txtt $3]]
             }
           }
         | DOLLAR_SIGN OPEN_BRACKET DECIMAL '/' pattern '/' format '/' CLOSE_BRACKET {
             if {[set val [snippets::get_tabstop $::snip_txtt $3]] ne ""} {
               set _ [list [parse_format $7 [regexp -inline -- $5 $val]] [list]]
             } else {
               set _ [list [get_retval $1 $2 $3 $4 $5 $6 $7 $8 $9] [snippets::set_tabstop $::snip_txtt $3]]
             }
           }
           ;

variable: DOLLAR_SIGN varname {
            set _ $2
          }
        | DOLLAR_SIGN OPEN_BRACKET varname ':' value CLOSE_BRACKET {
            set _ [expr {($3 eq "") ? $5 : $3}]
          }
        | DOLLAR_SIGN OPEN_BRACKET varname '/' pattern '/' format '/' opts CLOSE_BRACKET {
            set regexp_opts [list]
            if {[string first g $9] != -1} {
              lappend regexp_opts "-all"
            }
            set _ [parse_format $7 [regexp -inline {*}$regexp_opts -- $5 $3]]
          }
        | DOLLAR_SIGN OPEN_BRACKET varname '/' pattern '/' format '/' CLOSE_BRACKET {
            set _ [parse_format $7 [regexp -inline -- $5 $3]]
          }
          ;

varname: VARNAME {
           set txtt $::snip_txtt
           switch $1 {
             SELECTED_TEXT { set _ [expr {![catch { $txtt get sel.first sel.last } rc] ? $rc : ""}] }
             CLIPBOARD     { set _ [expr {![catch "clipboard get" rc] ? $rc : ""}] }
             CURRENT_LINE  { set _ [$txtt get "insert linestart" "insert lineend"] }
             CURRENT_WORD  { set _ [$txtt get "insert wordstart" "insert wordend"] }
             DIRECTORY     { set _ [file dirname [gui::get_info {} current fname]] }
             FILEPATH      { set _ [gui::get_info {} current fname] }
             FILENAME      { set _ [file tail [gui::get_info {} current fname]] }
             LINE_INDEX    { set _ [lindex [split [$txtt index insert] .] 1] }
             LINE_NUMBER   { set _ [lindex [split [$txtt index insert] .] 0] }
             CURRENT_DATE  { set _ [clock format [clock seconds] -format "%m/%d/%Y"] }
           }
         }
         ;

pattern: pattern CHAR {
           set _ "$1$2"
         }
       | pattern NEWLINE {
           set _ "$1\n"
         }
       | pattern TAB {
           set _ "$1\t"
         }
       | pattern DECIMAL {
           set _ "$1$2"
         }
       | pattern DOLLAR_SIGN {
           set _ "$1\$"
         }
       | pattern OPEN_PAREN {
           set _ "$1\("
         }
       | pattern CLOSE_PAREN {
           set _ "$1)"
         }
       | pattern '?' {
           set _ "?"
         }
       | CHAR {
           set _ $1
         }
       | NEWLINE {
           set _ "\n"
         }
       | TAB {
           set _ "\t"
         }
       | DECIMAL {
           set _ $1
         }
       | DOLLAR_SIGN {
           set _ "\$"
         }
       | OPEN_PAREN {
           set _ "("
         }
       | CLOSE_PAREN {
           set _ ")"
         }
       | '?' {
           set _ "?"
         }
         ;

opts: opts CHAR {
        set _ "$1$2"
      }
    | CHAR {
        set _ $1
      }
      ;

value: value CHAR {
         set _ [merge_values $1 [list $2 {}]]
       }
     | value NEWLINE {
         set _ [merge_values $1 [list "\n" {}]]
       }
     | value TAB {
         set _ [merge_values $1 [list "\t" {}]]
       }
     | value DECIMAL {
         set _ [merge_values $1 [list $2 {}]]
       }
     | value '/' {
         set _ [merge_values $1 [list "/" {}]]
       }
     | value variable {
         set _ [merge_values $1 [list $2 {}]]
       }
     | value shell {
         set _ [merge_values $1 [list $2 {}]]
       }
     | value tabstop {
         set _ [concat $1 $2]
       }
     | CHAR {
         set _ [list $1 {}]
       }
     | NEWLINE {
         set _ [list "\n" {}]
       }
     | TAB {
         set _ [list "\t" {}]
       }
     | DECIMAL {
         set _ [list $1 {}]
       }
     | '/' {
         set _ [list "/" {}]
       }
     | variable {
         set _ [list $1 {}]
       }
     | shell {
         set _ [list $1 {}]
       }
     | tabstop {
         set _ $1
       }
       ;

text: text CHAR {
        set _ "$1$2"
      }
    | text NEWLINE {
        set _ "$1\\n"
      }
    | text TAB {
        set _ "$1\\t"
      }
    | text DECIMAL {
        set _ "$1$2"
      }
    | text '/' {
        set _ "$1/"
      }
    | text OPEN_PAREN {
        set _ "$1\("
      }
    | text CLOSE_PAREN {
        set _ "$1)"
      }
    | text '?' {
        set _ "$1?"
      }
    | text ':' {
        set _ "$1:"
      }
    | text OPEN_BRACKET {
        set _ "$1$2"
      }
    | text CLOSE_BRACKET {
        set _ "$1$2"
      }
    | CHAR {
        set _ $1
      }
    | NEWLINE {
        set _ "\\n"
      }
    | TAB {
        set _ "\\t"
      }
    | DECIMAL {
        set _ $1
      }
    | '/' {
        set _ "/"
      }
    | OPEN_PAREN {
        set _ "("
      }
    | CLOSE_PAREN {
        set _ ")"
      }
    | '?' {
        set _ "?"
      }
    | ':' {
        set _ ":"
      }
    | OPEN_BRACKET {
        set _ $1
      }
    | CLOSE_BRACKET {
        set _ $1
      }
      ;

shell: '`' text '`' {
         set _ [expr {![catch "exec $2" rc] ? $rc : ""}]
       }
       ;

format: format CHAR {
          set _ "$1$2"
        }
      | format NEWLINE {
          set _ "$1\n"
        }
      | format TAB {
          set _ "$1\t"
        }
      | format DECIMAL {
          set _ "$1$2"
        }
      | format '?' {
          set _ "$1?"
        }
      | format case_fold {
          set _ "$1$2"
        }
      | format cond_insert {
          set _ "$1$2"
        }
      | format DOLLAR_SIGN DECIMAL {
          set _ "$1\$$3"
        }
      | CHAR {
          set _ $1
        }
      | NEWLINE {
          set _ "\n"
        }
      | TAB {
          set _ "\t"
        }
      | DECIMAL {
          set _ $1
        }
      | '?' {
          set _ "?"
        }
      | case_fold {
          set _ $1
        }
      | cond_insert {
          set _ $1
        }
      | DOLLAR_SIGN DECIMAL {
          set _ "\$$2"
        }
        ;

case_fold: LOWER format {
              set _ "$1$2"
            }
          | UPPER format {
              set _ "$1$2"
            }
          | LOWER_BLOCK format END_BLOCK {
              set _ "$1$2$3"
            }
          | UPPER_BLOCK format END_BLOCK {
              set _ "$1$2$3"
            }
            ;

cond_insert: OPEN_PAREN '?' DECIMAL ':' format CLOSE_PAREN {
               set _ [get_retval $1 $2 $3 $4 $5 $6]
             }
           | OPEN_PAREN '?' DECIMAL ':' format ':' format CLOSE_PAREN {
               set _ [get_retval $1 $2 $3 $4 $5 $6 $7 $8]
             }
             ;

%%

rename snip_error snip_error_orig
proc snip_error {s} {
  set ::snip_errstr "[string repeat " " $::snip_begpos]^"
  set ::snip_errmsg $s
}

