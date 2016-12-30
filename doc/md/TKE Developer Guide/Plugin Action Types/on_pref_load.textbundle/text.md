## on\_pref\_load

#### Description

The on\_pref\_load action is called shortly after the plugin is loaded/reloaded. The purpose of this action is to get a name/value list of preferences that are needed by the plugin. Preference values are stored in the same manner as TKE’s internal preferences, allowing the user to set options that are remembered between application invocations. These items are also changed within the TKE preference window within the Plugins category.

#### Tcl Registration

`{on_pref_load do_procedure}`

The _do\_procedure_ is a Tcl procedure that will be called when TKE needs to get the preference values from the plugin.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure must return a valid Tcl list which contains pairs of name and default value values (thus it must contain an even number of elements). The following example creates two preference values and specifies that their default values should be 0 and “red”:

	proc do_pref_load {} {
	  return {
	     Enable 0
	     Color  “red”
	  }
	}