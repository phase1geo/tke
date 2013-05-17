%{
source [file join $tke_dir snippet_lexer.tcl]
set snippet_value  ""
set snippet_errmsg ""
set snippet_errstr ""
set snippet_pos    0
%}

%token DECIMAL DOLLAR_SIGN

%%

main: statement {
        set ::snippet_value $1
      }
    ;

plain_text: IDENTIFIER 
          ;

variable: DOLLAR_SIGN IDENTIFIER
        | DOLLAR_SIGN '\{' IDENTIFIER ':' default_value '\}'
        | DOLLAR_SIGN '\{' IDENTIFIER '/' pattern '/' format '/' regexp_opts '\}'
        ;

shell: 

    
statement: IDENTIFIER ':' list_of_values {
             set _ [list $1 $3]
           }
         |
           IDENTIFIER '=' list_of_values {
             set _ [list $1 [list $3]]
           }
         | TCL_STRING {
             if {[catch {combo::user::output_string $1} rc]} {
               combo_error $rc
               COMBO__ABORT
             }
             set _ [list {} {{}}]
           }
         | list_of_values {
             set _ [list {} $1]
           }
         ;

list_of_values: list_of_values ',' value_list {
                  set _ [concat $1 $3]
                }
              | value_list {
                  set _ $1
                }
              ;

parameter_list: parameter_list ',' value_list {
                  lappend 1 $3
                  set _ $1
                }
              | value_list {
                  set _ [list $1]
                }
              | {
                  set _ [list]
                }
              ;

value_list: IDENTIFIER '(' parameter_list ')' {
              if {[catch {plugin::handle_combo_function $1 $3} rc]} {
                combo_error $rc
                COMBO__ABORT
              }
              set _ [lindex $rc 0]
              if {[lindex $rc 1]} {
                set combo::found_regen 1
              }
            }
          | '(' list_of_values ')' {
              set _ $2
            }
          | TCL_EXPR {
              if {[catch {combo::user::exec_expr $1} rc]} {
                combo_error $rc
                COMBO__ABORT
              }
              set _ $rc
            }
          | integer_value '-' integer_value {
              if {$1 > $3} {
                set tmp $1
                set 1   $3
                set 3 $tmp
              }
              set _ [list]
              for {set i $1} {$i <= $3} {incr i} {
                lappend _ $i
              }
            }
          | value '*' integer_value {
              if {$3 <= 0} {
                combo_error "Attempting to multiply by a value <= 0"
                COMBO_ABORT
              }
              set _ [lrepeat $3 $1]
            }
          | value {
              set _ $1
            }
          | IDENTIFIER {
              set _ $1
            }
          ;

integer_value: TCL_EXPR {
                 if {[catch {expr int([combo::user::exec_expr $1])} rc]} {
                   combo_error $rc
                   COMBO__ABORT
                 }
                 set _ $rc
               }
             | value {
                 set _ [expr int($1)]
               }
             | IDENTIFIER '(' parameter_list ')' {
                 if {[catch {expr int([lindex [plugin::handle_combo_function $1 $3] 0])} rc]} {
                   combo_error $rc
                   COMBO__ABORT
                 }
                 set _ [lindex $rc 0]
                 if {[lindex $rc 1]} {
                   set combo::found_regen 1
                 }
               }
             ;

value: DECIMAL {
         set _ $1
       }
     | '-' DECIMAL {
         set _ [expr 0 - $2]
       }
     | HEXIDECIMAL {
         set _ $1
       }
     | FLOAT {
         set _ $1
       }
     | DOLLAR_SIGN IDENTIFIER {
         if {[catch {combo::user::get_value $2} rc]} {
           combo_error $rc
           COMBO__ABORT
         }
         set _ $rc
       }
     ;

%%

rename combo_error combo_error_orig
proc combo_error {s} {
  set ::combo_errstr "[string repeat " " $::combo_begpos]^"
  set ::combo_errmsg $s
}
