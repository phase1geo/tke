# Plugin namespace
namespace eval number_converter {

  ######################################################################
  # Returns a decimal representation of the given number.
  proc get_number {txt startpos endpos} {

    array set charmap [list 0 0 1 1 2 2 3 3 4 4 5 5 6 6 7 7 8 8 9 9 a 10 b 11 c 12 d 13 e 14 f 15]

    # Get the selected text
    set str [$txt get $startpos $endpos]

    # Look for a valid numerical format
    if {[regexp {^(0[xX]|'[sS]?[hH])([0-9a-fA-F_]+)$} $str -> prefix value]} {
      set shift 4
    } elseif {[regexp {^(0[dD]|'[sS][dD])?([0-9_]+)$} $str -> prefix value]} {
      return [string map {_ {}} $value]
    } elseif {[regexp {^(0[oO]|'[sS][oO])([0-7_]+)$} $str -> prefix value]} {
      set shift 3
    } elseif {[regexp {^(0[bB]|'[sS][bB])([01_]+)$} $str -> prefix value]} {
      set shift 1
    } else {
      return ""
    }

    # Calculate the decimal value
    set val 0
    foreach c [split [string map {_ {}} [string tolower $value]] {}] {
      set val [expr ($val << $shift) | $charmap($c)]
    }

    return $val

  }

  ######################################################################
  # Inserts underscores every X characters where X is a value specified
  # within the plugin preferences.
  proc insert_underscores {str underscore} {

    if {$underscore > 0} {
      set words [list]
      while {$str ne ""} {
        lappend words [string range $str end-[expr $underscore - 1] end]
        set str [string range $str 0 end-$underscore]
      }
      return [join [lreverse $words] "_"]
    }

    return $str

  }

  ######################################################################
  # Perform numerical replacement as required.
  proc do_replace {prefix fmt {underscore 4}} {

    set txt [api::file::get_info [api::file::current_index] txt]

    foreach {endpos startpos} [lreverse [$txt tag ranges sel]] {
      if {[set num [get_number $txt $startpos $endpos]] ne ""} {
        $txt replace $startpos $endpos "$prefix[insert_underscores [format $fmt $num] $underscore]"
      }
    }

  }

  ######################################################################
  # Converts the current number to binary format.
  proc do_to_binary {} {

    do_replace "0b" "%llb" 4

  }

  ######################################################################
  # Converts the current number to an octal format.
  proc do_to_octal {} {

    do_replace "0o" "%llo" 3

  }

  ######################################################################
  # Converts the current number to a decimal format.
  proc do_to_decimal {} {

    do_replace "" "%lld" 0

  }

  ######################################################################
  # Converts the current number to a hexidecimal format.
  proc do_to_hexidecimal {} {

    do_replace "0x" "%llx" 4

  }

  ######################################################################
  # Returns 1 if any of the selections contains a numerical value.
  proc handle_all_state {} {

    if {[set index [api::file::current_index]] != -1} {
      set txt [api::file::get_info $index txt]
      foreach {startpos endpos} [$txt tag ranges sel] {
        if {[get_number $txt $startpos $endpos] ne ""} {
          return 1
        }
      }
    }

    return 0

  }

}

# Register all plugin actions
api::register number_converter {
  {menu command {Number Converter/To Binary}      number_converter::do_to_binary      number_converter::handle_all_state}
  {menu command {Number Converter/To Octal}       number_converter::do_to_octal       number_converter::handle_all_state}
  {menu command {Number Converter/To Decimal}     number_converter::do_to_decimal     number_converter::handle_all_state}
  {menu command {Number Converter/To Hexidecimal} number_converter::do_to_hexidecimal number_converter::handle_all_state}
}
