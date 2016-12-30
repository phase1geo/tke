## on\_uninstall

#### Description

The on\_uninstall action calls a procedure when the associated plugin is uninstalled by the user.  Because uninstalling does not cause the application to quit (i.e., the UI remains in view), this plugin action allows the plugin writer to cleanup the UI that might have been affected by this plugin.

#### Tcl Registration

`{on_uninstall do_procname}`

The _do\_procname_ value is a procedure that is called when this event occurs.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called when this event occurs.  No arguments are passed and the return value is ignored by the calling code.  The body of this procedure should only be used to clean up any UI changes that this plugin may have previously made.

The following example removes a text tag called “foobar” that was previously added.

	proc foobar_do {} {
	  variable txt
	  $txt tag delete foobar
	}