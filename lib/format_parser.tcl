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

######
# Begin autogenerated taccle (version 1.1) routines.
# Although taccle itself is protected by the GNU Public License (GPL)
# all user-supplied functions are protected by their respective
# author's license.  See http://mini.net/tcl/taccle for other details.
######

proc FORMAT_ABORT {} {
    return -code return 1
}

proc FORMAT_ACCEPT {} {
    return -code return 0
}

proc format_clearin {} {
    upvar format_token t
    set t ""
}

proc format_error {s} {
    puts stderr $s
}

proc format_setupvalues {stack pointer numsyms} {
    upvar 1 1 y
    set y {}
    for {set i 1} {$i <= $numsyms} {incr i} {
        upvar 1 $i y
        set y [lindex $stack $pointer]
        incr pointer
    }
}

proc format_unsetupvalues {numsyms} {
    for {set i 1} {$i <= $numsyms} {incr i} {
        upvar 1 $i y
        unset y
    }
}

array set ::format_table {
  8:? shift
  6:260,target 4
  17:266,target 26
  33:261,target 9
  36:?,target 1
  26:257 reduce
  15:257,target 16
  26:258 reduce
  26:260 reduce
  0:275,target 15
  26:261 reduce
  26:262 reduce
  1:258,target 14
  26:263 reduce
  26:264 reduce
  27:260,target 4
  26:265 reduce
  26:266 reduce
  26:267 reduce
  39:262,target 23
  33:0,target 9
  26:270 reduce
  26:271 reduce
  36:270,target 11
  22:258,target 6
  7:260,target 4
  18:266,target 26
  34:261,target 5
  4:267,target 10
  16:257,target 17
  2:258,target 13
  28:260,target 7
  33:?,target 9
  25:267,target 2
  37:270,target 22
  23:258,target 5
  8:260,target 4
  19:266,target 26
  20:266,target 26
  35:261,target 5
  29:0,target 8
  30:0,target 20
  5:267,target 10
  31::,target 21
  17:257,target 23
  14:265,target 15
  29:260,target 8
  30:260,target 20
  0:266,target 9
  9:0 reduce
  35:: shift
  26:267,target 3
  38:270,target 11
  35:? shift
  9:: reduce
  9:260,target 11
  36:261,target 5
  30:?,target 20
  29:?,target 8
  37:257 reduce
  6:267,target 10
  9:? reduce
  17:274,target 28
  37:258 reduce
  37:260 reduce
  18:257,target 23
  37:261 reduce
  37:262 reduce
  37:263 reduce
  37:264 reduce
  4:258,target 10
  15:265,target 16
  37:265 reduce
  31:260,target 21
  37:266 reduce
  37:267 reduce
  1:266,target 14
  37:270 reduce
  26:0,target 3
  27:267,target 4
  37:271 reduce
  27::,target 4
  39:270,target 23
  10:264,target 12
  25:258,target 2
  22:266,target 6
  37:261,target 22
  7:267,target 10
  18:274,target 28
  19:257,target 23
  20:257,target 23
  22:0 reduce
  5:258,target 3
  16:265,target 17
  26:?,target 3
  2:266,target 13
  28:267,target 7
  22:: reduce
  0:257,target 2
  13:257 shift
  26:258,target 3
  13:258 shift
  22:? reduce
  13:260 shift
  13:261 shift
  13:262 shift
  23:266,target 5
  38:261,target 5
  13:263 shift
  2:257 reduce
  13:264 shift
  23:0,target 5
  2:258 reduce
  2:260 reduce
  8:267,target 10
  13:266 shift
  19:274,target 28
  20:274,target 28
  2:261 reduce
  13:267 shift
  2:262 reduce
  21:257,target 32
  2:263 reduce
  13:270 shift
  5:275,target 15
  2:264 reduce
  2:265 reduce
  6:258,target 3
  2:266 reduce
  17:265,target 18
  33:260,target 9
  2:267 reduce
  13:274 goto
  13:275 goto
  2:270 reduce
  2:271 reduce
  30:267,target 20
  29:267,target 8
  0:274,target 14
  1:257,target 14
  27:258,target 4
  23:?,target 5
  39:261,target 23
  36:? shift
  9:267,target 11
  22:257,target 6
  9::,target 11
  6:275,target 15
  18:257 shift
  18:258 shift
  7:258,target 3
  18:260 shift
  18:265,target 19
  34:260,target 4
  18:261 shift
  18:262 shift
  18:263 shift
  7:257 shift
  4:266,target 10
  18:264 shift
  31:267,target 21
  7:258 shift
  18:265 reduce
  7:260 shift
  18:266 shift
  7:261 shift
  18:267 shift
  7:262 shift
  7:263 shift
  18:270 shift
  2:257,target 13
  7:264 shift
  13:264,target 8
  18:271 reduce
  28:258,target 7
  7:266 shift
  7:267 shift
  18:274 goto
  18:275 goto
  7:270 shift
  25:266,target 2
  8:?,target 1
  7:273 goto
  7:274 goto
  7:275 goto
  23:257,target 5
  7:275,target 15
  8:258,target 3
  19:265,target 30
  20:265,target 31
  35:260,target 25
  19:?,target 22
  20:?,target 22
  23:0 reduce
  5:266,target 9
  3:257,target 16
  14:264,target 15
  24:257 shift
  29:258,target 8
  30:258,target 20
  23:: reduce
  26:266,target 3
  16:0,target 17
  23:? reduce
  17::,target 18
  24:257,target 33
  8:275,target 15
  9:258,target 11
  36:260,target 4
  6:266,target 9
  5:?,target 1
  33:267,target 9
  37:0 reduce
  4:257,target 10
  15:264,target 16
  31:258,target 21
  1:265,target 14
  16:?,target 17
  27:266,target 4
  37:: reduce
  2:0,target 13
  10:263,target 12
  25:257,target 2
  37:? reduce
  29:257 reduce
  30:257 reduce
  29:258 reduce
  30:258 reduce
  29:260 reduce
  30:260 reduce
  22:265,target 6
  29:261 reduce
  30:261 reduce
  37:260,target 22
  29:262 reduce
  30:262 reduce
  29:263 reduce
  30:263 reduce
  30:264 reduce
  13:0,target 1
  29:264 reduce
  30:265 reduce
  7:266,target 9
  29:265 reduce
  34:267,target 10
  30:266 reduce
  10:0 reduce
  29:266 reduce
  30:267 reduce
  14::,target 15
  29:267 reduce
  30:270 reduce
  29:270 reduce
  30:271 reduce
  29:271 reduce
  5:257,target 2
  16:264,target 17
  2:265,target 13
  10:: reduce
  28:266,target 7
  2:?,target 13
  10:? reduce
  26:257,target 3
  23:265,target 5
  38:260,target 25
  13:?,target 22
  8:266,target 9
  35:267,target 27
  5:274,target 14
  35:257 shift
  35:258 shift
  6:257,target 2
  17:264,target 8
  35:260 shift
  33:258,target 9
  35:261 shift
  35:262 shift
  35:263 shift
  35:264 shift
  30:266,target 20
  10:0,target 12
  29:266,target 8
  35:266 shift
  35:267 shift
  0:273,target 13
  35:270 shift
  35:271 shift
  27:257,target 4
  35:274 goto
  35:275 goto
  39:260,target 23
  9:266,target 11
  36:267,target 10
  6:274,target 14
  7:257,target 2
  18:264,target 8
  34:258,target 3
  10:?,target 12
  4:265,target 10
  31:266,target 21
  13:263,target 7
  28:257,target 7
  37:0,target 22
  10:271,target 12
  25:265,target 2
  38:? shift
  37:267,target 22
  0:257 shift
  0:258 shift
  7:274,target 14
  34:275,target 15
  0:260 shift
  0:261 shift
  8:257,target 2
  19:264,target 8
  20:264,target 8
  35:258,target 24
  0:262 shift
  0:263 shift
  0:264 shift
  0:266 shift
  0:267 shift
  0:270 shift
  0:272 goto
  14:263,target 15
  37:?,target 22
  0:273 goto
  29:257,target 8
  30:257,target 20
  0:274 goto
  0:275 goto
  0:264,target 8
  26:265,target 3
  11:? shift
  38:267,target 27
  8:274,target 14
  35:275,target 29
  9:257,target 11
  36:258,target 3
  35::,target 36
  16:257 reduce
  16:258 reduce
  33:266,target 9
  16:260 reduce
  25:0 reduce
  16:261 reduce
  16:262 reduce
  16:263 reduce
  5:257 shift
  16:264 reduce
  5:258 shift
  15:263,target 16
  16:265 reduce
  31:257,target 21
  5:260 shift
  16:266 reduce
  5:261 shift
  16:267 reduce
  5:262 shift
  5:263 shift
  1:264,target 14
  16:270 reduce
  5:264 shift
  16:271 reduce
  25:: reduce
  27:265,target 4
  5:266 shift
  5:267 shift
  39:267,target 23
  5:270 shift
  10:262,target 12
  25:? reduce
  34:?,target 1
  5:273 goto
  36:275,target 15
  5:274 goto
  5:275 goto
  22:264,target 6
  37:258,target 22
  0:? shift
  34:266,target 9
  39:0 reduce
  16:263,target 17
  31:0,target 21
  2:264,target 13
  32::,target 34
  22:257 reduce
  28:265,target 7
  22:258 reduce
  22:260 reduce
  22:261 reduce
  39:: reduce
  22:262 reduce
  22:263 reduce
  22:264 reduce
  22:265 reduce
  22:266 reduce
  39:? reduce
  22:267 reduce
  23:264,target 5
  38:258,target 24
  22:270 reduce
  22:271 reduce
  35:266,target 26
  12:0 accept
  5:273,target 17
  31:?,target 21
  17:263,target 7
  33:257,target 9
  14:271,target 15
  30:265,target 20
  29:265,target 8
  0:272,target 12
  38:275,target 29
  27:0,target 4
  39:258,target 23
  27:257 reduce
  28::,target 7
  27:258 reduce
  9:265,target 11
  27:260 reduce
  36:266,target 9
  27:261 reduce
  27:262 reduce
  27:263 reduce
  6:273,target 18
  27:264 reduce
  27:265 reduce
  18:263,target 7
  27:266 reduce
  34:257,target 2
  26:0 reduce
  27:267 reduce
  27:270 reduce
  4:264,target 10
  15:271,target 16
  27:271 reduce
  31:265,target 21
  1:0 reduce
  13:262,target 6
  26:: reduce
  27:?,target 4
  10:270,target 12
  25:264,target 2
  26:? reduce
  37:266,target 22
  1:: reduce
  7:273,target 19
  34:274,target 14
  1:? reduce
  19:263,target 7
  20:263,target 7
  35:257,target 23
  33:257 reduce
  5:264,target 8
  16:271,target 17
  25::,target 2
  33:258 reduce
  33:260 reduce
  33:261 reduce
  33:262 reduce
  33:263 reduce
  33:264 reduce
  14:262,target 15
  33:265 reduce
  33:266 reduce
  33:267 reduce
  0:263,target 7
  33:270 reduce
  26:264,target 3
  33:271 reduce
  38:266,target 26
  8:273,target 20
  35:274,target 28
  36:257,target 2
  9:0,target 11
  13:0 reduce
  6:264,target 8
  17:271,target 18
  33:265,target 9
  15:262,target 16
  1:263,target 14
  27:264,target 4
  38:257 shift
  22::,target 6
  38:258 shift
  38:260 shift
  13:? shift
  38:261 shift
  39:266,target 23
  38:262 shift
  10:261,target 12
  38:263 shift
  38:264 shift
  38:266 shift
  36:274,target 14
  38:267 shift
  22:263,target 6
  37:257,target 22
  9:?,target 11
  38:270 shift
  38:271 shift
  7:264,target 8
  18:271,target 19
  38:274 goto
  38:275 goto
  27:0 reduce
  16:262,target 17
  2:263,target 13
  13:270,target 11
  28:264,target 7
  2:0 reduce
  27:: reduce
  27:? reduce
  17:0,target 18
  23:263,target 5
  38:257,target 23
  2:: reduce
  18::,target 19
  8:264,target 8
  2:? reduce
  14:257 reduce
  14:258 reduce
  14:260 reduce
  17:262,target 6
  14:261 reduce
  14:262 reduce
  6:?,target 1
  14:263 reduce
  3:257 shift
  14:264 reduce
  14:270,target 15
  30:264,target 20
  14:265 reduce
  29:264,target 8
  14:266 reduce
  14:267 reduce
  14:270 reduce
  14:271 reduce
  17:?,target 22
  38:274,target 28
  39:257,target 23
  9:264,target 11
  4::,target 10
  14:0 reduce
  18:262,target 6
  14:0,target 15
  4:263,target 10
  15:270,target 16
  31:264,target 21
  15::,target 16
  1:271,target 14
  14:: reduce
  13:261,target 5
  19:257 shift
  20:257 shift
  19:258 shift
  20:258 shift
  19:260 shift
  20:260 shift
  19:261 shift
  20:261 shift
  14:? reduce
  19:262 shift
  20:262 shift
  19:263 shift
  20:263 shift
  25:263,target 2
  8:257 shift
  19:264 shift
  20:264 shift
  8:258 shift
  19:265 shift
  20:265 shift
  8:260 shift
  19:266 shift
  20:266 shift
  8:261 shift
  19:267 shift
  20:267 shift
  22:271,target 6
  37:265,target 22
  8:262 shift
  8:263 shift
  19:270 shift
  20:270 shift
  8:264 shift
  34:273,target 35
  8:266 shift
  8:267 shift
  14:?,target 15
  19:274 goto
  19:262,target 6
  20:274 goto
  20:262,target 6
  19:275 goto
  20:275 goto
  8:270 shift
  28:0 reduce
  5:263,target 7
  16:270,target 17
  8:273 goto
  8:274 goto
  1::,target 14
  8:275 goto
  2:271,target 13
  14:261,target 15
  28:: reduce
  0:262,target 6
  26:263,target 3
  28:? reduce
  23:271,target 5
  25:257 reduce
  25:258 reduce
  25:260 reduce
  25:261 reduce
  25:262 reduce
  0:?,target 1
  25:263 reduce
  25:264 reduce
  6:263,target 7
  17:270,target 11
  25:265 reduce
  33:264,target 9
  25:266 reduce
  25:267 reduce
  25:270 reduce
  25:271 reduce
  15:261,target 16
  11:?,target 21
  1:262,target 14
  27:263,target 4
  39:265,target 23
  10:260,target 12
  36:273,target 38
  39::,target 23
  22:262,target 6
  7:263,target 7
  18:270,target 11
  34:264,target 8
  15:0 reduce
  4:271,target 10
  31:257 reduce
  31:258 reduce
  16:261,target 17
  31:260 reduce
  31:261 reduce
  31:262 reduce
  31:263 reduce
  2:262,target 13
  31:264 reduce
  15:: reduce
  28:263,target 7
  31:265 reduce
  31:266 reduce
  31:267 reduce
  25:271,target 2
  38:?,target 22
  31:270 reduce
  15:? reduce
  31:271 reduce
  23:262,target 5
  8:263,target 7
  19:270,target 11
  20:270,target 11
  35:264,target 8
  29:0 reduce
  30:0 reduce
  17:261,target 5
  30:263,target 20
  29:263,target 8
  4:0 reduce
  0:270,target 11
  30:: reduce
  26:271,target 3
  29:: reduce
  36:257 shift
  36:258 shift
  36:260 shift
  36:261 shift
  30:? reduce
  29:? reduce
  36:262 shift
  36:263 shift
  36:264 shift
  4:: reduce
  36:266 shift
  9:263,target 11
  36:264,target 8
  36:267 shift
  36:270 shift
  35:?,target 22
  4:? reduce
  36:273 goto
  18:261,target 5
  36:274 goto
  36:275 goto
  4:262,target 10
  31:263,target 21
  1:270,target 14
  27:271,target 4
  13:260,target 25
  33::,target 9
  10:267,target 12
  25:262,target 2
  22:270,target 6
  37:264,target 22
  19:261,target 5
  20:261,target 5
  16:0 reduce
  5:262,target 6
  2:270,target 13
  1:257 reduce
  28:271,target 7
  1:258 reduce
  14:260,target 15
  1:260 reduce
  16:: reduce
  1:261 reduce
  1:262 reduce
  0:261,target 5
  1:263 reduce
  1:264 reduce
  26:262,target 3
  1:265 reduce
  16:? reduce
  1:266 reduce
  1:267 reduce
  23:270,target 5
  38:264,target 8
  1:270 reduce
  1:271 reduce
  28:0,target 7
  30::,target 20
  29::,target 8
  6:262,target 6
  33:263,target 9
  31:0 reduce
  30:271,target 20
  29:271,target 8
  15:260,target 16
  1:261,target 14
  31:: reduce
  17:257 shift
  27:262,target 4
  17:258 shift
  17:260 shift
  17:261 shift
  17:262 shift
  39:264,target 23
  31:? reduce
  10:258,target 12
  17:263 shift
  6:257 shift
  17:264 shift
  28:?,target 7
  6:258 shift
  17:265 reduce
  6:260 shift
  9:271,target 11
  17:266 shift
  6:261 shift
  17:267 shift
  6:262 shift
  22:261,target 6
  6:263 shift
  17:270 shift
  6:264 shift
  17:271 reduce
  6:266 shift
  5:? shift
  7:262,target 6
  34:263,target 7
  6:267 shift
  17:274 goto
  17:275 goto
  6:270 shift
  4:270,target 10
  31:271,target 21
  6:273 goto
  16:260,target 17
  25:0,target 2
  6:274 goto
  6:275 goto
  26::,target 3
  2:261,target 13
  13:267,target 27
  28:262,target 7
  25:270,target 2
  23:261,target 5
  23:257 reduce
  23:258 reduce
  8:262,target 6
  23:260 reduce
  35:263,target 7
  23:261 reduce
  23:262 reduce
  17:0 reduce
  23:263 reduce
  5:270,target 11
  23:264 reduce
  25:?,target 2
  23:265 reduce
  17:260,target 25
  23:266 reduce
  23:267 reduce
  23:270 reduce
  14:267,target 15
  23:271 reduce
  29:262,target 8
  30:262,target 20
  17:: reduce
  26:270,target 3
  17:? shift
  22:0,target 6
  23::,target 5
  9:262,target 11
  36:263,target 7
  6:270,target 11
  33:271,target 9
  18:260,target 25
  4:261,target 10
  15:267,target 16
  28:257 reduce
  31:262,target 21
  28:258 reduce
  28:260 reduce
  28:261 reduce
  28:262 reduce
  27:270,target 4
  28:263 reduce
  13:258,target 24
  22:?,target 6
  28:264 reduce
  32:: shift
  28:265 reduce
  28:266 reduce
  28:267 reduce
  10:266,target 12
  25:261,target 2
  28:270 reduce
  28:271 reduce
  37:263,target 22
  7:270,target 11
  18:0,target 19
  6:? shift
  19:260,target 25
  20:260,target 25
  5:261,target 5
  16:267,target 17
  13:275,target 29
  28:270,target 7
  14:258,target 15
  7:?,target 1
  0:260,target 4
  26:261,target 3
  34:257 shift
  34:258 shift
  34:260 shift
  34:261 shift
  38:263,target 7
  34:262 shift
  34:263 shift
  34:264 shift
  18:?,target 22
  8:270,target 11
  35:271,target 37
  34:266 shift
  34:267 shift
  4:0,target 10
  34:270 shift
  18:0 reduce
  6:261,target 5
  17:267,target 27
  34:273 goto
  33:262,target 9
  34:274 goto
  34:275 goto
  30:270,target 20
  29:270,target 8
  15:258,target 16
  15:0,target 16
  18:: reduce
  1:260,target 14
  16::,target 17
  27:261,target 4
  18:? shift
  39:263,target 23
  10:257,target 12
  9:270,target 11
  4:?,target 10
  22:260,target 6
  39:257 reduce
  39:258 reduce
  7:261,target 5
  18:267,target 27
  39:260 reduce
  34:262,target 6
  39:261 reduce
  39:262 reduce
  33:0 reduce
  39:263 reduce
  10:257 reduce
  39:264 reduce
  31:270,target 21
  10:258 reduce
  15:?,target 16
  39:265 reduce
  10:260 reduce
  16:258,target 17
  39:266 reduce
  10:261 reduce
  39:267 reduce
  10:262 reduce
  1:0,target 14
  10:263 reduce
  39:270 reduce
  2:260,target 13
  10:264 reduce
  13:266,target 26
  39:271 reduce
  10:265 reduce
  28:261,target 7
  2::,target 13
  10:266 reduce
  33:: reduce
  10:267 reduce
  10:270 reduce
  10:271 reduce
  33:? reduce
  12:0,target 0
  37:271,target 22
  23:260,target 5
  8:261,target 5
  19:267,target 27
  20:267,target 27
  35:262,target 6
  7:? shift
  17:258,target 24
  1:?,target 14
  14:266,target 15
  29:261,target 8
  30:261,target 20
  0:267,target 10
  15:257 reduce
  15:258 reduce
  15:260 reduce
  15:261 reduce
  38:271,target 39
  15:262 reduce
  15:263 reduce
  4:257 reduce
  15:264 reduce
  4:258 reduce
  15:265 reduce
  4:260 reduce
  15:266 reduce
  4:261 reduce
  9:261,target 11
  15:267 reduce
  36:262,target 6
  4:262 reduce
  39:0,target 23
  4:263 reduce
  15:270 reduce
  4:264 reduce
  15:271 reduce
  4:265 reduce
  17:275,target 29
  33:270,target 9
  4:266 reduce
  4:267 reduce
  18:258,target 24
  4:270 reduce
  4:271 reduce
  10::,target 12
  4:260,target 10
  15:266,target 16
  31:261,target 21
  1:267,target 14
  13:257,target 23
  39:271,target 23
  10:265,target 12
  19:? shift
  20:? shift
  25:260,target 2
  39:?,target 23
  22:267,target 6
  37:262,target 22
  21:257 shift
  18:275,target 29
  34:270,target 11
  19:258,target 24
  20:258,target 24
  9:257 reduce
  5:260,target 4
  9:258 reduce
  16:266,target 17
  9:260 reduce
  9:261 reduce
  9:262 reduce
  2:267,target 13
  9:263 reduce
  13:274,target 28
  9:264 reduce
  9:265 reduce
  14:257,target 15
  37::,target 22
  9:266 reduce
  9:267 reduce
  0:258,target 3
  9:270 reduce
  9:271 reduce
  26:260,target 3
  34:? shift
  23:267,target 5
  38:262,target 6
  19:275,target 29
  20:275,target 29
  35:270,target 11
}

array set ::format_rules {
  9,l 273
  11,l 273
  15,l 273
  20,l 274
  19,l 274
  2,l 273
  6,l 273
  12,l 273
  16,l 273
  21,l 274
  3,l 273
  7,l 273
  13,l 273
  0,l 276
  17,l 273
  22,l 275
  4,l 273
  8,l 273
  10,l 273
  14,l 273
  18,l 274
  1,l 272
  23,l 275
  5,l 273
}

array set ::format_rules {
  23,dc 8
  5,dc 2
  0,dc 1
  17,dc 2
  12,dc 1
  8,dc 2
  21,dc 3
  3,dc 2
  15,dc 1
  10,dc 1
  6,dc 2
  18,dc 2
  1,dc 1
  13,dc 1
  9,dc 3
  22,dc 6
  4,dc 2
  16,dc 1
  11,dc 1
  7,dc 2
  20,dc 3
  19,dc 2
  2,dc 2
  14,dc 1
}

array set ::format_rules {
  13,line 62
  7,line 44
  10,line 53
  22,line 97
  4,line 35
  18,line 79
  1,line 24
  15,line 68
  9,line 50
  12,line 59
  6,line 41
  21,line 88
  3,line 32
  17,line 74
  14,line 65
  8,line 47
  11,line 56
  23,line 104
  5,line 38
  20,line 85
  19,line 82
  2,line 29
  16,line 71
}

proc format_parse {} {
    set format_state_stack {0}
    set format_value_stack {{}}
    set format_token ""
    set format_accepted 0
    while {$format_accepted == 0} {
        set format_state [lindex $format_state_stack end]
        if {$format_token == ""} {
            set ::format_lval ""
            set format_token [format_lex]
            set format_buflval $::format_lval
        }
        if {![info exists ::format_table($format_state:$format_token)]} {
            # pop off states until error token accepted
            while {[llength $format_state_stack] > 0 && \
                       ![info exists ::format_table($format_state:error)]} {
                set format_state_stack [lrange $format_state_stack 0 end-1]
                set format_value_stack [lrange $format_value_stack 0 \
                                       [expr {[llength $format_state_stack] - 1}]]
                set format_state [lindex $format_state_stack end]
            }
            if {[llength $format_state_stack] == 0} {
                format_error "parse error"
                return 1
            }
            lappend format_state_stack [set format_state $::format_table($format_state:error,target)]
            lappend format_value_stack {}
            # consume tokens until it finds an acceptable one
            while {![info exists ::format_table($format_state:$format_token)]} {
                if {$format_token == 0} {
                    format_error "end of file while recovering from error"
                    return 1
                }
                set ::format_lval {}
                set format_token [format_lex]
                set format_buflval $::format_lval
            }
            continue
        }
        switch -- $::format_table($format_state:$format_token) {
            shift {
                lappend format_state_stack $::format_table($format_state:$format_token,target)
                lappend format_value_stack $format_buflval
                set format_token ""
            }
            reduce {
                set format_rule $::format_table($format_state:$format_token,target)
                set format_l $::format_rules($format_rule,l)
                if {[info exists ::format_rules($format_rule,e)]} {
                    set format_dc $::format_rules($format_rule,e)
                } else {
                    set format_dc $::format_rules($format_rule,dc)
                }
                set format_stackpointer [expr {[llength $format_state_stack]-$format_dc}]
                format_setupvalues $format_value_stack $format_stackpointer $format_dc
                set _ $1
                set ::format_lval [lindex $format_value_stack end]
                switch -- $format_rule {
                    1 { 
        set ::format_value $1
       }
                    2 { 
          set _ "$1$2"
         }
                    3 { 
          set _ "$1\\n"
         }
                    4 { 
          set _ "$1\\t"
         }
                    5 { 
          set _ "$1$2"
         }
                    6 { 
          set _ "$1?"
         }
                    7 { 
          set _ "$1$2"
         }
                    8 { 
          set _ "$1$2"
         }
                    9 { 
          set _ [lindex $::format_matches $3]
         }
                    10 { 
          set _ $1
         }
                    11 { 
          set _ "\\n"
         }
                    12 { 
          set _ "\\t"
         }
                    13 { 
          set _ $1
         }
                    14 { 
          set _ "?"
         }
                    15 { 
          set _ $1
         }
                    16 { 
          set _ $1
         }
                    17 { 
          set _ [lindex $::format_matches $2]
         }
                    18 { 
              set _ "[string tolower [string index $2 0]][string range $2 1 end]"
             }
                    19 { 
              set _ [string totitle $2]
             }
                    20 { 
              set _ [string tolower $2]
             }
                    21 { 
              set _ [string toupper $2]
             }
                    22 { 
               if {[llength [lindex $::format_matches end]] <= $3} {
                 set _ $5
               } else {
                 set _ ""
               }
              }
                    23 { 
               if {[llength [lindex $::format_matches end]] <= $3} {
                 set _ $5
               } else {
                 set _ $7
               }
              }
                }
                format_unsetupvalues $format_dc
                # pop off tokens from the stack if normal rule
                if {![info exists ::format_rules($format_rule,e)]} {
                    incr format_stackpointer -1
                    set format_state_stack [lrange $format_state_stack 0 $format_stackpointer]
                    set format_value_stack [lrange $format_value_stack 0 $format_stackpointer]
                }
                # now do the goto transition
                lappend format_state_stack $::format_table([lindex $format_state_stack end]:$format_l,target)
                lappend format_value_stack $_
            }
            accept {
                set format_accepted 1
            }
            goto -
            default {
                puts stderr "Internal parser error: illegal command $::format_table($format_state:$format_token)"
                return 2
            }
        }
    }
    return 0
}

######
# end autogenerated taccle functions
######

rename format_error format_error_orig
proc format_error {s} {
  set ::format_errstr "[string repeat " " $::format_begpos]^"
  set ::format_errmsg $s
}

