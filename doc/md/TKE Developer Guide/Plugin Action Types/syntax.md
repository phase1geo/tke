## syntax

#### Description

The syntax action specifies the name of a .syntax file that will be added to the list of available syntax highlighters in the UI.

#### Tcl Registration

`{syntax filename}`

The syntax filename must be located in the same directory as the main.tcl plugin file and it must contain the .syntax extension.  The base name of the syntax file will be the name displayed in the UI.  For a description of the contents of this file, please refer to the syntax file chapter of this document.