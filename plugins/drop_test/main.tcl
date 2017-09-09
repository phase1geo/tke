# Plugin namespace
namespace eval drop_test {

  ######################################################################
  # Checks the incoming data and if it is an image file, sets the specified
  # string to be an image syntax.
  proc handle_image {istext data pstr} {

    upvar $pstr str

    if {!$istext && ([lsearch [list .gif .png .jpg .jpeg] [file extension $data]] != -1)} {
      set str "!\[\]($data)"
      return 1
    }

    return 0

  }

  ######################################################################
  # Called when a file is dropped
  proc on_drop {index istext data} {

    if {[api::file::get_info $index lang] eq "Markdown"} {

      set value ""
      set str   ""

      if {![handle_image $istext $data value]} {
        return 0
      }

      # Get the associated text widget
      set txt  [api::file::get_info $index txt]
      set pre  [$txt get "insert linestart" insert]
      set post [$txt get insert "insert lineend"]

      if {($pre ne "") && ![string is space [string index $pre end]]} {
        append str " "
      }
      append str $value
      if {($post ne "") && ![string is space [string index $post 0]]} {
        append str " "
      }

      # Insert the string
      $txt insert insert $str

      return 1

    }

    return 0

  }

}

# Register all plugin actions
api::register drop_test {
  {on_drop drop_test::on_drop}
}
