## api::menu::enabled

Determines whether the given menu path is able to be invoked within the main
menu system.  The value of _menu-path_ is a slash (/) separated hierarchical
string where each element of the string corresponds to a submenu within the
main menus.

For example, to see if the `Find Next` command exists within the `Edit`
menu, call this procedure as follows:

```Tcl
set enabled [api::menu::enabled "Find/Find Next"]
```

**Call structure**

`api::menu::enabled menu-path`

**Return value**

Returns a value of 1 if the specified menu path can be invoked in the main
menus; otherwise, returns a value of 0.
