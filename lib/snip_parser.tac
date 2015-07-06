%{
source [file join $::tke_dir lib snip_lexer.tcl]

set snip_txt     ""
set snip_value   ""
set snip_errmsg  ""
set snip_errstr  ""
set snip_pos     0
set snip_matches [list]

proc get_retval {args} {
  return [join $args {}]
}
%}

%token DECIMAL DOLLAR_SIGN VARNAME CHAR LOWER UPPER LOWER_BLOCK UPPER_BLOCK END_BLOCK NEWLINE TAB
%token OPEN_BRACKET CLOSE_BRACKET

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
           set _ [concat $1 [list $2 {}]]
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
           set _ [list $1 {}]
         }
       | tabstop {
           set _ $1
         }
       | shell {
           set _ [list $1 {}]
         }
         ;
         
tabstop: DOLLAR_SIGN DECIMAL {
           set _ [list " " [snippets::set_tabstop $::snip_txt $2]]
         }
       | DOLLAR_SIGN OPEN_BRACKET DECIMAL ':' value CLOSE_BRACKET {
           set _ [list $5 [snippets::set_tabstop $::snip_txt $3 $5]]
         }
         ;
         
transform: DOLLAR_SIGN OPEN_BRACKET DECIMAL '/' text '/' format '/' text CLOSE_BRACKET {
             if {[set val [snippets::get_tabstop $3]] ne ""} {
               set regexp_opts [list]
               if {[string first g $9] != -1} {
                 lappend regexp_opts -all
               }
               set _ [regexp -inline {*}$regexp_opts -- $5 $val]
             } else {
               set _ [get_retval $1 $2 $3 $4 $5 $6 $7 $8 $9 $10]
             }
           }
           ;

variable: DOLLAR_SIGN varname {
            set _ $2
          }
        | DOLLAR_SIGN OPEN_BRACKET varname ':' value CLOSE_BRACKET {
            set _ [expr {($3 eq "") ? $5 : $3}]
          }
        | DOLLAR_SIGN OPEN_BRACKET varname '/' text {
            lappend ::snip_matches [regexp -inline -- $5 $3]
            puts "snip_matches: $::snip_matches"
          }
          '/' format '/' text CLOSE_BRACKET {
            set ::snip_matches [lreplace $::snip_matches end end]
            set _ $8
          }
          ;
          
varname: VARNAME {
           set txt $::snip_txt
           switch $1 {
             SELECTED_TEXT  { set _ [$txt get sel.first sel.last] }
             CLIPBOARD      { set _ [expr {![catch "clipboard get" rc] ? $rc : ""}] }
             CURRENT_LINE   { set _ [$txt get "insert linestart" "insert lineend"] }
             CURRENT_WORD   { set _ [$txt get "insert wordstart" "insert wordend"] }
             DIRECTORY      { set _ [file dirname [gui::current_filename]] }
             FILEPATH       { set _ [gui::current_filename] }
             FILENAME       { set _ [file tail [gui::current_filename]] }
             FILENAME_UPPER { set _ [string toupper [file tail [gui::current_filename]]] }
             LINE_INDEX     { set _ [lindex [split [$txt index insert] .] 1] }
             LINE_NUMBER    { set _ [lindex [split [$txt index insert] .] 0] }
             CURRENT_DATE   { set _ [clock format [clock seconds] -format "%m/%d/%Y"] }
           }
         }
         ;
         
value: value CHAR {
         set _ "$1$2"
       }
     | value NEWLINE {
         set _ "$1\\n"
       }
     | value TAB {
         set _ "$1\\t"
       }
     | value DECIMAL {
         set _ "$1$2"
       }
     | value '/' {
         set _ "$1/"
       }
     | value variable {
         set _ "$1$2"
       }
     | value shell {
         set _ "$1$2"
       }
     | value tabstop {
         set _ [concat $1 {} $2]
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
     | variable {
         set _ $1
       }
     | shell {
         set _ $1
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
       
format: format text {
          set _ "$1$2"
        }
      | format case_fold {
          set _ "$1$2"
        }
      | format cond_insert {
          set _ "$1$2"
        }
      | text {
          set _ $1
        }
      | case_fold {
          set _ $1
        }
      | cond_insert {
          set _ $1
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
            
cond_insert: '(' '?' DECIMAL ':' format ')' {
               if {[llength [lindex $::snip_matches end]] <= $3} {
                 set _ $5
               } else {
                 set _ ""
               }
             }
             '(' '?' DECIMAL ':' format ':' format ')' {
               if {[llength [lindex $::snip_matches end]] <= $3} {
                 set _ $5
               } else {
                 set _ $7
               }
             }
             ;
      
%%

rename snip_error snip_error_orig
proc snip_error {s} {
  set ::snip_errstr "[string repeat " " $::snip_begpos]^"
  set ::snip_errmsg $s
}

