## api::menu::exists

Determines whether the given menu path exists within the main menu system. The value of _menu-path_ is a slash (/) separated hierarchical string where each element of the string corresponds to a submenu within the main menus. The _menu-path_ hierarchy must exactly match the English text for the menu.

For example, to see if the `Open File...` command exists within the `File` menu, call this procedure as follows:

```Tcl
set exists [api::menu::exists "File/Open File..."]
```

**Call structure**

`api::menu::exists menu-path`

**Return value**

Returns a value of 1 if the specified menu path exists in the main menus; otherwise, returns a value of 0.
