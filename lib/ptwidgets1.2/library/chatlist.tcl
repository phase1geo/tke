set tkdv_dir    [file join $env(P4WORKAREA) sn5 tools lib tkdv4]
set tkgrowl_dir [file join $tkdv_dir tkgrowl2.0]

lappend auto_path $tkdv_dir

namespace eval chatlist {

  array set data {}
  
  array set columns {
    id           0  
    thread       1
    from         2
    participants 3
    starred      4
    read         5
    msg          6
    msg_node     7
    hidden       8
  }

  ##############################################################
  # Creates a chatlist widget and returns the pathname.
  proc chatlist {w args} {

    variable data

    # Add the arguments
    foreach {opt value} $args {
      set data($w,opt,$opt) $value
    }

    frame $w

    # Create the widget
    set data($w,text) \
      [text $w.t -width 60 -height 20 -bg grey20 -fg white -wrap word -state disabled \
        -cursor left_ptr]

    pack $data($w,text) -fill both -expand yes

    # Create images
    set data($w,starred) \
      [image create bitmap -file [file join $::tkgrowl_dir img starred.bmp] -foreground white]
    set data($w,unread) \
      [image create bitmap -file [file join $::tkgrowl_dir img unread.bmp] -foreground white]
    set data($w,blank) \
      [image create bitmap -file [file join $::tkgrowl_dir img blank.bmp] -foreground white]

    # Initialize variables
    set data($w,curr_msgid)   0
    set data($w,selected_ids) [list]
    set data($w,table)        [list]

    bind $w             <Destroy>     "chatlist::destroy $w"
    bind $data($w,text) <Button-1>    "chatlist::handle_left_click $w %x %y"
    bind $data($w,text) <<Selection>> "chatlist::handle_text_selection $w"

    # Rename and alias the tokenentry window
    rename ::$w $w
    interp alias {} ::$w {} chatlist::widget_cmd $w

    return $w

  }

  ##############################################################
  # Handles a destroy event on the widget.
  proc destroy {w} {

    variable data

    # Destroy the text widget
    destroy $data($w,text)

    # Delete images
    foreach img [array get data $w,image,*] {
      image delete $data($img)
    }

    # Delete the data elements
    array unset data $w,*

  }

  ##############################################################
  # Returns the index of the row item.
  proc rowindex {name} {
  
    
  
  }

  ##############################################################
  # Handles a left click on the table.
  proc handle_left_click {w x y} {
    
    variable data

    set t $data($w,text)

    # Get the message id 
    if {[set id [lsearch -inline -glob [$t tag names [$t index @$x,$y]] id*]] ne ""} {

      # If a row was previously selected, do something
      if {[llength $data($w,selected_ids)] > 0} {

        # If it is the same row, deselect the row
        if {[set id_index [lsearch $data($w,selected_ids) $id]] != -1} {
          $t tag configure $id -background grey20
          set data($w,selected_ids) [lreplace $data($w,selected_ids) $id_index $id_index]
          event generate $w <<ChatlistSelect>>

        # Otherwise, deselect the last row and select this row
        } else {
          foreach selected_id $data($w,selected_ids) {
            $t tag configure $selected_id -background grey20
          }
          $t tag configure $id -background blue
          set data($w,selected_ids) $id
          event generate $w <<ChatlistSelect>>
        }

      # Otherwise, just select the current row
      } else {
        $t tag configure $id -background blue
        set data($w,selected_ids) $id
        event generate $w <<ChatlistSelect>>
      }

    }

  }
  
  ##############################################################
  # Handles a selection change to the text widget.
  proc handle_text_selection {w} {
  
    variable data
    
    # Clear the selection
    $data($w,text) tag remove sel 1.0 end
  
  }

  ##############################################################
  # Updates the given chat message based on its show/hide status.
  proc show_hide {w index} {

    variable data
    variable columns

    # Get the needed information for the given row
    set id     [lindex $data($w,table) $index $columns(id)]
    set hidden [lindex $data($w,table) $index $columns(hidden)]
    
    # Set the elide option for the row
    $data($w,text) tag configure row$id -elide $hidden

  }

  ##############################################################
  # Performs the various commands one can perform on a chatlist
  # widget.
  proc widget_cmd {w args} {

    # Check the arguments
    if {[llength $args] == 0} {
      return -code error "chatlist command must have at least one parameter"
    }
    
    switch -- [lindex $args 0] {
      configure     { return [configure $w {*}[lrange $args 1 end]] }
      cget          { return [cget $w {*}[lrange $args 1 end]] }
      index         { return [index $w 1 {*}[lrange $args 1 end]] }
      insert        { insert $w {*}[lrange $args 1 end] }
      delete        { delete $w {*}[lrange $args 1 end] }
      itemcget      { return [itemcget $w {*}[lrange $args 1 end]] }
      itemconfigure { return [itemconfigure $w {*}[lrange $args 1 end]] }
      selection     { return [selection $w {*}[lrange $args 1 end]] }
      curselection  { return [curselection $w {*}[lrange $args 1 end]] }
      see           { see $w {*}[lrange $args 1 end] }
      xview         { return [xview $w {*}[lrange $args 1 end]] }
      yview         { return [yview $w {*}[lrange $args 1 end]] }
      default       { return -code error "Unknown chatlist command ([lindex $args 0])" }
    }

  }

  ##############################################################
  # Configures the chatlist widget.
  proc configure {w args} {
    
    variable data

    # TBD

  }

  ##############################################################
  # Gets configuration information from the chatlist widget.
  proc cget {w args} {
    
    variable data

    # TBD

  }

  ##############################################################
  # Returns the integer index of the given index specifier.
  proc index {w endislast args} {

    variable data

    # Check args
    if {[llength $args] != 1} {
      return -code error "Incorrect arguments to chatlist::index"
    }

    set user_index [lindex $args 0]
    set table_len  [llength $data($w,table)]

    if {[string is integer $user_index]} {
      if {$user_index < 0} {
        return 0
      } elseif {$user_index > $table_len} {
        return [expr $table_len - $endislast]
      } else {
        return $user_index
      }
    } elseif {$user_index eq "end"} {
      return [expr $table_len - $endislast]
    } elseif {[regexp {^end\-(\d+)$} $user_index -> modifier]} {
      return [expr $table_len - ($endislast + $modifier)]
    } else {
      return -code error "Illegal index ($user_index)"
    }
 
  }

  ##############################################################
  # Inserts a new chat message to the widget at the given index.
  proc insert {w args} {
    
    variable data
    variable columns

    # Check the arguments
    if {[llength $args] != 9} {
      return -code error "Incorrect arguments to chatlist::insert"
    }

    set t $data($w,text)

    # Get the argument variables
    set index        [index $w 0 [lindex $args 0]]
    set thread       [lindex $args 1]
    set from         [lindex $args 2]
    set participants [lindex $args 3]
    set timestamp    [lindex $args 4]
    set starred      [lindex $args 5]
    set read         [lindex $args 6]
    set msg          [lindex $args 7]
    set msg_node     [lindex $args 8]

    # Get the next message ID
    set msg_id [incr data($w,curr_msgid)]

    # Figure out the starting index of the message
    if {$index == [llength $data($w,table)]} {
      set start_index [$t index end-1c]
    } else {
      set id [lindex $data($w,table) $index $columns(id)]
      set start_index [$t index id$id.first]
    }

    # Get the name of the image to display
    if {$starred} {
      set status starred
    } elseif {!$read} {
      set status unread
    } else {
      set status blank
    }

    # Insert the message into the text widget
    $t configure -state normal
    $t insert        $start_index "\n"
    $t window create $start_index \
      -window [frame $w.f$msg_id -width [winfo screenwidth .] -height 1] -padx 4 -pady 4
    $t insert        $start_index "$msg\n" msg
    $t insert        $start_index "    [clock format $timestamp]\n" italics
    $t image  create $start_index -image [users::get_image $from] -padx 4 -pady 4
    $t image  create $start_index -image $data($w,$status) -padx 4 -pady 4
    $t configure -state disabled

    # Get the font information
    array set tf [font actual [$t cget -font]]
    set isize [expr ($tf(-size) >= 0) ? ($tf(-size) - 2) : ($tf(-size) + 2)]

    # Configure the message
    $t tag configure italics -justify right -font [list $tf(-family) $isize italic]
    $t tag configure msg     -lmargin1 56 -lmargin2 56
    $t tag add id$msg_id  $start_index "$start_index+[expr 1 + [llength [split $msg \n]]]l"
    $t tag add row$msg_id $start_index "$start_index+[expr 2 + [llength [split $msg \n]]]l"

    # Insert the data into the table
    set entry [lrepeat [array size columns] ""]
    lset entry $columns(id)           $msg_id
    lset entry $columns(thread)       $thread
    lset entry $columns(from)         $from
    lset entry $columns(participants) $participants
    lset entry $columns(starred)      $starred
    lset entry $columns(read)         $read
    lset entry $columns(msg)          $msg
    lset entry $columns(msg_node)     $msg_node
    lset entry $columns(hidden)       0
    set data($w,table) [linsert $data($w,table) $index $entry]

  }

  ##############################################################
  # Deletes the chat message at the given row.
  proc delete {w args} {
    
    variable data
    variable columns

    # Get the first/last row
    if {[llength $args] == 1} {
      set first_row [index $w 1 [lindex 1 $args 0]]
      set last_row  $first_row
    } elseif {[llength $args] != 2} {
      set first_row [index $w 1 [lindex 1 $args 0]]
      set last_row  [index $w 1 [lindex 1 $args 1]]
      if {$first_row > $last_row} {
        return -code error "In chatlist::delete command, first must be less than or equal to last"
      }
    } else {
      return -code error "Incorrect arguments to chatlist::delete"
    }

    set t $data($w,text)
    
    # Delete the rows from the table
    $t configure -state normal
    for {set i $last_row} {$i >= $first_row} {incr i -1} {
      set id [lindex $data($w,table) $i $columns(id)]
      $t delete id$id.first "id$id.last + 1 lines"
      if {[set id_index [lsearch $data($w,selected_ids) $id]] != -1} {
        set data($w,selected_ids) [lreplace $data($w,selected_ids) $id_index $id_index]
      }
    }
    $t configure -state disabled

    # Delete the table list items
    set data($w,table) [lreplace $data($w,table) $first_row $last_row]

  }
  
  ##############################################################
  # Returns configuration values for a given row.
  proc itemcget {w args} {
  
    variable data
    variable columns
    
    # Check the arguments
    if {[llength $args] != 2} {
      return -code error "Incorrect parameters to chatlist::itemcget"
    }
    
    set index [index $w 1 [lindex $args 0]]
    set opt   [lindex $args 1]
    
    switch -- $opt {
      -hide   { return [lindex $data($w,table) $index $columns(hidden)] }
      default {
        return -code error "Unknown option in chatlist::itemcget ($opt)"
      }
    }
  
  }
  
  ##############################################################
  # Configures a given row.
  proc itemconfigure {w args} {
  
    variable data
    variable columns
  
    # Check the arguments
    if {[llength $args] != 3} {
      return -code error "Incorrect parameters to chatlist::itemconfigure"
    }
    
    set index [index $w 1 [lindex $args 0]]
    set opt   [lindex $args 1]
    set value [lindex $args 2]
    
    switch -- $opt {
      -hide {
        lset data($w,table) $index $columns(hidden) $value
        show_hide $w $index
      }
      default {
        return -code error "Unknown option in chatlist::itemconfigure ($opt)"
      }
    }
    
  }
  
  ##############################################################
  # Handles the selection command functionality.
  proc selection {w args} {
  
    variable data
    variable columns
    
    # Check the arguments
    if {[llength $args] == 0} {
      return -code error "Incorrect arguments to chatlist::selection"
    }
    
    switch -- [lindex $args 0] {
    
      clear {
        if {[llength $args] == 2} {
          set first_row [index $w 1 [lindex $args 1]]
          set last_row  $first_row
        } elseif {[llength $args] == 3} {
          set first_row [index $w 1 [lindex $args 1]]
          set last_row  [index $w 1 [lindex $args 2]]
          if {$first_row > $last_row} {
            return -code error "In chatlist::selection clear command, first must be less than or equal to last"
          }
        } else {
          return -code error "Incorrect arguments to chatlist::selection clear subcommand"
        }
        set t $data($w,text)
        for {set i $first_row} {$i <= $last_row} {incr i} {
          set id [lindex $data($w,table) $i $columns(id)]
          if {[set id_index [lsearch $data($w,selected_ids) "id$id"]] != -1} {
            $t tag configure id$id -background grey20
            set data($w,selected_ids) [lreplace $data($w,selected_ids) $id_index $id_index]
          }
        }
        return [list]
      }
      
      set {
        if {[llength $args] == 2} {
          set first_row [index $w 1 [lindex $args 1]]
          set last_row  $first_row
        } elseif {[llength $args] == 3} {
          set first_row [index $w 1 [lindex $args 1]]
          set last_row  [index $w 1 [lindex $args 2]]
          if {$first_row > $last_row} {
            return -code error "In chatlist::selection set command, first must be less than or equal to last"
          }
        } else {
          return -code error "Incorrect arguments to chatlist::selection set subcommand"
        }
        set t $data($w,text)
        for {set i $first_row} {$i <= $last_row} {incr i} {
          set id [lindex $data($w,table) $i $columns(id)]
          if {[lsearch $data($w,selected_ids) "id$id"] == -1} {
            $t tag configure id$id -background blue
            lappend data($w,selected_ids) id$id
          }
        }
        return [list]
      }
      
      includes {
        if {[llength $args] != 2} {
          return -code error "Incorrect arguments to chatlist::selection includes subcommand"
        }
        set id [lindex $data($w,table) [index $w 1 [lindex $args 1]] $columns(id)]
        return [expr [lsearch $data($w,selected_ids) "id$id"] != -1]
      }
      
      default {
        return -code error "Unknown selection subcommand ([lindex $args 0])"
      }
    }
    
  }
  
  ##############################################################
  # Returns the list of currently selected rows.
  proc curselection {w args} {
  
    variable data
    variable columns
    
    # Check the arguments
    if {[llength $args] != 0} {
      return -code error "Incorrect parameters to chatlist::curselection"
    }
    
    set rows [list]
    foreach selected_id $data($w,selected_ids) {
      lappend rows [lsearch -index $columns(id) $data($w,table) [string range $selected_id 2 end]]
    }
    
    return $rows
  
  }
  
  ##############################################################
  # Displays the specified row.
  proc see {w args} {
  
    variable data
    variable columns
    
    # Check the arguments
    if {[llength $args] != 1} {
      return -code error "Incorrect parameters to chatlist::see"
    }
    
    # Get the row index
    set index [index $w 1 [lindex $args 0]]
    
    # Get the ID of the given row
    set id [lindex $data($w,table) $index $columns(id)]
    
    $data($w,text) see [lindex [$data($w,text) tag ranges id$id] 0]
  
  }

  ##############################################################
  # Handles xview commands.
  proc xview {w args} {
    
    variable data

    # We'll just let the text widget handle the xview commands
    $data($w,text) xview {*}$args

  }

  ##############################################################
  # Handles yview commands.
  proc yview {w args} {
    
    variable data

    # We'll just let the text widget handle the yview commands
    $data($w,text) yview {*}$args

  }

}
