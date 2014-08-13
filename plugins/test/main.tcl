namespace eval test {
  
  proc on_start {} {
    set txt [api::file::add [file join [api::get_plugin_directory] main.tcl] \
      -gutters {{test heart {-symbol \u2665 -fg red -onenter test::gutter_on_enter -onleave test::gutter_on_leave -onclick test::gutter_on_click} dot {-symbol \u00b7 -fg green}}}]
    $txt gutter set test heart {2 3} dot 6
  }
  
  proc gutter_on_enter {txt} {
    puts "gutter get:                  [$txt gutter get test]"
    puts "gutter cget heart -fg:       [$txt gutter cget test heart -fg]"
    puts "gutter cget heart -onenter:  [$txt gutter cget test heart -onenter]"
    puts "gutter cget heart -onleave:  [$txt gutter cget test heart -onleave]"
    puts "gutter names:                [$txt gutter names]"
    puts "gutter configure:            [$txt gutter configure test]"
    puts "gutter configure heart:      [$txt gutter configure test heart]"
    $txt gutter configure test heart -fg blue
  }
  
  proc gutter_on_leave {txt} {
    $txt gutter clear test 0 10
    $txt gutter set test heart {4 5 6} dot {1 2}
  }
  
  proc gutter_on_click {txt} {
    $txt gutter delete test dot
  }

}

api::register test {
  {on_start test::on_start}
}
