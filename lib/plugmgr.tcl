# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2019  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:    plugmgr.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    12/06/2018
# Brief:   Namespace for the plugin manager.
######################################################################

namespace eval plugmgr {

  variable current_id ""

  array set default_pdata {
    author        "Anonymous"
    email         ""
    website       ""
    version       "1.0"
    category      "Miscellaneous"
    description   ""
    release_notes ""
    overview      ""
  }

  array set database {
    plugins {}
  }
  array set widgets  {}

  # TEMPORARY
#  array set database {
#    plugins {
#      0 {installed 1 update_avail 0 display_name {Plugin 0} author {Trevor Williams} email {phase1geo@gmail.com} website {http://www.apple.com} version {1.2.2} category miscellaneous description "Quick\ndescription\nYes" release_notes {Some release notes} overview {<p>This is a really great overview of 0!</p>}}
#      1 {installed 0 update_avail 0 display_name {Plugin 1} author {Trevor Williams} email {phase1geo@gmail.com} website {} version {2.0}   category miscellaneous description {Another quick description} release_notes {Some release notes about nothing} overview {<p>This is a really great overview of 1!</p>}}
#      2 {installed 0 update_avail 0 display_name {Plugin 2} author {Trevor Williams} email {phase1geo@gmail.com} website {} version {2.3}   category miscellaneous description {Quick description 2} release_notes {My release notes} overview {<p>This is a really great overview of 2!</p>}}
#      3 {installed 1 update_avail 1 display_name {Plugin 3} author {Trevor Williams} email {phase1geo@gmail.com} website {} version {2.4.1} category filesystem description {Quick description 3} release_notes {My release notes} overview {<p>This is a really great overview of 3!</p>}}
#      4 {installed 1 update_avail 0 display_name {Plugin 4} author {Trevor Williams} email {phase1geo@gmail.com} website {} version {1.5.2} category filesystem description {Quick description 4} release_notes {My release notes} overview {<p>This is a really great overview of 4!</p>}}
#    }
#  }

  ######################################################################
  # Adds a single plugin to the plugin database file.  Returns the
  # data that is stored in the plugin entry.
  proc add_plugin {dbfile name args} {

    variable default_pdata

    # Store the important plugin values
    array set pdata [array get default_pdata]
    foreach {attr value} $args {
      if {[info exists pdata($attr)]} {
        set pdata($attr) $value
      }
    }

    if {[file exists $dbfile]} {

      # Read in the existing values
      if {[catch { tkedat::read $dbfile } rc]} {
        return -code error "Unable to read the given plugin database file"
      }

      array set data    $rc
      array set plugins $data(plugins)

    }

    set plugins($name) [array get pdata]
    set data(plugins)  [array get plugins]

    # Save the file
    if {[catch { tkedat::write $dbfile [array get data] } rc]} {
      return -code error "Unable to update the plugin database file"
    }

    return [array get pdata]

  }

  ######################################################################
  # Displays the popup window to allow the user to adjust plugin information
  # prior to exporting.
  proc export_win {plugdir} {

    set w [toplevel .pmewin]
    wm title     $w [msgcat::mc "Export Plugin"]
    wm transient $w .

    ttk::frame     $w.tf
    ttk::label     $w.tf.vl  -text [format "%s: " [msgcat::mc "Version"]]
    ttk::combobox  $w.tf.vcb
    ttk::label     $w.tf.rl  -text [format "%s: \n(%s)" [msgcat::mc "Release Notes"] [msgcat::mc "Markdown"]] -justify center
    ttk::label     $w.tf.ol  -text [format "%s: " [msgcat::mc "Output Directory"]]
    ttk::entry     $w.tf.oe
    ttk::button    $w.tf.ob  -style BButton -text [msgcat::mc "Choose"] -command [list plugmgr::choose_output_dir $w]

    ttk::frame     $w.tf.tf
    text           $w.tf.tf.t  -wrap word -yscrollcommand [list $w.tf.tf.vb set]
    ttk::scrollbar $w.tf.tf.vb -orient vertical -command [list $w.tf.tf.t xview]

    grid rowconfigure    $w.tf.tf 0 -weight 1
    grid columnconfigure $w.tf.tf 0 -weight 1
    grid $w.tf.tf.t  -row 0 -column 0 -sticky news
    grid $w.tf.tf.vb -row 0 -column 1 -sticky ns

    grid rowconfigure $w.tf    1 -weight 1
    grid columnconfigure $w.tf 1 -weight 1
    grid $w.tf.vl  -row 0 -column 0 -sticky nw   -padx 2 -pady 2
    grid $w.tf.vcb -row 0 -column 1 -sticky news -padx 2 -pady 2
    grid $w.tf.rl  -row 1 -column 0 -sticky nw   -padx 2 -pady 2
    grid $w.tf.tf  -row 1 -column 1 -sticky news -padx 2 -pady 2
    grid $w.tf.ol  -row 2 -column 0 -sticky nw   -padx 2 -pady 2
    grid $w.tf.oe  -row 2 -column 1 -sticky news -padx 2 -pady 2
    grid $w.tf.ob  -row 2 -column 2 -sticky news -padx 2 -pady 2

    ttk::separator $w.sep -orient horizontal

    set width [msgcat::mcmax "Export" "Cancel"]

    ttk::frame $w.bf
    ttk::button $w.bf.export -style BButton -text [msgcat::mc "Export"] -width $width -command [list plugmgr::export $w $plugdir] -state disabled
    ttk::button $w.bf.cancel -style BButton -text [msgcat::mc "Cancel"] -width $width -command [list destroy $w]

    pack $w.bf.cancel -side right -padx 2 -pady 2
    pack $w.bf.export -side right -padx 2 -pady 2

    pack $w.tf  -fill both -expand yes
    pack $w.sep -fill x
    pack $w.bf  -fill x

    # Get the field values to populate
    lassign [get_versions $plugdir] version next_versions
    set release_notes [get_release_notes $plugdir]

    # Populate fields
    $w.tf.vcb configure -values $next_versions
    $w.tf.vcb set $version
    $w.tf.tf.t insert end $release_notes
    $w.tf.oe insert end [preferences::get General/DefaultPluginExportDirectory]
    $w.tf.oe configure -state readonly

    # Set the focus on the version entry field
    focus $w.tf.vcb

    # Make sure that the state of the export button is set properly
    handle_export_button_state $w

  }

  ######################################################################
  # Updates the state of the export button.
  proc handle_export_button_state {w {version ""}} {

    if {$version eq ""} {
      set version [$w.tf.vcb get]
    }

    set odir [$w.tf.oe get]

    if {[regexp {^\d+(\.\d+)+$} $version] && ($odir ne "")} {
      $w.bf.export configure -state normal
    } else {
      $w.bf.export configure -state disabled
    }

  }

  ######################################################################
  # If the given value is a valid version value, allow the Export button
  # to be clickable.
  proc check_version {w value} {

    handle_export_button_state $w $value

    return 1

  }

  ######################################################################
  # Allows the user to select an alternative output directory.
  proc choose_output_dir {w} {

    # Get the current output directory
    set initial_dir [$w.tf.oe get]

    if {$initial_dir eq ""} {
      if {[preferences::get General/DefaultPluginExportDirectory] ne ""} {
        set initial_dir [preferences::get General/DefaultPluginExportDirectory]
      } else {
        set initial_dir [gui::get_browse_directory]
      }
    }

    # Get the directory to save the file to
    if {[set odir [tk_chooseDirectory -parent $w -initialdir $initial_dir]] ne ""} {
      $w.tf.oe configure -state normal
      $w.tf.oe delete 0 end
      $w.tf.oe insert end $odir
      $w.tf.oe configure -state disabled
      handle_export_button_state $w
    }

  }

  ######################################################################
  # Get version information from the given plugin directory.
  proc get_versions {plugdir} {

    if {[catch { tkedat::read [file join $plugdir header.tkedat] } rc]} {
      return [list "1.0" {}]
    } else {
      array set header $rc
      set i       0
      set version [split $header(version) .]
      foreach num $version {
        if {$i == 0} {
          lappend next_versions "[expr $num + 1].0"
        } else {
          lappend next_versions [join [list {*}[lrange $version 0 [expr $i - 1]] [expr $num + 1]] .]
        }
        incr i
      }
      set next_versions [linsert $next_versions end-1 [join [list {*}$version 1] .]]
      return [list $header(version) [lreverse $next_versions]]
    }

  }

  ######################################################################
  # Get release notes from the given plugin directory.
  proc get_release_notes {plugdir} {

    if {[catch { open [file join $plugdir release_nodes.md] r } rc]} {
      return ""
    }

    set contents [read $rc]
    close $rc

    return $contents

  }

  ######################################################################
  # Update the version information.
  proc update_version {plugdir version} {

    set header [file join $plugdir header.tkedat]

    if {[catch { tkedat::read $header 0 } rc]} {
      return -code error "Unable to read header.tkedat"
    }

    array set contents $rc

    if {$version ne $contents(version)} {
      set contents(version) $version
      if {[catch { tkedat::write $header [array get contents] 0 } rc]} {
        return -code error "Unable to write header.tkedat"
      }
    }

  }

  ######################################################################
  # Updates the given release notes.
  proc update_release_notes {plugdir notes} {

    set release_notes [file join $plugdir release_notes.md]

    if {[catch { open $release_notes w } rc]} {
      return -code error "Unable to write release notes"
    }

    puts $rc $notes
    close $rc

  }

  ######################################################################
  # Takes the version number and the release notes and puts them into the
  # plugin directory and then perform the bundling process.
  proc export {w plugdir} {

    # Get the values from the interface
    set version       [$w.tf.vcb get]
    set release_notes [$w.tf.tf.t get 1.0 end-1c]
    set odir          [$w.tf.oe get]

    # Update the version information
    update_version $plugdir $version

    # Update the release notes
    update_release_notes $plugdir $release_notes

    # Create the plugin bundle
    if {[plugins::export_plugin . [file tail $plugdir] $odir]} {
      gui::set_info_message [msgcat::mc "Plugin export completed successfully"]
    }

    # Destroy the window
    destroy $w

  }

  ######################################################################
  # Creates the main pluging manager window.
  proc manager_win {} {

    variable widgets

    set w [toplevel .pmwin]
    wm title     $w [msgcat::mc "Plugin Manager"]
    wm transient $w .

    set bwidth [msgcat::mcmax "Available" "Installed"]

    ttk::frame  $w.nf
    ttk::frame  $w.nf.f
    set widgets(available_btn) [ttk::button $w.nf.f.avail   -style BButton -text [msgcat::mc "Available"] -width $bwidth -command plugmgr::available_selected]
    set widgets(installed_btn) [ttk::button $w.nf.f.install -style BButton -text [msgcat::mc "Installed"] -width $bwidth -command plugmgr::installed_selected]

    bind $widgets(available_btn) <Leave> {
      after idle {
        if {$plugmgr::last_pane eq "available"} {
          %W state active
        }
      }
    }
    bind $widgets(installed_btn) <Leave> {
      after idle {
        if {$plugmgr::last_pane eq "installed"} {
          %W state active
        }
      }
    }

    pack $w.nf.f.avail   -side left -padx 4 -pady 2
    pack $w.nf.f.install -side left -padx 4 -pady 2

    pack $w.nf.f -side top

    set widgets(nb) [ttk::notebook $w.nb -style Plain.TNotebook]

    $widgets(nb) add [set widgets(available) [create_available_pane $widgets(nb).avail]]
    $widgets(nb) add [set widgets(installed) [create_installed_pane $widgets(nb).install]]
    $widgets(nb) add [set widgets(detail)    [create_detail_pane    $widgets(nb).detail]]

    pack $w.nf        -fill x
    pack $widgets(nb) -fill both -expand yes

    # Make sure that everything looks correct theme-wise
    update_theme

    # Load the plugin database from the server
    load_database

    # Make the available notebook pane the visible panel
    available_selected

  }

  ######################################################################
  # Create the available plugin pane.
  proc create_table_pane {w type} {

    variable widgets

    ttk::frame $w

    ttk::frame $w.sf
    set widgets($type,search) [wmarkentry::wmarkentry $w.sf.e -validate key -validatecommand [list plugmgr::do_search $type %P] -width 30 -watermark [msgcat::mc "Search"]]

    if {$type eq "installed"} {
      set widgets($type,pupdate) [ttk::button $w.sf.upd -style BButton -text [msgcat::mc "Update All"] -command plugmgr::pupdate_all]
      pack $w.sf.upd -side right -padx 2 -pady 2
    }

    pack $w.sf.e -side left -padx 2 -pady 2

    ttk::frame $w.lf
    set widgets($type,table) [tablelist::tablelist $w.lf.tl -columns [list 0 [msgcat::mc "Plugins"]] \
      -stretch all -exportselection 1 -selectmode browse -showlabels 0 -relief flat -bd 0 -highlightthickness 0 \
      -yscrollcommand [list $w.lf.vb set]]
    set widgets($type,scroll) [scroller::scroller $w.lf.vb -orient vertical -command [list $w.lf.tl yview]]

    $widgets($type,table) columnconfigure 0 -name plugin -stretchable 1 -wrap 1 -editable 0 -formatcommand plugmgr::format_plugin_cell

    bind [$widgets($type,table) bodytag] <Return>          plugmgr::show_detail
    bind [$widgets($type,table) bodytag] <Double-Button-1> plugmgr::show_detail

    grid rowconfigure    $w.lf 0 -weight 1
    grid columnconfigure $w.lf 0 -weight 1
    grid $w.lf.tl -row 0 -column 0 -sticky news
    grid $w.lf.vb -row 0 -column 1 -sticky ns

    pack $w.sf -fill x                -padx 2 -pady 4
    pack $w.lf -fill both -expand yes -padx 2 -pady 4

    return $w

  }

  ######################################################################
  # Make sure that the plugin cell does not display the data natively.
  proc format_plugin_cell {value} {

    return ""

  }

  ######################################################################
  # Creates the available plugin pane.
  proc create_available_pane {w} {

    return [create_table_pane $w available]

  }

  ######################################################################
  # Creates the installed plugin pane.
  proc create_installed_pane {w} {

    return [create_table_pane $w installed]

  }

  ######################################################################
  # Creates the detail pane.
  proc create_detail_pane {w} {

    variable widgets

    ttk::frame $w

    set bwidth [msgcat::mcmax "Back" "Install" "Uninstall" "Update" "Delete"]

    ttk::frame $w.bf
    set widgets(back)      [ttk::button $w.bf.back      -style BButton -compound left -image search_prev -text [msgcat::mc "Back"]      -width $bwidth -command [list plugmgr::go_back]]
    set widgets(install)   [ttk::button $w.bf.install   -style BButton -text [msgcat::mc "Install"]   -width $bwidth -command [list plugmgr::install]]
    set widgets(pupdate)   [ttk::button $w.bf.pupdate   -style BButton -text [msgcat::mc "Update"]    -width $bwidth -command [list plugmgr::pupdate]]
    set widgets(uninstall) [ttk::button $w.bf.uninstall -style BButton -text [msgcat::mc "Uninstall"] -width $bwidth -command [list plugmgr::uninstall]]

    grid rowconfigure    $w.bf 0 -weight 1
    grid columnconfigure $w.bf 1 -weight 1
    grid $w.bf.back      -row 0 -column 0 -sticky news -padx 4 -pady 2
    grid $w.bf.install   -row 0 -column 2 -sticky news -padx 4 -pady 2
    grid $w.bf.pupdate   -row 0 -column 3 -sticky news -padx 4 -pady 2
    grid $w.bf.uninstall -row 0 -column 4 -sticky news -padx 4 -pady 2

    # Create HTML viewer
    ttk::frame $w.hf
    set widgets(html)    [text $w.hf.t -highlightthickness 0 -bd 0 -cursor arrow -yscrollcommand [list $w.hf.vb set]]
    set widgets(html,vb) [scroller::scroller $w.hf.vb -orient vertical   -command [list $w.hf.t yview]]

    # Make the HTML text widget setup to show HTML syntax
    HMinitialize $widgets(html)

    grid rowconfigure    $w.hf 0 -weight 1
    grid columnconfigure $w.hf 0 -weight 1
    grid $w.hf.t  -row 0 -column 0 -sticky news
    grid $w.hf.vb -row 0 -column 1 -sticky ns

    pack $w.bf -fill x                -padx 2 -pady 2
    pack $w.hf -fill both -expand yes -padx 2 -pady 2

    return $w

  }

  ######################################################################
  # Handle the Back button being pressed in the detail pane.
  proc go_back {} {

    variable last_pane

    # Run the last pane's select command
    ${last_pane}_selected

  }

  ######################################################################
  # Called when the available tab is selected.
  proc available_selected {} {

    variable widgets
    variable last_pane

    # Remember that this pane was selected
    set last_pane available

    # Select the available pane
    $widgets(nb) select $widgets(available)

    $widgets(available_btn) state  active
    $widgets(installed_btn) state !active

    # Populate the table
    populate_plugin_table "available"

    # Give the search panel the focus
    focus $widgets(available,search)

  }

  ######################################################################
  # Called when the available tab is selected.
  proc installed_selected {} {

    variable widgets
    variable last_pane

    # Remember that this pane was selected
    set last_pane installed

    # Select the installed pane
    $widgets(nb) select $widgets(installed)

    $widgets(available_btn) state !active
    $widgets(installed_btn) state  active

    # Populate the plugin table
    populate_plugin_table "installed"

    # Give the search panel the focus
    focus $widgets(installed,search)

  }

  ######################################################################
  # Populates the table of the given type with the needed plugin data.
  proc populate_plugin_table {type} {

    variable widgets
    variable database

    # Clear the table
    $widgets($type,table) delete 0 end

    array set db_plugins $database(plugins)

    set installed  [expr {($type eq "available") ? 0 : 1}]
    set updateable 0

    foreach name [lsort [array names db_plugins]] {
      array set data $db_plugins($name)
      if {$data(installed) == $installed} {
        append_plugin $type $data(display_name) $data(description) $name
      }
      incr updateable $data(update_avail)
    }

    if {$updateable} {
      pack $widgets(installed,pupdate) -side right -padx 4 -pady 2
    } else {
      pack forget $widgets(installed,pupdate)
    }

  }

  ######################################################################
  # Adds the given plugin to the given table.
  proc append_plugin {type name detail id} {

    variable widgets

    $widgets($type,table) insert end [list [list $name $detail $id]]
    $widgets($type,table) cellconfigure end,plugin -stretchwindow 1 -window plugmgr::make_plugin_cell -windowupdate plugmgr::update_plugin_cell

  }

  ######################################################################
  # Create the plugin cell and populate it with the appropriate text.
  proc make_plugin_cell {tbl row col win} {

    variable last_pane

    array set ttk_theme [theme::get_category_options ttk_style 1]
    array set theme     [theme::get_syntax_colors]

    lassign [$tbl cellcget $row,$col -text] name detail id

    text $win -wrap word -height 1 -relief flat -highlightthickness 0 -bd 0 -cursor [ttk::cursor standard] -background $theme(background) -foreground $theme(foreground)

    bind $win <Configure> [list plugmgr::update_height %W]
    bindtags $win [linsert [bindtags $win] 1 [$tbl bodytag] TablelistBody]

    if {[get_database_attr $id update_avail]} {
      set txt [list "\n" {} $name header "\t\t(Update Available)" pupdate "\n\n$detail\n" body]
    } else {
      set txt [list "\n" {} $name header "\n\n$detail\n" body]
    }

    $win tag configure header  -font [list -size 14 -weight bold] -foreground $theme(keywords)
    $win tag configure pupdate -foreground $theme(miscellaneous1) -justify right
    $win tag configure body    -lmargin1 20 -lmargin2 20
    $win insert end {*}$txt
    $win configure -state disabled

    return $win

  }

  ######################################################################
  # Updates the given plugin cell contents.
  proc update_plugin_cell {tbl row col win args} {

    array set opts $args

    foreach {opt value} $args {
      if {$value ne ""} {
        $win configure $opt $value
      }
    }

  }

  ######################################################################
  # Updates the height of the given text widget.
  proc update_height {txt} {

    $txt configure -height [expr [$txt count -displaylines 1.0 end] + 1]

    [winfo parent $txt] configure -height [winfo reqheight $txt]

  }

  ######################################################################
  # Creates the overview HTML code and returns this value.
  proc make_overview_html {name} {

    variable database

    array set db_plugins $database(plugins)

    if {![info exists db_plugins($name)]} {
      return ""
    }

    array set data $db_plugins($name)

    # Create the HTML code to display
    append html "<h1>$data(display_name)</h1><hr>"

    if {$data(overview) ne ""} {
      append html "$data(overview)<br><br><hr>"
    }

    if {$data(release_notes) ne ""} {
      append html "<h4>Release Notes</h4><dl>$data(release_notes)</dl>"
    }

    append html "<h4>Version</h4><dl>$data(version)</dl>"

    if {$data(author) ne ""} {
      append html "<h4>Author</h4><dl>$data(author)</dl>"
    } else {
      append html "<h4>Author</h4><dl>Anonymous</dl>"
    }

    if {$data(email) ne ""} {
      append html "<h4>E-mail</h4><dl><a href=\"mailto:$data(email)\">$data(email)</a></dl>"
    }

    if {$data(website) ne ""} {
      append html "<h4>Website</h4><dl><a href=\"$data(website)\">$data(website)</a></dl>"
    }

    return $html

  }

  ######################################################################
  # Displays the plugin detail in the detail pane.
  proc show_detail {} {

    variable widgets
    variable current_id
    variable database
    variable last_pane

    # Get the currently selected row
    set selected [$widgets($last_pane,table) curselection]

    # Get the plugin ID
    set current_id [lindex [$widgets($last_pane,table) cellcget $selected,plugin -text] 2]

    # Get the content to display
    set html [make_overview_html $current_id]

    # Clear the detail text widget
    $widgets(html) configure -state normal
    $widgets(html) delete 1.0 end

    # Add the HTML to the HTML widget
    HMparse_html $html "HMrender $widgets(html)"

    # Configure the text widget to be disabled
    $widgets(html) configure -state disabled

    if {$last_pane eq "available"} {
      grid remove $widgets(uninstall)
      grid remove $widgets(pupdate)
      grid $widgets(install)
    } else {
      grid remove $widgets(install)
      grid $widgets(uninstall)
      if {[get_database_attr $current_id update_avail]} {
        grid $widgets(pupdate)
      } else {
        grid remove $widgets(pupdate)
      }
    }

    # Display the detail pane
    $widgets(nb) select $widgets(detail)

  }

  ######################################################################
  # Installs the given plugin from memory.
  proc install {} {

    variable widgets
    variable current_id

    # Download the file
    if {[set fname [get_bundle_fname $current_id]] eq ""} {
      show_error_message [msgcat::mc "Failed to download plugin bundle"]
      return
    }

    # Import the file
    plugins::import_plugin .pmwin $fname

    # Delete the bundle file
    catch { file delete -force $fname }

    # Reload the plugin information
    plugins::load

    # Get the plugin index
    if {[set index [plugins::get_plugin_index $current_id]] eq ""} {
      return
    }

    # Perform the plugin install
    plugins::install_item $index

    # Set the database installed value
    set_database_attr $current_id installed 1

    # Save the database
    save_database

    # Update the UI state of the pane
    grid remove $widgets(install)
    grid remove $widgets(pupdate)
    grid $widgets(uninstall)

  }

  ######################################################################
  # Updates the given plugin from memory.
  proc pupdate {} {

    variable widgets
    variable current_id
    variable database

    # Download the file
    if {[set fname [get_bundle_fname $current_id]] eq ""} {
      show_error_message [msgcat::mc "Failed to download plugin bundle"]
      return
    }

    # Import the file
    plugins::import_plugin .pmwin $fname

    # Delete the file
    catch { file delete -force $fname }

    # Perform the plugin install
    plugins::reload

    # Specify that the update is no longer available
    set_database_attr $current_id update_avail 0

    # Save the database
    save_database

    # Update the UI state of the pane
    grid remove $widgets(pupdate)

  }

  ######################################################################
  # Update all of the plugins that are upgradable.
  proc pupdate_all {} {

    variable widgets
    variable database

    array set db_plugins $database(plugins)

    # Import the plugins that have an update available
    foreach name [array names db_plugins] {
      array set data $db_plugins($name)
      if {$data(update_avail)} {
        if {[set fname [get_bundle_fname $name]] eq ""} {
          lappend error_plugins $name
        } else {
          plugins::import_plugin .pmwin $fname
          catch { file delete -force $fname }
          set data(update_avail) 0
          set db_plugins($name)  [array get data]
        }
      }
    }

    # Reload the plugins
    plugins::reload

    # Save the database changes
    array set database(plugins) [array get db_plugins]

    # Save the database
    save_database

    if {[llength $error_plugins] > 0} {
      show_error_message [msgcat::mc "Failed to download the following plugin bundles:"] $error_plugins
    } else {
      pack forget $widgets(installed,pupdate)
    }

  }

  ######################################################################
  # Uninstalls the given plugin from memory.
  proc uninstall {} {

    variable widgets
    variable current_id

    # Get the plugin index
    if {[set index [plugins::get_plugin_index $current_id]] eq ""} {
      return
    }

    # Uninstall the item
    plugins::uninstall_item $index

    # Delete the data
    catch { file delete -force [file join $::tke_home iplugins $current_id] }

    # Save the fact that the plugin is no longer installed
    set_database_attr $current_id installed 0

    # Save the database
    save_database

    # Update the UI state of the pane
    grid remove $widgets(uninstall)
    grid remove $widgets(pupdate)
    grid $widgets(install)

  }

  ######################################################################
  # Performs search with the given value.
  proc do_search {type value} {

    variable widgets

    set tbl      $widgets($type,table)
    set tbl_size [$tbl size]

    if {$value eq ""} {
      for {set i 0} {$i < $tbl_size} {incr i} {
        $tbl rowconfigure $i -hide 0
      }
    } else {
      for {set i 0} {$i < $tbl_size} {incr i} {
        set txt [$tbl windowpath $i,plugin].t
        $tbl rowconfigure $i -hide [expr {[$txt search -nocase -exact -- $value 1.0] ne ""} ? 0 : 1]
      }
    }

    return 1

  }

  ######################################################################
  # This is called whenever the theme changes.
  proc update_theme {} {

    variable widgets

    # If the window does not exist, just return
    if {![winfo exists .pmwin]} {
      return
    }

    array set theme  [theme::get_category_options ttk_style 1]
    array set syntax [theme::get_syntax_colors]

    $widgets(available,table)  configure -background $theme(background) -foreground $theme(foreground)
    $widgets(available,scroll) configure -background $theme(background) -foreground $theme(foreground)
    $widgets(installed,table)  configure -background $theme(background) -foreground $theme(foreground)
    $widgets(installed,scroll) configure -background $theme(background) -foreground $theme(foreground)
    $widgets(html,vb)          configure -background $syntax(background) -foreground $syntax(foreground)

    # Update the HTML view colors
    $widgets(html) configure -background $syntax(background) -foreground $syntax(foreground)

    $widgets(html) tag configure link -foreground $syntax(miscellaneous1) -relief flat
    $widgets(html) tag configure h4   -foreground $syntax(keywords)
    $widgets(html) tag configure code -background $syntax(numbers) -foreground $syntax(background)

  }

  ######################################################################
  # Loads the plugin database file from the server.
  proc load_database {} {

    variable database

    set url "http://tke.sourceforge.net/plugins/plugins.tkedat"

    # Download the database to a local file
    if {[set fname [utils::download_url $url]] eq ""} {
      show_error_message [msgcat::mc "Unable to fetch plugin database"]
      return
    }

    # Load the downloaded file
    if {[catch { tkedat::read $fname } rc]} {
      file delete -force $fname
      show_error_message [msgcat::mc "Unable to load plugin database file"]
      return
    }

    catch { file delete -force $fname }

    # Make sure that the database is cleared
    array unset database

    array set database    $rc
    array set new_plugins $database(plugins)

    # Initialize the new plugins database
    foreach name [array names new_plugins] {
      array set new_plugin $new_plugins($name)
      set new_plugin(update_avail) 0
      set new_plugin(installed)    0
      set new_plugins($name) [array get new_plugin]
    }

    # Load the local file and compare the old versions to the new versions
    if {![catch { tkedata::read [file join $::tke_home iplugins plugins.tkedat] } rc]} {

      array set old_data    $rc
      array set old_plugins $old_data(plugins)

      # Cross-reference the old database with the new, updating the new
      foreach name [array names old_plugins] {
        if {[info exists new_plugins($name)]} {
          array set old_plugin $old_plugins($name)
          array set new_plugin $new_plugins($name)
          set new_plugin(update_avail) [expr {$old_plugin(version) ne $new_plugin(version)}]
          set new_plugin(installed)    1
          set new_plugins($name) [array get new_plugin]
        }
      }

    }

    # Save the new plugins data back to the database
    set database(plugins) [array get new_plugins]

  }

  ######################################################################
  # Saves the internal database structure to the local plugins database file.
  proc save_database {} {

    variable database

    if {[catch { tkedat::write [file join $::tke_home iplugins plugins.tkedat] [array get database] } rc]} {
      return -code error "Unable to update the plugin database file"
    }

  }

  ######################################################################
  # Retrieves the specified attribute value from the database.
  proc get_database_attr {id attr} {

    variable database

    array set db_plugins $database(plugins)
    array set data       $db_plugins($id)

    return $data($attr)

  }

  ######################################################################
  # Sets the given database attribute to the specified value.
  proc set_database_attr {id attr value} {

    variable database

    array set db_plugins $database(plugins)
    array set data       $db_plugins($id)

    set data($attr)       $value
    set db_plugins($id)   [array get data]
    set database(plugins) [array get db_plugins]

  }

  ######################################################################
  # Returns the necessary URL to download the given plugin package.
  proc get_bundle_fname {id} {

    set url "http://tke.sourceforge.net/plugins/$id.tkeplugz"

    return [utils::download_url $url]

  }

  ######################################################################
  # Displays the given error message for the plugin manager.
  proc show_error_message {msg {detail ""}} {

    tk_messageBox -parent .pmwin -icon error -title [msgcat::mc "Error"] -type ok -default ok -message $msg -detail $detail

  }

}


