=Last changes:

Version 1.9 (11 Jan'19)

  - EOL of editable items chanded to |!| instead of \\n (that are for commands)


Version 1.8 (29 Dec'18)

  - bug fixed as for getting file name to edit (with %E wildcard)
  - command edited 'on fly' (e.g. as in grep.mnu's GREP TEMPLATE)
  - Ctrl+W hotkey for e_menu's editor
  - TKE editor's colors for e_menu's editor
  - icon removed from e_menu's editor
  - menu.mnu, grep.mnu, hg.mnu updated


Version 1.7 (24 Dec'18)

  - TKE default_foreground, default_background used for e_menu main colors
  - e_menu's internal editor called to edit the .mnu
  - menu.mnu, hg.mnu updated


Version 1.6 (20 Dec'18)

  - %B / %T wildcards are cancelled as browser / terminal
  - %D wildcard (message) is run without catching errors
  - new %C / %T wildcards to run Tcl code with catched / non-catched errors
  - hg.mnu updated (rollback, merge -P)
  - new grep.mnu to search for a selected text in a current directory


Version 1.5 (17 Dec'18)

  - Windows issue fixed: multiline command batch formed 'on fly'


Version 1.4 (16 Dec'18)

  - sel_tcl.tmp instead of tmp_sel.tcl as a temporary file name (for SCM ignoring).
  - %PD wildcard may be extended to contain a list of project directories.
  - %P wildcard allows to prepare a command by Tcl substitutions and replacing \n.
  - menu.mnu changed, fossil.mnu changed, git.mnu changed, new hg.mnu
  - e_menu.tcl is reformatted as for using em:: namespace.

