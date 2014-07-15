# HEADER_BEGIN
# NAME         text_binding
# AUTHOR       Trevor Williams  (phase1geo@gmail.com)
# DATE         08/14/2013
# INCLUDE      yes
# DESCRIPTION  Tests the text binding plugin capabilities
# HEADER_END

namespace eval plugins::text_binding {
  
  proc do_foobar {binding} {
    
    puts "In do_foobar, binding: $binding"
    
  }
  
  proc do_barfoo {binding} {
    
    puts "In do_barfoo, binding: $binding"
    
  }
  
}

plugins::register text_binding {
  {text_binding pretext  foobar plugins::text_binding::do_foobar}
  {text_binding posttext barfoo plugins::text_binding::do_barfoo}
}
