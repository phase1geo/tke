## on\_rename

#### Description

The on\_rename action calls a procedure when a file or directory is renamed within the sidebar.  Specifically, this procedure will be called just prior to the rename being performed to allow the plugin to take any necessary actions on the given file/directory.

#### Tcl Registration

`{on_rename do_procname}`

The _do\_procname_ value is a procedure that is called when this event occurs.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called when this event occurs.  Two arguments are passed.  The first parameter is the full original pathname.  The second parameter is the full new pathname.  The return value is ignored.

The following example displays the original and new filenames.

	proc foobar_do {old_name new_name} {
	  puts “File $old_name has been renamed to $new_name”
	}