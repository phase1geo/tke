## file\_info

#### Description

The file\_info plugin type allows the user to add information to the file information panel within the sidebar (when it is displayed). File information is presented in a "Title: Value" format at the bottom of the panel (in the same way that the "Modified" information is presented). This allows plugins to provide additional, customizable information in the file information panel.

#### Tcl Registration

	{file_info title file_value_procname}

The title field is the string that will be displayed on the left side of the information row. It briefly describes what information is presented on the right side of the information row. You should keep this string as short as possible so that the file information panel stays compact and succinct.

The "file\_value\_procname" is the name of a Tcl procedure that will be called with the filename to get information for. This procedure is documented below.

#### Tcl Procedures

**The "file\_value" Procedure**

The "file\_value" procedure contains the code that will be executed when the user selects a single file in the sidebar. It will be called with the full filename path of the selected file. It must return a string value. If the file information is not valid for the given filename, return the empty string. TKE will omit displaying this row of file information in this case. If the file information is valid for the given filename, return the file information.
 
Example:

	# Returns the reversed string representation of the given filename
	proc file_value_reverse {fname} {
	 return [string reverse [file tail $fname]]
	}