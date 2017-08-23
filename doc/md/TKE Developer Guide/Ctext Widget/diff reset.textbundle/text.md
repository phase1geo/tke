### diff reset

This command must be called prior to calling any of the other diff-related commands.  If the difference information needs to be changed (i.e., one of the files in the difference is changed), this command must be called to remove all embedded difference information and reset the widget. 

**Call structure**

`pathname diff reset`

**Return value**

None.

**Parameters**

None.

**Example**

```Tcl
proc apply_diff {txt} {

  # Reset the widget for difference display
  $txt diff reset

  # Show that the second file had two lines added, starting at line 5
  $txt diff add 5 2
   
}
```