### Creating Launcher Commands

TKE has a powerful launcher capability that allows the user to interact with the GUI via keyboard commands.  This functionality is also available to plugins via the plugin launcher registration procedure.  This procedure is called once for each plugin command that is available.  To register a launcher command, call the following procedure from within one of the "do" style procedures.

`api::register_launcher description command`

The _description_ argument is a short description of the launcher command.  This string is displayed in the launcher results.  The _command_ argument is the Tcl command to execute when the user selects the launcher entry.  The contents of this command can be anything.

Here is a brief example of how to use this command:

	namespace eval foobar {
	  ...
	  proc launcher_command {} {
	      puts "FOOBAR"
	  }
	  proc do {} {
	      api::register_launcher "Print FOOBAR” foobar::launcher_command
	  }
	  ...
	}

The above code will create a launcher that will print the string "FOOBAR" to standard output when invoked in the command launcher.

To unregister a previously registered command launcher command, call the following:

`api::unregister_launcher description`

The value of _description_ must match the string passed to the api\::register\_launcher command to properly unregister the launcher command.