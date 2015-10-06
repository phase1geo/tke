set tke_dir  [file normalize ..]
set tke_home [file join ~ .tke]

package require tablelist

source utils.tcl
source themes.tcl
source themer.tcl

ttk::style theme settings clam {
  ttk::style configure BButton [ttk::style configure TButton]
  ttk::style configure BButton -anchor center -padding 2 -relief flat
  ttk::style map       BButton [ttk::style map TButton]
  ttk::style layout    BButton [ttk::style layout TButton]
}

ttk::style theme use clam

themer::create
