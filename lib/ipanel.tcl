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
# Name:    ipanel.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    08/05/2017
# Brief:   Namespace for an information panel.
######################################################################

# msgcat::note Information panel displayed in the sidebar

namespace eval ipanel {

  array set current {}
  array set widgets {}

  ######################################################################
  # Create the needed images.
  proc create_images {} {

    # If the images have already been created, return immediately
    if {[lsearch [image names] sidebar_info_close] != -1} {
      return
    }

    theme::register_image sidebar_info_close bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar information panel for closing the panel"} \
      -file [file join $::tke_dir lib images close.bmp] \
      -maskfile [file join $::tke_dir lib images close.bmp] \
      -foreground 1

    theme::register_image sidebar_info_refresh bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar information panel for refreshing content"} \
      -file [file join $::tke_dir lib images refresh.bmp] \
      -maskfile [file join $::tke_dir lib images refresh.bmp] \
      -foreground 1

    theme::register_image sidebar_info_show bitmap sidebar -background \
      {msgcat::mc "Image displayed in sidebar information panel for showing file in sidebar"} \
      -file [file join $::tke_dir lib images show.bmp] \
      -maskfile [file join $::tke_dir lib images show.bmp] \
      -foreground 1

  }

  ######################################################################
  # Creates the information panel and returns the pathname to the panel.
  proc create {w args} {

    variable widgets
    variable current

    # Initialize variables
    set current($w) ""

    array set opts {
      -closecmd ""
      -showcmd  ""
      -lastfile ""
    }
    array set opts $args

    # Create images if we need them
    create_images

    # Create file info images
    image create photo  $w,photo_preview
    image create bitmap $w,bitmap_preview

    # Create file info panel
    set widgets($w,f)        [frame $w -class info_panel]
    set widgets($w,fblank)   [label $w.blank -image [image create bitmap -file [file join $::tke_dir lib images blank.bmp]]]
    set widgets($w,fbframe)  [frame $w.bf]
    set widgets($w,frefresh) [label $w.bf.refresh -image sidebar_info_refresh]
    set widgets($w,v,image)  [label $w.preview]
    set widgets($w,f,1)      [frame $w.f1]
    set widgets($w,v,name)   [label $w.name]
    set widgets($w,v,type)   [label $w.type]
    set widgets($w,f,2)      [frame $w.f2]

    bind $widgets($w,frefresh) <Button-1> [list ipanel::update $w]
    bind $widgets($w,f)        <Enter>    [list grid $w.bf]
    bind $widgets($w,f)        <Leave>    [list grid remove $w.bf]

    # Add tooltips to the buttons
    tooltip::tooltip $widgets($w,frefresh) [msgcat::mc "Update Info"]

    if {$opts(-closecmd) ne ""} {
      set widgets($w,fclose) [label $w.bf.close -image sidebar_info_close]
      bind $widgets($w,fclose) <Button-1> [list ipanel::run_command $w $opts(-closecmd)]
      tooltip::tooltip $widgets($w,fclose) [msgcat::mc "Close Panel"]
      pack $widgets($w,fclose) -side right -padx 2 -pady 2
    }

    pack $widgets($w,frefresh) -side right -padx 2 -pady 2

    # If the user has provided a show command
    if {$opts(-showcmd) ne ""} {
      set widgets($w,fshow) [label $w.bf.show -image sidebar_info_show]
      bind $widgets($w,fshow) <Button-1> [list ipanel::run_command $w $opts(-showcmd)]
      tooltip::tooltip $widgets($w,fshow) [msgcat::mc "Show in Sidebar"]
      pack $widgets($w,fshow) -side right -padx 2 -pady 2
    }

    grid rowconfigure    $w 4 -weight 1
    grid columnconfigure $w 1 -weight 1
    grid $w.blank    -row 0 -column 0 -sticky w  -padx 2 -pady 4
    grid $w.bf       -row 0 -column 1 -sticky ne -padx 2 -pady 2
    grid $w.preview  -row 1 -column 0 -rowspan 4 -padx 2 -pady 2
    grid $w.name     -row 2 -column 1 -sticky w
    grid $w.type     -row 3 -column 1 -sticky w

    grid remove $w.bf

    set row 5
    foreach {lbl name copy} [list [msgcat::mc "Modified"] mod 1 [msgcat::mc "Attributes"] attrs 0 \
                                  "MD5" md5 1 "SHA-1" sha1 1 "SHA-224" sha224 1 "SHA-256" sha256 1 \
                                  [msgcat::mc "Counts"] cnts 0 [msgcat::mc "Read Time"] rtime 0 \
                                  [msgcat::mc "Version"] ver 1 [msgcat::mc "Favorite"] fav 0] {
      set widgets($w,l,$name) [label $w.l$name -text [format "%s:" $lbl]]
      set widgets($w,v,$name) [label $w.v$name -anchor w]
      if {$copy} {
        bind $widgets($w,v,$name) <Button-1> [list ipanel::copy_info $w $name]
      }
      grid $widgets($w,l,$name) -row $row -column 0 -sticky e
      grid $widgets($w,v,$name) -row $row -column 1 -sticky w
      incr row
    }

    # Insert any file information plugin information
    # insert_info_panel_plugins $w

    return $w

  }

  ######################################################################
  # Inserts the file information plugin labels into the file information panel.
  proc insert_info_panel_plugins {} {

    variable widgets

    foreach {name w} [array get widgets *,f] {

      # Remove any existing plugins
      foreach name [array names widgets $w,l,plug*] {
        lassign [split $name ,] dummy1 dummy2 pname
        grid forget $widgets($w,l,$pname) $widgets($w,v,$pname)
        destroy $widgets($w,l,$pname) $widgets($w,v,$pname)
      }

      # Forget the previous plugin widgets
      array unset widgets $w,*,plug*

      # Figure out which row we should start inserting
      set row [lindex [grid size $w] 1]

      # Get the colors
      set lfgcolor [$widgets($w,l,mod) cget -foreground]
      set lbgcolor [$widgets($w,l,mod) cget -background]
      set vfgcolor [$widgets($w,v,mod) cget -foreground]
      set vbgcolor [$widgets($w,v,mod) cget -background]

      # Get any file information plugin entries
      foreach {index title copy} [plugins::get_sidebar_info_titles] {

        # Create the widgets
        set widgets($w,l,plug$index) [label $w.pl$index -text "$title:" -foreground $lfgcolor -background $lbgcolor]
        set widgets($w,v,plug$index) [label $w.pv$index -anchor w -foreground $vfgcolor -background $vbgcolor]

        # If the item is copyable, make it so now
        if {$copy} {
          bind $widgets($w,v,plug$index) <Button-1> [list ipanel::copy_info $w plug$index]
        }

        # Insert them into the grid
        grid $w.pl$index -row $row -column 0 -sticky e
        grid $w.pv$index -row $row -column 1 -sticky w -columnspan 3
        incr row

      }

    }

  }

  ######################################################################
  # Updates the file information panel to match the current selections
  proc update {w {fname ""}} {

    variable widgets
    variable current

    # Update the current filename
    if {$fname ne ""} {
      set current($w) $fname
    }

    # Get the list of attributes
    array set attrs [concat {*}[lmap a [preferences::get Sidebar/InfoPanelAttributes] {list $a 1}]]

    # Always display the file name
    $widgets($w,v,name) configure -text [file tail $current($w)]

    # Update all of the fields
    update_image    $w [info exists attrs(preview)] [info exists attrs(imagesize)]
    update_type     $w [info exists attrs(syntax)] [info exists attrs(filesize)]
    update_attrs    $w [info exists attrs(permissions)] [info exists attrs(owner)] [info exists attrs(group)]
    update_counts   $w [info exists attrs(linecount)] [info exists attrs(wordcount)] [info exists attrs(charcount)]
    update_rtime    $w [info exists attrs(readtime)]
    update_checks   $w [info exists attrs(md5)] [info exists attrs(sha1)] [info exists attrs(sha224)] [info exists attrs(sha256)]
    update_mod      $w [info exists attrs(modified)]
    update_version  $w [info exists attrs(version)]
    update_favorite $w [info exists attrs(favorite)]

    # Insert plugin values
    foreach {index value} [plugins::get_sidebar_info_values $current($w)] {
      $widgets($w,v,plug$index) configure -text $value
      if {$value eq ""} {
        grid remove $widgets($w,l,plug$index) $widgets($w,v,plug$index)
      } else {
        grid $widgets($w,l,plug$index) $widgets($w,v,plug$index)
      }
    }

  }

  ######################################################################
  # Update the preview image and name fields.
  proc update_image {w preview imagesize} {

    variable widgets
    variable current

    set fname $current($w)

    if {($preview || $imagesize) && [file isfile $fname]} {
      if {([file extension $fname] eq ".bmp") && ![catch { image create bitmap -file $fname } orig]} {
        $w,bitmap_preview configure -file $fname -foreground [utils::get_default_foreground]
        update_info_image $w $orig $w,bitmap_preview $preview $imagesize
      } elseif {![catch { image create photo -file $fname } orig]} {
        $w,photo_preview blank
        ::image_scale $orig 64 64 $w,photo_preview
        update_info_image $w $orig $w,photo_preview $preview $imagesize
      } else {
        grid remove $widgets($w,v,image)
      }
    } else {
      grid remove $widgets($w,v,image)
    }

  }

  ######################################################################
  # Handle output to the type field.
  proc update_type {w syntax filesize} {

    variable widgets
    variable current

    set fname $current($w)

    if {($syntax || $filesize) && [file isfile $fname]} {
      if {$syntax} {
        if {[set type [$widgets($w,v,type) cget -text]] eq ""} {
          lappend typelist [expr {[utils::is_binary $fname] ? [msgcat::mc "Binary"] : [syntax::get_default_language $fname]}]
        } else {
          lappend typelist [lindex [split $type ,] 0]
        }
      }
      if {$filesize} {
        lappend typelist [utils::get_file_size $fname]
      }
      $widgets($w,v,type) configure -text [join $typelist ", "]
      grid $widgets($w,v,type)
    } elseif {[file isdirectory $fname]} {
      $widgets($w,v,type) configure -text [msgcat::mc "Directory"]
      grid $widgets($w,v,type)
    } else {
      grid remove $widgets($w,v,type)
    }

  }

  ######################################################################
  # Update the file attributes field.
  proc update_attrs {w permissions owner group} {

    variable widgets
    variable current

    set fname $current($w)

    if {$permissions || $owner || $group} {
      set attrlist [list]
      if {$permissions && ([set perms [utils::get_file_permissions $fname]] ne "")} {
        lappend attrlist $perms
      }
      if {$owner && ([set own [utils::get_file_owner $fname]] ne "")} {
        lappend attrlist $own
      }
      if {$group && ([set grp [utils::get_file_group $fname]] ne "")} {
        lappend attrlist $grp
      }
      if {$attrlist ne [list]} {
        $widgets($w,v,attrs) configure -text [join $attrlist ", "]
        grid $widgets($w,l,attrs) $widgets($w,v,attrs)
      } else {
        grid remove $widgets($w,l,attrs) $widgets($w,v,attrs)
      }
    } else {
      grid remove $widgets($w,l,attrs) $widgets($w,v,attrs)
    }

  }

  ######################################################################
  # Update line, word and character counts field.
  proc update_counts {w line word char} {

    variable widgets
    variable current

    set fname $current($w)

    if {$line || $word || $char} {
      set attrlist [list]
      if {$line && ([set count [utils::get_file_count $fname line]] ne "")} {
        lappend attrlist "$count lines"
      }
      if {$word && ([set count [utils::get_file_count $fname word]] ne "")} {
        lappend attrlist "$count words"
      }
      if {$char && ([set count [utils::get_file_count $fname char]] ne "")} {
        lappend attrlist "$count chars"
      }
      if {$attrlist ne [list]} {
        $widgets($w,v,cnts) configure -text [join $attrlist ", "]
        grid $widgets($w,l,cnts) $widgets($w,v,cnts)
      } else {
        grid remove $widgets($w,l,cnts) $widgets($w,v,cnts)
      }
    } else {
      grid remove $widgets($w,l,cnts) $widgets($w,v,cnts)
    }

  }

  ######################################################################
  # Updates the readtime field.
  proc update_rtime {w readtime} {

    variable widgets
    variable current

    set fname $current($w)

    if {$readtime} {
      if {[set words [utils::get_file_count $fname word]] ne ""} {
        set wpm  [preferences::get Sidebar/InfoPanelReadingTimeWordsPerMinute]
        set mins [expr round( $words / $wpm.0 )]
        $widgets($w,v,rtime) configure -text "$mins minutes"
        grid $widgets($w,l,rtime) $widgets($w,v,rtime)
      } else {
        grid remove $widgets($w,l,rtime) $widgets($w,v,rtime)
      }
    } else {
      grid remove $widgets($w,l,rtime) $widgets($w,v,rtime)
    }

  }

  ######################################################################
  # Updates each of the checksum fields.
  proc update_checks {w md5 sha1 sha224 sha256} {

    variable widgets
    variable current

    set fname $current($w)

    foreach {type enable} [list md5 $md5 sha1 $sha1 sha224 $sha224 sha256 $sha256] {
      if {$enable} {
        if {[set value [utils::get_file_checksum $fname $type]] ne ""} {
          $widgets($w,v,$type) configure -text $value
          grid $widgets($w,l,$type) $widgets($w,v,$type)
        } else {
          grid remove $widgets($w,l,$type) $widgets($w,v,$type)
        }
      } else {
        grid remove $widgets($w,l,$type) $widgets($w,v,$type)
      }
    }

  }

  ######################################################################
  # Updates the modified field.
  proc update_mod {w modified} {

    variable widgets
    variable current

    if {$modified} {
      file stat $current($w) finfo
      $widgets($w,v,mod) configure -text [clock format $finfo(mtime)]
      grid $widgets($w,l,mod) $widgets($w,v,mod)
    } else {
      grid remove $widgets($w,l,mod) $widgets($w,v,mod)
    }

  }

  ######################################################################
  # Updates the version field.
  proc update_version {w version} {

    variable widgets
    variable current

    set fname $current($w)

    if {$version && [file isfile $fname]} {
      set cvs [diff::get_default_cvs $fname]
      if {[set ver [diff::${cvs}::get_current_version $fname]] ne ""} {
        $widgets($w,v,ver) configure -text $ver
        grid $widgets($w,l,ver) $widgets($w,v,ver)
      } else {
        grid remove $widgets($w,l,ver) $widgets($w,v,ver)
      }
    } else {
      grid remove $widgets($w,l,ver) $widgets($w,v,ver)
    }

  }

  ######################################################################
  # Updates the favorite field.
  proc update_favorite {w favorite} {

    variable widgets
    variable current

    set fname $current($w)

    if {$favorite} {
      $widgets($w,v,fav) configure -text [expr {[favorites::is_favorite $fname] ? [msgcat::mc "Yes"]: [msgcat::mc "No"]}]
      grid $widgets($w,l,fav) $widgets($w,v,fav)
    } else {
      grid remove $widgets($w,l,fav) $widgets($w,v,fav)
    }

  }

  ######################################################################
  # Updates the file information image and related information.
  proc update_info_image {w orig image preview imagesize} {

    variable widgets

    # Update the image
    if {$preview} {
      $widgets($w,v,image) configure -image $image
      grid $widgets($w,v,image)
    } else {
      grid remove $widgets($w,v,image)
    }

    # Calculate the syntax and name values
    if {$imagesize} {
      $widgets($w,v,name) configure -text "[$widgets($w,v,name) cget -text] ([image width $orig] x [image height $orig])"
    }

    # Delete the original image
    image delete $orig

    # Set the syntax to Unsupported
    $widgets($w,v,type) configure -text "Unsupported"

  }

  ######################################################################
  # Copies the information from the given label to the clipboard.
  proc copy_info {w name} {

    variable widgets

    # Copy the value to the clipboard
    clipboard clear
    clipboard append [$widgets($w,v,$name) cget -text]

    # Get the information label name
    set name [string range [$widgets($w,l,$name) cget -text] 0 end-1]

    # Output the copy status
    gui::set_info_message [format "%s %s" $name [msgcat::mc "value copied to clipboard"]]

  }

  ######################################################################
  # Returns true if the information panel contains information that can
  # be immediately viewed.
  proc is_viewable {w} {

    variable current

    return [expr {$current($w) ne ""}]

  }

  ######################################################################
  # Executes the given close command.
  proc close {w} {

    variable current

    # Clear current
    set current($w) ""

  }

  ######################################################################
  # Run the user show command.
  proc run_command {w cmd} {

    variable current

    uplevel #0 {*}$cmd [list $current($w)]

  }

  ######################################################################
  # Update the information panel widgets with the given theme information.
  proc update_theme {title_fgcolor value_fgcolor bgcolor active_bgcolor} {

    variable widgets

    # Colorize the frame widgets
    foreach w [array names widgets *,f*] {
      $widgets($w) configure -background $bgcolor
    }

    # Colorize the title labels
    foreach w [array names widgets *,l,*] {
      $widgets($w) configure -foreground $title_fgcolor -background $bgcolor
    }

    # Colorize the value labels
    foreach w [array names widgets *,v,*] {
      $widgets($w) configure -foreground $value_fgcolor -background $bgcolor
      if {[bind $widgets($w) <Button-1>] ne ""} {
        bind $widgets($w) <Enter> [list %W configure -background $active_bgcolor]
        bind $widgets($w) <Leave> [list %W configure -background $bgcolor]
      }
    }

    # Colorize the close button background using the active color
    foreach btn [list fshow frefresh fclose] {
      foreach w [array names widgets *,$btn] {
        bind $widgets($w) <Enter> [list %W configure -background $active_bgcolor]
        bind $widgets($w) <Leave> [list %W configure -background $bgcolor]
      }
    }

    # Tell anyone who cares that the theme changed
    foreach {name w} [array get widgets *,f] {
      event generate $w <<ThemeChange>> -data $bgcolor
    }

  }

}

