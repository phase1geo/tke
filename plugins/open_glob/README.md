
# What is this?


The `open_glob` plugin allows you to open files from the sidebar's directory.

The files are open recursively, according to the glob patterns.

The file glob patterns are set in "Preferences / Plugins / open_glob".


# Setup


The plugin is customized in "Preferences / Plugins / open_glob".

There are seven strings that can contain lists of glob patterns.

The glob patterns are separated by commas and/or spaces.

For example, the pattern list:
  _*.md, *.tcl_
means that Markdown and Tcl files would be open.

If some pattern contains spaces it should be quoted, e.g.:
  _"my spaced file*.*" "another spaced*.*"_

Do not forget press "Save" button to save your customized lists.


# Usage


To access the `open_glob` plugin you should select one or several (when Ctrl key pressed) directories by left-clicking on them.

After that the right-clicking would envoke the popup menu where you will see the "Open by patterns" item.

This menu item contains your customized pattern lists. Select any list to open the corresponding files in TKE.

