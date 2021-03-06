# Plugin namespace
namespace eval pref_test {

  ######################################################################
  # Called when preferences are loaded.
  proc on_pref_load {} {

    return {
      "Enable"  0
      "Mode"    "value_b"
      "Status"  "slow"
      "Value"   "This is a value"
      "Tokens"  {foobar barfoo nice}
      "Message" "Something"
      "Integer" 5
      "Google"  9
      "Goober"  1
      "Color"   "red"
      "BColor"  "blue"
      "Table"   ""
    }

  }

  ######################################################################
  # Create the preferences UI.
  proc on_pref_ui {w} {

    # api::preferences::widget checkbutton $w "Enable" "Enables this plugin"

    # pack [ttk::labelframe $w.lf -text "Mode"] -fill x
    # api::preferences::widget radiobutton $w.lf "Mode" "This is mode A" -value value_a
    # api::preferences::widget radiobutton $w.lf "Mode" "This is mode B" -value value_b
    # api::preferences::widget radiobutton $w.lf "Mode" "This is mode C" -value value_c

    # pack [ttk::labelframe $w.sf -text "Spinboxes"] -fill x
    # api::preferences::widget spinbox     $w.sf "Integer" "Just an integer value" -from 0 -to 10 -grid 1
    # api::preferences::widget spinbox     $w.sf "Google"  "A lot of stuff"        -from 0 -to 20 -grid 1
    # api::preferences::widget spinbox     $w.sf "Goober"  "Hardly anything"       -from 0 -to 2  -ending "nothings" -grid 1

    api::preferences::widget menubutton  $w "Status"  "Status of this plugin" -values [list slow medium fast]
    api::preferences::widget entry       $w "Value"   "Enter a value here" -watermark "Optional"
    api::preferences::widget token       $w "Tokens"  "Enter some tokens" -watermark "Non-optional"
    api::preferences::widget text        $w "Message" "Enter a message here" -height 2 -help "This is just a test message of the text widget.  See how nice it is and how well this documentation looks!"
    api::preferences::widget help        $w "This is some sort of text message to check that the help text is displayed properly and will line wrap at the appropriate times.  I have no idea if this will work or not."
    api::preferences::widget table       $w "Table" "Nice Table" -height 3 \
      -columns {
        {"Enable" -type checkbutton -value 1}
        {"Column A" -type menubutton -value "test" -values {test nice good}}
        {"Column B"}
      }

    pack [ttk::labelframe $w.cf -text "Colors"] -fill x
    api::preferences::widget colorpicker $w.cf "Color" "Pick a color" -color "blue" -grid 1
    api::preferences::widget colorpicker $w.cf "BColor" "Pick another color" -color "blue" -grid 1

  }

}

# Register all plugin actions
api::register pref_test {
  {on_pref_load pref_test::on_pref_load}
  {on_pref_ui   pref_test::on_pref_ui}
}
