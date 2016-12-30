##  Plugin Bundle Structure

As stated previously, all plugin bundles must reside in the TKE installation's "plugins" directory, must contain the header.tkedat and main.tcl files (with the required elements).  Optionally, the directory can also contain a README.md (Markdown formatted) file which should contain any plugin usage information for the user.  These elements are described in detail in this section.

#### header.tkedat

Every plugin bundle must contain a valid header.tkedat file which is a specially formatted in a tkedat format.  The header file can contain comments (ignored by the parser) by specifying the “#” character at the beginning of a line.  Any other lines must be specified as follows:

**Name**

`name {value}`

The value of _value_ must be the name of the plugin.  This name should match the name of the bundle directory and it must match the name used in the plugin\::register procedure call (more about this later).  The name of the plugin must be a valid variable name (i.e., no spaces, symbols, etc.).

**Author**

`author {name}`

The value of _name_ should be the name of the user who originally created the plugin.

**Email**

`email {email_address}`

The value of _email\_address_ should be the e-mail address of the user who original created the plugin.

**Version**

`version {version}`

The value of _version_ is a numbering system in the format of "major.minor".

**Include**

`include {value}`

The value of _value_ is either "yes" or "no".  This line specifies whether this plugin should be included in the list of available plugins that user's can install.  Typically this value should be set to the value "yes" which will allow the plugin to be used by users; however, setting this value to "no" allows a plugin which is incomplete or currently not working to be temporarily disabled.

**Trust Required**

`trust_required {value}`

The value of _value_ is either “yes” or “no”.  If the value is set to “no” (the default value if this option is not specified in the header file), the plugin will not ask the user to grant it trust and the plugin will be run in “safe” or “untrusted” mode (see the “Safe Interpreter Description” section for details).  If the value is set to “yes”, the user will be prompted to grant the plugin trust to operate.  If trust is granted, the plugin will be installed and the plugin will be given the full Tcl command set to use.  If trust is rejected, the plugin will not be installed.

**Description**

`description {paragraph}`

The value of paragraph should be a paragraph (multi-lined and formatted) which describes what this plugin does.

The following is an example of what a plugin header might look like:

	name           {p4_filelog} 
	author         {John Smith}
	email          {jsmith@bubba.com}       
	version        {1.0} 
	include        {yes}
	trust_required {no}
	description    {Adds a function to the sidebar menu popup for
	files that, when selected, displays the entire
	Perforce filelog history for that file in a
	new editor tab.}

#### Registration

Each plugin needs to register itself with the plugin architecture by calling the api\::register procedure (from the main.tcl bundle file) which has the following call structure:

`api::register name action_type_list`

The value of _name_ must match the plugin name in the plugin header.  As such, the name must be a valid variable name.

The _action\_type\_list_ is a Tcl list that contains all of the plugin action types used by this plugin.  Each plugin action type is a Tcl list that contains information about the plugin action item.  Every plugin must contain at least one plugin action type.  The contents that make up a plugin action type list depend on the type of plugin action type, though the first element of the list is always a string which names the action type.  Appendix A describes each of the plugin action types.

As an example of what a call to the api\::register procedure looks like, consider the following example.  This example shows what a fairly complex plugin can do.

	api::register word_count {
	  {menu command "Display word count"
	      word_count::menu_do
	      word_count::menu_handle_state}
	}

This plugin's purpose is going to display the number of words the exist in the current text widget in the information bar.  The menu command will be available in the “Plugins” menu.  The menu element is a command type where the word\_count\::menu\_do will be run when the command is selected.  The word\_count\::menu\_handle\_state call be executed to set the menu state to disabled if no text widget currently is displayed or it will be enabled if there is a current text widget displayed.

#### Plugin Action Namespace and Procedures

The third required group of elements within a plugin file is the plugin namespace and namespace procedures that are called out in the action type list within the plugin.  Every plugin must contain a namespace that matches the name of the plugin in the header.  Within this namespace are all of the variables and procedures used for the plugin.  It is important that no global variables get created within the plugin to avoid naming collisions.

The makeup and usage of the namespace procedures are fully described in Appendix A.

#### Other Elements

In addition to the required three elements of a plugin file, the user may include any other procedures, variables, packages, etc. that are needed for the plugin within the file.  It is important to note that all plugin variables and procedures reside within the plugin namespace.