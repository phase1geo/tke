# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2018  Trevor Williams (phase1geo@gmail.com)
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

  array set database {}
  array set widgets  {}

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
    text           $w.tf.tf.t  -wrap word -xscrollcommand [list $w.tf.tf.vb set] -yscrollcommand [list $w.tf.tf.hb set]
    ttk::scrollbar $w.tf.tf.vb -orient vertical   -command [list $w.tf.tf.t yview]
    ttk::scrollbar $w.tf.tf.hb -orient horizontal -command [list $w.tf.tf.t xview]

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
    # load_database

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

    pack $w.sf.e -side left -padx 2 -pady 2

    ttk::frame     $w.lf
    set widgets($type,table) [tablelist::tablelist $w.lf.tl -columns [list 0 [msgcat::mc "Plugins"]] \
      -stretch all -exportselection 1 -selectmode browse -showlabels 0 -relief flat -bd 0 -highlightthickness 0 \
      -yscrollcommand [list $w.lf.vb set]]
    set widgets($type,scroll) [scroller::scroller $w.lf.vb -orient vertical -command [list $w.lf.tl yview]]

    $widgets($type,table) columnconfigure 0 -name plugin -stretchable 1 -wrap 1 -editable 0 -formatcommand plugmgr::format_plugin_cell

    bind [$widgets($type,table) bodytag] <Return> [list plugmgr::show_detail $type]

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
    set widgets(back)      [ttk::button $w.bf.back      -style BButton -text [msgcat::mc "Back"]      -width $bwidth -command [list plugmgr::go_back]]
    set widgets(install)   [ttk::button $w.bf.install   -style BButton -text [msgcat::mc "Install"]   -width $bwidth -command [list plugmgr::install]]
    set widgets(pupdate)   [ttk::button $w.bf.update    -style BButton -text [msgcat::mc "Update"]    -width $bwidth -command [list plugmgr::pupdate]
    set widgets(uninstall) [ttk::button $w.bf.uninstall -style BButton -text [msgcat::mc "Uninstall"] -width $bwidth -command [list plugmgr::uninstall]]
    set widgets(delete)    [ttk::button $w.bf.delete    -style BButton -text [msgcat::mc "Delete"]    -width $bwidth -command [list plugmgr::delete]]

    grid rowconfigure    $w.bf 0 -weight 1
    grid columnconfigure $w.bf 1 -weight 1
    grid $w.bf.back      -row 0 -column 0 -sticky news -padx 4 -pady 2
    grid $w.bf.install   -row 0 -column 2 -sticky news -padx 4 -pady 2
    grid $w.bf.pupdate   -row 0 -column 3 -sticky news -padx 4 -pady 2
    grid $w.bf.uninstall -row 0 -column 4 -sticky news -padx 4 -pady 2
    grid $w.bf.delete    -row 0 -column 5 -sticky news -padx 4 -pady 2

    # Create HTML viewer
    ttk::frame $w.hf
    set widgets(html)    [text $w.hf.t -highlightthickness 0 -bd 0 \
                                       -xscrollcommand [list $w.hf.hb set] -yscrollcommand [list $w.hf.vb set]]
    set widgets(html,vb) [scroller::scroller $w.hf.vb -orient vertical   -command [list $w.hf.t yview]]
    set widgets(html,hb) [scroller::scroller $w.hf.hb -orient horizontal -command [list $w.hf.t xview]]

    # Make the HTML text widget setup to show HTML syntax
    HMinitialize $widgets(html)

    grid rowconfigure    $w.hf 0 -weight 1
    grid columnconfigure $w.hf 0 -weight 1
    grid $w.hf.t  -row 0 -column 0 -sticky news
    grid $w.hf.vb -row 0 -column 1 -sticky ns
    grid $w.hf.hb -row 1 -column 0 -sticky ew

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

    # Give the search panel the focus
    focus $widgets(available,search)

    # Populate the table
    populate_plugin_table "available"

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

    # Give the search panel the focus
    focus $widgets(installed,search)

    # Populate the plugin table
    populate_plugin_table "installed"

  }

  ######################################################################
  # Populates the table of the given type with the needed plugin data.
  proc populate_plugin_table {type} {

    variable widgets
    variable database

    # Clear the table
    $widgets($type,table) delete 0 end

    # Put some dummy data in it
    if {$type eq "available"} {
      append_plugin $type "Best Plugin Ever" "This plugin does some really incredible things so you gotta get it!  I am so inspired to do something really great right now.\n\nAre you too?" 0
      append_plugin $type "Good Plugin" "Doing everything all over again" 1
    } else {
      append_plugin $type "Installed Plugin #1" "You already know that this plugin does" 2
      append_plugin $type "Installed Plugin #2" "You already know that this plugin does, too" 2
    }

    foreach name [lsort [array names database]] {
      array set data $database($name)
      append_plugin $type $data(display_name) $data(FOOBAR) $name
    }

    # author        "Anonymous"
    # email         ""
    # website       ""
    # version       "1.0"
    # category      "Miscellaneous"
    # description   ""
    # release_notes ""

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

    lassign [$tbl cellcget $row,$col -text] name detail id

    ttk::frame $win
    text $win.t -wrap word -height 1 -relief flat -highlightthickness 0 -bd 0 -cursor arrow
    ttk::separator $win.sep -orient horizontal

    bind $win.t <Configure>       [list plugmgr::update_height %W]
    bind $win.t <Double-Button-1> [list plugmgr::show_detail $last_pane]
    bindtags $win.t [linsert [bindtags $win.t] 1 TablelistBody]

    pack $win.t   -fill both -expand yes
    pack $win.sep -fill x

    array set theme [theme::get_syntax_colors]

    $win.t tag configure header -font [list -size 14 -weight bold] -foreground $theme(keywords)
    $win.t tag configure body   -lmargin1 20 -lmargin2 20
    $win.t insert end "\n" {} $name header "\n\n$detail\n" body
    $win.t configure -state disabled

    pack $win -fill both -expand yes

    return $win

  }

  ######################################################################
  # Updates the given plugin cell contents.
  proc update_plugin_cell {tbl row col win args} {

    $win.t configure {*}$args

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

    if {![info exists database($name)]} {
      return ""
    }

    array set data $database($name)

    # Create the HTML code to display
    append html "<h1>$data(display_name)</h1>"
    append html "<h3>Version</h3>$data(version)<br/>"
    append html "$data(overview)<br/>"
    append html "<h3>Author</h3>$data(author)<br/>"
    append html "<h3>E-mail</h3>$data(author)<br/>"
    append html "<h3>Website</h3>$data(website)<br/>"

    return $html

  }

  ######################################################################
  # Displays the plugin detail in the detail pane.
  proc show_detail {type} {

    variable widgets
    variable current_id
    variable database

    # Get the currently selected row
    set selected [$widgets($type,table) curselection]

    # Get the plugin ID
    set current_id [lindex [$widgets($type,table) cellcget $selected,plugin -text] 2]

    # Get the content to display
    set html [make_overview_html $current_id]

    # Add the HTML to the HTML widget
    HMparse_html $html "HMrender $widgets(html)"

    # Configure the text widget to be disabled
    $widgets(html) configure -state disabled

    if {$type eq "available"} {
      grid remove $widgets(uninstall)
      grid remove $widgets(delete)
      grid $widgets(install)
    } else {
      $widgets(delete)  configure -state normal
      grid remove $widgets(install)
      grid $widgets(uninstall)
      grid $widgets(delete)
    }

    # Display the detail pane
    $widgets(nb) select $widgets(detail)

  }

  ######################################################################
  # Installs the given plugin from memory.
  proc install {} {

    variable widgets
    variable current_id

    set url "https://FOOBAR/$current_id.tkeplugz"

    # Download the file
    if {[set fname [download_url $url]] eq ""} {
      return -code error "Failed to download plugin bundle"
    }

    # Import the file
    plugins::import_plugin .pmwin $fname
 
    # Reload the plugin information
    plugins::load

    # Get the plugin index
    if {[set index [plugins::get_plugin_index $current_id]] eq ""} {
      return
    }

    # Perform the plugin install
    plugins::install_item $index

    # Update the UI state of the pane
    grid remove $widgets(install)
    grid remove $widgets(pupdate)
    grid $widgets(uninstall)
    grid $widgets(delete)
    $widgets(delete) configure -state normal

  }

  ######################################################################
  # Updates the given plugin from memory.
  proc pupdate {} {

    variable widgets
    variable current_id

    set url "https://FOOBAR/$current_id.tkeplugz"

    # Download the file
    if {[set fname [download_url $url]] eq ""} {
      return -code error "Failed to download plugin bundle"
    }

    # Import the file
    plugins::import_plugin .pmwin $fname
 
    # Perform the plugin install
    plugins::reload

    # Update the UI state of the pane
    grid remove $widgets(pupdate)

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

    # Update the UI state of the pane
    grid remove $widgets(uninstall)
    grid remove $widgets(pupdate)
    grid $widgets(install)

  }

  ######################################################################
  # Deletes the given plugin from the user's installed plugin directory.
  proc delete {} {

    variable current_id

    # Get the plugin index
    if {[set index [plugins::get_plugin_index $current_id]] eq ""} {
      return
    }

    # Uninstall the item
    plugins::uninstall_item $index

    # Delete the data
    catch { file delete -force [file join $::tke_home iplugins $current_id] }

    # Update the UI state of the pane
    go_back

  }

  ######################################################################
  # This is called whenever the theme changes.
  proc update_theme {} {

    variable widgets

    # If the window does not exist, just return
    if {![winfo exists .pmwin]} {
      return
    }

    array set theme [theme::get_category_options ttk_style 1]

    $widgets(available,table)  configure -background $theme(background) -foreground $theme(foreground)
    $widgets(available,scroll) configure -background $theme(background) -foreground $theme(foreground)
    $widgets(installed,table)  configure -background $theme(background) -foreground $theme(foreground)
    $widgets(installed,scroll) configure -background $theme(background) -foreground $theme(foreground)
    $widgets(html)             configure -background $theme(background) -foreground $theme(foreground)
    $widgets(html,vb)          configure -background $theme(background) -foreground $theme(foreground)
    $widgets(html,hb)          configure -background $theme(background) -foreground $theme(foreground)

  }

  ######################################################################
  # Loads the plugin database file from the server.
  proc load_database {} {

    variable database

    set url "https://TBD/plugins.tkedat"

    # Download the database to a local file
    if {[set fname [utils::download_url $url]] eq ""} {
      return -code error "Unable to fetch plugin database"
    }

    # Load the downloaded file
    if {[catch { tkedat::read $fname } rc]} {
      return -code error "Unable to load plugin database file"
    }

    # Make sure that the database is cleared
    array unset database

    array set data     $rc
    array set database $data(plugins)

    # Load the local file and compare the old versions to the new versions
    if {![catch { tkedata::read $fname } rc]} {

      array set old_data    $rc
      array set old_plugins $old_data(plugins)
      array set new_plugins $database(plugins)

      # Initialize the new plugins database
      foreach name [array names new_plugins] {
        array set new_plugin $new_plugins($name)
        set new_plugin(update_avail) 0
        set new_plugin(installed)    0
        set new_plugins($name) [array get new_plugin]
      }

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

      # Save the new plugins data back to the database
      set database(plugins) [array get new_plugins]

    }

  }

}


