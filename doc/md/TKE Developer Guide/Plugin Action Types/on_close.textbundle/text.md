## on\_close

#### Description

The on\_update plugin type allows the user to add an action to take whenever the contents of an editor is automatically updated by the application.  This event is triggered when a file that is loaded into the editor is updated outside of the editor and focus is given back to the editor.  If the file content within the editor is not in the modified state, TKE will automatically load the new file content and trigger this event.  If the file content is in the modified state, a popup window will be presented to the user, letting them know that the file content has changed and asking them if they would like to accept the update or ignore it.  If the user accepts the update request, the file content will be updated and this event will be triggered.

#### Tcl Registration

`{on_update do_procname}`

The value of _do\_procname_ is the name of the procedure that will be called after the file content has been updated in the editor.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called after a file is updated in the UI.  It is passed a single argument, the file index of the file being closed.  This argument value can be used to get information about the associated file.  The return value is ignored.

The following example displays the name of the file that was updated.

```Tcl
proc foobar_do {file_index} {
  set fname [api::file::get_info $file_index fname]
  puts “File $fname has been updated”
}
```