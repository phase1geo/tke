set ::tke_dir [file dirname [pwd]]

source fontchooser.tcl
source utils.tcl

pack [fontchooser::create .fc -mono 1 -sizes {6 7 8} -styles {Regular} -effects 0]

bind .fc <<FontChanged>> { puts %d }

ttk::style theme use clam
