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
    xview    16
    yview    17
    cursor   18
    encode   19
  }

  ######################################################################
  # PUBLIC PROCEDURES
  ######################################################################

  ######################################################################
  # Returns a list of information based on the types of data requested
  # in the parameters for the given file.
  proc get_info {from from_type args} {

    variable files
    variable fields

    switch $from_type {
      tab {
        set index [lsearch -index $fields(tab) $files $from]
      }
      fileindex {
        set index $from
      }
    }

    # Verify that we found a matching file
    if {$index == -1} {
      return -code error "files::get_info, Unable to find file with attribute ($from_type) and value ($from)"
    }

    set i 0
    foreach to_type $args {
      upvar $to_type type$i
      if {$to_type eq "fileindex"} {
        set retval [set type$i $index]
      } elseif {[info exists fields($to_type)]} {
        set retval [set type$i [lindex $files $index $fields($to_type)]]
      } else {
        return -code error "files::get_info, Unsupported to_type ($to_type)"
      }
      incr i
    }

    return $retval

  }

  ######################################################################
  # Sets one or more file fields for the given file.
  proc set_info {from from_type args} {

    variable files
    variable fields

    switch $from_type {
      tab {
        set index [lsearch -index $fields(tab) $files $from]
      }
      fileindex {
        set index $from
      }
    }

    # Verify that we found a matching file
    if {$index == -1} {
      return -code error "files::get_info, Unable to find file with attribute ($from_type) and value ($from)"
    }

    foreach {type value} $args {
      if {![info exists fields($type)]} {
        return -code error "files::set_info, Unsupported to_type ($type)"
      }
      lset files $index $fields($type) $value
    }

  }

  ######################################################################
  # Returns the number of opened files.
  proc get_file_num {} {

    variable files

    return [llength $files]

  }

  ######################################################################
  # Returns the list of opened files.
  proc get_indices {field {pattern *}} {

    variable files
    variable fields

    if {![info exists fields($field)]} {
      return -code error "Unknown file field ($field)"
    }

    return [lsearch -all -index $fields($field) $files $pattern]

  }

  ######################################################################
  # Returns the list of all opened tabs.
  proc get_tabs {{pattern *}} {

    variable files
    variable fields

    set tabs [list]
    foreach t [lsearch -all -index $fields(tab) -inline $files $pattern] {
      lappend tabs [lindex $t $fields(tab)]
    }

    return $tabs

  }

  ######################################################################
  # Returns 1 if the given filename exists (either locally or remotely).
  proc exists {index} {

    get_info $index fileindex fname remote

    if {$remote eq ""} {
      return [file exists $fname]
    } else {
      return [remote::file_exists $remote $fname]
    }

  }

  ######################################################################
  # Returns true if the file is currently opened within an editing buffer.
  proc is_opened {fname remote} {

    return [expr [get_index $fname $remote] != -1]

  }

  ######################################################################
  # Counts the number of opened files in the given directory.
  proc num_opened {fname remote} {

    variable files
    variable fields

    set count 0

    foreach index [lsearch -all -index $fields(fname) $files $fname*] {
      incr count [expr {[lindex $files $index $fields(remote)] eq $remote}]
    }

    return $count

  }

  ######################################################################
  # Returns the index of the matching filename.
  proc get_index {fname remote args} {

    variable files
    variable fields

    array set opts {
      -diff   0
      -buffer 0
    }
    array set opts $args

    foreach index [lsearch -all -index $fields(fname) $files $fname] {
      if {([lindex $files $index $fields(remote)] eq $remote) && \
          ([lindex $files $index $fields(diff)]   eq $opts(-diff)) && \
          ([lindex $files $index $fields(buffer)] eq $opts(-buffer))} {
        return $index
      }
    }

    return -1

  }

  ######################################################################
  # Returns the modification time of the given file (either locally or
  # remotely).
  proc modtime {index} {

    get_info $index fileindex fname remote

    if {$remote eq ""} {
      file stat $fname stat
      return $stat(mtime)
    } else {
      return [remote::get_mtime $remote $fname]
    }

  }

  ######################################################################
  # Normalizes the given filename and resolves any NFS mount information if
  # the specified host is not the current host.
  proc normalize {host fname} {

    # Perform a normalization of the file
    set fname [file normalize $fname]

    # If the host does not match our host, handle the NFS mount normalization
    if {$host ne [info hostname]} {
      array set nfs_mounts [preferences::get NFSMounts]
      if {[info exists nfs_mounts($host)]} {
        lassign $nfs_mounts($host) mount_dir shortcut
        set shortcut_len [string length $shortcut]
        if {[string equal -length $shortcut_len $shortcut $fname]} {
          set fname [string replace $fname 0 [expr $shortcut_len - 1] $mount_dir]
        }
      }
    }

    return $fname

  }

  ######################################################################
  # Checks to see if the given file is newer than the file within the
  # editor.  If it is newer, prompt the user to update the file.
  proc check_file {index} {

    variable files
    variable fields

    # Get the file information
    get_info $index fileindex tab fname mtime modified

    if {$fname ne ""} {
      if {[exists $index]} {
        set file_mtime [modtime $index]
        if {$mtime != $file_mtime} {
          if {$modified} {
            set answer [tk_messageBox -parent . -icon question -message [msgcat::mc "Reload file?"] \
              -detail $fname -type yesno -default yes]
            if {$answer eq "yes"} {
              gui::update_file $index
            }
          } else {
            gui::update_file $index
          }
          lset files $index $fields(mtime) $file_mtime
        }
      } elseif {$mtime ne ""} {
        set answer [tk_messageBox -parent . -icon question -message [msgcat::mc "Delete tab?"] \
          -detail $fname -type yesno -default yes]
        if {$answer eq "yes"} {
          gui::close_tab $tab -check 0
        } else {
          lset files $index $fields(mtime) ""
        }
      }
    }

  }

  ######################################################################
  # Adds a new file to the list of opened files.
  proc add {fname tab args} {

    variable files
    variable fields

    array set opts [list \
      -save_cmd "" \
      -lock     0 \
      -readonly 0 \
      -sidebar  0 \
      -buffer   0 \
      -gutters  [list] \
      -diff     0 \
      -tags     [list] \
      -loaded   0 \
      -eol      "" \
      -remember 0 \
      -remote   "" \
      -xview    0 \
      -yview    0 \
      -cursor   1.0 \
      -encode   [encoding system] \
    ]
    array set opts $args

    set file_info [lrepeat [array size fields] ""]

    lset file_info $fields(fname)    $fname
    lset file_info $fields(mtime)    ""
    lset file_info $fields(save_cmd) $opts(-save_cmd)
    lset file_info $fields(tab)      $tab
    lset file_info $fields(lock)     $opts(-lock)
    lset file_info $fields(readonly) [expr $opts(-readonly) || $opts(-diff)]
    lset file_info $fields(sidebar)  $opts(-sidebar)
    lset file_info $fields(buffer)   $opts(-buffer)
    lset file_info $fields(modified) 0
    lset file_info $fields(gutters)  $opts(-gutters)
    lset file_info $fields(diff)     $opts(-diff)
    lset file_info $fields(tags)     $opts(-tags)
    lset file_info $fields(loaded)   $opts(-loaded)
    lset file_info $fields(remember) $opts(-remember)
    lset file_info $fields(remote)   $opts(-remote)
    lset file_info $fields(xview)    $opts(-xview)
    lset file_info $fields(yview)    $opts(-yview)
    lset file_info $fields(cursor)   $opts(-cursor)
    lset file_info $fields(encode)   $opts(-encode)

    if {($opts(-remote) eq "") && !$opts(-buffer) && [file exists $fname]} {
      lset file_info $fields(eol) [get_eol_translation $fname]
    } else {
      lset file_info $fields(eol) [get_eol_translation ""]
    }

    # Add the file information to the files list
    lappend files $file_info

  }

  ######################################################################
  # Close the file associated with the given tab.
  proc remove {tab} {

    variable files
    variable fields

    # Get the file index
    if {[get_info $tab tab fileindex] != -1} {
      set files [lreplace $files $fileindex $fileindex]
    }

  }

  ######################################################################
  # gzips the given filename, adding the .gz file extension.
  proc gzip {fname} {

    set fin [open $file rb]
    set header [dict create filename $file time [file mtime $file] comment "Created by Tclinfo patchlevel"]
    set fout [open $file.gz wb]
    zlib push gzip $fout -header $header
    fcopy $fin $fout
    close $fin
    close $fout

  }

  ######################################################################
  # gunzips the given filename, returning the contents of the file.
  proc gunzip {fname} {

    # TBD

  }

  ######################################################################
  # Returns the contents of the file located at the given tab.  Returns
  # a value of 1 if the file was successfully loaded; otherwise, returns
  # 0.
  proc get_file {tab pcontents} {

    variable files
    variable fields

    get_info $tab tab fileindex fname diff remote encode

    # Set the loaded indicator
    lset files $fileindex $fields(loaded) 1

    upvar $pcontents contents

    # Get the file contents
    if {$remote ne ""} {
      remote::get_file $remote $fname $encode contents modtime
      lset files $fileindex $fields(mtime) $modtime
    } elseif {![catch { open $fname r } rc]} {
      fconfigure $rc -encoding $encode
      set contents [string range [read $rc] 0 end-1]
      close $rc
      lset files $fileindex $fields(mtime) [file mtime $fname]
    } else {
      return 0
    }

    return 1

  }

  ######################################################################
  # Saves the contents of the given file contents.
  proc set_file {tab contents} {

    variable files
    variable fields

    get_info $tab tab fileindex fname remote eol encode

    if {$remote ne ""} {

      # Save the file contents to the remote file
      if {![remote::save_file $remote $fname $encode $contents modtime]} {
        gui::set_error_message [msgcat::mc "Unable to write remote file"] ""
        return 0
      }

      lset files $fileindex $fields(mtime) $modtime

    } elseif {![catch { open $fname w } rc]} {

      # Write the file contents
      catch { fconfigure $rc -translation $eol -encoding $encode }
      puts $rc $contents
      close $rc

      lset files $fileindex $fields(mtime) [file mtime $fname]

    } else {

      gui::set_error_message [msgcat::mc "Unable to write file"] $rc
      return 0

    }

    return 1

  }

  ######################################################################
  # Save command for new files.  Changes buffer into a normal file
  # if the file was actually saved.
  proc save_new_file {save_as index} {

    variable files
    variable fields

    # Set the buffer state to 0 and clear the save command
    if {($save_as ne "") || ([lindex $files $index $fields(fname)] ne "Untitled")} {
      lset files $index $fields(buffer)   0
      lset files $index $fields(save_cmd) ""
      lset files $index $fields(remember) 1
      return 1
    } elseif {[set save_as [gui::prompt_for_save]] ne ""} {
      lset files $index $fields(buffer)   0
      lset files $index $fields(save_cmd) ""
      lset files $index $fields(fname)    $save_as
      lset files $index $fields(remember) 1
      return 1
    }

    return -code error "New file was not saved"

  }

  ######################################################################
  # Returns the EOL translation to use for the given file.
  proc get_eol_translation {fname} {

    set type [expr {($fname eq "") ? "sys" : [preferences::get Editor/EndOfLineTranslation]}]

    switch $type {
      auto    { return [utils::get_eol_char $fname] }
      sys     { return [expr {($::tcl_platform(platform) eq "windows") ? "crlf" : "lf"}] }
      default { return $type }
    }

  }

  ######################################################################
  # Move the given folder to the given directory.
  proc move_folder {fname remote dir} {

    return [rename_folder $fname [file join $dir [file tail $fname]] $remote]

  }

  ######################################################################
  # Renames the given folder to the new name.
  proc rename_folder {old_name new_name remote} {

    variable files
    variable fields

    if {$remote eq ""} {

      # Normalize the filename
      set new_name [file normalize $new_name]

      # Allow any plugins to handle the rename
      plugins::handle_on_rename $old_name $new_name

      if {[catch { file rename -force -- $old_name $new_name } rc]} {
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
    foreach index [lsearch -all -index $fields(fname) $files $old_name*] {
      set old_fname [lindex $files $index $fields(fname)]
      lset files $index $fields(fname) "$new_name[string range $old_fname [string length $old_name] end]"
      lset files $index $fields(mtime) [modtime $index]
      gui::get_info $index fileindex tab
      gui::update_tab $tab
    }

    return $new_name

  }

  ######################################################################
  # Deletes the given folder from the file system.
  proc delete_folder {dir remote} {

    # Allow any plugins to handle the rename
    plugins::handle_on_delete $dir

    if {$remote eq ""} {
      if {[catch { file delete -force -- $dir } rc]} {
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
  # Move the given filename to the given directory.
  proc move_file {fname remote dir} {

    variable files
    variable fields

    # Create the new name
    set new_name [file join $dir [file tail $fname]]

    # Handle the move like a rename
    plugins::handle_on_rename $fname $new_name

    # Perform the move
    if {$remote eq ""} {
      if {[catch { file rename -force -- $fname $new_name } rc]} {
        return -code error $rc
      }
    } else {
      if {![remote::rename_file $remote $fname $new_name]} {
        return -code error ""
      }
    }

    # Find the matching file in the files list and change its filename to the new name
    if {[set index [get_index $fname $remote]] != -1} {

      # Update the stored name to the new name and modification time
      lset files $index $fields(fname) $new_name
      lset files $index $fields(mtime) [modtime $index]

      # Get some information about the current file
      gui::get_info $index fileindex tab

      # Update the tab text
      gui::update_tab $tab

    }

    return $new_name

  }

  ######################################################################
  # Performs a file rename.
  proc rename_file {old_name new_name remote} {

    variable files
    variable fields

    if {$remote eq ""} {

      # Normalize the filename
      set new_name [file normalize $new_name]

      # Allow any plugins to handle the rename
      plugins::handle_on_rename $old_name $new_name

      # Perform the rename operation
      if {[catch { file rename -force -- $old_name $new_name } rc]} {
        return -code error $rc
      }

    } else {

      # Allow any plugins to handle the rename
      plugins::handle_on_rename $old_name $new_name

      if {![remote::rename_file $remote $old_name $new_name]} {
        return -code error ""
      }

    }

    # Find the matching file in the files list and change its filename to the new name
    if {[set index [get_index $old_name $remote]] != -1} {

      # Update the stored name to the new name and modification time
      lset files $index $fields(fname) $new_name
      lset files $index $fields(mtime) [modtime $index]

      # Get some information about the current file
      gui::get_info $index fileindex tab txt lang

      # Reset the syntax highlighter to match the new name
      if {[set new_lang [syntax::get_default_language $new_name]] ne $lang} {
        syntax::set_language $txt $new_lang
      }

      # Update the tab text
      gui::update_tab $tab

    }

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
        if {![catch { exec -ignorestderr which gio 2>@1 }]} {
          if {[catch { exec -ignorestderr gio trash $fname } rc]} {
            return -code error $rc
          }
          close_tabs $fname $isdir
          return
        } elseif {![catch { exec -ignorestderr which gvfs-trash 2>@1 }]} {
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
          if {[catch { exec -ignorestderr [freewrap::unpack $binit] [file normalize $fname] } rc]} {
            return -code error $rc
          }
          close_tabs $fname $isdir
          return
        } elseif {[file exists $binit]} {
          if {[catch { exec -ignorestderr $binit [file normalize $fname] } rc]} {
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
