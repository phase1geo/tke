source fontchooser.tcl

pack [fontchooser::create .fc -mono 1]

bind .fc <<FontChanged>> { puts %d }

ttk::style theme use clam
