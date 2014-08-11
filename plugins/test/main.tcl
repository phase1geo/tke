namespace eval test {
  
  proc on_start {} {
    set txt [api::file::add [file join [api::get_plugin_directory] main.tcl] \
      -gutters {{test heart \u2665 {-fg red -onenter test::gutter_on_enter} dollar $ {-fg green}}}]
    $txt setgutter test heart {2 3} dollar 6
  }
  
  proc gutter_on_enter {txt} {
    puts "HERE!"
  }

}

api::register test {
  {on_start test::on_start}
}
