# Last changes:


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

