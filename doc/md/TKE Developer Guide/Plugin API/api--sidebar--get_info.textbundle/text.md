## api\::sidebar\::get\_info

Returns information for the sidebar file/directory at the given index.

**Call structure**

`api::sidebar::get_info sb_index attribute`

**Return value**

Returns the value associated with the given index/attribute.  If the specified index is not a valid
index value for the sidebar, an empty string will be returned.

**Parameters**

| Parameter | Description |
| - | - |
| sb\_index | Index of file/directory in the sidebar.  Calling api\::sidebar\::get\_current\_index will provide the currently selected element in the sidebar. |
| attribute | Specifies the type of information to obtain for the given index. See the list of valid values in the table below. |

**Attributes**

| Attribute | Description |
| - | - |
| fname | Normalized filename. |
| file\_index | The file index of the file.  This value can be used in the api\::file\::get\_info API call to get other information about the file. |

