## api\::sidebar\::set\_info

Sets the sidebar state of the given sidebar item to a specified value.

**Call structure**

`api::sidebar::set_info sb_index attribute value`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| sb\_index | Index of item in sidebar to modify. |
| attribute | Sidebar attribute to modify. See the list of valid attributes in the table below. |
| value | Value to assign to the given attribute. |

**Attributes**

| Name | Description |
| - | - |
| open | Specifies if the sidebar item should be opened (1) or closed (0). This attribute is only valid for sidebar directories. This will have no effect on sidebar files. |

**Example**

```Tcl
# Get the selected sidebar index
set sb_index [api::sidebar::get_selected_indices]
	
# Make the contents of the directory visible
api::sidebar::set_info $sb_index open 1
```