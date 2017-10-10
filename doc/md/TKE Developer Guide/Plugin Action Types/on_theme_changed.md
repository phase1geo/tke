## on\_theme\_changed

#### Description

The `on_theme_changed` action calls a procedure that is called after the user has changed the application theme. Use this plugin action if your plugin manipulates colors that are based on the current theme colors.

#### Tcl Registration

`{on_theme_changed do_procname}`

The _do\_procname_ value is a procedure that is called when this event occurs.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called when this event occurs. No parameters are passed. The return value is ignored.