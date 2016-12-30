## on\_duplicate

#### Description

The on\_duplicate action calls a procedure immediately after a file or directory is duplicated within the sidebar.

#### Tcl Registration

`{on_duplicate do_procname}`

The _do\_procname_ value is a procedure that is called when this event occurs.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called when this event occurs.  Two arguments are passed.  The first parameter is the full original pathname.  The second parameter is the full pathname of the duplicated file.  The return value is ignored.

The following example displays the new filename.

	proc foobar_do {orig_name new_name} {
	  puts “File $orig_name has been duplicated ($new_name)”
	}