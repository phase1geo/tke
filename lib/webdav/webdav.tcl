# Copyright 2004 Jean-Claude Wippler <jcw@equi4.com>.  All rights reserved.
#
# Reference:
#   http://www.webdav.org
#
# Usage: set dav [::webdav::open url]
#        puts [::webdav::getlist $dav]
#	 ::webdav::close $dav

package provide webdav 0.7

# override std http package
package require http
package require xml
catch { package require expat }

# adapted from TclSOAP 1.6.7's http.tcl
# this proc contributed by [Donal Fellows]
proc ::http::geturl_followRedir {url args} {
  foreach x {1 2 3 4 5} {
    set token [eval [linsert $args 0 geturl $url]]
    switch -glob -- [ncode $token] {
      30[1237] {}
      default  { return $token }
    }
    upvar #0 $token state
    array set meta $state(meta)
    if {![info exist meta(Location)]} { return $token }
    set url $meta(Location)
    cleanup $token
  }
  return -code error "maximum relocation depth reached: site loop?"
}

namespace eval webdav {
  namespace export open close connect
  namespace export enumerate getstat getlist get put copy mkdir delete

  variable timing 0	;# 1 to print network+parse timing info, 0 to disable
  variable seq 0	;# used to generate unique connection descriptors
  variable base	;# base url, one entry per connection
  variable hdrs	;# extra headers, one entry per connection

  # set up an XML parser command object once, to be re-used each time
  variable parser [xml::parser -elementstartcommand  ::webdav::_enumStart \
  -elementendcommand    ::webdav::_enumEnd \
  -characterdatacommand ::webdav::_enumItem \
  -ignorewhitespace     1]

  # perform a connection request via http, args is a pairwise list of headers
  # if the length of args is odd, the first item has extra options for geturl
  # (yeah, it's a hack, but this simplifies use here and it's private anyway)
  proc _request {conn req path args} {
    variable timing
    variable base
    variable hdrs
    set tt [clock clicks]
    #puts "_request $req -> $base($conn)$path"
    set cmd [list ::http::geturl_followRedir $base($conn)$path -method $req]
    if {[llength $args] % 2 != 0} {
      set cmd [concat $cmd [lindex $args 0]]
      set args [lrange $args 1 end]
    }
    lappend cmd -headers [concat $hdrs($conn) $args] -keepalive 0 -binary 1
    set t [eval $cmd]
    upvar #0 $t state
    if {[regexp { [45]0\d (.*)} $state(http) - e]} {
      return -code error "$path: $e"
    }
    set d $state(body)
    #set fd [::open test.out w]
    #puts -nonewline $fd $d
    #::close $fd
    http::cleanup $t
    if {[string first { has been created} $d] >= 0} { set d "" }
    if {$timing} {
      set tt [expr {([clock clicks]-$tt)/1000}]
      puts [list webdav $conn $req $base($conn)$path - $tt mSec]
    }
    return $d
  }

  proc open {url args} {
    variable seq
    variable base
    variable hdrs

    set conn dav[incr seq]
    set base($conn) "[string trimright [regsub ^dav: $url http:] /]/"
    set hdrs($conn) ""

    array set opts {-username "" -password ""}
    array set opts $args
    if {[array size opts] != 2} { return -code error "open: bad option" }

    if {$opts(-username) ne ""} {
      package require base64
      set auth [base64::encode $opts(-username):$opts(-password)]
      lappend hdrs($conn) Authorization [list Basic $auth]
    }
    if {[catch { _head $conn "" }]} {
      close $conn
      return -code error "$url: not found or not a directory"
    }
    return $conn
  }

  proc close {conn} {
    variable base
    variable hdrs
    if {![info exists base($conn)]} {
      return -code error "$conn: no such webdav descriptor"
    }
    unset base($conn) hdrs($conn)
  }

  proc _enumStart {name args} {
    variable lastelem $name
    if {[string match *response $name]} {
      variable response
      array unset response
      set response(type) file
    }
  }

  proc _enumEnd {name args} {
    variable lastelem ""
    if {[string match *response $name]} {
      variable response
      if {[info exists response(path)]} {
        variable result
        set path $response(path)
        unset response(path)
        if {[string index $path end] eq "/"} {
          set response(type) directory
          #set path [string trimright $path /]
        }
        lappend result $path [array get response]
      }
    }
  }

  proc _enumItem {data} {
    variable lastelem
    variable response
    switch -glob $lastelem {
      *href {
        # assume first href item is always the path name
        if {![info exists response(path)]} {
          set response(path) $data
        }
      }
      *getcontentlength {
        set response(size) $data
      }
      *creationdate {
        set data [string map {T " " Z " "} $data]
        set response(ctime) [clock scan $data -gmt 1]
      }
      *getlastmodified {
        set response(mtime) [clock scan [join [lrange $data 0 end-1]]]
      }
    }
  }

  proc enumerate {conn path depth} {
    variable timing
    variable parser
    variable result ""
    variable base
    $parser reset
    set r [_request $conn PROPFIND $path Depth $depth]
    set tt [clock clicks]
    $parser parse $r
    if {$timing} {
      set tt [expr {([clock clicks]-$tt)/1000}]
      puts [list webdav $conn parse $path $depth - \
      [string length $r] bytes, $tt mSec]
    }
    #puts [list enumerate $conn $path $depth $::webdav::base($conn) - $result]
    # remove the root prefix and ignore lock entries
    set b [regsub {^(.*://)?[^/]+} $base($conn) {}]$path
    set n [string length $b]
    #puts b-$b-n-$n
    set r ""
    foreach {x y} $result {
      if {[string first $b $x] == 0} {
        lappend r [string trimleft [string range $x $n end] /] $y
      } else { puts stderr [list DAV-ENUM? $x $b] }
    }
    #puts e-$r
    return $r
  }

  proc getstat {conn path} {
    return [lindex [enumerate $conn $path 0] 1]
  }

  proc getlist {conn {path ""}} {
    set r ""
    foreach {x y} [enumerate $conn $path 1] {
      if {$x ne ""} { lappend r $x }
    }
    #puts g-$r
    return $r
  }

  proc _head {conn path} {
    _request $conn HEAD $path
  }

  proc get {conn path} {
    return [_request $conn GET $path]
  }

  proc put {conn path data} {
    lappend extra -query $data -binary 1 -type application/octet-stream
    lappend extra -keepalive 0
    _request $conn PUT $path $extra
    return
  }

  proc copy {conn path dest} {
    variable base
    _request $conn COPY $path Destination $base($conn)$dest
    return
  }

  proc mkdir {conn path} {
    if {[catch { _head $conn $path }]} {
      _request $conn MKCOL $path
    }
    return
  }

  proc delete {conn path} {
    _request $conn DELETE $path
    return
  }

  # objectified interface
  namespace eval ::webdav::obj { }

  proc _call {conn cmd args} {
    uplevel 1 [linsert $args 0 ::webdav::$cmd $conn]
  }

  proc connect {args} {
    set conn [eval [linsert $args 0 open]]
    interp alias {} ::webdav::obj::$conn {} ::webdav::_call $conn
    return ::webdav::obj::$conn
  }

}

# vim: set sw=4 sts=4 :
