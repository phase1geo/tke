## on\_delete

#### Description

The on\_delete action calls a procedure just before a file is deleted from the file system within the sidebar.

#### Tcl Registration

`{on_delete do_procname}`

The _do\_procname_ value is a procedure that is called when this event occurs.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called when this event occurs.  One parameter is passed — the full pathname of the file being deleted.  The return value is ignored.

The following example displays the deleted filename.

	proc foobar_do {name} {
	  puts “File $name is deleted”
	}