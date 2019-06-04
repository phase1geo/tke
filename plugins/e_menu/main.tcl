# This TKE plugin allows the user to invoke the user's menu to execute various commands closely bound with TKE environment. The menus are hierarchical and can contain as many submenus and their commands as you need.

# Plugin namespace
namespace eval e_menu {

  variable plugdir [api::get_plugin_source_directory]/e_menu

  variable datadir [api::get_plugin_data_directory]

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

  #====== Save the selected text to a temporary file

  proc save_to_tmp {sel} {
    set tmpname [file join [api::get_home_directory] "sel_tcl.tmp"]
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

  #====== Get options y0-y9 from #ARGS0... through #ARGS9...
  #
  # These #ARGS's are the comments of current edited file.
  # E.g. if we have the comments such as:
  #   #ARGS0
  #   #ARGS1 par1 par2
  #   #ARGS2 par3
  # then we would have the options of e_menu:
  #   "y0="
  #   "y1=par1 par2"
  #   "y2=par3"

  proc y_options {} {

    set txt [get_txt]
    set res [list "" "" "" "" "" "" "" "" "" ""]
    if {$txt == ""} {return $res}
    foreach st [split [$txt get 1.0 end] \n] {
      set st [string trim $st]
      if {[string match {#ARGS[0-9]*:*} $st]} {
        #ARGS0: .. #ARGS9: are the same as #ARGS10: .. ARGS99: and at that
        #only first found #ARGS would be interpreted as argument of "Run me"
        #i.e. as %z8 while others can be used in other menus as %y0 .. %y9
        set icol [string first : $st]
        set ind [string index $st 5]
        set y_opt "y$ind=[string trim [string range $st [incr icol] end]]"
        set y_opt [string map {\" \'} $y_opt]
        if {[lindex $res $ind]==""} {
          set res [lreplace $res $ind $ind $y_opt]
        }
      }
    }
    return $res

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
    if {![init_e_menu]} return
    set h_opt [set s_opt [set f_opt [set d_opt [set PD_opt [set F_opt ""]]]]]
    set z1_opt [set z2_opt [set z3_opt  [set z4_opt  [set z5_opt ""]]]]
    set z6_opt [set z7_opt ""]
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
      lassign [get_selection] sel
      foreach s [split $sel \n] {
        set s_opt [string trimright $s]
        if {$s_opt!=""} {
          set s_opt [string map {\" \\\" \{ \\\{ \( "\\\\(" \
          \> "" \< ""} "s=$s_opt"]  ;# s= 1st line of the selection
          set tmpname [save_to_tmp $sel]
          if {$tmpname!=""} {
            set z2_opt "z2=$tmpname"     ;# z2= temp.file of the selection
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
      catch {
        # here we use env.variables E_MENU_PD and E_MENU_PN
        # stripped of special symbols (obsolete, though may be useful)
        set z3_opt "z3=[string map {/ _ \\ _ { } _ . _} $::env(E_MENU_PD)]"
        set z4_opt "z4=$::env(E_MENU_PN)"
      }
      if {$file_index>0} {
        catch {set z6_opt z6=[api::file::get_info [expr $file_index-1] fname]}
      }
      catch {set z7_opt z7=[api::file::get_info [expr $file_index+1] fname]}
    }
    set z1_opt "z1=$plugdir"
    set fg "fg=[api::get_default_foreground]"
    set bg "bg=[api::get_default_background]"
    set fE "fE=#aeaeae"
    catch {set fE "fE=[[get_txt] cget -foreground]"}
    set bE "bE=#161717"
    catch {set bE "bE=[[get_txt] cget -background]"}
    set fS "fS=#ffffff"
    catch {set fS "fS=[[get_txt] cget -selectforeground]"}
    set bS "bS=#0000ff"
    catch {set bS "bS=[[get_txt] cget -selectbackground]"}
    set cc "cc=#888888"
    catch {set cc "cc=[[get_txt] cget -insertbackground]"}
    set y_opts [y_options]
    # args for calling the current module
    # taken from #ARGS[0-9] e.g.
    #ARGS1 arg1 "spaced arg2" etc.
    set z8_opt "z8="
    foreach y $y_opts {
      if {$y!=""} {
        set z8_opt "z8=[string range $y 3 end]"
        break
      }
    }
    if {$z8_opt=="z8=" && $s_opt!=""} {
      set z8_opt "z8=[string range $s_opt 2 end]"
    }
    set z5_opt "z5=$z5_opt"
    if {[catch {
        exec tclsh $plugdir/e_menu.tcl "md=$datadir/menus" "m=menu.mnu" \
          $fg $bg $fE $bE $cc $h_opt $s_opt $f_opt $d_opt $PD_opt $fS $bS \
          $z1_opt $z2_opt $z3_opt $z4_opt $z5_opt $z6_opt $z7_opt $z8_opt &
      } e]} {
      api::show_error "\nError of run:\n
        tclsh $plugdir/e_menu.tcl\n
        with arguments:\nmd=$datadir/menus\nm=menu.mnu\n
        ----------------------\n$e"
    }
    return
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
