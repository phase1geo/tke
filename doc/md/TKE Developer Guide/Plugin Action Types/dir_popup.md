## dir\_popup

#### Description

The dir\_popup plugin type allows the user to add a new menu command to the popup menu in the sidebar when any non-root directory is right-clicked.  All root\_popup plugins can optionally append any number of “_.submenu_” items to the menubar menu representing a cascading menu hierarchy within the menu that the command will be placed in.  This allows the user to organize plugin menu items into groups, making the menu easier to find commands and easier to read/understand.

#### Tcl Registration

```Tcl
{dir_popup command hierarchy do_procname handle_state_procname}
{dir_popup {checkbutton variable} hierarchy do_procname handle_state_procname}
{dir_popup {radiobutton variable value} hierarchy do_procname handle_state_procname}
{dir_popup separator hierarchy}
```

The “dir\_popup command” type creates a menu command that, when clicked, runs the procedure called _do\_procname_.  The _hierarchy_ value specifies the menu hierarchy (optional) and string text in the menu (joined with periods).  The hierarchy will be created if it does not exist.

The “dir\_popup checkbutton” type creates a menu command has an on/off state associated with it.  When the menu item is clicked, the state of the menu item is inverted and the _do\_procname_ procedure is called.  The _variable_ argument is the name of a variable containing the current on/off value associated with the menu item.  The _hierarchy_ value specifies the menu hierarchy (optional) and string text in the menu (joined with periods).  The hierarchy will be created if it does not exist.

The “dir\_popup radiobutton” type creates a menu command that has an on/off state such that in a group of multiple menu items that share the same variable, only one is on at at time.  When the menu item is clicked, the state of the menu item is set to on and the _do\_procname_ procedure is called.  The _variable_ argument is the name of a variable containing the menu item that is currently on.  The _value_ value specifies a unique identifier for this menu within the group.  When the value of variable is set to value, this menu option will have the on state.  The _hierarchy_ value specifies the menu hierarchy (optional) and string text in the menu (joined with periods).  The hierarchy will be created if it does not exist.

The “dir\_popup separator” type creates a horizontal separator in the menu which is useful for organizing menu options.  The _hierarchy_ value, in this case, only refers to the menu hierarchy to add the separator to (menu separators don’t have text associated with them).

#### Tcl Procedures

**The "do" Procedure**

The "do" procedure contains the code that will be executed when the user invokes the menu item in the menubar.
 
Example:

```Tcl
proc foobar_dir_popup_do {} {
  puts "Foobar directory popup item has been clicked!"
}
```

**The "handle\_state" Procedure**

The "handle\_state" procedure is called when the popup menu is created (when a right click occurs within a tab).  This procedure is responsible for determining the state of the menu item of normal (1) or disabled (0) as deemed appropriate by the plugin creator.

Example:

```Tcl
proc foobar_dir_popup_handle_state {} {
  return $some_test_condition
}
```