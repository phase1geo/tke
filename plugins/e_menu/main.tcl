# This TKE plugin allows the user to invoke the user's menu to execute various commands closely bound with TKE environment. The menus are hierarchical and can contain as many submenus and their commands as you need.

# Plugin namespace
namespace eval e_menu {

  variable plugdir [api::get_plugin_source_directory]/e_menu

  variable datadir [api::get_plugin_data_directory]

  variable do_save_file 1
  variable opt1 "EMENU_do_save_file"

#  proc d {args} { tk_messageBox -title INFO -icon info -message "$args" }

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

    set truesel 0
    set txt [get_txt]
    if {$txt == ""} {return [list "" 0 0 0]}
    set err [catch {$txt tag ranges sel} sel]
    if {!$err && [llength $sel]==2} {
      lassign $sel pos pos2           ;# single selection
      set sel [$txt get $pos $pos2]
      set truesel 1
    } else {
      if {$err || [string trim $sel]==""} {
        set pos  [$txt index "insert wordstart"]
        set pos2 [$txt index "insert wordend"]
        set sel [string trim [$txt get $pos $pos2]]
        if {![string is wordchar -strict $sel]} {
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
            set truesel 1 ;# found
            break
          }
        }
        set sel [$txt get $pos $pos2]
      }
    }
    if {[string length $sel] == 0} {
      set pos 0
    }
    return [list $sel $pos $pos2 $truesel]

  }

  #====== Save the selected text to a temporary file

  proc save_to_tmp {sel} {
    set tmpname [file join [api::get_home_directory] "menus/sel_tcl.tmp~"]
    try {
      set tmpfile [open $tmpname w]
      puts -nonewline $tmpfile $sel
      close $tmpfile
    } on error {r} {
      set tmpname ""
    }
    return $tmpname
  }

  #====== Check if the platform is MS Windows

  proc iswindows {} {

    return [expr {$::tcl_platform(platform) == "windows"} ? 1: 0]

  }

  #====== Normalize filename as for Windows

  proc fn {fname} {

    if {[iswindows]} {
      set fname [string map {/ \\\\} $fname]
    }
    return $fname

  }

  #####################################################################
  #  DO procedures
  #####################################################################

  #====== initialize the plugin's directory

  proc init_e_menu {} {

    variable plugdir
    variable datadir
    if {![file exists "$datadir/menus"]} {
      catch "file delete -force $datadir"
      catch "file mkdir $datadir"
      if {[catch {file copy -force $plugdir/menus $datadir} e]} {
        api::show_error "\nCannot create:\n$datadir\n------------\n$e"
        return false
      }
    }
    return true

  }

  #====== Call user's menu

  proc do_e_menu {} {

    variable plugdir
    variable datadir
    variable do_save_file
    if {![init_e_menu]} return
    set h_opt [set s_opt [set f_opt [set d_opt [set PD_opt [set F_opt ""]]]]]
    set z1_opt [set TF_opt [set z3_opt  [set z4_opt  [set z5_opt ""]]]]
    set z6_opt [set z7_opt [set ts_opt [set PN_opt ""]]]
    set offline_help_dir "$plugdir/www.tcl.tk/man/tcl8.6"
    if {[file exists $offline_help_dir]} {
      set h_opt "h=$offline_help_dir"
    } else {
      # try 2nd location of offline help ~/DOC/www.tcl.tk
      catch {set z5_opt $::env(HOME)}
      if {[catch {set offline_help_dir "$z5_opt/DOC/www.tcl.tk/man/tcl8.6"}]} {
        set offline_help_dir "$datadir/www.tcl.tk/man/tcl8.6"
      }
      if {[file exists $offline_help_dir]} {
        set h_opt "h=$offline_help_dir"
      }
    }
    set file_index [api::file::current_index]
    if {$file_index != -1} {
      lassign [get_selection] sel - - truesel
      if {$truesel} {
        set ts_opt "ts=1"  ;# a real selection, not just a word under a caret
      }
      foreach s [split $sel \n] {
        set s_opt [string trimright $s]
        if {$s_opt!=""} {
          ;# only 1st non-empty line of the selection is for s= argument
          ;# all selection is saved to a temporary file of TF= argument
          set s_opt [string map { \> "" \< ""} "s=$s_opt"]
          set tmpname [save_to_tmp $sel]
          if {$tmpname!=""} {
            set TF_opt "TF=$tmpname"     ;# TF= temp.file of the selection
          }
          break
        }
      }
      set file_name [fn [api::file::get_info $file_index fname]]
      if {$file_name != "" && $file_name != "Untitled"} {
        set dir_name [file dirname $file_name]
        catch {cd $dir_name}
        set dir_name [fn $dir_name]
        set f_opt "f=$file_name"
        set d_opt "d=$dir_name"
        set PD_opt "PD=$dir_name"
      } else {
        set d_opt "d=[pwd]"
        set PD_opt "PD=[pwd]"
      }
      # here we try to use env.variables E_MENU_PD and E_MENU_PN
      # and z3/z4 stripped of special symbols (though obsolete can be useful)
      catch {
        set PDname $::env(E_MENU_PD)
        set PD_opt "PD=$PDname"
        set z3_opt "z3=[string map {/ _ \\ _ { } _ . _} $PDname]"
      }
      catch {
        set PNname $::env(E_MENU_PN)
        set PN_opt "PN=$PNname"
        set z4_opt "z4=[string map {/ _ \\ _ { } _ . _} $PNname]"
      }
      if {$file_index>0} {
        catch {set z6_opt z6=[api::file::get_info [expr $file_index-1] fname]}
      }
      catch {set z7_opt z7=[api::file::get_info [expr $file_index+1] fname]}
    }
    set z1_opt "z1=$plugdir"
    # here we try and set colors of TKE's current color scheme
    # (defaults are taken from MildDark theme, huh)
    set fg "fg=[api::theme::get_value tabs -inactiveforeground]"
    set bg "bg=[api::theme::get_value tabs -inactivebackground]"
    set fI "fI=[api::theme::get_value tabs -activeforeground]"
    set bI "bI=[api::theme::get_value tabs -activebackground]"
    set fE "fE=#d2d2d2"
    catch {set fE "fE=[[get_txt] cget -foreground]"}
    set bE "bE=#181919"
    catch {set bE "bE=[[get_txt] cget -background]"}
    set fS "fS=#280000"
    catch {set fS "fS=[[get_txt] cget -selectforeground]"}
    set bS "bS=#ff5577"
    catch {set bS "bS=[[get_txt] cget -selectbackground]"}
    set cc "cc=#00a0f0"
    catch {set cc "cc=[[get_txt] cget -insertbackground]"}
    set z5_opt "z5=$z5_opt"
    # l= option is a current edited line's number (maybe useful in commands)
    set l_opt l=[expr {int([[get_txt] index "insert linestart"])}]
    # try and save the edited file if necessary
    do_pref_load
    if {$do_save_file} {
      catch {api::menu::invoke "File/Save"}
    }
    # at last we try to call e_menu
    if {[catch {
        exec tclsh "$plugdir/e_menu.tcl" "md=$datadir/menus" m=menu.mnu \
          $fg $bg $fE $bE $cc $h_opt $s_opt $f_opt $d_opt $PD_opt $fS $bS \
          $fI $bI $z1_opt $TF_opt $z3_opt $z4_opt $z5_opt $z6_opt $z7_opt \
          $l_opt $ts_opt $PN_opt &
      } e]} {
      api::show_error "\nError of run:\n
        tclsh $plugdir/e_menu.tcl\n
        with arguments:\nmd=$datadir/menus\nm=menu.mnu\n
        ----------------------\n$e"
    }
    return
  }

  #====== Procedures to load/set the plugin's preferences

  proc do_pref_load {} {

    variable do_save_file
    variable opt1
    if {[catch "api::preferences::get_value $opt1" do_save_file] } {
      set do_save_file 1
    }
    get_do_save_file $do_save_file
    return "$opt1 $do_save_file"

  }

  proc do_pref_ui {w} {

    variable opt1
    pack [ttk::labelframe $w.sf -text "
To save the edited file before running an external command
is a sort of insurance against data losses.

Also, this makes the current edited buffer
be accessible to SCM (and similar) commands.
"] -fill x
    api::preferences::widget checkbutton $w.sf "$opt1" \
      "Do save the edited file"
    return

  }

  proc get_do_save_file {inst} {

    variable do_save_file
    set do_save_file [string trim $inst]
    if {$do_save_file ne ""} {
      if { [catch {set do_save_file [expr int($do_save_file)]}] } {
        set do_save_file 1
        return 0
      }
    }
    return 1

  }

  #====== Procedures to register the plugin

  proc handle_state {} {

    return 1

  }

}

#====== Register plugin action

api::register e_menu {
  {menu command {E_menu - User Menus} e_menu::do_e_menu e_menu::handle_state}
  {on_pref_load e_menu::do_pref_load}
  {on_pref_ui e_menu::do_pref_ui}
}
