## api::menu::invoke

Invokes the given command with the specified menu path within the main menu system.  The value of _menu-path_ is a slash (/) separated hierarhical string where each element of the string corresponds to a submenu within the main menus. The _menu-path_ hierarchy must exactly match the English text for the menu.

For example, to invoke the `Indent` command within the `Edit / Indentation` submenu, call this procedure as follows:

```Tcl
set exists [api::menu::exists "Edit/Indentation/Indent"]
```

**Important Note**: This API call replaces the now obsolete api::invoke\_menu function.

**Call structure**

`api::menu::invoke menu-path`

**Return value**

Returns a value of 1 if the specified menu path exists in the main menus; otherwise, returns a value of 0.
