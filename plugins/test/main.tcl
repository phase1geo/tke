namespace eval test {
  
  proc on_start {} {
    set txt [api::file::add [file join [api::get_plugin_directory] main.tcl] -gutters {{test {\u2665 {-foreground red}} {$ {-foreground green}}}}]
    $txt setgutter test \u2665 2 \u2665 3 $ 6
  }

}

api::register test {
  {on_start test::on_start}
}
