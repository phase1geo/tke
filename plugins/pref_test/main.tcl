# Plugin namespace
namespace eval pref_test {

  ######################################################################
  # Called when preferences are loaded.
  proc on_pref_load {} {

    return [list "Enable" 0]

  }

}

# Register all plugin actions
api::register pref_test {
  {on_pref_load pref_test::on_pref_load}
}
