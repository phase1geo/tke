## on\_open

#### Description

The on\_open plugin action is called after a new tab has been created and after the file associated with the tab has been read and added to the editor in the editor pane.

#### Tcl Registration

`{on_open do_procname}`

The _do\_procname_ is the name of the procedure that is called for this action type.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called when the file has been added to the editor.   The procedure takes a single argument, the file index of the added file.  You can use this file index to get various pieces of information about the added file using the api\::file\::get\_info API procedure.  The return value is ignored.

The following example will display the full pathname of a file that was just added to the editor.

	proc foobar_do {file_index} {
	 set fname [api::file::get_info $file_index fname]
	 puts “File $fname was just opened”
	}