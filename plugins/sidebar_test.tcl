# HEADER_BEGIN
# NAME         sidebar_test
# AUTHOR       Trevor Williams  (phase1geo@gmail.com)
# DATE         08/14/2013
# INCLUDE      no
# DESCRIPTION  Tests the sidebar plugin capabilities
# HEADER_END

namespace eval plugins::sidebar_test {
  
  ######################################################################
  proc root_popup_do {} {
    
    puts "In root_popup_do"
    
  }
  
  ######################################################################
  proc root_popup_state {} {
    
    return 0
    
  }
  
  ######################################################################
  proc dir_popup_do {} {
    
    puts "In dir_popup_do"
    
  }
  
  ######################################################################
  proc dir_popup_state {} {
    
    return 1
    
  }
  
  ######################################################################
  proc file_popup_do {} {
    
    puts "In file_popup_do"
    
  }
  
  ######################################################################
  proc file_popup_state {} {
    
    return 1
    
  }
  
  ######################################################################
  proc tab_popup_do {} {
    
    puts "In tab_popup_do"
    
  }
  
  ######################################################################
  proc tab_popup_state {} {
    
    return 1
    
  }

}

plugins::register sidebar_test {
  {root_popup command "Sidebar Test.Output Root"      plugins::sidebar_test::root_popup_do plugins::sidebar_test::root_popup_state}
  {dir_popup  command "Sidebar Test.Output Directory" plugins::sidebar_test::dir_popup_do  plugins::sidebar_test::dir_popup_state}
  {file_popup command "Sidebar Test.Output File"      plugins::sidebar_test::file_popup_do plugins::sidebar_test::file_popup_state}
  {tab_popup  command "Tab Test.Output Tab"           plugins::sidebar_test::tab_popup_do  plugins::sidebar_test::tab_popup_state}
}
