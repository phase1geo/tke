package require http

# Plugin namespace
namespace eval url_validator {

  variable url_pattern {(https?://)?[a-z0-9\-]+\.[a-z0-9\-\.]+(?:/|(?:/[a-zA-Z0-9!#\$%&'\*\+,\-\.:;=\?@\[\]_~]+)*)}
  variable checked     {}

  array set langs {
    "Markdown"     markdown
    "MultMarkdown" markdown
    "HTML"         html
    "HelpSystem"   heml
  }

  ######################################################################
  # Parses the given Markdown file
  proc check_url {url {startpos ""} {endpos ""}} {

    variable checked

    set tags [list]

    if {![catch { http::geturl $url -validate 1 } token]} {
      set status [http::status $token]
      set ncode  [http::ncode  $token]
      http::cleanup $token
    } else {
      set status "Bad URL"
      set ncode  ""
    }

    lappend checked [list $url $status $ncode $startpos $endpos]

  }

  ######################################################################
  # Parses the given text widget for HTML specified URLs.
  proc parse_file {txt} {

    variable url_pattern

    set i 0
    foreach index [$txt search -all -count lengths -regexp -- $url_pattern 1.0 end] {
      set endpos [$txt index $index+[lindex $lengths $i]c]
      check_url [$txt get $index $endpos] $index $endpos
      incr i
    }

  }

  ######################################################################
  # Displays the checked URLs.
  proc display_checked_urls {{txt ""}} {

    variable checked

    if {[winfo exists .urlval]} {
      destroy .urlval
    }

    toplevel .urlval
    wm title .urlval "Checked URLs"

    set columns [list status code line startpos]

    if {$txt eq ""} {
      set displaycolumns [list status code]
    } else {
      set displaycolumns [list status code line]
    }

    set table [ttk::treeview .urlval.tv -columns $columns -displaycolumns $displaycolumns \
      -xscrollcommand [list .urlval.hb set] -yscrollcommand [list .urlval.vb set]]
    ttk::scrollbar .urlval.vb -orient vertical   -command [list .urlval.tv yview]
    ttk::scrollbar .urlval.hb -orient horizontal -command [list .urlval.tv xview]

    $table heading #0     -text "URL"
    $table heading status -text "Status"
    $table heading code   -text "Code"

    $table column #0     -stretch 1 -width 400 -minwidth 200 -anchor w
    $table column status -width 100 -minwidth 50 -anchor center
    $table column code   -width 100 -minwidth 50 -anchor center

    if {$txt ne ""} {
      $table heading line -text "Line"
      $table column  line -width 100 -minwidth 50 -anchor e
    }

    # $table tag configure bad -foreground red
    if {$txt ne ""} {
      $table tag bind both <ButtonPress> [list url_validator::handle_click %W %x %y $txt]
    }

    grid rowconfigure    .urlval 0 -weight 1
    grid columnconfigure .urlval 0 -weight 1
    grid .urlval.tv -row 0 -column 0 -sticky news
    grid .urlval.vb -row 0 -column 1 -sticky ns
    grid .urlval.hb -row 1 -column 0 -sticky es

    # Create the images, if necessary
    if {[lsearch [image names] bad] == -1} {
      image create photo bad  -file [file join [api::get_plugin_directory] bad.gif]
      image create photo good -file [file join [api::get_plugin_directory] good.gif]
    }

    # Populate the the table with the checked status
    foreach item $checked {
      lassign $item url status code startpos endpos
      set tag [expr {(($status eq "ok") && ($code == 200)) ? "good" : "bad"}]
      $table insert {} end -text "  $url" -image $tag -values [list $status $code [lindex [split $startpos .] 0] $startpos] -tags [list both $tag]
    }

  }

  ######################################################################
  # Handles a left click on the results table.
  proc handle_click {table x y txt} {

    if {![winfo exists $txt]} {
      return
    }

    set item     [$table identify item $x $y]
    set startpos [lindex [$table item $item -values] 3]

    # Display the text widget
    api::reset_text_focus $txt
    tk::TextSetCursor $txt $startpos

  }

  ######################################################################
  # Searches for all URLS found in the current file, checks each found
  # link and displays any broken links in a popup window.
  proc do_file {} {

    variable langs
    variable checked

    set file_index [api::file::current_index]
    set checked    [list]

    # Parse the file for URLs
    parse_file [set txt [api::file::get_info $file_index txt]]

    # Display the checked URLs
    display_checked_urls $txt

  }

  ######################################################################
  # Returns 1 if the current file is available for parsing.
  proc handle_file_state {} {

    variable langs

    if {[set file_index [api::file::current_index]] == -1} {
      return 0
    }

    return [info exists langs([api::file::get_info $file_index lang])]

  }

  ######################################################################
  # Verify all selected text for URLs.
  proc do_select {} {

    variable checked

    set file_index [api::file::current_index]
    set txt        [api::file::get_info $file_index txt]
    set checked    [list]

    if {![catch { $txt tag ranges sel } selected]} {
      foreach {startpos endpos} $selected {
        check_url [$txt get $startpos $endpos] $startpos $endpos
      }
    }

    # Display the checked URLs
    display_checked_urls $txt

  }

  ######################################################################
  # Handles the state of the validate URL selection menu command.
  proc handle_select_state {} {

    if {[set file_index [api::file::current_index]] == -1} {
      return 0
    }

    set txt [api::file::get_info $file_index txt]

    if {[catch { $txt tag ranges sel } selected]} {
      return 0
    }

    return [expr {$selected ne [list]}]

  }

  ######################################################################
  # Allow the user to enter a URL in the entry field.
  proc do_url {} {

    variable checked

    set checked [list]

    if {[api::get_user_input "Enter URL:" url 0]} {

      # Check the entered URL
      check_url $url

      # Display the checked URLs
      display_checked_urls

    }

  }

  ######################################################################
  # Handles the validate URL menu command.
  proc handle_url_state {} {

    return 1

  }

}

# Register all plugin actions
api::register url_validator {
  {menu command {URL Validator/Validate file links} url_validator::do_file   url_validator::handle_file_state}
  {menu command {URL Validator/Validate selection}  url_validator::do_select url_validator::handle_select_state}
  {menu command {URL Validator/Validate URL}        url_validator::do_url    url_validator::handle_url_state}
}
