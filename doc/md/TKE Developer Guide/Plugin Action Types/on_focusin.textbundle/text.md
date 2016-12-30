## on\_focusin

#### Description

The on\_focusin action type is called whenever a text widget receives input focus (i.e., the text widget’s tab was selected, the file was viewed by clicking the filename in the sidebar, etc.)

#### Tcl Registration

`{on_focusin do_procname}`

The _do\_procname_ procedure is called whenever focus is given to a text widget.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called whenever focus is given to a text widget.  It is passed a single argument, the file index of the file that was given focus.  This value can be used to get information about the file.  The return value is ignored.

The following example displays the read-only status of the currently selected file.

	proc focus_do {file_index} {
	  if {[api::file::get_info $file_index readonly]} {
		      puts “Selected file is readonly”
	  } else {
		      puts “Selected file is read/write”
	  }
	}

