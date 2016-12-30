## on\_quit

#### Description

The on\_quit plugin type allows the user to add an action to take just before the tkdv session is quit.  This can be used to perform file cleanup or other types of cleanup.

#### Tcl Registration

`{on_quit do_procname}`
 
The value of _do\_procname_ is the name of the procedure that will be called prior to the application quitting.

#### Tcl Procedures
 
**The "do" Procedure**

The "do" procedure contains the code that will be executed when the tkdv session is quit.

Example:

	proc foobar_on_quit_do {} {
	 file delete -force foobar.txt
	}