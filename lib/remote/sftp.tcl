
proc sFTPopen {ftpI host user password port rq_timeout args } {
  global ftp glob env
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout

  frputs "sFTPopen " ftpI host user password port rq_timeout
  exp_log_user $glob(debug)
  if {$glob(debug)} {
    if {[info exists myexpect] } {
      # only my expect can handle a Log procedure.
      exp_log_file -a -proc Log
    } else {
    exp_log_file  -a -noappend $glob(tmpdir)/Log
    }
  }
  lassign $password  password idfile passphrase
  if {$idfile != "" } {
    set idfile [file join $env(HOME)/.ssh $idfile]

    if {$glob(os) == "Unix" } {
      set r [catch {spawn -noecho sftp -P $port -i $idfile -p $user@$host} out]
    } else {
      set r [catch {spawn -noecho psftp -i $idfile $user@$host} out]
    }
  } else {
    if {$glob(os) == "Unix" } {
       set r [catch {spawn -noecho sftp -P $port  -p $user@$host} out]
    } else {
       set r [catch {spawn -noecho psftp  $user@$host} out]
    }
  }
  if {$r != 0} {return -code error "Really bad error: $out" }
  set timeout $rq_timeout

#  puts "doine expect_after"
  expect_after timeout \
      {if {[info exists ignorto] } {Log "Time out ignored" ;exp_continue } else \
	   {set expect_out(1,string) "Connection timed out $ftpI" ;set re 1}}\
      eof {set expect_out(1,string) "Connection closed $ftpI" ;set re 1}

  frputs "doing expect 1 "
  exp_log_user $glob(debug)
  expect -re "(.*assword:.*)" \
      {Log $expect_out(1,string)
	Log "sending password1"
	exp_send $password\r
	exp_continue} \
      -re "(.*sername .*)\r?\n" {
	Log $expect_out(1,string)
	exp_continue}\
      -re "(.*.?assphrase for key .*: )" {
	Log $expect_out(1,string)
	Log "sending passphrase"
	exp_send "$passphrase\r"
	exp_continue} \
      -re "(.* host key is not .*y/n. |.* authenticity of host .*\(yes/no\)\? )"\
      {
	set st [regsub -all {\r} $expect_out(1,string) {}]
	Log $st
	incr ignorto
	if { [smart_dialog .apop . [_ "Accept new host?"] \
		  [list {} "$st" [_ "\nClick your answer."]] \
		  1 2 [list [_ "No"] [_ "Yes"]]] == 1} {
	  set an [expr {[string match "*(yes/*" $expect_out(1,string)] ? \
			       "yes" : "y" } ]
	  unset ignorto
	  frputs "back from y/n " an
	  Log "sending $an"
	  exp_send "$an\r"
	  exp_continue
	} else {
	  Log "sending 'no'"
	  exp_send "no\r"
	  Log "Aborting Login"
	  set re 10
	}
      } \
      -re "(.*yes\r\n)" {
	Log $expect_out(1,string)
	exp_continue} \
      -re "(.*Warning: .*)\r?\n" {
	Log [regsub -all {\r} $expect_out(1,string) {}]
	exp_continue}\
      -re "(.*Connecting .*)" {
	Log $expect_out(1,string)
	Log "sending password2"
	exp_send $password\r
	exp_continue} \
      -re "(.*Connected to.*)\r?\n" {
	Log $expect_out(1,string)
	exp_continue} \
      -re ".*(Remote working directory is .*)\r?\n" {
	Log $expect_out(1,string)
	exp_continue} \
      -re "(.*Permanently added .*)\r*\n" {
	Log $expect_out(1,string)
	exp_continue}\
      -re "(.*assword.*|.*unable.*|.*assphrase.*|.*onnection closed.*)" {
	Log "exit open: Failed with $expect_out(1,string)"
	set re 5}\
     -re "(.*.?sftp> )" {
	Log $expect_out(1,string)
	set re 0} \
      -re "(.*)\r*\n" {
	Log $expect_out(1,string)
	exp_continue}

  frputs "exiting spawn  " re spawn_id expect_out(1,string) expect_out(buffer)
  if {$re != 0} {
    catch exp_close
    set spawn_id -1
  }
  if {$re == 5} {
    return -code error "Password not accepted $expect_out(1,string)"
  }
  if {$re == 10} {
    #We will not ok a host.  It is up to the user to do that,
    PopError "Host not seen before and rejected, login aborted."
    catch exp_close
    set spawn_id -1
    return -code error "$expect_out(1,string)"
  }
  return $spawn_id
}


proc sFTPcd {ftpI new_wd} {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  exp_log_user $glob(debug)
  frputs "try cd to  " $new_wd
  Log "cd to $new_wd"
  exp_send "cd [sftpfixfilename $new_wd]\r"
  set x 0
  expect \
      -re "\r?cd \[^\n]*\r?\n.?sftp> " {set x 10}\
      -re ".?(Directory .*)\r?\n.?sftp> " {set x 3} \
      -re ".?Remote .* now \[^\r\n]*\r?\n.?sftp> " {set x 10} \
      -re "\r?(Can't change directory\[^\n]*)\r\n.?sftp> " {set x 3} \
      -re "\r?(Couldn't canonicalise\[^\n]*)\r\n.?sftp> " {set x 2}

#  puts "cd... $x"
  frputs "cd: " x expect_out(1,string)
  if {$x != 10 } {
    return -code error "$expect_out(1,string)"
  }
#  puts "cd returns $x"
  return 1
}

proc sFTPrename {ftpI  old new} {
  global ftp
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  # current name old change to new
  # ren for windows
  exp_send "rename [sftpfixfilename $old] \
                   [sftpfixfilename $new]\r"
  expect -re "(Couldn't .*)\r?\n.?sftp> " {incr re} \
      -re "(.*: no such file .*)\r?\n.?sftp> " {incr re} \
      -re "(.*: \[^/\r\n]*)\r?\n.?sftp> " {incr re} \
      -re ".*\r?\n.?sftp> " {incr re 0}

  if {$re} {return -code error "$expect_out(1,string)"}
  return $re
}

proc sFTPdelete {ftpI filename} {
  global ftp
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  # file to remove ftp($ftpI,delete,filename)
  Log "Deleting $filename"
  exp_send "rm [sftpfixfilename $filename]\r"
  expect -re "(Couldn't delete file: .*)\r?\n.?sftp> " {incr re} \
      -re "(Removing .*)\r?\n.?sftp> " {incr re 0}\
      -re ".*rm .*: OK\r?\n.?sftp> " {incr re 0} \
      -re "(.*: \[^/\r\n]*)\r?\n.?sftp> " {incr re}
   if {$re} {return -code error "$expect_out(1,string)"}
  return $re
}

proc sFTPmkdir { ftpI dir } {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  exp_log_user $glob(debug)
  # create dir ftp($ftpI,mkdir,dir)
#  exp_send "mkdir [regsub -all {\ } $dir {\\ }]\r"
  exp_send "mkdir [sftpfixfilename $dir]\r"

  expect -re "\r?(Couldn't .*)\r?\n.?sftp> " {incr re} \
      -re ".*mkdir .*: OK\r?\n.?sftp> " {incr re 0} \
      -re "(.*: \[^/\r\n]*)\r?\n.?sftp> " {incr re} \
      -re ".*\r?\n.?sftp> " {incr re 0}
  if {$re} {return -code error "$expect_out(1,string)"}
  return $re
}

proc sFTPrmdir { ftpI dir } {
  global ftp
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  # dir to remove is ftp($ftpI,rmdir,dir)
#  exp_send "rmdir [regsub -all {\ } $dir {\\ }]\r"
  exp_send "rmdir [sftpfixfilename $dir]\r"
  expect -re "(Couldn't remove directory: .*)\r?\n.?sftp> " {incr re} \
      -re ".*rmdir .*: OK\r?\n.?sftp> " {incr re 0} \
      -re "(.*: \[^/\r\n]*)\r?\n.?sftp> " {incr re} \
      -re ".*\r?\n.?sftp> " {incr re 0}
  if {$re} {return -code error "$expect_out(1,string)"}
  return $re
}

proc sFTPpwd { ftpI } {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  frputs "try pwd  " spawn_id
  exp_log_user $glob(debug)
#  Log "sendingfrom pwd: pwd "
  exp_send "pwd\r"
  set re 0
  expect \
      -re "(pwd ?\[^\n]*\r?\n)" {
	frputs "found echo  " expect_out(1,string)
	exp_continue}\
      -re ".*Remote working directory: (\[^\r]*)\r?\n.?sftp> " {incr re 0} \
      -re ".*Remote working directory is (\[^\r]*)\r?\n.?sftp> " {incr re 0} \
      -re ".*Remote directory is (\[^\r]*)\r?\n.?sftp> " {incr re 0} \
      -re "(.*sftp> )" {
	frputs "pwd,ignor3  " expect_out(1,string)
	set re 2}\
      -re "(\r?\n)" {frputs "pwd,ignor1  " expect_out(1,string) ;exp_continue}
#  Log "pwd returns $expect_out(1,string) & $re"
  frputs "pwd out  " re expect_out(1,string) expect_out(buffer)
  switch $re {
    0 {return $expect_out(1,string)}
    1 {return -code error "$expect_out(1,string)"}
    2 -
    default {return -code error "Unexpected return from pwd:\
                                $expect_out(1,string)"}
  }
}


proc sFTPlist { ftpI all} {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  # use -l (long list) -f (no sort) -a depends on all
  # about 12.5k entries at 80 chars each (hay, just poke around on sourceforge)
  exp_match_max 1000000
  set cmd [expr {$all == "-a" ? "ls -alf" : "ls -lf" } ]
  set cmd [expr {$glob(os) == "Unix" ? $cmd : "ls" } ]
  exp_send "$cmd\r"
  expect \
      -ex "$cmd\r\n" {exp_continue}\
      timeout {if {$glob(abortcmd) == 1} {
	sFTPclose  $ftpI
	set expect_out(1,string) "User Abort";
	set re 1
      } else {
	Log "Large directory, have patience.\
                      You may abort with Stop button. [incr co]"
	exp_continue
      }
      } \
      -re ".*: (Permission denied).*\r?\n.?sftp> " {set re 1} \
      -re "Listing directory \[^\n]*\n" {exp_continue} \
      -re "(.*)\r?\n.?sftp> " {incr re 0} \
      -re "sftp> " {incr re 0; set expect_out(1,string) {}}
  if {$re}  {return -code error "$expect_out(1,string)"}
  # remove the \r chars
  #  puts "$expect_out(1,string)"
  set re [regsub -all {\r} $expect_out(1,string) "" ]
  #  puts  [split $re "\n"]
  exp_match_max -d
  return [split $re "\n"]
}

proc sFTP_DoSearch { ftpI filename } {
  global ftp
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  return -code error "Not supported ... yet"
}

proc sFTPreget { ftpI remoteFileName localFileName } {
  return [sFTPget $ftpI $remoteFileName $localFileName]
}

proc sFTPget { ftpI remoteFileName localFileName } {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  exp_log_user $glob(debug)
  # get  remoteFileName and put it localFileName
  # use -p to get full times etc.
  set opt [expr {$glob(os) == "Unix" ? "-P" : ""} ]
  set remotename [sftpfixfilename $remoteFileName]
  Log "get $remoteFileName to $localFileName"
  exp_send "get $opt $remotename \
  [sftpfixfilename $localFileName]\r"

  expect timeout {
    if {$glob(abortcmd) == 1} {
      set expect_out(1,string) "User abort" ;sFTPclose  $ftpI;set re 1
    } else {
      exp_continue
    }
  } \
  -re "(Couldn't .*)\r\n.?sftp> " {incr re} \
  -re "Fetching .*\r\n" {exp_continue} \
  -re "\r.*$remotename *(\[^ ].*:\[0-9]\[0-9])" {
    LogStatusOnly \
    "Transfer [file tail $remotename] $expect_out(1,string) ETA"
    if {$glob(abortcmd) == 1} {
      set expect_out(1,string) "User abort"
      sFTPclose  $ftpI
      set re 1
    } else {
      exp_continue
    }
  } \
    -re ".*remote:.* => local:\[^\n\r]*\r?\n.?sftp> " {incr re 0}\
    -re "(.*: failure)\r?\n.?sftp> " {incr re} \
    -re ".*\r\n.?sftp> " {incr re 0}
    if {$re} {return -code error "$expect_out(1,string)"}
    return $re
}

proc sFTPput { ftpI localFileName remoteFileName } {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  exp_log_user $glob(debug)
  set localname [sftpfixfilename $localFileName]
  set opt [expr {$glob(os) == "Unix" ? "-P" : ""} ]
  exp_send "put $opt $localname  \
                   [sftpfixfilename $remoteFileName]\r"
  expect \
      timeout {if {$glob(abortcmd) == 1} {
	set expect_out(1,string) "User abort"
	sFTPclose  $ftpI; set re 1
      } else {
	exp_continue
      }}\
      -re "(Couldn't .*)\r\n.?sftp> " {incr re} \
      -re "\r*(.*Permission denied).*\r\n.?sftp> " {incr re} \
      -re "Uploading .*\r\n" {exp_continue} \
      -re "\r.*$localname *(\[^ ].*\[0-9]\[0-9])" {
	LogStatusOnly "Transfer [file tail $localname] $expect_out(1,string) ETA"
	if {$glob(abortcmd) == 1} {
	  set expect_out(1,string) "User abort"
	  sFTPclose  $ftpI; set re 1
	} else {
	  exp_continue
	}} \
      -re ".*local:.* => remote:\[^\n]\r?\n.?sftp> " {incr re 0}\
      -re "(.*: failure)\r?\n.?sftp> " {incr re} \
      -re ".*\r?\n.?sftp> " {incr re 0}

  if {$re && ![string match {*Couldn't fsetstat*} $expect_out(1,string)]} {
    return -code error "$expect_out(1,string)"
  }
  return $re
}

proc sFTPlink { ftpI exist new} {
  global ftp
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  frputs "link  $exist $new"
  # point to this: ftp($ftpI,exist_fname) with this name ftp($ftpI,ln_fname)
  exp_send "ln -s [sftpfixfilename $exist] \
               [sftpfixfilename $new]\r"

  expect \
      -re "Permission denied\r\n.?sftp> " {incr re} \
      -re "(.*psftp: unknown .*)\r?\n.?sftp> " {incr re} \
      -re "Couldn't .*\r\n.?sftp> " {incr re} \
      -re "(.*)\r\n.?sftp> " {incr re 0;puts "$expect_out(1,string)" }
  if {$re} {return -code error "$expect_out(1,string)"}
   return $re
}

proc sFTPchmod {ftpI mode file} {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  exp_log_user $glob(debug)
  frputs "sFTPchmod trying " ftpI mode file
  exp_send "chmod $mode [sftpfixfilename $file]\r"
  expect \
      -re "(Changing mode \[^\n]*)\r\n.?sftp> " {incr re 0} \
      -re "((.ouldn't .*)|(.*denied.*))\r*\n.?sftp> " {incr re} \
      -re "(.*chmod: .*)\r*\n.?sftp> " {incr re} \
      -re "(.*: no such file .*)\r*\n.?sftp> " {incr re} \
      -re "(.*)\r*\n.?sftp> " {incr re 0 }

  frputs "Chmod result  " re expect_out(1,string)
  if {! $re} return ""
  return [regsub -all {\r} $expect_out(1,string) {}]
}
proc sFTPchown {ftpI mode file} {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  exp_log_user $glob(debug)
  frputs "sFTPchown trying " ftpI mode file
  exp_send "chown $mode [sftpfixfilename $file]\r"
  expect \
      -re "(Changing .*\[^\n]*)\r\n.?sftp> " {incr re 0} \
      -re "((.ouldn't .*)|(.*denied.*))\r*\n.?sftp> " {incr re} \
      -re "(.*chown: .*)\r*\n.?sftp> " {incr re} \
      -re "(.*: no such file .*)\r*\n.?sftp> " {incr re} \
      -re "(.*)\r*\n.?sftp> " {incr re 0 }

  frputs "Chown result  " re expect_out(1,string)
  if {! $re} return ""
  return [regsub -all {\r} $expect_out(1,string) {}]
}

proc sFTPclose { ftpI} {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  exp_send [expr {$glob(os) == "Unix" ? "quit\r" : "exit\r"} ]
  exp_log_file
  exp_close
}
proc sftpfixfilename { n } {
  global glob
  if {$glob(os) == "Unix" } {
    set n [regsub -all {\ } $n {\\ }]
    set n [regsub -all {\"} $n {\\"}] ;# an odd \\" \}\] to help emacs
  } else {
    set n [regsub -all {\"} $n {\"\"}]
    set n \"$n\"
  }
  return $n
}

proc sFTPcommand {ftpI command} {
  global ftp glob
  upvar #0 ftp($ftpI,handle) spawn_id
  upvar #0 ftp($ftpI,timeout) timeout
  frputs "try $command " spawn_id
  exp_log_user $glob(debug)
#  expect -re ".*"
#  Log "sendingfrom pwd: pwd "
  exp_send "$command\r"
  set re 0
  expect  -re "(.*)\r?\n.?sftp> " {incr re 2}

  return [regsub -all {\r} $expect_out(1,string) {}]
}

proc sFTPsite2 {ftpI cmd one two} {
  return 0
}
