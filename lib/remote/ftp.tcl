# This is the ftp file for the library ftp interface
#
package require ftp

# We just get the call and pass it on after supplying the handle

proc FTPopen {ftpI host user password port timeout blksize progress errorproc} {
  global ftp
  set ftp($ftpI,handle) [::ftp::Open $host $user $password \
			     -port $port \
			     -mode passive \
			     -blocksize $blksize \
			     -progress $progress \
			     -timeout $timeout \
			     -output "$errorproc"]
  frputs "Ftpopen  " host user password port ftp($ftpI,handle)
  set ::ftp::ftp$ftp($ftpI,handle)(Start_Time) 0
  set ::ftp::ftp$ftp($ftpI,handle)(Total) 0
}

proc FTPcd { ftpI new_wd} {
  global ftp
  return [::ftp::Cd $ftp($ftpI,handle) $new_wd]
}
		       
proc FTPrename { ftpI old new} {
  global ftp
  ::ftp::Rename $ftp($ftpI,handle)  $old $new
}

proc FTPdelete { ftpI filename} {
  global ftp
  ::ftp::Delete $ftp($ftpI,handle) $filename
}

proc FTPmkdir {ftpI dir } {
  global ftp
  ::ftp::MkDir  $ftp($ftpI,handle) $dir
}

proc FTPrmdir {ftpI dir} {
  global ftp
  ::ftp::RmDir $ftp($ftpI,handle) $dir
}

proc FTPpwd { ftpI } {
  global ftp
  return [::ftp::Pwd $ftp($ftpI,handle)]
}

proc FTPlist { ftpI showall } {
  global ftp
  # all is either "" or "-a"
  return [::ftp::List $ftp($ftpI,handle) $showall ]
}

proc FTPget {ftpI remoteFileName localFileName} {
  global ftp
  return [::ftp::Get $ftp($ftpI,handle) $remoteFileName $localFileName]
}

proc FTPreget {ftpI remoteFileName localFileName} {
  global ftp
  return [::ftp::$Reget $ftp($ftpI,handle) $remoteFileName $localFileName]
}

proc FTPput {ftpI localFileName remoteFileName } {
  global ftp
  return [::ftp::Put $ftp($ftpI,handle) $localFileName $remoteFileName]
}

proc FTPlink {ftpI exist new} {
  global config ftp
  set opt [expr {$config(create_relative_links) == 1 ? "-sr" : "-s"}]
  # Let try to cobble a command together
  return [eval ::ftp::Quote $ftp($ftpI,handle) ln $opt $exist $new ]
  CantDoThat
}

proc FTPsite2 {ftpI cmd one two} {
  global ftp
  frputs "Trying $cmd on  " ftpI $one $two
  set r [::ftp::Quote $ftp($ftpI,handle) SITE $cmd $one $two]
  frputs "FTPchmod  " $cmd $one $two "found  " r
  if {[string match  "200 *" $r]} {
    frputs "Returning success "
    return ""
  }
  return $r
}

proc FTPchmod {ftpI mode file} {
  global ftp
  return [FTPsite2 chmod $mode $file]
}

proc FTPclose {ftpI} {
  global ftp
  ::ftp::ftpClose $ftp($ftpI,handle)
}

proc FTP_DoSearch { ftpI filename} {
  global ftp
  set re [::ftp::Quote $ftp($ftpI,handle) site locate $filename]
  if {[string match {500*} $re] } {
    return -code error $re
  }
  return $re
}

proc FTPcommand {ftpI command} {
  global ftp
  return [eval ::ftp::Quote $ftp($ftpI,handle) $command]
}
			 
			     
