## on\_start

#### Description

The on\_start plugin action is called when the application starts.  More precisely, the following actions will take place prior to running procedures associated with this action type.

- Preferences are loaded
- Plugins are loaded
- Snippet contents are loaded
- Clipboard history is loaded
- Syntax highlighting information is loaded
- User interface components are built (but not yet displayed to the user)

At this point, any on\_start action procedures are run.  The following events occur after this occurs.

- Command-line files are added to the interface
- Last session information is restored to the interface

The action type allows plugins to initialize or make user interface modifications.

#### Tcl Registration

`{on_start do_procname}`

The value of _do\_procname_ is the name of the procedure to run when Tcl is started.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure contains the code that will be executed when the application starts.  It is passed no options and has no return value.  You can perform any type of initialization within this procedure.