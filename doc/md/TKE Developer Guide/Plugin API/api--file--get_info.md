## api::file::get\_info

Returns information about the file specified by the given index based on the attribute that this passed.

**Call structure**

`api::file::get_info file_index attribute`

**Return value**

Returns the attribute value for the given file.  If an invalid _file\_index_ is specified or an invalid attribute is specified, an error will be thrown.

**Parameters**

| Parameter | Description |
| - | - |
| file\_index | Unique identifier for a file as returned by the get_current_index procedure. |
| attribute | Specifies the type of information to return. See the attribute table below for the list of valid values. |

**Attributes**

| Attribute | Description |
| - | - |
| fname | Normalized file name. |
| mtime | Last modification timestamp. |
| lock | Specifies the current lock status of the file. |
| readonly | Specifies if the file is readonly. |
| modified | Specifies if the file has been modified since the last save. |
| sb\_index | Specifies the index of the file in the sidebar. |
| txt | Returns the pathname of the text widget associated with the file\_index. This will also allow the plugin to use the returned value as a Tcl command. |
| current | Returns a boolean value of true if the file is the current one being edited. |
| vimmode | Returns a boolean value of true if the editor is in “Vim mode” (i.e., any Vim mode that is not insert/edit mode). |
| lang | Returns the name of the syntax language associated with the given file. |

