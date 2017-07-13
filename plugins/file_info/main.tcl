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
  {info_panel "Reverse" file_info::do_reverse}
  {info_panel "Length"  file_info::do_length}
}
