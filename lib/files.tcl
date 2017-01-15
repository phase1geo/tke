# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2017  Trevor Williams (phase1geo@gmail.com)
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
# Name:    files.tcl
# Author:  Trevor Williams  (trevorw@sgi.com)
# Date:    11/22/2016
# Brief:   Handles all file-related functionality.
######################################################################

namespace eval files {

  variable files {}

  array set fields {
    fname    0
    mtime    1
    save_cmd 2
    tab      3
    lock     4
    readonly 5
    sidebar  6
    modified 7
    buffer   8
    gutters  9
    diff     10
    tags     11
    loaded   12
    eol      13
    remember 14
    remote   15
  }

  ######################################################################
  # PUBLIC PROCEDURES
  ######################################################################

  ######################################################################
  # Returns a list of information based on the types of data requested
  # in the parameters for the given file.
  proc get_info {from from_type to_types} {

    variable files
    variable fields

    switch $from_type {
      tab {
        set index [lsearch -index $fields(tab) $files $from]
      }
      fileindex {
        set index $from
      }
      fname {
        set index [lsearch -index $fields(fname) $files $from]
      }
    }

    # Verify that we found a matching file
    if {$index == -1} {
      return -code error "files::get_info, Unable to find file with attribute ($from_type) and value ($from)"
    }

    set tos [list]

    foreach to_type $to_types {
      if {![info exists fields($to_type)]} {
        return -code error "files::get_info, Unsupported to_type ($to_type)"
      }
      lappend tos [lindex $files $index $fields($to_type)]
    }

    return $tos

  }

  ######################################################################
  # Returns the number of opened files.
  proc get_file_num {} {

    variable files

    return [llength $files]

  }

  ######################################################################
  # Returns the list of opened files.
  proc get_names {} {

    variable files
    variable fields

    return [lsearch -all -index $fields(fname) $files *]

  }

  ######################################################################
  # Returns 1 if the given filename exists (either locally or remotely).
  proc exists {fname} {

    set remote [get_info $fname fname remote]

    if {$remote eq ""} {
      return [file exists $fname]
    } else {
      return [[ns remote]::file_exists $remote $fname]
    }

  }

  ######################################################################
  # Renames the given folder to the new name.
  proc rename_folder {old_name new_name remote} {

    if {$remote eq ""} {

      # Normalize the filename
      set new_name [file normalize $new_name]

      # Allow any plugins to handle the rename
      plugins::handle_on_rename $old_name $new_name

      if {[catch { file rename -force $old_name $new_name } rc]} {
        return -code error $rc
      }

    } else {

      # Allow any plugins to handle the rename
      plugins::handle_on_rename $old_name $new_name

      if {![remote::rename_file $remote $old_name $new_name]} {
        return -code error ""
      }

    }

    # If this is a displayed file, update the file information
    gui::change_folder $old_name $new_name

    return $new_name

  }

  ######################################################################
  # Deletes the given folder from the file system.
  proc delete_folder {dir remote} {

    # Allow any plugins to handle the rename
    plugins::handle_on_delete $dir

    if {$remote eq ""} {
      if {[catch { file delete -force $dir } rc]} {
        return -code error $rc
      }
    } else {
      if {![remote::remove_directories $remote [list $dir] -force 1]} {
        return -code error ""
      }
    }

    # Close any opened files within one of the deleted directories
    gui::close_dir_files [list $dir]

  }

  ######################################################################
  # Performs a file rename.
  proc rename_file {old_name new_name remote} {

    if {$remote eq ""} {

      # Normalize the filename
      set new_name [file normalize $new_name]

      # Allow any plugins to handle the rename
      plugins::handle_on_rename $old_name $new_name

      # Perform the rename operation
      if {[catch { file rename -force $old_name $new_name } rc]} {
        return -code error $rc
      }

    } else {

      # Allow any plugins to handle the rename
      plugins::handle_on_rename $old_name $new_name

      if {![remote::rename_file $remote $old_name $new_name]} {
        return -code error ""
      }

    }

    # Update the file information (if necessary)
    gui::change_filename $old_name $new_name

    return $new_name

  }

  ######################################################################
  # Duplicates the given filename.
  proc duplicate_file {fname remote} {

    # Create the default name of the duplicate file
    set dup_fname "[file rootname $fname] Copy[file extension $fname]"
    set num       1
    if {$remote eq ""} {
      while {[file exists $dup_fname]} {
        set dup_fname "[file rootname $fname] Copy [incr num][file extension $fname]"
      }
      if {[catch { file copy $fname $dup_fname } rc]} {
        return -code error $rc
      }
    } else {
      while {[remote::file_exists $remote $dup_fname]} {
        set dup_fname "[file rootname $fname] Copy [incr num][file extension $fname]"
      }
      if {![remote::duplicate_file $remote $fname $dup_fname]} {
        return -code error ""
      }
    }

    # Allow any plugins to handle the rename
    plugins::handle_on_duplicate $fname $dup_fname

    return $dup_fname

  }

  ######################################################################
  # Deletes the given file.
  proc delete_file {fname remote} {

    # Allow any plugins to handle the deletion
    plugins::handle_on_delete $fname

    if {$remote eq ""} {
      if {[catch { file delete -force $fname } rc]} {
        return -code error $rc
      }
    } else {
      if {![remote::remove_files $remote [list $fname]]} {
        return -code error ""
      }
    }

    # Close the tab associated with this filename
    catch { gui::close_files [list $fname] }

  }

  ######################################################################
  # Moves the given file/folder to the trash.  If there are any issues,
  # we will throw an exception.
  proc move_to_trash {fname isdir} {

    # Allow any plugins to handle the deletion
    plugins::handle_on_trash $fname

    # Move the original directory to the trash
    switch -glob $::tcl_platform(os) {

      Darwin {
        set cmd "tell app \"Finder\" to move the POSIX file \"$fname\" to trash"
        if {[catch { exec -ignorestderr osascript -e $cmd } rc]} {
          return -code error $rc
        }
        close_tabs $fname $isdir
        return
      }

      Linux* {
        if {![catch { exec -ignorestderr which gvfs-trash 2>@1 }]} {
          if {[catch { exec -ignorestderr gvfs-trash $fname } rc]} {
            return -code error $rc
          }
          close_tabs $fname $isdir
          return
        } elseif {![catch { exec -ignorestderr which kioclient 2>@1 }]} {
          if {[catch { exec -ignorestderr kioclient move $fname trash:/ } rc]} {
            return -code error $rc
          }
          close_tabs $fname $isdir
          return
        } elseif {[file exists [set trash [file join ~ .local share Trash]]]} {
          if {[info exists ::env(XDG_DATA_HOME)] && ($::env(XDG_DATA_HOME) ne "") && [file exists $::env(XDG_DATA_HOME)]} {
            set trash $::env(XDG_DATA_HOME)
          }
          set trash_path [get_unique_path [file join $trash files] [file tail $fname]]
          if {![catch { open [file join $trash info [file tail $trash_path].trashinfo] w } rc]} {
            puts $rc "\[Trash Info\]"
            puts $rc "Path=$fname"
            puts $rc "DeletionDate=[clock format [clock seconds] -format {%Y-%m-%dT%T}]"
            close $rc
          } else {
            return -code error $rc
          }
        } elseif {[file exists [set trash [file join ~ .Trash]]]} {
          set trash_path [get_unique_path [file join $trash files] [file tail $fname]]
        } else {
          return -code error [msgcat::mc "Unable to determine how to move to trash"]
        }
      }

      *Win*  {
        set binit [file join $::tke_dir Win binit binit.exe]
        if {[namespace exists ::freewrap] && [zvfs::exists $binit]} {
          if {[catch { exec -ignorestderr [freewrap::unpack $binit] $fname } rc]} {
            return -code error $rc
          }
          close_tabs $fname $isdir
          return
        } elseif {[file exists $binit]} {
          if {[catch { exec -ignorestderr $binit $fname } rc]} {
            return -code error $rc
          }
          close_tabs $fname $isdir
          return
        } elseif {[file exists [file join C: RECYCLER]]} {
          set trash_path [file join C: RECYCLER]
        } elseif {[file exists [file join C: {$Recycle.bin}]]} {
          set trash_path [file join C: {$Recycle.bin}]
        } else {
          return -code error [msgcat::mc "Unable to determine how to move to trash"]
        }
      }

      default {
        return -code error [msgcat::mc "Unable to determine platform"]
      }

    }

    # Finally, move the file/directory to the trash
    if {[catch { file rename -force $fname $trash_path } rc]} {
      return -code error $rc
    }

    # Close the opened tabs
    close_tabs $fname $isdir

  }

  ######################################################################
  # PRIVATE PROCEDURES
  ######################################################################

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

  ######################################################################
  # Closes any tabs associated with the directory/file.
  proc close_tabs {fname isdir} {

    # Close all of the deleted files from the UI
    if {$isdir} {
      gui::close_dir_files [list $fname]
    } else {
      gui::close_files [list $fname]
    }

  }

}
