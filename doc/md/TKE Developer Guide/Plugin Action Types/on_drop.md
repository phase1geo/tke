## on\_drop

#### Description

The on\_drop plugin type allows the plugin to take action whenever a file or piece of text is dragged and dropped on an editing buffer. The plugin is given the type of data dropped on the buffer and allows the plugin to handle the dropped information or not.

#### Tcl Registration

`{on_drop do-procname}`

The value of _do-procname_ is the name of the procedure that will be called when the file/text is dropped on the editing buffer.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called once a file or text is dropped on an editing buffer.  It is passed three arguments, the file index of the editing buffer, a boolean value that specifies if the dropped content is a file (0) or piece of text (1), and the name of the file or the string of dropped text. 

Within this procedure, the plugin can take whatever action with the dropped data that it would like to take.

The procedure must return a value of 1 if it is taking action on the dropped information; otherwise, it should return a value of 0. If no plugin takes action on the dropped text, TKE will perform the built-in behavior.

The following example checks to see if the dropped content was a file and, if so, inserts the name of the file surrounded by parenthesis; otherwise, it indicates that no action was taken.

```Tcl
proc foobar_do {file_index istext data} {
  if {!$istext} {
    set txt [api::file::get_info $file_index txt]
    $txt insert insert "($data)"
    return 1
  }
  return 0
}
```