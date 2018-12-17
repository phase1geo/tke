####################################################################
#
# This script provides GetSetIni oo::class for saving and reading
# the variables of single or list type.
#
# Call to save:
#   getsetini setIni nfile ?-single var? ?-list lst? ...
#
# Call to read:
#   getsetini getIni nfile
#
# Where:
#   nfile - name of file to save the variables in (if "" or "-",
#           the default *.ini is taken)
#   var   - a single variable
#   lst   - a list variable
#
# Example:
#   source getsetini.tcl
#   set listIt {
#                {fr1 - - 1 2 "frame1"}
#                {fr2 - - 3 4 "frame2"}
#              }
#   set var1 "some value"
#   set nfile "myInits.ini"
#   getsetini setIni $nfile -list listIt -single var1
#   # ...
#   getsetini getIni $nfile
#   getsetini destroy
#
####################################################################

oo::class create GetSetIni {

  variable TYPSINGLE
  variable TYPLIST
  variable VARBEGIN

  constructor {} {

    set TYPSINGLE "-single"
    set TYPLIST   "-list"
    set VARBEGIN  "############:"

  }

  method dataFileName {datafile} {

    if {$datafile in {"" "-"}} {
      set datafile [file rootname $::argv0].ini
    }
    return $datafile

  }

  method getIni {{datafile ""}} {

    set datafile [my dataFileName $datafile]
    if {![file exists $datafile]} {
      return 0
    }
    set ch [open $datafile]
    set contents [read $ch]
    close $ch
    set dataset 0
    foreach line [split $contents \n] {
      set line [string trim $line]
      if {$line==""} continue
      lassign [split $line] start medium finish
      if {$start == $VARBEGIN} {
        set vartype $medium
        set varname $finish
        if {$vartype==$TYPLIST} {
          uplevel 1 [list set $varname [list]]
        }
      } elseif {[info exists vartype]} {
        if {$vartype == $TYPSINGLE} {
          uplevel 1 [list set $varname $line]
          incr dataset
        } elseif {$vartype == $TYPLIST} {
          uplevel 1 [list lappend $varname [list {*}$line]]
          incr dataset
        }
      }
    }
    return $dataset

  }

  method setIni {{datafile ""} args} {

    set ch [open [my dataFileName $datafile] w]
    foreach {vartype varname} $args {
      puts $ch "$VARBEGIN $vartype $varname"
      if {$vartype=="$TYPLIST"} {
        set lst [uplevel 1 set $varname]
        foreach l $lst {
          puts $ch $l
        }
      } elseif {$vartype=="$TYPSINGLE"} {
        puts $ch [uplevel 1 set $varname]
      }

    }
    close $ch

  }

}

