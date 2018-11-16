## api::get\_user\_input

Displays a prompt message and an entry field, placing the cursor into the entry field for immediate text entry.  Once a value has been input, the value will be assigned to the variable passed to this procedure.  Allows the plugin to get user input.

**Call structure**

`api::get_user_input message variable ?allow_vars?`
  
**Return value**

Returns a value of 1 if the user hit the RETURN key in the text entry field to indicate that a value was obtained by the user and stored in the provided variable.  Returns a value of 0 if the user hit the ESCAPE key or clicked on the close button to indicate that the value of variable was not set and should not be used. 

**Parameters**

| Parameter | Description |
| - | - |
| message | Message to prompt user for input (should be short and not contain any newline characters). |
| variable | Name of variable to store the user-supplied response in.  If a value of 1 is returned, the contents in the variable is valid; otherwise, a return value 0 indicates the contents in the variable is not valid. If the variable contains a non-empty value, that value will be displayed in the input field with the text immediately selected. |
| allow\_vars | Optional.  If set to 1, any environment variables specified in the user string will have value substitution performed and the resulting string will be stored in the variable parameter.  If set to 0, no substitutions will be performed.  By default, substitution is performed. |

**Example**

```Tcl
set filename “”
if {[api::get_user_input “Filename:” filename 1]} {
  puts “File $filename was given”
} else {
  puts “No filename specified”
}
```


