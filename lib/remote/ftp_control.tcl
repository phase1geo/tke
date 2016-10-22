set ftp(procs) [info procs FTP\[a-z\]* ]

# --------- API commands
proc FTP_OpenSession { ftpI sftp host_and_port user password realhost init} {
  global ftp glob config
  frputs "ftpI" "sftp" "host_and_port" "user" "password" "realhost" "init"
  set ftp($ftpI,sftp) $sftp

  # This is here to allow users to write there own xFTP code and have it
  # linked to filerunner on the fly.
  set found 0
  if {[info procs $ftp($ftpI,sftp)FTPopen] == ""} {
    # use 'list' to protect file names with blanks
    foreach dir [list $glob(conf_dir) $glob(lib_fr)/Makefiles $glob(lib_fr)] {
      frputs "looking for $dir/$ftp($ftpI,sftp)ftp.tcl "
      if {[file exist $dir/$ftp($ftpI,sftp)ftp.tcl]} {
        frputs "sourcing  $dir/$ftp($ftpI,sftp)ftp.tcl "
        source $dir/$ftp($ftpI,sftp)ftp.tcl
        if {[info procs $ftp($ftpI,sftp)FTPopen] == ""} {continue}
        set found 1
        break
      }
    }
  } else {
    set found 1
  }
  if { ! $found} {
    PopWarn "Could not find $ftp($ftpI,sftp)ftp.tcl\n \
    looked in these dirs:\n \
    $glob(conf_dir) $glob(lib_fr)/Makefiles $glob(lib_fr) \
    \n\n Aborting $ftp($ftpI,sftp)ftp connection."
    return -code error "$ftp($ftpI,sftp)ftp.tcl not found"
  }
  foreach proc $ftp(procs) {
    if {[info procs $ftp($ftpI,sftp)$proc] == "" } {
      lappend notfound $ftp($ftpI,sftp)$proc
    }
  }
  if {[info exists notfound]} {
    PopWarn "Could not find procs: $notfound \n\n \
    Aborting $ftp($ftpI,sftp) connection."
    return -code error "Required functions not found in $ftp($ftpI,sftp)ftp.tcl"
  }	
  set ftp($ftpI,debug) $glob(ftp,debug)
  set ftp($ftpI,realhost) $realhost
  set ftp($ftpI,user) $user
  set ftp($ftpI,password) $password
  set ftp($ftpI,state) {}
  set ftp($ftpI,pwd) ""
  set ftp($ftpI,new_wd) ""
  set ftp($ftpI,resume) 0
  set ftp($ftpI,init_cmd) $init
  set ftp($ftpI,ignorError) 0
  set ftp($ftpI,error) {}
  set ftp($ftpI,start_time) {}
  set ftp(blksize) [expr {1024 * 16}]
  set r [regexp {([^:]+)(:([0-9]+))?} $host_and_port match ftp($ftpI,host) dummy ftp($ftpI,port)]
  if {!$r} {
    FTP_Error $ftpI "Malformed (s)FTP URL $host_and_port.\
    Format: site:port ex: ftp.foo.bar:21"
  }
  if {$ftp($ftpI,port) == ""} {
    if {$sftp == "" } {
      set ftp($ftpI,port) 21
    } else {
      set ftp($ftpI,port) 22
    }
  }
  if { $ftp($ftpI,debug) } {
    puts "--$ftp($ftpI,init_cmd) --$ftp($ftpI,realhost) --$init"
    puts " realhost  $ftp($ftpI,realhost) \
    \nuser	 $ftp($ftpI,user) \
    \npassword   $ftp($ftpI,user)\
    \nport	 $ftp($ftpI,port)\
    \nmode passive\
    \nprogress FTP_Progress $ftpI \
    \ntimeout $config(ftp,timeout)\
    \noutput FTP_Package_Error $ftpI"

    if {$sftp == "" } {
      set ::ftp::DEBUG 1
    }

  }
  FTP_OpenLink $ftpI
  return
}

proc FTP_OpenLink {ftpI} {
  global ftp config
  global errorInfo
  set ftp($ftpI,timeout)  $config(ftp,timeout)
  set ftp($ftpI,handle) -1
  $ftp($ftpI,sftp)FTPopen \
    $ftpI \
    $ftp($ftpI,host) \
    $ftp($ftpI,user) \
    $ftp($ftpI,password)\
    $ftp($ftpI,port)\
    $config(ftp,timeout)\
    $ftp(blksize) \
    "FTP_Progress $ftpI" \
    "FTP_Package_Error $ftpI"	
  set ftp($ftpI,start_time) {}
  set ftp($ftpI,state) "opening"
  if {$ftp($ftpI,handle) == -1 } {
    set ftp($ftpI,handle) ""
    frputs "Error in OpenLink  " errorInfo
    FTP_Error $ftpI "Error Connecting"
    return
  }
  #  if {$ftp($ftpI,init_cmd) != ""} {
  #    set ftp($ftpI,state) "ftp::Quote"
  #    eval {::ftp::Quote $ftp($ftpI,init_cmd)}
  #  }
}

proc FTP_StartClock {ftpI} {
  global ftp
  set ftp($ftpI,t_one) [ClockMilliSeconds]
  if {$ftp($ftpI,resume)} {
    set ftp($ftpI,expected_size) [expr {$ftp($ftpI,expected_size) - \
					    $ftp($ftpI,resume,pos)}]
  }
  set ftp($ftpI,start_time) [clock seconds]
  set ftp($ftpI,blkcount) 0
  set ftp($ftpI,oldicon) [wm iconname .]
  wm iconname . "? ? [file tail $ftp($ftpI,to_fname)]"
}

proc FTP_StopClock {ftpI {get 0}} {
  global ftp
  if {[set start_time $ftp($ftpI,start_time)] == {} } return

  wm iconname . $ftp($ftpI,oldicon)

  set end_time [clock seconds]
  # This assumes success !! ?
  set size $ftp($ftpI,expected_size)
  if {$end_time == $start_time} {
    set total_speed "? kB/s"
  } else {
    set total_speed "[format "%.2f"\
          [expr {$size / 1024.0 / ($end_time - $start_time)}]] kB/s"
  }
  set ftp($ftpI,start_time) {}
  LogStatusOnly "Transfer [file tail $ftp($ftpI,to_fname)] :\
                 $size bytes -- done ($total_speed)"
  if {$get == "abort" } return
  if {! $get} {
    LogSilent "Transfer ftp://$ftp($ftpI,realhost)$ftp($ftpI,from_fname)\
               -> $ftp($ftpI,to_fname): $size bytes -- done ($total_speed)"
  } else {
    LogSilent "Transfer $ftp($ftpI,from_fname)\
               -> ftp://$ftp($ftpI,realhost)$ftp($ftpI,to_fname):\
               $size bytes -- done ($total_speed)"
  }
  if {$get && [Try {set s [file size $ftp($ftpI,to_fname)] } "" 1] == 0 } {
    if {$ftp($ftpI,expected_size) > 0 && ($s != $ftp($ftpI,expected_size) ||\
        $s != $size) } {
      PopWarn "Warning: Files ftp://$ftp($ftpI,realhost)$ftp($ftpI,to_fname),\
               $ftp($ftpI,from_fname) are not the same size"
    }
  }
}

proc FTP_Abort {ftpI} {
  # To abort a file transfer...
  global ftp
  if {$ftp($ftpI,sftp) == "s"} {
    $ftp($ftpI,sftp)FTPabort $ftpI
  } else {
    ::ftp::Close $ftp($ftpI,handle)
    frputs "Aborted, trying to recover.. "
  }
  FTP_StopClock $ftpI abort
}

proc FTP_Progress {ftpI sofar} {
  global ftp config glob
  set chunksize 4096
  set t_two [ClockMilliSeconds]
  # for speed we use up to the last ten calls to figure the elapsed time
  # the amount of data will be blksize per call, up to the ten we keep track of
  # StartClock sets ftp($ftpI,t_one) to [ClockMilliSeconds]
  incr ftp($ftpI,blkcount)
  if {$t_two - $ftp($ftpI,t_one) < 1000} {return}

  set timeInc [expr {($t_two -  $ftp($ftpI,t_one)) /1000.0}]
  if {$timeInc <= 0.0} { set timeInc 1.0 }
  set speed_Bps [expr { $ftp($ftpI,blkcount) * $ftp(blksize) / \
			   $timeInc}]
  set ftp($ftpI,t_one) $t_two
  set ftp($ftpI,blkcount) 0
  set speed [format "%.2f" [expr {$speed_Bps / 1024.0}]]
  set eta "?"
  set eta_abs "?"

  if {$speed_Bps > 0} {
    # figure how much time we will need to finish at this rate...
    set tmp [format "%.0f" [expr ($ftp($ftpI,expected_size) - $sofar) / \
				$speed_Bps]]
    if { $tmp >= 0 } {
      set eta [format "%02d:%02d" [expr $tmp / 60] [expr $tmp % 60]]
      if { $config(dateformat) == "yymmdd" } {
	set tmp_date "%y%m%d "
      } else {
	set tmp_date "%d%m%y "
      }
      set tmp_s [clock seconds]
      if { [clock format [expr $tmp_s + $tmp] -format "%y%m%d"] ==\
	       [clock format $tmp_s -format "%y%m%d"] } {
	set tmp_date ""
      }
      set eta_abs [clock format [expr $tmp_s + $tmp] -format "$tmp_date%R"]
    }
  }
  if {$ftp($ftpI,expected_size) > 0} {
    LogStatusOnly "Transfer [file tail $ftp($ftpI,to_fname)] :\
                    $sofar / $ftp($ftpI,expected_size) bytes\
                    ($speed kB/s, ETA $eta $eta_abs)"
  } else {
    LogStatusOnly "Transfer [file tail $ftp($ftpI,to_fname)] :\
                     $sofar bytes ($speed kB/s)"
  }
  wm iconname . "$eta $eta_abs [file tail $ftp($ftpI,to_fname)]"
  update idletasks
  if { $glob(abortcmd) } {
    FTP_Abort $ftpI
  }
  return
}

# calls to this funcion from a look at the ftp package:
#
# Pram1       Pram2   Pram3   Reason
# timeout                     connction timed out
# temminated                  remote server closed connection
# user                        info, sent user name
# password                    info, sent password
# error       text            Some error with reason
# connect     usr,pwd,host    opening connection
# connect     <n>             n is the instance, i.e. the nth connection
# quit                        we disconnected
# quote       buffer          quote sent
# type        type            connection type
# list        stats           list is done here are stats
# size        file    size    size sent
# modtime     file    time    file mod time
# pwd         dir             pwd result
# cd          dir             cd result
# mkdir       dir             mkdir result
# rmdir       dir             rmdir result
# delete      file            delete result
# rename      oldname newname rename result
# put         name            put result
# append      name            append result
# get         from     to     reget result
# get         from            get result
#

# ""          Timeout.. error  timeout message
# handle      message   error  some error
# handle      --->      command (only if debug) this command sent
# handle      message   control (only if verbose) internal error
# handle      C: 421 not control (only if verbose) service not available
# handle      ->        ""       (only if debug)   remote server closed
# handle      rc = ..   ""       some error
# handle      C: <n>     control (only if verbose)
# handle      Bad con..  error   bad connection
# handle      Not con..  error   not connected
# handle      n byte..   ""      (only if verbose) num bytes sent
# handle      wrong #..  error  wrong number of arguments
# handle      Must ..    error  bad data source for put
# handle      File ..    error  source file does not exist
# handle      Cannot...  error  can not return variable or channel
# handle      Starting.. ""     (only if debug) starting a connection
# handle      op = val   ""     (only if debug) options given
# handle      no opt..   ""     (only if debug) no options given
# handle      -> n..     ""     (only if debug) bytes sent message
# handle      D: ...     data   (only if verbose) port closed message
# handle      D: ...     data   (only if verbose) connection from message
#
#

proc FTP_Package_Error {ftpI id mess state} {
  global ftp
  frputs "ftp error: " id mess state
  if {$state == "error" && $mess == "Not connected!" } {
    if { $ftp($ftpI,handle) == "" } return
    set mess "Link is closed $ftpI"
    if { $ftp($ftpI,state) == "LinkCheck" } {
      LogStatusOnly "Link Check failed, reopening link to $ftpI"
      FTP_OpenLink $ftpI
      return
    }
    FTP_Error $ftpI $mess
  }
  if {$mess == "Error opening connection!" && \
	  ($ftp($ftpI,state) == "get" || $ftp($ftpI,state) == "put") } {
    return
  }
#  frputs "state >$state <$ftpI handle $id mess >$mess < "
  if {[string match "*ermission denied*" $mess] || \
	  [string match {* 5[0-9][0-9] *} $mess] || \
	  [string match {* 4[0-9][0-9] *} $mess]} {
    if { $ftp($ftpI,error) == {} } {
      set ftp($ftpI,error) $mess
      frputs "setting: " mess
    }
    return
  }

  if {($state == "error" && !$ftp($ftpI,ignorError)) } {
    frputs "Passing " $mess
    FTP_CheckError $ftpI $mess
    return
  }
}

proc FTP_recover {ftpI} {
  global ftp
  set r [catch "$ftp($ftpI,sftp)FTPpwd $ftpI" result]
  set ::ftpVwait [list $r $result]
  frputs "recover  " r result
  return
}

proc FTP_MakeSureLinkIsUp { ftpI } {
  # Can only be called after FTP_OpenSession has been called
  global ftp
  if {$ftp($ftpI,handle) == "" } {
    error "$ftpI has not been opened yet"
    return
  }
  set ftp($ftpI,state)  "LinkCheck"
  # A real hands off condition.  It seems that in some case
  # the ftp code hangs (like after an attempt to get to a
  # write protected file)
  frputs "Deploying the after code "
  set afterId [after 10000 "set ::ftpVwait 10"]
  set afterId2 [after 1 FTP_recover $ftpI]

  vwait ::ftpVwait
  after cancel $afterId
  after cancel $afterId2
  lassign $::ftpVwait r result
  frputs "recover2 " r result
  if {$r != 0 || $result == {}} {
    # Try to re-open the link...
    # If it fails, let it ripple up...
    frputs "Link Check Failed " result
    FTP_OpenLink $ftpI
    # looks good, reset the working dir...
    set wd $ftp($ftpI,pwd)
    frputs "Recovering closed link " wd
    set ftp($ftpI,pwd) ""
    FTP_CD $ftpI $wd
  }
  set ftp($ftpI,error) {}
}

proc FTP_TrimDir { dir } {
  while { [string range $dir 0 1] == "//" } {
    set dir [string range $dir 1 end]
  }
  set dir [string trimright $dir /]
  if { $dir == "" } { set dir / }
  if { [string index $dir 0] == "/" } {
    while { 1 } {
      set len [string length $dir]
      if { [string range $dir [expr $len - 3] end] == "/.." } {
        set dir [file dirname [file dirname $dir]]
      } else {
        break
      }
    }
  }
  return $dir
}

proc FTP_CD { ftpI new_wd } {
  global ftp
  if {$new_wd == "" } { set new_wd "/" }
  if {[string index $new_wd 0] != "/"} {
    FTP_Error $ftpI "Internal error: FTP_CD can only\
                 be called with an absolute path.($new_wd)"
  }
  frputs "CD to " new_wd "was " ftp($ftpI,pwd)
  FTP_MakeSureLinkIsUp $ftpI
  set new_wd [FTP_TrimDir $new_wd]
  if { $new_wd == $ftp($ftpI,pwd) } {
    return 1
  }
  set ftp($ftpI,state) "cd"
  set ftp($ftpI,new_wd) $new_wd
  set r [catch "$ftp($ftpI,sftp)FTPcd $ftpI \"$new_wd\"" result]
  if { $r != 0 && [string match -nocase "*closed*" $result] } {
    FTP_OpenLink $ftpI
    set result [$ftp($ftpI,sftp)FTPcd $ftpI $new_wd]
  }
  if {$result == 1} {
    set ftp($ftpI,pwd) $new_wd
    return 1
  }
  return $result
}

proc FTP_Rename { ftpI oldname newname } {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  set ftp($ftpI,rename,oldname) $oldname
  set ftp($ftpI,rename,newname) $newname
  set ftp($ftpI,state) "rename"
  $ftp($ftpI,sftp)FTPrename $ftpI $oldname $newname
  # Could be a move, get both dirs if so.
  FTP_InvalidateCache $ftpI $oldname
  FTP_InvalidateCache $ftpI $newname
}

proc FTP_Delete { ftpI filename } {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  set ftp($ftpI,delete,filename) $filename
  set ftp($ftpI,state) "delete"
  $ftp($ftpI,sftp)FTPdelete $ftpI $filename
  FTP_InvalidateCache $ftpI $filename
}

proc FTP_MkDir { ftpI dir } {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  frputs "FTP_MKDir  " dir "working dir $ftp($ftpI,pwd)  "
  set ftp($ftpI,state) "mkdir"
  $ftp($ftpI,sftp)FTPmkdir $ftpI $dir
  FTP_InvalidateCache $ftpI $dir
}

proc FTP_RmDir { ftpI dir } {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  set ftp($ftpI,state) "rmdir"
  $ftp($ftpI,sftp)FTPrmdir $ftpI $dir
  # Two dirs need to be removed, the one we did and its parent
  FTP_InvalidateCache $ftpI $dir/foo
  FTP_InvalidateCache $ftpI $dir

}

proc FTP_IsDir { ftpI new_wd } {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  set new_wd [FTP_TrimDir $new_wd]
  set ftp($ftpI,new_wd) $new_wd
  set ftp($ftpI,ignorError) 1
  set ftp($ftpI,state) "cd"
  if { [catch "$ftp($ftpI,sftp)FTPcd $ftpI $new_wd" out] || $out == 0} {
    if {[string match {*timed out*} $out] } {
      return -code error $out
    }
    return 0
  }
  set ftp($ftpI,pwd) $new_wd
  return $new_wd
}

proc FTP_PWD { ftpI } {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  set ftp($ftpI,state) "pwd"
  return [$ftp($ftpI,sftp)FTPpwd $ftpI]
}

proc FTP_Chmod { ftpI mode file} {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  FTP_InvalidateCache $ftpI $file
  return [$ftp($ftpI,sftp)FTPchmod $ftpI $mode $file]
}

proc FTP_Chown { ftpI mode file} {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  FTP_InvalidateCache $ftpI $file
  return [$ftp($ftpI,sftp)FTPchown $ftpI $mode $file]
}

proc FTP_CloseSession { ftpI } {
  global ftp
  FTP_ShutDown $ftpI
  return
}

proc FTP_List { ftpI showall } {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  LogStatusOnly "Reading ftp directory $ftp($ftpI,realhost)$ftp($ftpI,pwd)"
  set cache_result [FTP_ReadCache $ftp($ftpI,realhost)$ftp($ftpI,pwd)]
  if {$cache_result != ""} {
    LogStatusOnly "Reading ftp directory $ftp($ftpI,realhost)$ftp($ftpI,pwd)\
                   -- done (found in cache)"
    return $cache_result
  }
  set all [expr {$showall ? "-a" : ""}]
  set ftp($ftpI,state) "list"

  set result [$ftp($ftpI,sftp)FTPlist $ftpI $all ]

  FTP_WriteCache $ftp($ftpI,realhost)$ftp($ftpI,pwd) $result
  LogStatusOnly "Reading ftp directory $ftp($ftpI,realhost)$ftp($ftpI,pwd) -- done"
  return $result
}

proc FTP_DispatchDoSearch { ftpI filename } {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  set ftp($ftpI,state) "LOCATE"
  set ftp($ftpI,search,name) $filename
  return [$ftp($ftpI,sftp)FTP_DoSearch $ftpI $filename]
}

proc FTP_GetFile { ftpI remoteFileName localFileName expectedSize {resume 0}} {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI

  if { [string range $remoteFileName 0 1] == "//" } {
    set remoteFileName [string range $remoteFileName 1 end]
  }
  if { [string range $localFileName 0 1] == "//" } {
    set localFileName [string range $localFileName 1 end]
  }
  set ftp($ftpI,expected_size) $expectedSize
  set ftp($ftpI,from_fname) $remoteFileName
  set ftp($ftpI,to_fname) $localFileName
  set ftp($ftpI,resume) 0
  set ftp($ftpI,state) "get"
  if { $resume && [file writable "$localFileName"] } {
    set r [catch {set ftp($ftpI,resume,pos) [file size "$localFileName"]}]
    set ftp($ftpI,resume) [expr !$r]
  }
  set get [expr {$ftp($ftpI,resume) ? {reget} : {get}}]
  FTP_StartClock $ftpI

  set rt [$ftp($ftpI,sftp)FTP$get $ftpI $remoteFileName $localFileName]

  FTP_CheckError $ftpI
  return $rt
}

proc FTP_PutFile { ftpI localFileName remoteFileName expectedSize } {
  global ftp
  set ftp($ftpI,expected_size) $expectedSize
  set ftp($ftpI,to_fname) $remoteFileName
  set ftp($ftpI,from_fname) $localFileName

  if { [string range $remoteFileName 0 1] == "//" } {
    set remoteFileName [string range $remoteFileName 1 end]
  }
  if { [string range $localFileName 0 1] == "//" } {
    set localFileName [string range $localFileName 1 end]
  }

  FTP_MakeSureLinkIsUp $ftpI
  FTP_InvalidateCache $ftpI $remoteFileName
  FTP_StartClock $ftpI
  set ftp($ftpI,state) "put"

  set rt [$ftp($ftpI,sftp)FTPput $ftpI $localFileName $remoteFileName]

  FTP_CheckError  $ftpI
  return $rt
}

proc FTP_LinkFile {ftpI exist new } {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  set ftp($ftpI,state) "ln"
  FTP_InvalidateCache $ftpI $new

  return [$ftp($ftpI,sftp)FTPlink $ftpI $exist $new]
}

proc FTP_command {ftpI command} {
  global ftp
  FTP_MakeSureLinkIsUp $ftpI
  set r [catch "$ftp($ftpI,sftp)FTPcommand $ftpI \"$command\"" result]
  if {$r != 0} {
    frputs "Return from $ftp($ftpI,sftp)FTPcommand $ftpI $command " command result
    set result "Sorry, the command \"$command\" returned error: $result"
  }
  return $result
}

proc FTP_InvalidateCache {{ftpI ""} {file ""}} {
  global ftp
  if {$ftpI == ""} {
    set ftp(cache) ""
    if { [info exists  ftp(cacheTimeOut)]} {
      after cancel $ftp(cacheTimeOut)
      unset ftp(cacheTimeOut)
    }
    return
  }
  # If we are here it is a targeted cache delete.
  set r [FTP_ReadCache $ftp($ftpI,realhost)$file 1]
  frputs "\nCache deleted  " r ftpI file
}

proc FTP_Error { ftpI message } {
  global ftp
  FTP_ShutDown $ftpI
  frputs "in FTP_error"
  error  "$message\n\nHost: $ftp($ftpI,realhost)\nCommand: $ftp($ftpI,state)"
}

proc FTP_CheckError {ftpI {message ""}} {
  global ftp
  if {$message == ""} {
    set message $ftp($ftpI,error)
  }
  frputs "CheckError " message
  if {$message == "" } {
    FTP_StopClock $ftpI
    return
  }
  FTP_StopClock $ftpI abort
  error "$message\n\nHost: $ftp($ftpI,realhost)\nCommand: $ftp($ftpI,state)"
}


proc FTP_ShutDown { ftpI } {
  global ftp
  if {$ftp($ftpI,handle) != -1} {
    catch "$ftp($ftpI,sftp)FTPclose $ftpI"
  }
  set ftp($ftpI,handle) ""
  set ftp($ftpI,host) ""
  set ftp($ftpI,realhost) ""
  set ftp($ftpI,user) ""
  set ftp($ftpI,password) ""
  set ftp($ftpI,state) ""
  set ftp($ftpI,pwd) ""
  set ftp($ftpI,new_wd) ""
  set ftp($ftpI,resume) 0
}


proc FTP_ReadCache { key {del 0}} {
  global ftp
  set i 0
  foreach k $ftp(cache) {
    if {[lindex $k 0] == "$key"} {
      set item $k
      set result [lindex $item 1]
      set ftp(cache) [lreplace $ftp(cache) $i $i]
      if { ! $del} {
	lappend ftp(cache) $item
      }
      return [lindex $item 1]
    }
    incr i
  }
  return ""
}

proc FTP_WriteCache { key data } {
  global ftp config
  set item [list $key $data]
  lappend ftp(cache) $item
  set length [llength $ftp(cache)]
  if {$length > $config(ftp,cache,maxentries)} {
    set ftp(cache) [lrange $ftp(cache) 1 end]
  }
  if { [info exists  ftp(cacheTimeOut)]} {
    after cancel $ftp(cacheTimeOut)
  }
  set ftp(cacheTimeOut) [after 60000 FTP_InvalidateCache]
}

if {$glob(debug)} {
  proc FTPlog_user {args} {exp_log_user 1}
} else {
  proc FTPlog_user {args} {exp_log_user 0}
}
