# This TKE plugin allows the user to invoke the user's menu to execute various commands closely bound with TKE environment. The menus are hierarchical and can contain as many submenus and their commands as you need.

# Plugin namespace
namespace eval e_menu {

  #====== Make string of args (1 2 3 ... be string of "1 2 3 ...")

  proc string_of_args {args} {

    set msg ""; foreach m $args {set msg "$msg $m"}
    return [string trim $msg " \{\}"]

  }

  #====== Show info message, e.g.: MES "Info title" $st == $BL_END \n\n ...

  proc MES {title args} {

    tk_messageBox -parent . -title $title \
      -type ok -default ok -message [string_of_args $args]

  }

  #====== Show error message, e.g.: ERR $st == $BL_END \n\n ...

  proc ERR {args} {

    api::show_error [string_of_args $args]

  }

  #====== Show debug message, e.g.: D $st == $BL_END \n\n ...

  proc D {args} {

    MES "Debug" $args

  }

  proc get_txt {} {

    set file_index [api::file::current_index]
    if {$file_index == -1} {
      return ""
    }
    return [api::file::get_info $file_index txt]

  }

  #====== Get current word or selection

  # returns a list containing:
  # - selection/word
  # - starting position of selection/word or 0
  # - ending position of selection/word

  proc get_selection {} {

    set txt [get_txt]
    if {$txt == ""} {return [list "" 0 0]}
    set err [catch {$txt tag ranges sel} sel]
    if {!$err && [llength $sel]==2} {
      lassign $sel pos pos2           ;# single selection
      set sel [$txt get $pos $pos2]
    } else {
      if {$err || [string trim $sel]==""} {
        set pos  [$txt index "insert wordstart"]
        set pos2 [$txt index "insert wordend"]
        set sel [string trim [$txt get $pos $pos2]]
        if {$sel==""} {
          # when cursor just at the right of word: take the word at the left
          # e.g. if "_" stands for cursor then "word_" means selecting "word"
          set pos  [$txt index "insert -1 char wordstart"]
          set pos2 [$txt index "insert -1 char wordend"]
          set sel [$txt get $pos $pos2]
        }
      } else {
        foreach {pos pos2} $sel {     ;# multiple selections: find current one
          if {[$txt compare $pos >= insert] ||
          [$txt compare $pos <= insert] && [$txt compare insert <= $pos2]} {
            break
          }
        }
        set sel [$txt get $pos $pos2]
      }
    }
    if {[string length $sel] == 0} {
      set pos 0
    }
    return [list $sel $pos $pos2]

  }

  # ====== Save the selected text to a temporary file

  proc save_to_tmp {sel} {
    set tmpname [file join [api::get_home_directory] "tmp_sel.tcl"]
    try {
      set tmpfile [open $tmpname w]
      puts -nonewline $tmpfile $sel
      close $tmpfile
    } on error {r} {
      set tmpname ""
    }
    return $tmpname
  }

  #####################################################################
  #  DO procedures
  #####################################################################

  #===== Call user's menu

  proc do_e_menu {} {

    set h_opt ""
    set s_opt ""
    set f_opt ""
    set d_opt ""
    set s0_opt ""
    set s1_opt ""
    set s2_opt ""
    set z2_opt ""
    set offline_help_dir "[api::get_plugin_directory]/www.tcl.tk/man/tcl8.6"
    if {[file exists $offline_help_dir]} {
      set h_opt "h=$offline_help_dir"
    }
    set file_index [api::file::current_index]
    if {$file_index != -1} {
      lassign [get_selection] sel
      foreach s [split $sel \n] {
        set s_opt [string trimright $s]
        if {$s_opt!=""} {
          set s_opt "s=$s_opt"           ;# s= 1st line of the selection
          set tmpname [save_to_tmp $sel]
          if {$tmpname!=""} {
            set z2_opt "z2=$tmpname"     ;# z2= temp.file of the selection
          }
          break
        }
      }
      set file_name [api::file::get_info $file_index fname]
      if {$file_name != "" && $file_name != "Untitled"} {
        set dir_name [file dirname $file_name]
        set f_opt "f=$file_name"
        set d_opt "d=$dir_name"
        set s0_opt "s0=[file tail $file_name]"
        set s1_opt "s1=[file tail $dir_name]"
      }
    }
    set tke [file normalize [file join [api::get_plugin_directory]/../../../../bin tke]]
    set plugdir "[api::get_plugin_directory]/e_menu"
    exec tclsh $plugdir/e_menu.tcl \
    "m=menus/menu.mnu" "ed=$tke" fs=11 w=40 wc=1 \
    "z1=$plugdir" $h_opt $s_opt $f_opt $d_opt $s0_opt $s1_opt $s2_opt $z2_opt &
  }

  #====== Procedures to register the plugin

  proc handle_state {} {

    return 1

  }

}

#====== Register plugin action

api::register e_menu {
  {menu command {E_menu - User Menus} e_menu::do_e_menu e_menu::handle_state}
}
