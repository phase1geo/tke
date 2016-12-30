## vcs

#### Description

The vcs action allows a plugin to provide the functionality required to create a new version control system handler for the TKE difference view. When a vcs action is created, the action’s name will appear in the version control list within a difference view, and that version control system will be checked to see if it manages an opened file when a difference view is requested.

This action allows a plugin to extend the supported version control systems available.

If your plugin contains the vcs action, you will need to request permission from the user to run your plugin as vcs plugin actions will be given filenames and will be required to run shell commands to perform necessary action.

#### Tcl Registration

`{vcs name handles versions get_file_cmd get_diff_cmd find_version get_version_log}`

The _name_ option specifies the Version Control system name that will be displayed in the difference viewer version control list.  The name does not need to match the version control system; however, it is preferred that the name does match to avoid user confusion.

#### Tcl Procedures

**The “handles” Procedure**

The “handles” procedure is given the full pathname of a file and must return a boolean value of true if the version control system is managing this file; otherwise, it must return a value of false. This procedure should be written in a performance optimized manner as it will be called after the user requests to view a file’s difference view and before the file difference is viewed.

The following example is from the vcs\_example plugin which represents how a Mercurial plugin would operate.

	proc handles {fname} {
	  return [expr {![catch hg status $fname]}]
	}

**The “versions” Procedure**

The “versions” procedure will return a Tcl list containing the version identifiers that are associated with the filename that is passed to the procedure.

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

**The “get\_file\_cmd” Procedure**

Given the specified filename and version identifier, returns the command to execute which will return the full contents of the given version of the given filename.

	proc get_file_cmd {fname version} {
	  return “|hg cat -r $version $fname”
	}

**The “get\_diff\_cmd” Procedure**

Given the specified filename and two versions, return the difference command that will output a unified difference between the two versions of the given file.  The value of the v2 parameter can be a value of “Current” which should be interpreted as the version of the file that is currently being edited.

	proc get_diff_cmd {fname v1 v2} {
	  if {$v2 eq “Current”} {
	     return “hg diff -r $v1 $fname”
	  } else {
	     return “hg diff -r $v1 -r $v2 $fname”
	  }
	}

**The “find\_version” Procedure**

The “find\_version” procedure will return the file version that contained the last change to the specified line number which is no later than the given version number.  Keep in mind that the value of the v2 input parameter may be a value of “Current” which should be interpreted to be the version of the file that is currently being edited.  If the change could not be found, return an empty string.

	proc find_version {fname v2 linenum} {
	  if {$v2 eq “Current”} {
	     if {![catch { exec hg annotate $fname } rc]} {
	        if {[regexp {^\s*(\d+):} [lindex [split $rc \n] [expr $linenum-1]] -> version]} {
	           return $version
	        }
	     }
	  } else {
	     if {![catch { exec hg annotate -r $v2 $fname } rc]} {
	        if {[regexp {^\s*(\d+):} [lindex [split $rc \n] [expr $linenum-1]] -> version]} {
	           return $version
	        }
	     }
	  }
	  return “”
	}

**The “get\_version\_log” Procedure**

The “get\_version\_log” procedure returns the change descriptions for the specified version of the specified filename.  If no change description could be found, return the empty string.

	proc get_version_log {fname version} {
	  if {![catch { exec hg log -r $version $fname } rc]} {
	     return $rc
	  }
	  return “”
	}