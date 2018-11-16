## Creating a New Plugin Template

Creating a new plugin file template is a straightforward process.  First, you must open a new terminal and set the TKE development environment variable to a value of 1 as follows:

`setenv TKE_DEVEL 1`

After this command has been entered, run TKE from that same shell.  When the application is ready, go to the "Plugins / Create..." menu command (the "Create..." command will be missing from the Plugins menu if TKE is started without the TKE\_DEVEL environment variable set).

This will display an entry field at the bottom of the window, prompting you to enter the name of the plugin being created.  This name must be a legal variable name (i.e., no whitespace, symbols, etc.)  Once a name has been provided and the RETURN key pressed, a new plugin bundle will be created (in the .tke/iplugins directory) which is named the same as the entered name.  Within the bundle, TKE will create a partially filled out template for both the header.tkedat and main.tcl, and these files will displayed within two editor tabs so that the developer can start coding the new plugin behavior.

Supposing that we entered a plugin name of "foobar", the resulting directory (bundle) “foobar” would be created.  The following files will exist in the directory:

header.tkedat

	name           {foobar}
	author         {}
	email          {}
	version        {1.0}
	include        {yes}
	trust_required {no}
	description    {}

main.tcl

```Tcl
namespace eval foobar {
}
	
api::register foobar {
}
```

It is advisable for you to also create a file called README.md in the directory as well which should primarily contain plugin usage information. A user can display the contents of this file within TKE in a read-only buffer by using the Plugins / Show Installed… menu option and selecting one of the installed plugins from the resulting window.

You may, optionally, place any other files that are needed by your plugin within the plugin bundle, including, but not limited to, other Tcl source files, packages, data files, and images.

You cannot use any content that requires a compilation on the installation machine.