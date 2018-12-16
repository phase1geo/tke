## on\_trash

#### Description

The on\_trash action calls a procedure that is called prior to moving a file/folder to the trash.

#### Tcl Registration

`{on_trash do_procname}`

The _do\_procname_ value is a procedure that is called when this event occurs.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called when this event occurs.  One parameter is passed — the full pathname of the file being moved to the trash.  The return value is ignored.

The following example displays the trashed filename.

```Tcl
proc foobar_do {name} {
  puts “File $name is being moved to the trash”
}
```