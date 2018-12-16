# Plugin namespace
namespace eval vcs_example {

  proc handles {fname} {
    return [expr {![catch { exec hg status $fname }]}]
  }

  proc versions {fname} {
    set versions [list]
    if {![catch { exec hg log $fname } rc]} {
      foreach line [split $rc \n] {
        if {[regexp {changeset:\s+(\d+):} $line -> version]} {
          lappend versions $version
        }
      }
    }
    return $versions
  }

  proc get_file_cmd {fname version} {
    return "|hg cat -r $version $fname"
  }

  proc get_diff_cmd {fname v1 v2} {
    if {$v2 eq "Current"} {
      return "hg diff -r $v1 $fname"
    } else {
      return "hg diff -r $v1 -r $v2 $fname"
    }
  }

  proc find_version {fname v2 lnum} {
    if {$v2 eq "Current"} {
      if {![catch { exec hg annotate $fname } rc]} {
        if {[regexp "^\\s*(\\d+):" [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
          return $version
        }
      }
    } else {
      if {![catch { exec hg annotate -r $v2 $fname } rc]} {
        if {[regexp "^\\s*(\\d+):" [lindex [split $rc \n] [expr $lnum - 1]] -> version]} {
          return $version
        }
      }
    }
    return ""
  }

  proc get_version_log {fname version} {
    if {![catch { exec hg log -r $version $fname } rc]} {
      return $rc
    }
    return ""
  }

}

# Register all plugin actions
api::register vcs_example {
  {vcs "Mercurial2" vcs_example::handles vcs_example::versions vcs_example::get_file_cmd vcs_example::get_diff_cmd vcs_example::find_version vcs_example::get_version_log}
}
