# Plugin namespace
namespace eval file_info {

  proc do_reverse {fname} {
    return [string reverse [file tail $fname]]
  }

  proc do_length {fname} {
    return [string length [file tail $fname]]
  }

}

# Register all plugin actions
api::register file_info {
  {info_panel "Reverse" 1 file_info::do_reverse}
  {info_panel "Length"  0 file_info::do_length}
}
