# Last changes:


Versions `1.50 through 1.53 (20 Apr'20)`

  - apave package v2.5
  - bug fix: focusing items at hotkey pressing (pr_button)
  - bug fix: disabling "undo to blank" in editor
  - upper letters as hotkeys (if possible)
  - tt= argument, %TT wildcard introduced
  - fossil mnu corr.
  - clean-ups


Versions `1.45 through 1.49`

  - macros %MC entered
  - %U wildcard got an argument
  - #ARGS processing corrected
  - rt= argument (size ratio "min/init")
  - apave changed
  - .mnu changed


Version `1.44 (12 Jan'20)`

  - s="" hides HELP/EXEC/SHELL when g= specified
  - cleanup


Version `1.42 (26 Dec'19)`

  - bugfix for choosers (if no choice, fields were cleared)
  - -width/-w, -height/-h for editor may set low/high limits
  - parent/child relations corrected
  - .mnu changed: fonts/sizes, variables initialized, readonly checkboxes


Versions `1.35 through 1.41`

  - "on top" means also "don't close a menu at choosing an item"
  - %C Tcl command added to [OPTIONS]
  - fossil.mnu enhanced with dialogs and %C of [OPTIONS]
  - 'readonly' mode for text widget
  - '-state disabled' replaced by '-ro 1' for .mnu's texts
  - dangerous commands of .mnu are colored by TKE marker's color
  - 'ftx' file content widget
  - theme colors fixed, incl. ones passed by TKE
  - pavecli.tcl for shell scripts
  - doctest-for-emenu updated, mostly for "doctest source"
  - package require pave


Version `1.34 (2 Nov'19)`

  - date/time attributes of menus untouched at executing their commands
  - removing temporary files (menus/*.tmp~) on exit
  - .mnu changed accordingly
  - main.mnu: file differences for Fossil (default) / Git
  - grep.mnu: input dialogs for a search string
  - help updated at aplsimple.github.io


Version `1.33 (31 Oct'19)`

  - pave: file content widgets (fco, flb) added
  - fossil.mnu, git.mnu changed accordingly
  - TKE colors reset for e_menu


Versions `1.30 through 1.32`

  - no moving menu at clicking "On top"
  - when "On top"=on, no exit after RE: and SE: commands
  - delegating "On top"=on to child menus
  - yesnocancel dialog added to existing yesno, okcancel
  - only files less than 1Mb are read (outside of TKE, in file managers)
  - Tcl/Tk offline help file names normalized
  - new %F_ wildcard meaning %F underlined
  - ";" can be used as a command divider in a1=, a2= commands
  - pave modified


Version `1.29 (3 Sep'19)`

  - ::em::prjname
  - help: bitbucket.org -> github.com
  - fossil menus revised and rewritten
  - git menus changed


Version `1.28 (23 Aug'19)`

  - exec -ignorestderr when running Linux terminal
  - "# ARGS1.." works as "#ARGS1.." for in-text arguments
  - possible issue with 'workdir' fixed
  - in pave, in editor, Alt+Up/Down to move lines up/down
  - in pave, undo is enabled by default for text widget
  - few .mnu changed


Version `1.27 (3 Aug'19)`

  - ln=, cn= arguments, to read a word under caret if no selection
  - yn= argument, to confirm exit at Escape pressing
  - in=1.0 in [OPTIONS] section, to save & restore last run position
  - in=1.0 included in .mnu files


Version `1.26 (25 Jul'19)`

  - e_menu.tcl: catched {cd $cpwd} - as the directory may be deleted by commands
  - paveme.tcl: set attrs..-nocomm - as more secure
  - hg.mnu shorted & hg2.mnu expanded with 'hg forget/remove/add'


Version `1.25 (14 Jul'19)`

  - bugfixing: add [OPTIONS] if absent in edited menu
  - 'cd %d' before 'Edit/create selection' & 'Open in browser' in menu.mnu


Version `1.24 (12 Jul'19)`

  - TF= argument, %TF wildcard
  - saving/restoring the variables in [OPTIONS]
  - saving/restoring the cursor's position at editing a menu
  - Ctrl+Y to delete a line at editing
  - Ctrl+D to double a line at editing
  - popup menu at editing
  - hg2.mnu: 'Push with BIN'
  - help updated amd moved to aplsimple.bitbucket.io
  - clearance a bit

Version `1.23 (23 Jun'19)`

  - ss= argument, %ss wildcard
  - option "Do save the edited file" in Preferences/Plugins/e_menu


Version `1.22 (9 Jun'19)`

  - %AR, %L wildcards
  - "ts=", "l=" arguments ("z8=" stuff removed due to %AR)
  - "==" instead of ">>" for input dialogs
  - "-disabledtext" option for input dialogs
  - setting a revision number in "Differences" item of menu.mnu
  - "hg help" in hg.mnu


Version `1.21 (4 Jun'19)`

  - E_MENU_OPTIONS environment variable for options outside the plugin
  - co= option (additional line continuator)
  - tailing spaces trimmed by editor
  - [MENU] section of menu file
  - %b and %B made equal in %IF
  - clearance a bit


Version `1.20 (2 Jun'19)`

  - input dialog (%I wildcard) enhanced
  - line continuation for long items
  - test1.mnu for demo of these
  - help rebuild


Version `1.19 (31 May'19)`

  - help rewritten totally; e_menu's code changed accordingly


Version `1.18 (25 May'19)`

  - bug fixing for double 'exec' in S proc
  - bug fixing for 'pa=' argument - needs to be 0 at calling submenu
  - bug fixing for [string length $] - fired always, not critical
  - %x wildcard (a file extension from %f)
  - changed menu.mnu, hg.mnu, side.mnu, utils.mnu; removed python.mnu
  - starting modifications of help (mainly about 'project dependence')


Version `1.17 (26 Apr'19)`

  - bug fixing for "silent" parameter of shell0 proc:
  - %IF %THEN %ELSE wildcards can include %Q, %D, %T, %I, %C
  - #ARGS10: .. ARGS99: .. arguments for "Run me" are allowed
  - lxterminal replaced xterm in menu.mnu


Version `1.16 (31 Mar'19)`

  - pave code changed:
    - dialog's width calculated neatlier
    - "-ontop" option for dialogs (incl. e_menu's D, Q)
    - \\n to \n converting in "message" (for using dialogs in .mnu)
    - combobox coloring continued
  - some .mnu changed


Version `1.15 (16 Mar'19)`

  - theming in accordance with TKE current theme
  - %D message in %IF clause
  - diff a current tab against left/right tab (utils.mnu)


Version `1.14 (2 Mar'19)`

  - e_menu.tcl changed as for submenu arrow icon:
    - nicely visible
    - Windows issues resolved
  - paveme.tcl changed (menubar added)
  - git2.mnu, side.mnu changed (appearance)


Version `1.13 (9 Feb'19)`

  - pave*.tcl changed (focused, themed)
  - utils.mnu: wget (edited item)
  - %T, %S, %z5 wildcards


Version `1.12 (31 Jan'19)`

  - PaveDialog input: entering data used in commands
  - hg.mnu: input dialogs added
  - %F wildcard added: 'assumed filename' ="%f" if "%f" exists, otherwise ="*"
  - bug fix: workdir taken from %f


Version `1.11 (15 Jan'19)`

  - y[0-9]= arguments as module args from #ARGS[0-9] placeholders
  - s3= argument equal to the first of y[0-9]= or s=


Version `1.10 (11 Jan'19)`

  - fixed after-shocks of pavedialogs
  - corrected the window centering (paveme.tcl)


Version `1.9 (11 Jan'19)`

  - EOL of editable items chanded to |!| instead of \\n (that are for commands)


Version `1.8 (29 Dec'18)`

  - bug fixed as for getting file name to edit (with %E wildcard)
  - command edited 'on fly' (e.g. as in grep.mnu's GREP TEMPLATE)
  - Ctrl+W hotkey for e_menu's editor
  - TKE editor's colors for e_menu's editor
  - icon removed from e_menu's editor
  - menu.mnu, grep.mnu, hg.mnu updated


Version `1.7 (24 Dec'18)`

  - TKE *default_foreground, default_background* used for e_menu main colors
  - e_menu's internal editor called to edit the .mnu
  - menu.mnu, hg.mnu updated


Version `1.6 (20 Dec'18)`

  - %B / %T wildcards are cancelled as browser / terminal
  - %D wildcard (message) is run without catching errors
  - new %C / %T wildcards to run Tcl code with catched / non-catched errors
  - hg.mnu updated (rollback, merge -P)
  - new grep.mnu to search for a selected text in a current directory


Version `1.5 (17 Dec'18)`

  - Windows issue fixed: multiline command batch formed 'on fly'


Version `1.4 (16 Dec'18)`

  - *sel_tcl.tmp* instead of *tmp_sel.tcl* as a temporary file name (for SCM ignoring).
  - %PD wildcard may be extended to contain a list of project directories.
  - %P wildcard allows to prepare a command by Tcl substitutions and replacing \n.
  - menu.mnu changed, fossil.mnu changed, git.mnu changed, new hg.mnu
  - e_menu.tcl is reformatted as for using em:: namespace.

