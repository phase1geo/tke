## api::sidebar::get\_info

Returns information for the sidebar file/directory at the given index.

**Call structure**

`api::sidebar::get_info sb_index attribute`

**Return value**

Returns the value associated with the given index/attribute.  If the specified index is not a valid
index value for the sidebar, an empty string will be returned.

**Parameters**

| Parameter | Description |
| - | - |
| sb\_index | Index of file/directory in the sidebar.  Calling `api::sidebar::get_current_index` will provide the currently selected element in the sidebar. |
| attribute | Specifies the type of information to obtain for the given index. See the list of valid values in the table below. |

**Attributes**

| Attribute | Description |
| - | - |
| fname | Normalized filename. |
| file\_index | The file index of the file.  This value can be used in the `api::file::get_info` API call to get other information about the file. |
| is\_dir | Returns 1 if the given sidebar item is a directory; otherwise, returns 0. |
| is\_open | Returns 1 if the given sidebar item is opened; otherwise, returns 0. |
| parent | Returns the index of the specified index parent node in the tree. |
| children | Returns an ordered list of sidebar indices that are children of the specified sidebar index. |
| sortby | Returns the order in which the directory is sorted by. Only valid if _index_ pertains to a directory; otherwise, returns the empty string. Valid values are: **name**, **manual** |