# This TKE plugin allows the user to highlight all matches of a word
# when it's selected by double-clicking.

# Plugin namespace
namespace eval open_glob {

  variable globs {
    OG_glob1 ""
    OG_glob2 ""
    OG_glob3 ""
    OG_glob4 ""
    OG_glob5 ""
    OG_glob6 ""
    OG_glob7 ""
  }
  variable dolist {}
  variable ttl "Open by patterns"

  #proc d {args} { tk_messageBox -title INFO -icon info -message "$args" }

  ###################################################################
  # Procedures to register the plugin

  proc do_pref_load {} {

    variable globs
    set listv [list]
    foreach {nam val} $globs {
      if {[catch "api::preferences::get_value $nam" val]} {
        set val ""
      }
      lappend listv $nam [string trim $val]
    }
    return $listv

  }

  proc do_pref_ui {w} {

    variable globs
    pack [ttk::labelframe $w.sf -text \
"Enter the globs to open sidebar files. Divide them by commas and/or spaces.
For example:   1) *.tcl,*.md   2) *.html *.htm *.css   3) \"with space.*\", \
nospace.*"] \
-fill x
    foreach {nam val} $globs {
      api::preferences::widget text $w.sf $nam "[incr iGlobNomer]) glob pattern:" -height 1
#       api::preferences::widget entry $w.sf $nam "Enter glob value:"
    }
    return

  }

  proc open_files {dirname args} {

    foreach dir [glob [file join $dirname *]] {
      if {[file isdirectory $dir]} {
        open_files $dir {*}$args
      }
    }
    # no dirs anymore
    foreach filetempl [split $args ", "] {
      if {![catch {set files [glob [file join $dirname $filetempl]]}]} {
        foreach f $files {
          api::file::add_file $f
        }
      }
    }
    return

  }

  proc do_glob {args} {

    foreach ind [api::sidebar::get_selected_indices] {
      if {[api::sidebar::get_info $ind is_dir]} {
        set dirname [api::sidebar::get_info $ind fname]
        open_files $dirname {*}$args
      }
    }
    return

  }

  proc handle_state {} {

    return 1

  }

}

#####################################################################
# Register plugin action

if 1 {
set open_glob::dolist []
foreach {n pat} [open_glob::do_pref_load] {
  if {[string trim $pat]==""} {continue}
  append open_glob::dolist "{dir_popup command {$open_glob::ttl/$pat} {open_glob::do_glob $pat} open_glob::handle_state}\n\n"
  append open_glob::dolist "{root_popup command {$open_glob::ttl/$pat} {open_glob::do_glob $pat} open_glob::handle_state}\n\n"
}
api::register open_glob " \
$open_glob::dolist \
{on_pref_ui open_glob::do_pref_ui} \
{on_pref_load open_glob::do_pref_load} \
"
}

