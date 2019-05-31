

# What is this?

The e_menu plugin provides a context help on Tcl/Tk commands/keywords while editing a Tcl script.

Also the e_menu provides a system of context menus closely bound to the editing. The menu system isn't restricted with Tcl/Tk.

As for the context Tcl/Tk help, it's meant that while editing a file.tcl you can set the caret on desirable Tcl/Tk command/keyword and press Ctrl+F1 (or F1, if you map F1 smartly to call e_menu) and after that you would get a help (man) page for the selected Tcl/Tk command/keyword.

See
  http://aplsimple.ucoz.ru/e_menu/e_menu.html
about details of creating and using menus.

This help is available also in the plugin by pressing F1 key or through its popup menu.

*Note:*
The plugin was tested under Linux (Debian) and Windows. All bug fixes and corrections for other platforms would be appreciated at aplsimple$mail.ru.


# Prerequisites

The following Tcl packages need to be installed:

tcllib
tklib
tls (tcl-tls in Debian)


# List of features

The e_menu has the following features:

 - calling a context help for Tcl/Tk during editing
 - Tcl/Tk help pages can be made and called offline for faster response
 - opening any number of menus containing any commands (programs) to run
 - passing a selected text to the menu commands to process
 - the selection can be passed as underlined (“_” instead of “ ”), 'plused' (“+” instead of “ ”) or stripped of special symbols (“, $, %, {}, [], <>, *)
 - commands can be run by itself and by shell in console box
 - commands can be run with or without waiting their completion
 - internal command %E %s means “edit/create a file(s) with name(s) = selected text”
 - internal command %B ”%s“ means “browse an internet link = selected text”
 - internal command %M ”%s“ means “show a message = selected text”
 - internal command %Q “title” “message %s” means “ask a confirmation, possibly with selected text”
 - a batch of commands can be united under a single menu item
 - any command can be confirmed, with message box of title and text including the selection
 - commands can include backslashes as opposed to Unix's ”/“ (esp. for Windows)
 - a hierarchy of menus
 - a child menu can be called with or without waiting it, with or without closing its parent menu
 - a child menu can be called with closing its parent and calling back the parent after closing the child
 - menus can be called (or made afterwards) as 'stayed on the top'
 - menus can be called to stay at any desirable position with reasonable width
 - inactive menus are lowlighted as opposed to highlighted active ones
 - menu items can be bound to hotkeys F1-F12 (by default they are bound to 1-9a-z)
 - menu items and their underlying commands can include up to 10 counters of runs per a menu
 - menu items and their underlying commands can be supplied with current date/time
 - menus can be run just before running the editor (with some shell command file)
 - menus are independent applications and as such can be run independently on the editor
 - any menu item can be assigned to 'autorun' at start of e_menu (submenus including)
 - commands that are invisible in menu may be assigned to 'autorun' (submenus including)
 - Tcl command(s) can be assigned to 'autorun' at start of e_menu
 - menus can be edited 'on fly' and then re-read
 - when calling non-existent menu you are prompted to create it; so you can create all menu system 'on fly'
 - 'autorun' items and commands are also re-run when the menu is re-read
 - e_menu can be started with a pause to delay its initialization
 - items can be run repeatedly at intervals set in seconds
 - e_menu neighboring applications can be killed with two keystrokes (sort of clearance)
 - there are a lot of 'look and feel' options (incl. highlighting 'master' or 'dangerous' menus)
 - the options may be set at calling of e_menu and/or in [OPTIONS] section of a menu
 - parent menu options are inherited by child menu and can be overridden by its [OPTIONS]
 - for an easy exercise, git as well as fossil support of the editor can be implemented with e_menu
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

Note that the blank lines and the # comments are ignored. All other lines are considered to be directory names of your projects.

When your edited file is located in one of those directories (or its subdirectory), the corresponding project directory is used as %PD wildcard of menu.


# Few hints

Please, view tke/plugins/e_menu/main.tcl for the calling format of the plugin. You can include your own arguments in the call.

You may consider the start of TKE from a command .sh/.bat file with setting the PD variable that means a project directory for e_menu.

Having the Desktop TKE folder and a heap of command files in it, you can run the TKE and its plugins being sensitive to your project's location.


# Example of use

Here is an example of bash file that runs TKE and e_menu application positioned at right side of screen:

  #! /bin/bash
  myTKE="/home/apl/PG/Tcl-Tk/UTILS/tke"
  # This makes TKE and its plugins being project sensitive
  PROJECT="$1"
  THEME="$2"
  SUBJ=": $3"
  DIR="$myTKE/lib/tke/plugins/$PROJECT"
  BROWSER="/usr/bin/chromium"
  EDITOR="$myTKE/bin/tke"
  LEFT=+1505
  curdir="$PWD"
  cd "$DIR"
  wish $myTKE/lib/tke/plugins/e_menu/e_menu/e_menu.tcl \
    "s0=$PROJECT" "x1=$THEME" "x2=$SUBJ" "b=$BROWSER" "PD=$DIR" \
    "ed=$EDITOR" "h=/home/apl/DOC/Tcl/www.tcl.tk/man/tcl8.6" \
    m=menus/side.mnu g=$LEFT+27 t=1 o=0 w=18 fs=10 pa=100 ah=1,2,3  &
  $EDITOR &
  cd "$curdir"

The m= argument means that the started side.mnu is located in menus subdirectory of the e_menu plugin's directory. Of course, it may be located wherever you want. But this example shows that any project's menus may be accumulated uniformly under the menus subdirectory of plugin. Thus, common menus may be under menus/ directory, while particular ones being in menus/subdirs.

The h= argument means the location of offline Tcl help.

The g= means +x+y screen position of side.mnu.

The t=1 sets "Stay on top" mode for the menu.

The o=0 hides the ornamental messages of menu.

The w=21 sets the menu's width in characters.

The fs= sets the menu items' font size.

The pa=100 sets 100 milliseconds pause before real working of e_menu (it may be useful for some preparative actions taken before showing the menu).

The ah=1,2,3 runs the [HIDDEN] items of side.mnu at its startup.

This bash file (let it be tke.sh) can be run so:
  bash tke.sh "my_project_1" "Preparing docs" ": readme.md"
which sets the project dir, theme and subject arguments for e_menu.

A similar .bat file can be created to run TKE in Windows.
