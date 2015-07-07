source [file join $::tke_dir lib snip_parser.tab.tcl]

######
# Begin autogenerated fickle (version 2.04) routines.
# Although fickle itself is protected by the GNU Public License (GPL)
# all user-supplied functions are protected by their respective
# author's license.  See http://mini.net/tcl/fickle for other details.
######

# If snip_wrap() returns false (zero), then it is assumed that the
# function has gone ahead and set up snip_in to point to another input
# file, and scanning continues.  If it returns true (non-zero), then
# the scanner terminates, returning 0 to its caller.  Note that in
# either case, the start condition remains unchanged; it does not
# revert to INITIAL.
#   -- from the flex(1) man page
proc snip_wrap {} {
    return 1
}

# ECHO copies snip_text to the scanner's output if no arguments are
# given.  The scanner writes its ECHO output to the snip_out global
# (default, stdout), which may be redefined by the user simply by
# assigning it to some other channel.
#   -- from the flex(1) man page
proc ECHO {{s ""}} {
    if {$s == ""} {
        puts -nonewline $::snip_out $::snip_text
    } else {
        puts -nonewline $::snip_out $s
    }
}

# SNIP__FLUSH_BUFFER flushes the scanner's internal buffer so that the
# next time the scanner attempts to match a token, it will first
# refill the buffer using SNIP__INPUT.
#   -- from the flex(1) man page
proc SNIP__FLUSH_BUFFER {} {
    set ::snip__buffer ""
    set ::snip__index 0
    set ::snip__done 0
}

# snip_restart(new_file) may be called to point snip_in at the new input
# file.  The switch-over to the new file is immediate (any previously
# buffered-up input is lost).  Note that calling snip_restart with snip_in
# as an argument thus throws away the current input buffer and
# continues scanning the same input file.
#   -- from the flex(1) man page
proc snip_restart {new_file} {
    set ::snip_in $new_file
    SNIP__FLUSH_BUFFER
}

# The nature of how it gets its input can be controlled by defining
# the SNIP__INPUT macro.  SNIP__INPUT's calling sequence is
# "SNIP__INPUT(buf,result,max_size)".  Its action is to place up to
# max_size characters in the character array buf and return in the
# integer variable result either the number of characters read or the
# constant SNIP__NULL (0 on Unix systems) to indicate EOF.  The default
# SNIP__INPUT reads from the global file-pointer "snip_in".
#   -- from the flex(1) man page
proc SNIP__INPUT {buf result max_size} {
    upvar $result ret_val
    upvar $buf new_data
    if {$::snip_in != ""} {
        set new_data [read $::snip_in $max_size]
        set ret_val [string length $new_data]
    } else {
        set new_data ""
        set ret_val 0
    }
}

# yy_scan_string sets up input buffers for scanning in-memory
# strings instead of files.  Note that switching input sources does
# not change the start condition.
#   -- from the flex(1) man page
proc snip__scan_string {str} {
    append ::snip__buffer $str
    set ::snip_in ""
}

# unput(c) puts the character c back onto the input stream.  It will
# be the next character scanned.
#   -- from the flex(1) man page
proc unput {c} {
    set s [string range $::snip__buffer 0 [expr {$::snip__index - 1}]]
    append s $c
    set ::snip__buffer [append s [string range $::snip__buffer $::snip__index end]]
}

# Returns all but the first n characters of the current token back to
# the input stream, where they will be rescanned when the scanner
# looks for the next match.  snip_text and snip_leng are adjusted
# appropriately.
#   -- from the flex(1) man page
proc snip_less {n} {
    set s [string range $::snip__buffer 0 [expr {$::snip__index - 1}]]
    append s [string range $::snip_text $n end]
    set ::snip__buffer [append s [string range $::snip__buffer $::snip__index end]]
    set ::snip_text [string range $::snip_text 0 [expr {$n - 1}]]
    set ::snip_leng [string length $::snip_text]
}

# input() reads the next character from the input stream.
#   -- from the flex(1) man page
proc input {} {
    if {[string length $::snip__buffer] - $::snip__index < 1024} {
       set new_buffer_size 0
       if {$::snip__done == 0} {
           SNIP__INPUT new_buffer new_buffer_size 1024
           append ::snip__buffer $new_buffer
           if {$new_buffer_size == 0} {
               set ::snip__done 1
           }
       }
       if $::snip__done {
           if {[snip_wrap] == 0} {
               return [input]
           } elseif {[string length $::snip__buffer] - $::snip__index == 0} {
               return {}
           }
        }
    }
    set c [string index $::snip__buffer $::snip__index]
    incr ::snip__index
    return $c
}

# Pushes the current start condition onto the top of the start
# condition stack and switches to new_state as though you had used
# BEGIN new_state.
#   -- from the flex(1) man page
proc snip__push_state {new_state} {
    lappend ::snip__state_stack $new_state
}

# Pops off the top of the state stack; if the stack is now empty, then
# pushes the state "INITIAL".
#   -- from the flex(1) man page
proc snip__pop_state {} {
    set ::snip__state_stack [lrange $::snip__state_stack 0 end-1]
    if {$::snip__state_stack == ""} {
        snip__push_state INITIAL
    }
}

# Returns the top of the stack without altering the stack's contents.
#   -- from the flex(1) man page
proc snip__top_state {} {
    return [lindex $::snip__state_stack end]
}

# BEGIN followed by the name of a start condition places the scanner
# in the corresponding start condition. . . .Until the next BEGIN
# action is executed, rules with the given start condition will be
# active and rules with other start conditions will be inactive.  If
# the start condition is inclusive, then rules with no start
# conditions at all will also be active.  If it is exclusive, then
# only rules qualified with the start condition will be active.
#   -- from the flex(1) man page
proc BEGIN {new_state {prefix snip_}} {
    eval set ::${prefix}_state_stack [lrange \$::${prefix}_state_stack 0 end-1]
    eval lappend ::${prefix}_state_stack $new_state
}

# initialize values used by the lexer
set ::snip_text {}
set ::snip_leng 0
set ::snip__buffer {}
set ::snip__index 0
set ::snip__done 0
set ::snip__state_stack {}
BEGIN INITIAL
array set ::snip__state_table {INITIAL 1}
if {![info exists ::snip_in]} {
    set ::snip_in "stdin"
}
if {![info exists ::snip_out]} {
    set ::snip_out "stdout"
}

######
# autogenerated snip_lex function created by fickle
######

# Whenever yylex() is called, it scans tokens from the global input
# file yyin (which defaults to stdin).  It continues until it either
# reaches an end-of-file (at which point it returns the value 0) or
# one of its actions executes a return statement.
#   -- from the flex(1) man page
proc snip_lex {} {
    upvar #0 ::snip_text snip_text
    upvar #0 ::snip_leng snip_leng
    while {1} {
        set snip__current_state [snip__top_state]
        if {[string length $::snip__buffer] - $::snip__index < 1024} {
            if {$::snip__done == 0} {
                set snip__new_buffer ""
                SNIP__INPUT snip__new_buffer snip__buffer_size 1024
                append ::snip__buffer $snip__new_buffer
                if {$snip__buffer_size == 0 && \
                        [string length $::snip__buffer] - $::snip__index == 0} {
                    set ::snip__done 1
                }
            }
            if $::snip__done {
                if {[snip_wrap] == 0} {
                    set ::snip__done 0
                    continue
                } elseif {[string length $::snip__buffer] - $::snip__index == 0} {
                    break
                }
            }            
        }
        set ::snip_leng 0
        set snip__matched_rule -1
        # rule 0: [ \n\t\b\f]+
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A([ \n\t\b\f]+)} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 0
        }
        # rule 1: \\[luLUEnt\$]
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A(\\[luLUEnt\$])} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 1
        }
        # rule 2: \$
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A(\$)} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 2
        }
        # rule 3: \{
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A(\{)} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 3
        }
        # rule 4: \}
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A(\})} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 4
        }
        # rule 5: \(
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A(\()} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 5
        }
        # rule 6: \)
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A(\))} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 6
        }
        # rule 7: [`:/\?]
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A([`:/\?])} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 7
        }
        # rule 8: [0-9][0-9]*
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A([0-9][0-9]*)} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 8
        }
        # rule 9: (CLIPBOARD|CURRENT_LINE|CURRENT_WORD|DIRECTORY|FILEPATH|FILENAME|LINE_INDEX|LINE_NUMBER|CURRENT_DATE)
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A((CLIPBOARD|CURRENT_LINE|CURRENT_WORD|DIRECTORY|FILEPATH|FILENAME|LINE_INDEX|LINE_NUMBER|CURRENT_DATE))} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 9
        }
        # rule 10: .
        if {$::snip__state_table($snip__current_state) && \
                [regexp -start $::snip__index -indices -line  -- {\A(.)} $::snip__buffer snip__match] > 0 && \
                [lindex $snip__match 1] - $::snip__index + 1 > $::snip_leng} {
            set ::snip_text [string range $::snip__buffer $::snip__index [lindex $snip__match 1]]
            set ::snip_leng [string length $::snip_text]
            set snip__matched_rule 10
        }
        if {$snip__matched_rule == -1} {
            set ::snip_text [string index $::snip__buffer $::snip__index]
            set ::snip_leng 1
        }
        incr ::snip__index $::snip_leng
        # workaround for Tcl's circumflex behavior
        if {[string index $::snip_text end] == "\n"} {
            set ::snip__buffer [string range $::snip__buffer $::snip__index end]
            set ::snip__index 0
        }
        switch -- $snip__matched_rule {
            0 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos [string length $snip_text]
  return $::CHAR
            }
            1 {
puts -nonewline "Found escape! ("
  puts -nonewline $snip_text
  puts -nonewline ","
  puts -nonewline [string index $snip_text 1]
  puts ")"
  set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos [string length $snip_text]
  switch [string index $snip_text 1] {
    l       { return $::LOWER }
    u       { puts {HERE A}; return $::UPPER }
    L       { return $::LOWER_BLOCK }
    U       { return $::UPPER_BLOCK }
    E       { return $::END_BLOCK }
    n       { return $::NEWLINE }
    t       { return $::TAB }
    default {
      set ::snip_lval $snip_text
      return $::CHAR
    }
  }
            }
            2 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos
  return $::DOLLAR_SIGN
            }
            3 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos
  return $::OPEN_BRACKET
            }
            4 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos
  return $::CLOSE_BRACKET
            }
            5 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos
  return $::OPEN_PAREN
            }
            6 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos
  return $::CLOSE_PAREN
            }
            7 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos
  return $snip_text
            }
            8 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos [string length $snip_text]
  return $::DECIMAL
            }
            9 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos [string length $snip_text]
  return $::VARNAME
            }
            10 {
set ::snip_lval $snip_text
  set ::snip_begpos $::snip_endpos
  incr ::snip_endpos [string length $snip_text]
  return $::CHAR
            }
            default
                { ECHO }
        }
    }
    return 0
}
######
# end autogenerated fickle functions
######


