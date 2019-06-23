
# What is this?

The e_menu plugin provides a system of menus closely bound to the editing.

Also the e_menu plugin provides a context help on Tcl/Tk commands/keywords while editing a Tcl script.

It means that while editing a file.tcl you can set the caret on desirable Tcl/Tk command/keyword and press Ctrl+F1 (or F1, if you map F1 to e_menu) and after that you would get a help page for the selected Tcl/Tk command/keyword.

For details of creating and using menus, refer to:

  http://aplsimple.ucoz.ru/e_menu/e_menu.html

This help is available also in the plugin by pressing F1 key or through its popup menu.

The specific feature of TKE's e_menu is an option available in "Edit / Preferences / Plugins". This option switches on / off saving a current file before running the plugin.

*Note:*
The plugin was tested under Linux (Debian) and Windows. All bug fixes and corrections for other platforms would be appreciated by aplsimple on "gmail.com".


# List of features

The e_menu has the following features:

 - calling a context help for Tcl/Tk while editing a Tcl script (nay, any text containing Tcl)
 - for faster response Tcl/Tk help pages can be made and called offline
 - opening any number of menus containing any commands (programs) to run
 - passing a selected text as %s wildcard to the menu commands to process
 - using a lot of other wildcards in the menu commands, including %f (edited file name), %x (its extention), %d (its directory), %PD (its project's directory derived from %d)
 - commands can be run by itself and by shell in console box
 - commands can be run with or without waiting their completion
 - internal command %E means “edit a file”
 - internal command %B means “browse an internet link”
 - internal command %M means “do a message”
 - internal command %Q means “do a query“
 - internal command %I means “enter a data that can be required by next commands“
 - internal command %C means “execute a Tcl code“
 - internal command %S means “execute OS command“
 - internal command %IF means “conditional execution“ (all internal commands can include a selected text)
 - a batch of multiple commands can be united under a single menu item which in turn can be multi-lined
 - a menu item can include the whole shell script, so no need of disk files to perform it
 - any command can be confirmed, with message box of title and text including the selection
 - input dialogs (with entries, checkboxes, radiobuttons etc.) may provide data for commands
 - a hierarchy of menus is provided
 - a child menu can be called with or without waiting it, with or without closing its parent menu
 - a child menu can be called with closing its parent and calling back the parent after closing the child
 - menus can be called (or made afterwards) as 'stayed on the top of screen'
 - menus can be called to stay at any desirable position with reasonable width
 - inactive menus are lowlighted as opposed to highlighted active ones
 - menu items can be bound to hotkeys F1-F12 (by default they are bound to 1-9a-zA-Z which makes maximum 61+3=64 items)
 - menu items and their underlying commands can include counters of their calls (up to 10 counters per a menu)
 - menu items and their underlying commands can be supplied with current date/time
 - e_menu menus are independent applications and as such can be run independently on the editor
 - any menu item can be assigned to 'autorun' at start of e_menu (submenus including)
 - commands that are invisible in menu may be assigned to 'autorun' (submenus including)
 - Tcl command(s) can be assigned to 'autorun' at start of e_menu
 - menus can be edited 'on fly' and then re-read
 - when calling non-existent menu you are prompted to create it from a template; so you can create all menu system 'on fly'
 - 'autorun' items and commands are also re-run when the menu is re-read
 - menu items can be run repeatedly at intervals set in seconds
 - e_menu can be started with a pause to delay its initialization
 - e_menu neighboring applications can be killed with two keystrokes (sort of clearance)
 - there are a lot of 'look and feel' options
 - the options may be set at calling of e_menu and/or in [OPTIONS] section of a menu
 - parent menu options are inherited by child menu and can be overridden by its [OPTIONS]
 - as an easy exercise, Mercurial or Fossil SCM support can be provided with e_menu
 - encoding of menus is utf-8

Besides, the TKE e_menu plugin supplies the following Tcl features:
 - executing the current Tcl script in tclsh (with selected text as arguments of script)
 - executing the selected Tcl code in tclsh


# Making the menus project-sensitive

In the menus, the %PD wildcard is often used. It is defined as "a directory of current project". If you work with one project, you can rightly set the "PD=" argument of e_menu as "PD=your-project-dir".

But what can you do when the TKE files are from various projects (hence various directories)? In such case you may define PD= argument as a name of file containing the list of project directory names.

For example, you pass to e_menu the "PD=/home/me/PD-dirs.txt" argument where the PD-dirs.txt contains for example:

  *# list of project directories for e_menu*

  *# directory of various projects*
  */home/apl/PG/Tcl-Tk/projects*

  *# directory of TKE clone*
  */home/apl/TKE-clone/TKE-clone*

  *# directory of TKE data (incl. iplugins, plugins, themes)*
  */home/apl/.tke*

The blank lines and the # comments are ignored. All other lines are considered to be directory names of your projects.

When your edited file is located in one of those directories (or its subdirectory), the corresponding directory name is used as %PD wildcard of menu.

While editing a file you would not be uneasy, sort of "what a project is open? which project this file is of? is its project open? may I open files from other projects?" and so on. The main thing is the registration of projects' directories in PD-dirs.txt or whatever it's named. The e_menu would know the project your file is from and as such it would perform the commands related to your file and its project.


# See also

Further details:

  http://aplsimple.ucoz.ru/e_menu/e_menu.html

