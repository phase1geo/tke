## api\::invoke\_menu

Invokes the functionality associated with a menu item.  This allows plugins to perform “workflows”.  The menu hierarchy is defined by taking the names of all menus in the hierarchy (case is important) and joining them with the “/“ character.  Therefore, to invoke the File -\> Format Text -\> All command, you would pass the following:

`api::invoke_menu “File/Format Text/All”`

**Call structure**

`api::invoke_menu menu_hierarchy_path`

**Return value**

None.  Returns an error if the given menu hierarchy string cannot be found.

**Parameters**

| Parameter | Description |
| - | - |
| menu\_hierarchy\_path | String representing the hierarchical menu path to the menu command to execute.  Each portion of the menu path must match the menu exactly and all menu portions must be joined by the “/“ character. |

