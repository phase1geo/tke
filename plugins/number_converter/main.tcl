# Plugin namespace
namespace eval number_converter {

  ######################################################################
  # Returns a decimal representation of the given number.
  proc get_number {txt startpos endpos} {

    set str [$txt get $startpos $endpos]

    if {[regexp {^((0d)?[0-9_]+|0[oO][0-7_]+|0[bB][01_]+|0[xX][0-9a-fA-F_]+)$} $str -> value]} {
      return [format %lld [string map {_ {}} $value]]
    }

    return ""

  }

  ######################################################################
  # Inserts underscores every X characters where X is a value specified
  # within the plugin preferences.
  proc insert_underscores {str} {

    set underscore 3

    if {$underscore > 0} {
      set words [list]
      while {$str ne ""} {
        lappend words [string range $str end-$underscore end]
        set str [string range $str 0 end-$underscore]
      }
      return [string reverse [join $words "_"]]
    }

    return $str

  }

  ######################################################################
  # Converts the current number to binary format.
  proc do_to_binary {} {

    set txt [api::file::get_info [api::file::current_file_index] txt]

    foreach {endpos startpos} [lreverse [$txt tag ranges sel]] {
      if {[set num [get_number $txt $startpos $endpos]] ne ""} {
        $txt replace $startpos $endpos "0b[insert_underscores [format %b $num]]"
      }
    }

  }

  ######################################################################
  # Returns 1 if any of the selections contains a numerical value.
  proc handle_all_state {} {

    set txt [api::file::get_info [api::file::current_file_index] txt]

    foreach {startpos endpos} [$txt tag ranges sel] {
      if {[get_number $txt $startpos $endpos] ne ""} {
        return 1
      }
    }

    return 0

  }

}

# Register all plugin actions
api::register number_converter {
  {menu command {Number Converter/To Binary} number_converter::do_to_binary number_converter::handle_all_state}
}
