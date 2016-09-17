set Release(socksend.tcl) {$Header: /home/cvs/tktest/socksend/socksend.tcl,v 1.21 2015/11/16 18:26:15 clif Exp $}
set SockData(debug) 0

proc socksendDebug {str} {
    global SockData
    if {!$SockData(debug)} {return}
    if {![info exists SockData(dbgout)]} {
      set SockData(dbgout) [open /tmp/tkreplSS-[pid].txt w]
    }
    puts $SockData(dbgout) $str
    flush $SockData(dbgout)
}

socksendDebug "I AM: [tk appname] -- [info script]"
proc socksendsetup {port} {
    global SockData
    if {[catch {socket -server sockconnect $port} ret]} {
        puts stderr "socksendsetup: (set up server) socket $port failed ($ret)"
	error $ret $ret
    }
}

proc sockconnect {channel hostaddr port} {
    global SockData
    global ReplayData
    set name [gets $channel]
    set id $name
    set SockData($id,channel) $channel

    fileevent $channel readable "sockreceive $channel"
    after 500 [list ConnectToApp $id]
}

proc sockreceive {channel} {
    global ReplayData
    global SockData

    if [eof $channel] {
        close $channel

        set ReplayData(ConnectedApps) {}
        set ReplayData(Status) Disconnected
	
        return
    }
    set line [gets $channel]
    socksendDebug "READ: $line"
    append SockData($channel,Command) $line\n
    if {[info complete $SockData($channel,Command)]} {
      # processData might not return quickly - if 
      # there is a vwait in the command invoked, for instance.
      #  Must clear that data buffer before invoking this to avoid
      # multiple copies of the command being invoked.

      set data $SockData($channel,Command) 
      set SockData($channel,Command) ""
      processData $data
    }
}

proc processData {data} {
  socksendDebug "PROCESS: $data"
  set fail [catch {uplevel #0 $data} rtn]
  if {$fail} {
      # Sigh.  I don't like putting a call to higher level
      #  code in a low level function, but there's no good way
      #  to pass the error condition back up to application code
      #  from a function invoked from the event loop.
      socksendDebug "ERROR: $data \n  Rtn: $rtn" 
      # RemoteMsgToUser "ERROR: $data \n  Rtn: $rtn" high
  }
}

proc sockappsetup {his_name his_port {his_addr localhost}} {
    socksendDebug "his_name: $his_name his_port $his_port his_addr: $his_addr"
    global SockData
    set count 0
    while {[catch {socket $his_addr $his_port} ch]} {
       incr count
       if {$count > 20} {
           tk_messageBox -type ok -message "Unable to contact $his_name ($his_port at $his_addr)"
	   exit
       }
       after 1000
    }
    fileevent $ch readable "sockreceive $ch"
    set SockData($his_name,channel) $ch
#    puts $ch [file tail [info script]]
    puts $ch [tk appname]
    flush $ch
    socksendDebug "OPENED CLIENT SOCKET as [tk appname]"
}

proc tkrsend {args} {
   return [eval socksend $args]
}

proc tkerror {msg} {
  puts "TKERROR: $msg"
}

proc socksendopen {id port {host localhost}} {
    global SockData
    set SockData($id,channel) [socket $host $port]
    fileevent $ch readable "sockreceive $SockData($id,channel)"
}

proc socksend {args} {

    global ReplayData 
    global SockData

    if {[info exists ReplayData(RecordingOn)] &&
        ($ReplayData(RecordingOn) ==1)} {
      whereAmI-Server
    }

    if {[string first "-a" $args] == 0} {
        set args [string trim [string range $args 6 end]]
    }
    lassign $args key val
    set key [concat {*}$key]
    socksendDebug "SOCKSEND: $args -- $key -- $val"
    if {([string first Destroy $val]  > 0) && 
        ([string first "MsgToU" $val] < 0)} {
        if {![string equal "" [info procs whereAmI-Client]]} {
	  whereAmI-Client
	}
    }
    socksendDebug "SOCKSEND: puts $SockData($key,channel) '$val'"
    puts $SockData($key,channel) $val
    flush $SockData($key,channel) 
}

proc GetUniqueSocketId {} {
  error GetUniqueSocketId
}
