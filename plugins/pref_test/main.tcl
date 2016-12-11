# Plugin namespace
namespace eval pref_test {

  ######################################################################
  # Called when preferences are loaded.
  proc on_pref_load {} {

    return [list "Enable"  0 \
                 "Mode"    "value_b" \
                 "Status"  "slow" \
                 "Value"   "This is a value" \
                 "Message" "Something" \
                 "Integer" 5]

  }

  ######################################################################
  # Create the preferences UI.
  proc on_pref_ui {w} {

    api::preferences::widget checkbutton $w "Enable" "Enables this plugin"

    pack [ttk::labelframe $w.lf -text "Mode"] -fill x
    api::preferences::widget radiobutton $w.lf "Mode"   "This is mode A" "value_a"
    api::preferences::widget radiobutton $w.lf "Mode"   "This is mode B" "value_b"
    api::preferences::widget radiobutton $w.lf "Mode"   "This is mode C" "value_c"

    api::preferences::widget menubutton $w "Status" "Status of this plugin" [list slow medium fast]
    api::preferences::widget spinbox    $w "Integer" "Just an integer value" 0 10 1
    api::preferences::widget entry      $w "Value"  "Enter a value here"
    api::preferences::widget text       $w "Message" "Enter a message here"

  }

}

# Register all plugin actions
api::register pref_test {
  {on_pref_load pref_test::on_pref_load}
  {on_pref_ui   pref_test::on_pref_ui}
}
