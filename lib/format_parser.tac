%{
source [file join $::tke_dir lib format_lexer.tcl]

set format_txt     ""
set format_value   ""
set format_errmsg  ""
set format_errstr  ""
set format_pos     0
set format_matches [list]

proc get_retval {args} {
  return [join $args {}]
}
%}

%token DECIMAL DOLLAR_SIGN VARNAME CHAR LOWER UPPER LOWER_BLOCK UPPER_BLOCK END_BLOCK NEWLINE TAB
%token OPEN_BRACKET CLOSE_BRACKET OPEN_PAREN CLOSE_PAREN

%%

main: format {
        set ::format_value $1
      }
      ;

format: format CHAR {
          set _ "$1$2"
        }
      | format NEWLINE {
          set _ "$1\\n"
        }
      | format TAB {
          set _ "$1\\t"
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
          set _ [lindex $::format_matches $3]
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
          set _ [lindex $::format_matches $2]
        }
        ;

case_fold: LOWER format {
              set _ "[string tolower [string index $2 0]][string range $2 1 end]"
            }
          | UPPER format {
              set _ [string totitle $2]
            }
          | LOWER_BLOCK format END_BLOCK {
              set _ [string tolower $2]
            }
          | UPPER_BLOCK format END_BLOCK {
              set _ [string toupper $2]
            }
            ;

cond_insert: OPEN_PAREN '?' DECIMAL ':' format CLOSE_PAREN {
               if {[llength [lindex $::format_matches end]] <= $3} {
                 set _ $5
               } else {
                 set _ ""
               }
             }
           | OPEN_PAREN '?' DECIMAL ':' format ':' format CLOSE_PAREN {
               if {[llength [lindex $::format_matches end]] <= $3} {
                 set _ $5
               } else {
                 set _ $7
               }
             }
             ;

%%

rename format_error format_error_orig
proc format_error {s} {
  set ::format_errstr "[string repeat " " $::format_begpos]^"
  set ::format_errmsg $s
}

