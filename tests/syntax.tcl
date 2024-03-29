namespace eval syntax {

  ######################################################################
  # Initializes the diagnostic and returns the pathname of the added
  # text widget.
  proc initialize {} {

    variable current_tab

    # Add a new tab
    set current_tab [gui::add_new_file end]

    # Get the current text widget
    set txt [gui::get_info $current_tab tab txt]

    # Set the language to Tcl
    syntax::set_language $txt "HTML"

    return $txt

  }

  ######################################################################
  # Handles diagnostic cleanup and fails if there is a valid fail message.
  proc cleanup {{fail_msg ""}} {

    variable current_tab

    # Close the tab
    gui::close_tab $current_tab -check 0

    # If there was a fail message, exit with a failure
    if {$fail_msg ne ""} {
      return -code error $fail_msg
    }

  }

  # Verify that mixed languag is highlighted properly
  proc run_test1 {} {

    # Get the text widget
    set txt [initialize]

    # Set the syntax to Markdown
    syntax::set_language $txt "Markdown"

    set str {
      <strong>Hello</strong> **World**
    }

    $txt insert end "\n[string trim $str]"

    if {[$txt syntax ranges tag] ne [list 2.1 2.7 2.14 2.21]} {
      cleanup "Tag tags are incorrect ([$txt syntax ranges tag])"
    }
    if {[$txt syntax ranges bold] ne [list 2.25 2.30]} {
      cleanup "Bold tags are incorrect ([$txt syntax ranges bold])"
    }

    # Clean things up
    cleanup

  }

  # Verify embedded language highlighting.
  proc run_test2 {} {

    # Get the text widget
    set txt [initialize]

    set str {
<html>
  <!-- PHP block -->
  <?php
    // This is a comment
    if( $a ) {
      $b = 0;
    }
  ?>
</html>
    }

    $txt insert end "\n[string trim $str]"

    if {[$txt syntax ranges keywords] ne [list 6.4 6.6]} {
      cleanup "Keyword miscompare ([$txt syntax ranges keywords])"
    }
    if {[$txt syntax ranges tag] ne [list 2.1 2.5 3.3 3.6 4.3 4.7 10.1 10.6]} {
      cleanup "Tag miscompare ([$txt syntax ranges tag])"
    }
    if {[$txt syntax ranges comstr1c0] ne [list 3.2 3.20]} {
      cleanup "Block comment miscompare ([$txt syntax ranges comstr1c0])"
    }
    if {[$txt syntax ranges comstr1l] ne [list 5.4 6.0]} {
      cleanup "PHP comment miscompare ([$txt syntax ranges comstr1l:PHP])"
    }
    if {[$txt syntax ranges Lang=PHP] ne [list 5.0 9.0]} {
      cleanup "PHP language miscompare ([$txt syntax ranges Lang=PHP])"
    }

    # Clean things up
    cleanup

  }

  # Verify embedded syntax that is lacking the correct starting symbol
  proc run_test3 {} {

    # Get the text widget
    set txt [initialize]

    set str {
<html>
  <!-- PHP block -->
  <php
    // This is a comment
    if( $a ) {
      $b = 0;
    }
  ?>
</html>
    }

    $txt insert end "\n[string trim $str]"

    if {[$txt syntax ranges keywords] ne [list]} {
      cleanup "Keyword miscompare ([$txt syntax ranges keywords])"
    }
    if {[$txt syntax ranges tag] ne [list 2.1 2.5 3.3 3.6 4.3 4.6 10.1 10.6]} {
      cleanup "Tag miscompare ([$txt syntax ranges tag])"
    }
    if {[$txt syntax ranges comstr1c0] ne [list 3.2 3.20]} {
      cleanup "Block comment miscompare ([$txt syntax ranges comstr1c0])"
    }
    if {[$txt syntax ranges comstr1l] ne [list]} {
      cleanup "PHP comment miscompare ([$txt syntax ranges comstr1l])"
    }
    if {[$txt syntax ranges Lang=PHP] ne [list]} {
      cleanup "PHP language miscompare ([$txt syntax ranges Lang=PHP])"
    }

    # Clean things up
    cleanup

  }

  # Verify that syntax highlighting is correct when ending symbol is missing
  proc run_test4 {} {

    # Get the text widget
    set txt [initialize]

    set str {
<html>
  <!-- PHP block -->
  <?php
    // This is a comment
    if( $a ) {
      $b = 0;
    }
  >
</html>
    }

    $txt insert end "\n[string trim $str]"

    if {[$txt syntax ranges keywords] ne [list 6.4 6.6]} {
      cleanup "Keyword miscompare ([$txt syntax ranges keywords])"
    }
    if {[$txt syntax ranges tag] ne [list 2.1 2.5 3.3 3.6 4.3 4.7 10.1 10.6]} {
      cleanup "Tag miscompare ([$txt syntax ranges tag])"
    }
    if {[$txt syntax ranges comstr1c0] ne [list 3.2 3.20]} {
      cleanup "Block comment miscompare ([$txt syntax ranges comstr1c0])"
    }
    if {[$txt syntax ranges comstr1l] ne [list 5.4 6.0]} {
      cleanup "Line comment miscompare ([$txt syntax ranges comstr1l])"
    }
    if {[$txt syntax ranges Lang=PHP] ne [list 5.0 11.0]} {
      cleanup "PHP language miscompare ([$txt syntax ranges Lang=PHP])"
    }

    # Clean things up
    cleanup

  }

  # Verify that embedded block comment ends at the language boundary
  proc run_test5 {} {

    # Get the text widget
    set txt [initialize]

    set str {
<html>
  <!-- PHP block -->
  <?php
    /* This is a comment
    if( $a ) {
      $b = "nice";
    }
  ?>
</html>
    }

    $txt insert end "\n[string trim $str]"

    if {[$txt syntax ranges keywords] ne [list 6.4 6.6]} {
      cleanup "Keyword miscompare ([$txt syntax ranges keywords])"
    }
    if {[$txt syntax ranges tag] ne [list 2.1 2.5 3.3 3.6 4.3 4.7 10.1 10.6]} {
      cleanup "Tag miscompare ([$txt syntax ranges tag])"
    }
    if {[$txt syntax ranges comstr1c0] ne [list 3.2 3.20 5.4 9.0]} {
      cleanup "Block comment0 miscompare ([$txt syntax ranges comstr1c0])"
    }
    if {[$txt syntax ranges comstr0d0] ne [list]} {
      cleanup "String miscompare ([$txt syntax ranges comstr0d0])"
    }
    if {[$txt syntax ranges Lang=PHP] ne [list 5.0 9.0]} {
      cleanup "PHP language miscompare ([$txt syntax ranges Lang=PHP])"
    }

    # Clean things up
    cleanup

  }

  # Verify that inserting an extra character to a language symbol causes a highlight change
  proc run_test6 {} {

    # Get the text widget
    set txt [initialize]

    set str {
<html>
  <!-- PHP block -->
  <?php
    /* This is a comment
    if( $a ) {
      $b = "nice";
    }
  ?>
</html>
    }

    $txt insert end "\n[string trim $str]"
    $txt insert 4.4 a

    if {[$txt syntax ranges keywords] ne [list 6.4 6.6]} {
      cleanup "Keyword miscompare ([$txt syntax ranges keywords])"
    }
    if {[$txt syntax ranges tag] ne [list 2.1 2.5 3.3 3.6 4.3 4.8 10.1 10.6]} {
      cleanup "Tag miscompare ([$txt syntax ranges tag])"
    }
    if {[$txt syntax ranges comstr1c0] ne [list 3.2 3.20]} {
      cleanup "Block comment miscompare ([$txt syntax ranges comstr1c0])"
    }
    if {[$txt syntax ranges comstr1l] ne [list]} {
      cleanup "PHP comment miscompare ([$txt syntax ranges comstr1l])"
    }
    if {[$txt syntax ranges Lang=PHP] ne [list]} {
      cleanup "PHP language miscompare ([$txt syntax ranges Lang=PHP])"
    }

    # Clean things up
    cleanup

  }

  # Verify that deleting a character from a language symbol causes a highlight change
  proc run_test7 {} {

    # Get the text widget
    set txt [initialize]

    set str {
<html>
  <!-- PHP block -->
  <?php
    /* This is a comment
    if( $a ) {
      $b = "nice";
    }
  ?>
</html>
}

    $txt insert end "\n[string trim $str]"
    $txt delete 4.4

    if {[$txt syntax ranges keywords] ne [list 6.4 6.6]} {
      cleanup "Keyword miscompare ([$txt syntax ranges keywords])"
    }
    if {[$txt syntax ranges tag] ne [list 2.1 2.5 3.3 3.6 4.3 4.6 10.1 10.6]} {
      cleanup "Tag miscompare ([$txt syntax ranges tag])"
    }
    if {[$txt syntax ranges comstr1c0] ne [list 3.2 3.20]} {
      cleanup "Block comment miscompare ([$txt syntax ranges comstr1c0])"
    }
    if {[$txt syntax ranges comstr1l] ne [list]} {
      cleanup "PHP comment miscompare ([$txt syntax ranges comstr1l])"
    }
    if {[$txt syntax ranges Lang=PHP] ne [list]} {
      cleanup "PHP language miscompare ([$txt syntax ranges Lang=PHP])"
    }

    # Clean things up
    cleanup

  }

}

