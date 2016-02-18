%{
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
# Name:    snip_parser.tac
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    8/10/2015
# Brief:   Parser for snippet syntax.
######################################################################

source [file join $::tke_dir lib emmet_lexer.tcl]

set emmet_value  ""
set emmet_errmsg ""
set emmet_errstr ""
set emmet_pos    0

proc apply_multiplier {items multipler} {

  # TBD

}

%}

%token IDENTIFIER NUMBER CHILD SIBLING CLIMB OPEN_GROUP CLOSE_GROUP MULTIPLY NUMBERING
%token OPEN_ATTR CLOSE_ATTR ASSIGN ID CLASS VALUE TEXT

%%

main: expression {
        set ::emmet_value $1
      }

expression: item {
              set _ $1
            }
          | ID IDENTIFIER {
              set _ [list id $2]
            }
          | CLASS IDENTIFIER {
              set _ [list class $2]
          }
          | expression item {
              set _ [list $1 $2]
            }
          | expression ID IDENTIFIER {
              set _ [list $1 [list id $3]]
            }
          | expression CLASS IDENTIFIER {
              set _ [list $1 [list class $]]
            }
          | expression CHILD item {
              set _ [list $1 [list child $1]]
            }
          | expression SIBLING item {
              set _ [list $1 [list sibling $1]]
            }
          | expression CLIMB item {
              set _ [list $1 [list climb $1]]
            }
          | expression MULTIPLY NUMBER {
              set _ [apply_multiplier $1 $3]
            }
          | OPEN_GROUP expression CHILD item CLOSE_GROUP {
              set _ [list [list $1 [list child $4]]]
            }
          | OPEN_GROUP expression SIBLING item CLOSE_GROUP {
              set _ [list [list $1 [list sibling $4]]]
            }
          | OPEN_GROUP expression CLIMB item CLOSE_GROUP {
              set _ [list [list $1 [list climb $4]]]
            }
          | OPEN_GROUP expression MULTIPLY NUMBER CLOSE_GROUP {
              set _ [list [apply_multipler $2 $4]]
            }
          ;

item: IDENTIFIER {
        set _ [list ident $1]
      }
    | IDENTIFIER numbering {
        set _ [list ident $1 $2]
      }
    | TEXT {
        set _ [list text $1]
      }
    | OPEN_ATTR attrs CLOSE_ATTR {
        set _ [list attrs $2]
      }
    ;

attr: IDENTIFIER ASSIGN VALUE {
        set _ [list $1 "=\"$3\""]
      }
    | IDENTIFIER ASSIGN NUMBER {
        set _ [list $1 "=\"$3\""]
      }
    | IDENTIFIER {
        set _ [list $1]
      }
    ;

attrs: attr {
         set _ [list $1]
       }
     | attrs attr {
         set _ [list $1 $2]
       }
     ;

numbering: NUMBERING {
             set _ [list $1 1 1]
           }
         | NUMBERING '@' NUMBER {
             set _ [list $1 $3 1]
           }
         | NUMBERING '@' '-' {
             set _ [list $1 1 -1]
           }
         | NUMBERING '@' NUMBER '-' {
             set _ [list $1 $3 -1]
           }
         ;

%%

rename emmet_error emmet_error_orig

proc emmet_error {s} {

  set ::emmet_errstr "[string repeat { } $::emmet_begpos]^"
  set ::emmet_errmsg $s

}
