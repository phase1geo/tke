### delete

The delete command works almost exactly the same as the standard text delete command with one exception, it can accept an optional “-moddata” option.  The moddata option allows the user to pass user-specific information to the callback procedure that handles the <<Modified>> virtual event.

In TKE, there is only one value that is used for -moddata, the value of “ignore”.  Adding the “-moddata ignore” option will cause the deletion to not change the modified state of the text widget.  This allows plugin code to delete data from the buffer without making it look like the user modified the contents of the buffer.

**Call structure**

`pathname delete ?-moddata value? index1 ?index2?`

**Return value**

None.