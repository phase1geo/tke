## api::menu::selected

Returns the selected status of a checkbutton or radiobutton style menu item.  The value of _menu-path_ is a slash (/) separated hierarchical string where each element of the string correspond to a submenu within the main menus. The _menu-path_ hierarchy must exactly match the English text for the menu.

This command is only valid for menu items that are either checkbuttons or radio buttons.  If the menu path specified is either invalid or refers to a menu item that is not a checkbutton or radiobutton, the empty string will be returned.

For example, to see if the `Vim Mode` option is selected in the `Edit` menu, call this procedure as follows:

```Tcl
if {[api::menu::selected "Edit/Vim Mode"]} {
  ...
}
```

**Call structure**

`api::menu::selected menu-path`

**Return value**

Returns a value of 1 if the specified menu path is currently selected; otherwise, returns a value of 0.
