# Plugin namespace
namespace eval editorconfig {

  # Called after the current file is opened
  proc do_open {} {

    set fname [api::file::get_info [api::file::current_index] fname]

    # Parse the .editorconfig files found in the current file's path
    parse_configs $fname

  }

  # Parses the configuration file settings found in the entire directory tree
  proc parse_configs {fname} {

    set path    [file split [file dirname $fname]]
    set pathlen [llength $path]

    array set opts {
      indent_style             ""
      indent_size              ""
      tab_width                ""
      end_of_line              ""
      charset                  ""
      trim_trailing_whitespace ""
      insert_final_newline     ""
      root                     0
    }

    for {set i [expr $pathlen - 1]} {$i >= 0} {incr i -1} {
      set config [file join {*}[lrange $path 0 $i]]
      if {[file exists $config] && [parse_config $config opts]} {
        break
      }
    }

    return [array get opts]

  }

  # Parses the given configuration file.  Returns 0 if the configuration
  # file was unreadable or was not specified as a root file.
  proc parse_config {fname config popts} {

    upvar $popts opts

    set root_found 0
    set skip       0

    if {[catch { open $config r } rc]} {
      return 0
    }

    set contents [read $rc]
    close $rc

    foreach line [split $contents \n] {
      if {[regexp {^\s*[#;]} $line]} {
        # This is a comment
      } elseif {[regexp {^\s*\[([^\]]+)\]} $line -> filepattern]} {
        set skip 0
        if {![parse_filepattern $fname $filepattern]} {
          set skip 1
        }
      } else {!$skip && [regexp {^\s*(\w+)\s*=\s*(\S+)$} $line -> key value]} {
        if {($key eq "root") && ($value eq "true")} {
          set root_found 1
        } elseif {[info exists opts($key)] && ($opts($key) eq "")} {
          set opts($key) $value
        }
      }
    }

    return $root_found

  }

  # Parses the given filepattern and compares it against the given fname.  If they
  # match, returns 1; otherwise, returns 0.
  proc parse_filepattern {fname pattern} {

    set re [string map {{**} {.*} {*} {[^/]*} {.} {\.} {[!} {[^}} $pattern]

    puts "fname: re: $re"

    return 0

  }

}

# Register all plugin actions
api::register editorconfig {
  {on_open editorconfig::do_open}
}
