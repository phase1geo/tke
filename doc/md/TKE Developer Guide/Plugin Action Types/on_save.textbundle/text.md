## on\_save

#### Description

The on\_save action calls a procedure when a file is saved in the editor pane.  Specifically, the action is called after the file is given a save name (the “fname” attribute of the file will be set) but before the file is actually written to the save file.

#### Tcl Registration

`{on_save do_procname}`

The _do\_procname_ value is a procedure that is called when this event occurs.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called when this event occurs.  It is passed a single parameter value, the file index of the file being save.  This value can be used in calls to the api\::file\::get\_info to get information about the saved file.  The return value is ignored.

The following example displays the name of the file being saved.

	proc foobar_do {file_index} {
	  set fname [api::file::get_info $file_index fname]
	  puts “File $fname is being saved”
	}