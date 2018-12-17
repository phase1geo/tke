
# What is this?


The `add_shortcut` plugin allows you to add your own hotkeys to the existing TKE shortcuts.

You can make the shortcuts that start the command sets of:

  - menu item invokers
  - event handlers
  - external command starters
  - or a combination of these

A usual example looks like:

  - invoke "File/Save All" menu item to save the file changes
  - (on condition) execute "compile" command
  - (on condition) execute "build" command
  - execute "run" command

As the compile/build/run all depend on a file extension, you can set the conditional execution of the commands, e.g. %IF "%x"==".html" %THEN browser "%f".

Just that simple. You make these command sets and assign shortcuts to run them. Then you press the shortcuts while editing a file in TKE and view the results of their execution.

Also, the `add_shortcut` plugin allow you to add the duplicates to the existing TKE shortcuts, e.g. it might be convenient to have:

  F2 as the duplicate of Ctrl+S
  F3 as the duplicate of Alt+N
  etc.

Thus you can use the TKE shortcuts as well as the shortcuts you got used to in other environments.

The `add_shortcut` plugin can be also helpful for those localized TKE installations where it's desirable to have Ctrl+C, Ctrl+X, Ctrl+V working with a locale keyboard. Their calls can be problematic on localized platforms. In such cases you can engage this plugin.

The `add_shortcut` plugin can make the Super and Menu keys available for TKE, e.g. Super key for TKE main menu (or any external command), Menu key for TKE popup menus.

Finally, the `add_shortcut` plugin can run its shortcuts at the start of TKE.

*Note:*
The plugin was tested under Linux (Debian) and Windows. All bug fixes and corrections for other platforms would be appreciated at aplsimple$mail.ru.


# Usage


The `add_shortcut` plugin consists of two parts: a custimization and an execution.

The customizing part is invoked by *Plugins / Add Shortcuts* menu item.

After customizing you should restart TKE in order to enable the plugin's second part, i.e. the execution of the plugin's customized shortcuts.

The execution is rather straightforward: you are just pressing the according keys to execute the customized commands.

The customization is rather simple. After calling "Plugin/ Add Shortcuts" menu item you enter the following dialog:

  *-----------------------------------------------------------------*
  *|                 General info about the plugin                 |*
  *-----------------------------------------------------------------*
  *|      Group info              |                                |*
  *|      of current record       |                                |*
  *|------------------------------|                                |*
  *|                              |                                |*
  *|                              |         Tree of groups         |*
  *|      Shortcut info           |                                |*
  *|      of current record       |         and shortcuts          |*
  *|                              |                                |*
  *|                              |                                |*
  *|------------------------------|                                |*
  *| Buttons to update the record |                                |*
  *-----------------------------------------------------------------*
  *| Field for messages           | Buttons to save/cancel changes |*
  *-----------------------------------------------------------------*

At the left you are entering the data of shortcuts, then with *Add* / *Change* button you are posting the changes to the list at the right.

Setting the cursor on a record and pressing *Delete* button you would delete this record.

To create a new record you should fill the following fields:

  - Group info:    *Name* - any description of shortcut group
    (as for a group record, it's enough to fill this field only)

  - Shortcut info: *Name* - any description of the shortcut

  - Shortcut info: `ID`   - the main field where you should press the hotkey(s)

Note that the `ID` field cannot accept all possible combinations of keys. For example, Ctrl+F1..F12, Alt+F1..F12 would most probably be caught by OS, so you are allowed only Shift+F1..F12 in case you want to use F1-F12 row of keys with modifiers.

In order to help with command sets, the dialog provides the *Type* field, where you may choose the type of record and then fill its runnable contents:

  - MENU - menu envoker, set as: *MENU = menu path*
           e.g. MENU = File/Save
  - EVENT - event handler, set as: *MENU = event*
           e.g. EVENT = <Control-percent>
  - COMMAND - command starter, set as: *COMMAND = external command*
           e.g. COMMAND = some-external-command
  - MISC (any combination of previous)

The conditional execution is defined as:

  MENU    = *%IF* condition *%THEN* menu path1 *%ELSE* menu path2
  EVENT   = *%IF* condition *%THEN* event handler1 *%ELSE* event handler2
  COMMAND = *%IF* condition *%THEN* command1 *%ELSE* command2

where *%ELSE* part is optional and *condition* can be:

  - to check if the current platform is Windows:
      [iswindows]
  - to check if the current platform is not Windows:
      ![iswindows]
  - to check the current file's pathname:
      "%f"=="file"
  - to check the current file's root name:
      "%n"=="fileroot"
  - to check the current file's extention:
      "%x"==".ext"
  - to check the current file directory:
      "%d"=="dir"
  - to check the current file directory's root name:
      [file tail "%d"]=="dirroot"
  - to check other Tcl conditions, e.g.
      [clock format [clock seconds] -format %A]=="Friday"

The *Contents* field can contain the following wildcards:

  %t0 - current time (hh:mm:ss)
  %t1 - current date (yyyy-mm-dd)
  %t2 - current date+time (yyyy-mm-dd_hh:mm:ss)
  %t3 - current day of week (e.g. Monday)
  %f  - current edited file
  %n  - name (without dir and ext) of current edited file
  %x  - extention of current edited file
  %d  - directory of current edited file
  %s  - current selection/word
  %t  - terminal
  %b  - browser

For example:

  COMMAND = cd "%d"
  Command = %t tclsh "%f"
  command = %b "%f"

You can also include your comments to the contents. Use any markers, e.g.:

  #   it's me.tcl
  //  it's me.cpp
  rem it's me.bat

Finally, you can set the options:

  - *Active* to enable/disable the current record
  - *AutoStart* to run the record at start of TKE
  - *Sorted list* to sort the list of records

As a special help for event handlers you have the *Test* button that allows you to check if your event handlers are correct.

After changing the shortcut list you may click *Apply* or *Save* to save it.

The `add_shortcut` plugin makes backups of old data. If you'd mistaken, those backups would help you to roll back the changes.

The customized data are saved to *adsh_platform.ini* files. So, though having [iswindows] condition you have no need of it.

