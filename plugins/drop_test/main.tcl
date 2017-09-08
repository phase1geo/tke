# Plugin namespace
namespace eval drop_test {

  ######################################################################
  # Called when a file is dropped
  proc on_drop {index type data} {
    
    api::log "In on_drop, index: $index, type: $type, data: $data"
    
    return 1
    
  }

}

# Register all plugin actions
api::register drop_test {
  {on_drop drop_test::on_drop}
}
