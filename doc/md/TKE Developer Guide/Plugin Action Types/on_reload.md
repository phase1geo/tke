## on\_reload

#### Description

The on\_reload plugin type allows the user to store/restore internal data when the user performs a plugin reload operation.  In the event that a plugin is reloaded, any internal data structures/state will be lost when the plugin is reloaded (re-sourced).  The plugin may choose to store any internal data/state to non-corruptible memory within the plugin architecture just prior to the plugin being resourced and then restore that memory back into the plugin after it has been re-sourced.
Tcl Registration
 
`{on_reload store_procname restore_procname}`
   
The value of _store\_procname_ is the name of a procedure which will be called just prior to the reload operation taking place.  The value of _restore\_procname_ is the name of a procedure which will be called after the reload operation has occurred.

#### Tcl Procedures
 
**The "store" Procedure**

The "store" procedure contains code that saves any necessary internal data/state to non-corruptible memory.  It is called just prior to the plugin being re-sourced by the plugin architecture.  The TKE API contains a procedure that can be called to safely store a variable along with its value such that the variable name and value can be restored properly.

Example:

```Tcl
proc foobar_on_reload_store {index} {

  variable some_data
  
  # Save the value of some_data to non-corruptible memory
  api::plugin::save_variable $index "some_data" $some_data
  
  # Save the geometry of a plugin window if it exists
  if {[winfo exists .mywindow]} {
    api::plugin::save_variable $index "mywindow_geometry" [winfo geometry .mywindow]
    destroy .mywindow
  }
  
}
```

In this example, we have a local namespace variable called "some\_data" that contains some information that we want to preserve during a plugin reload.  The example uses a user-available procedure within the plugin architecture called “api\::plugin\::save\_variable” which takes three arguments:  the unique identifier for the plugin (which is the value of the parameter called “index"), the string name of the value that we want to save, and the value to save.  Note that the value must be given in a "pass by value" format.  The example also saves the geometry of a plugin window if it currently exists.

**The "restore" Procedure**

The "restore" procedure contains code that restores any previously saved information from the "store" procedure from non-corruptible memory back to the plugin memory.  It is called immediately after the plugin has been re-sourced.

Example:

	proc foobar_on_reload_restore {index} {
	  variable some_data
	  # Retrieve the value of some_data and save it to the 
	  # internal variable
	  set some_data [api::plugin::load_variable $index "some_data"]
	  # Get the plugin window dimensions if it previously existed
	   set geometry [api::plugin::load_variable $index “mywindow_geometry”]
	   if {$geometry ne ""} {
	      create_mywindow
	      wm geometry .mywindow $geometry
	   }
	}

In this example, we restore the value of some\_data by calling the plugin architecture's built-in “api\::plugin\::load\_variable” procedure which takes two parameters (the unique index value for the plugin and the name of the variable that was previously stored) and returns the stored value (the procedure also removes the stored data from its internal memory).  If the index/name combination was not previously stored, a value of empty string is returned.  The example also checks to see if the mywindow geometry was saved.  If it was it means that the window previously existed, so the restore will recreate the window (with an internal procedure called "create\_mywindow" in this case) and the sets the geometry of the window to the saved value.
