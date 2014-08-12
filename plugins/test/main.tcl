namespace eval test {
  
  proc on_start {} {
    set txt [api::file::add [file join [api::get_plugin_directory] main.tcl] \
      -gutters {{test heart \u2665 {-fg red -onenter test::gutter_on_enter} dollar $ {-fg green}}}]
    $txt gutter set test heart {2 3} dollar 6
  }
  
  proc gutter_on_enter {txt} {
    puts "gutter get:                  [$txt gutter get test]"
    puts "gutter cget heart -fg:       [$txt gutter cget test heart -fg]"
    puts "gutter cget heart -onenter:  [$txt gutter cget test heart -onenter]"
    puts "gutter cget heart -onleave:  [$txt gutter cget test heart -onleave]"
    puts "gutter names:                [$txt gutter names]"
  }

}

api::register test {
  {on_start test::on_start}
}
