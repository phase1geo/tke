######################################################################
# Name:    utils.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    01/03/2017
# Brief:   Contains utility procedures used by specl files.
######################################################################

namespace eval specl {

  # Values to pass to the second argument of the check_for_update procedure.
  variable RTYPE_STABLE 1
  variable RTYPE_DEVEL  2

  variable appname      ""
  variable version      ""
  variable release      1
  variable rss_url      ""
  variable download_url ""
  variable oses         {linux mac win}

  ######################################################################
  # Loads the specl version file.
  proc load_specl_version {specl_version_dir} {

    # Read the version and URL information
    if {[catch "source [file join $specl_version_dir specl_version.tcl]" rc]} {
      return -code error $rc
    }

  }

}

namespace eval specl::utils {

  array set xignore    {}
  array set xignore_id {}

  ######################################################################
  # Returns the MD5 checksum for the given bundle.
  proc get_checksum {bundle} {

    # On Mac OSX, the md5sum executable is just called "md5" and its output is a bit different
    if {$::tcl_platform(os) eq "Darwin"} {
      if {[catch { exec -ignorestderr md5 $bundle } rc]} {
        return ""
      }
      return [lindex $rc 3]

    # Otherwise, use the normal md5sum
    } else {
      if {[catch { exec -ignorestderr md5sum $bundle } rc]} {
        return ""
      }
      return [lindex $rc 0]
    }

  }

  ######################################################################
  # Returns the node content found within the given parent node.
  proc get_elements {node name} {

    set ref [dom::document getElementsByTagName $node $name]

    return [set $ref]

  }

  ######################################################################
  # Returns a single element node.
  proc get_element {node name} {

    if {[llength [set elements [get_elements $node $name]]] == 0} {
      return -code error "Unable to find element node $name"
    }

    return [lindex $elements 0]

  }

  ######################################################################
  # Returns the data located inside the node text element.
  proc get_text {node} {

    return [dom::node cget [dom::node cget $node -firstChild] -nodeValue]

  }

  ######################################################################
  # Returns the data located inside the CDATA element.
  proc get_cdata {node} {

    return [dom::node cget [dom::node cget [dom::node cget $node -firstChild] -nextSibling] -nodeValue]

  }

  ######################################################################
  # Searches for and returns the attribute in the specified parent.
  proc get_attr {parent name} {

    return [dom::element getAttribute $parent $name]

  }

  ######################################################################
  # Returns a unique pathname in the given directory.
  proc get_unique_path {dpath fname} {

    set path  [file join $dpath $fname]
    set index 0
    while {[file exists $path]} {
      set path [file join $dpath "$fname ([incr index])"]
    }

    return [file normalize $path]

  }

  ###########################################################################
  # Performs the set operation on a given yscrollbar.
  proc set_yscrollbar {sb first last} {

    # If everything is displayed, hide the scrollbar
    if {($first == 0) && (($last == 1) || ($last == 0))} {
      grid remove $sb
    } else {
      grid $sb
      $sb set $first $last
    }

  }

  ######################################################################
  # Performs the set operation on a given xscrollbar.
  proc set_xscrollbar {sb first last} {

    variable xignore
    variable xignore_id

    if {($first == 0) && ($last == 1)} {
      grid remove $sb
      set_xignore $sb 1 0
      set xignore_id($sb) [after 1000 [list specl::utils::set_xignore $sb 0 1]]
    } else {
      if {![info exists xignore($sb)] || !$xignore($sb)} {
        grid $sb
        $sb set $first $last
      }
      set_xignore $sb 0 0
    }

  }

  ######################################################################
  # Clears the xignore and xignore_id values.
  proc set_xignore {sb value auto} {

    variable xignore
    variable xignore_id

    # Clear the after (if it exists)
    if {[info exists xignore_id($sb)]} {
      after cancel $xignore_id($sb)
      unset xignore_id($sb)
    }

    # Set the xignore value to the specified value
    set xignore($sb) $value

  }

  ######################################################################
  # Opens the given filename in an external application, using one of the
  # open terminal commands to determine the proper application to use.
  proc open_file_externally {fname {in_background 0}} {

    set opts ""

    switch -glob $::tcl_platform(os) {
      Darwin {
        if {$in_background} {
          set opts "-g"
        }
        catch { exec open {*}$opts $fname }
      }
      Linux* {
        catch { exec xdg-open $fname }
      }
      *Win* {
        catch { exec os.startfile $fname }
      }
    }

  }

  ######################################################################
  # Creates a bold font and returns its value.
  proc bold_font {} {

    return [font create {*}[font actual TkDefaultFont] -weight bold]

  }

  ######################################################################
  # Initializes the given text widget to render HTML via htmllib.
  proc HMinitialize {win} {

    # Initialize the text widget to display HTML
    HMinit_win $win

    # Set <ul> symbols
    HMset_state $win -symbols [string repeat \u2022\u2023\u25e6\u2043 5]

  }

  ######################################################################
  # Handles the creation of an image.
  proc HMhandle_image {win handle src} {

    variable animation_ids

    # Initialize tfile to indicate that it was not used
    set tfile ""

    # If the file is from the web, download it
    if {[string first "http" $src] == 0} {
      set tfile [file join / tmp tmp.[pid]]
      set outfl [open $tfile w]
      http::geturl $src -channel $outfl
      close $outfl
      set src $tfile
    }

    # Load the GIF information
    set depth 0
    if {![catch { gifblock::gif.load blocks $tfile } rc]} {
      set depth [llength [set gc_blocks [lsearch -all [gifblock::gif.blocknames blocks] {Graphic Control}]]]
    }

    # Create the image from the file
    if {$depth == 0} {
      if {[catch { image create photo -file $src } img_list]} {
        puts $::errorInfo
        return
      }
    } else {
      for {set i 0} {$i < $depth} {incr i} {
        if {![catch { image create photo -file $tfile -format "gif -index $i" } img]} {
          lappend img_list [list $img [expr [gifblock::gif.get blocks [lindex $gc_blocks $i] {delay time}] * 10]]
        }
      }
    }

    # Delete the temporary file if set
    if {$tfile ne ""} {
      file delete $tfile
    }

    # If this is an animated GIF, display the next image in the series after the given period of time
    if {[llength $img_list] > 1} {
      set animation_ids($handle) [after [lindex $img_list 0 1] [list specl::utils::HMcycle_image $handle 1 $img_list]]
    }

    # Display the image
    HMgot_image $handle [lindex $img_list 0 0]

  }

  ######################################################################
  # Handles an animated GIF.
  proc HMcycle_image {handle pos img_list} {

    variable animation_ids

    if {[winfo exists $handle]} {

      lassign [lindex $img_list $pos] img delay

      # Display the image
      HMgot_image $handle $img

      # Increment the position
      incr pos
      if {$pos >= [llength $img_list]} { set pos 0 }

      # Cycle again
      set animation_ids($handle) [after $delay [list specl::utils::HMcycle_image $handle $pos $img_list]]

    }

  }

  ######################################################################
  # Cancels all animations for the current window.
  proc HMcancel_animations {} {

    variable animation_ids

    # Cancel all of the outstanding IDs
    foreach {handle id} [array get animation_ids] {
      after cancel $id
    }

    # Clear all of the IDs
    array unset animation_ids

  }

}

