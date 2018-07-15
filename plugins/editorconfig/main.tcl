# Plugin namespace
namespace eval editorconfig {

  array set default_opts {
    indent_style             ""
    indent_size              ""
    tab_width                ""
    end_of_line              ""
    charset                  ""
    trim_trailing_whitespace ""
    insert_final_newline     ""
    root                     0
  }
  array set opts {}

  # Called after the current file is opened
  proc do_open {index} {

    set fname [api::file::get_info $index fname]
    api::log "In do_open, fname: $fname"

    # Parse the .editorconfig files found in the current file's path
    parse_configs $fname

    # Apply the configuration information
    apply_configuration $index

  }

  # Parses the configuration file settings found in the entire directory tree
  proc parse_configs {fname} {

    variable opts
    variable default_opts

    set path    [file split $fname]
    set pathlen [llength $path]

    array set opts [array get default_opts]

    for {set i [expr $pathlen - 2]} {$i >= 0} {incr i -1} {
      set config [file join {*}[lrange $path 0 $i] .editorconfig]
      puts "config: $config"
      if {[file exists $config] && [parse_config [file join {*}[lrange $path [expr $i + 1] end]] $config]} {
        break
      }
    }

  }

  # Parses the given configuration file.  Returns 0 if the configuration
  # file was unreadable or was not specified as a root file.
  proc parse_config {fname config} {

    variable opts

    api::log "In parse_config, fname: $fname, config: $config"

    set root_found 0
    set skip       0

    if {[catch { open $config r } rc]} {
      return 0
    }

    set contents [read $rc]
    close $rc

    foreach line [split $contents \n] {
      if {[regexp {^\s*[#;]} $line]} {
        api::log "  Found a comment: $line"
        # This is a comment
      } elseif {[regexp {^\s*\[([^]]+)\]} $line -> filepattern]} {
        api::log "  Found a file pattern: $line, pattern: $filepattern"
        set skip 0
        if {![parse_filepattern $fname $filepattern]} {
          set skip 1
        }
      } elseif {!$skip && [regexp {^\s*(\w+)\s*=\s*(\S+)$} $line -> key value]} {
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

    return [regexp $re [file tail $fname]]

  }

  # Applies the gathered configuration information for the given file
  proc apply_configuration {index} {

    variable opts

    api::log "In apply_configuration info"

    foreach {opt value} [array get opts] {
      if {($opt ne "root") && ($value ne "")} {
        api::log "Setting option $opt to $value"
      }
    }

  }

}

# Register all plugin actions
api::register editorconfig {
  {on_open editorconfig::do_open}
}
