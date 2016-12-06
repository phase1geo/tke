# Copyright 2004 Jean-Claude Wippler <jcw@equi4.com>.  All rights reserved.

package provide vfs::dav 0.7

package require vfs
package require webdav

if 0 {
    vfs::filesystem internalerror ::report
    proc ::report {args} { puts stderr "VFS error: $::errorInfo" }
}

namespace eval ::vfs::dav {
    namespace export Mount Unmount

    variable cache 1		;# 1 to enable, 0 to disable dir stat caching
    variable cacheCurr ""
    variable cacheList

    proc Mount {url local args} {
	::vfs::log "dav-vfs: attempt to mount $url at $local"
	set conn [eval [linsert $args 0 ::webdav::open $url]]
	if {![catch {::vfs::filesystem info $url}]} {
	    ::vfs::log "dav-vfs: unmounted old mount point at $url"
	    ::vfs::unmount $url
	}
	::vfs::filesystem mount $local [list ::vfs::dav::handler $url $conn]
	::vfs::RegisterMount $local [list ::vfs::dav::Unmount $conn]
	return $url
    }

    proc Unmount {conn local} {
	::webdav::close $conn
	::vfs::filesystem unmount $local
    }

    proc handler {url conn cmd root relative actualpath args} {
	::vfs::log "handler $url $conn $cmd"
	if {$cmd == "matchindirectory"} {
	    eval [linsert $args 0 $cmd $conn $relative $actualpath]
	} else {
	    eval [linsert $args 0 $cmd $conn $relative]
	}
    }

    proc stat {conn name} {
	::vfs::log "stat $name"
	set r [cached_getstat $conn $name]
	lappend r dev -1 uid -1 gid -1 nlink 1 ino 0 atime 0 mode 0777
	return $r
    }

    proc access {conn name mode} {
	::vfs::log "access $name $mode"
	if {[llength [cached_getstat $conn $name]] > 0} { return 0 }
	return 1
    }

    proc open {conn name mode permissions} {
	::vfs::log "open $name $mode $permissions"
	switch -glob -- $mode {
	    "" -
	    "r" {
		set fd [::vfs::memchan]
		fconfigure $fd -translation binary
		puts -nonewline $fd [::webdav::get $conn $name]
		seek $fd 0
		fconfigure $fd -translation auto
		return [list $fd]
	    }
	    "w" {
		# error if parent dir does not exist
		#::webdav::getstat $conn [file dirname $name]
		# create empty file right away, will overwrite on close
		variable cacheCurr ""
		::webdav::put $conn $name "?"
		set fd [::vfs::memchan]
		::vfs::log "flush on close $conn $name $fd"
		return [list $fd [list ::vfs::dav::doclose $conn $name $fd]]
	    }
	    default {
		return -code error "illegal access mode \"$mode\""
	    }
	}
    }

    proc doclose {conn name fd} {
	variable cacheCurr ""
	::vfs::log "close called $conn $name $fd"
	flush $fd
	fconfigure $fd -translation binary
	seek $fd 0
	::webdav::put $conn $name [read $fd]
    }

    proc dumpcache {} {
	variable cacheCurr
	variable cacheList
	puts [string repeat . 50]
	puts [list cacheCurr $cacheCurr]
	parray cacheList
	puts [string repeat = 50]
    }

    proc cached_getlist {conn path} {
	variable cacheCurr
	variable cacheList
	set e [::webdav::enumerate $conn $path 1]
	set cacheCurr $conn
	array unset cacheList
	set r ""
	foreach {x y} $e {
	    set x [string trimright $x /]
	    if {$x ne ""} { lappend r $x }
	    set cacheList(/$x) $y
	}
#dumpcache
#puts [list cached_getlist $conn $path -> $cacheCurr #[llength $r]]
	::vfs::log [list cached_getlist $conn $path -> $cacheCurr #[llength $r]]
	return $r
    }

    proc cached_getstat {conn path} {
	variable cache
	variable cacheCurr
	variable cacheList
#puts "cached_getstat $conn $path - cacheCurr $cacheCurr"
	if {$cache && $conn eq $cacheCurr && [info exists cacheList($path)]} {
	    set r $cacheList($path)
#puts "    found -> $r"
	    #unset cacheList($path)
	    return $r
	}
#puts "    CACHE MISS"
	return [::webdav::getstat $conn $path]
    }

    proc matchindirectory {conn path actualpath pattern type} {
	::vfs::log "matchindirectory $conn $path $actualpath $pattern $type"
	# glob -nocomplain eats all errors, so squirrel the real status away...
	variable globstatus ""
	set r {}
	if {$pattern ne ""} {
	    if {[catch { cached_getlist $conn $path } all]} {
		set globstatus $all
		return -code error $all
	    }
	    foreach f $all {
		if {[string match $pattern $f]} {
		    ::vfs::log "check: $f"
		    if {[matchtype $conn $path/$f $type]} {
			lappend r [file join $actualpath $f]
		    }
		}
	    }
	} elseif {[matchtype $conn $path $type]} {
	    lappend r $actualpath
	}
	return $r
    }

    proc matchtype {conn path type} {
	if {$type == 0} { return 1 }
	set r [cached_getstat $conn $path]
	if {[lsearch -exact $r directory] >= 0} {
	    if {$type & (1<<2)} { return 1 }
	} else {
	    if {$type & (1<<4)} { return 1 }
	}
	return 0
    }

    proc createdirectory {conn name} {
	variable cacheCurr ""
	::vfs::log "createdirectory $name"
	::webdav::mkdir $conn $name
    }

    proc removedirectory {conn name recursive} {
	variable cacheCurr ""
	::vfs::log "removedirectory $name"
	if {!$recursive && [llength [::webdav::enumerate $conn $name 1]] > 2} {
	    error "cannot delete $name: not empty"
	}
	::webdav::delete $conn $name
    }

    proc deletefile {conn name} {
	variable cacheCurr ""
	::vfs::log "deletefile $name"
	::webdav::delete $conn $name ;# also deletes directory
    }

    proc fileattributes {conn path args} {
	::vfs::log "fileattributes $args"
	switch -- [llength $args] {
	    0 {
		# list strings
		return [list]
	    }
	    1 {
		# get value
		set index [lindex $args 0]
	    }
	    2 {
		# set value
		set index [lindex $args 0]
		set val [lindex $args 1]
		error "write access not implemented"
	    }
	}
    }

    proc utime {conn path actime mtime} {
	# don't throw an error, it messes things up, just ignore it
	#error "utime not implemented"
    }
}

# vim: set sw=4 sts=4 :
