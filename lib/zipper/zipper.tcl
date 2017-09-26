# This code is a rewrite and extension of the zipper
# code found at http://equi4.com/critlib/ and the
# unzip code found at http://wiki.tcl.tk/17433

package provide zipper 0.2
package require vfs::zip

namespace eval zipper {

    namespace ensemble create
    namespace export list2zip unzip zcopy zstat

    # -- list2zip
    #
    # zip a list of files into a single zip archive.
    #
    # ARGUMENTS
    #  from  - path to source directory
    #  flist - a list of file and/or directory paths to be zipped
    #  to    - name of zip file that will be created; including
    #          '.zip' is up to the user; 'to' can be a full or
    #          relative path; if 'to' exists it will be overwritten
    #
    # RETURNS
    #  null
    #
    proc list2zip { dir flist to } {
        initialize [open ${to} w]
        foreach f ${flist} {
            regsub {^\./} ${f} {} to
            set from [file join [file normalize ${dir}] ${to}]
            if { [file isfile ${from}] } {
                set fd [open ${from}]
                fconfigure ${fd} -translation binary -encoding binary
                addentry ${to} [read ${fd}] [file mtime ${from}]
                close ${fd}
            } elseif { [file isdir ${from}] } {
                adddir ${to} [file mtime ${from}]
                lappend dirs ${f}
            }
        }
        close [finalize]
    }

    # -- unzip
    #
    # unzip a zip archive created with list2zip into a directory.
    #
    # ARGUMENTS
    #  zname - path to zip archive file
    #  to    - directory where archived file will be placed; if
    #          directory doesn't exist it will be created
    #
    # RETURNS
    #  0 if success, otherwise 1
    #
    proc unzip { zname to } {

      set zfile [file normalize ${zname}]
      if { ![file readable ${zfile}] } {
        return 1
      }

      if { ![file isdirectory ${to}] } {
        file mkdir ${to}
      }

      set items [zstat ${zname}]

      foreach item [dict keys ${items}] {
        set target [file join ${to} ${item}]
        set type [dict get ${items} ${item} type]
        if { ${type} eq "directory" } {
          file mkdir ${target}
        } else {
          zcopy ${zname} ${item} ${to}
        }
      }

      return 0

    }

    # -- zcopy
    #
    # copy a file from a zip archive file to an external directory
    #
    # ARGUMENTS
    #  zname - path to zip archive file (include the '.zip')
    #  path  - file path within a zip archive (no leading './')
    #  to    - directory where archived file will be placed
    #          (directory must already exist)
    #
    # RETURNS
    #  null
    #
    proc zcopy { zname path to } {
        set zmount [file normalize ${zname}]
        set from [file join ${zmount} ${path}]
        set to [file normalize [file join ${to} ${path}]]
        file mkdir [file dirname ${to}]
        set zid [vfs::zip::Mount ${zmount} ${zmount}]
        file copy ${from} ${to}
        set sdict [::vfs::zip::stat ${zid} ${path}]
        set mode [dict get ${sdict} mode]
        set mtime [dict get ${sdict} mtime]
        set atime [dict get ${sdict} atime]
        catch { file attributes ${to} -permissions ${mode} }
        file mtime ${to} ${mtime}
        file atime ${to} ${atime}
        ::vfs::zip::Unmount ${zid} ${zmount}
    }

    # -- zstat
    #
    # return status information on all the items int a zip archive.
    #
    # ARGUMENTS
    #  zname - path to zip archive file (include the '.zip')
    #
    # RETURNS
    #  dict  - keys are paths and their values are dicts of stat info
    #
    proc zstat { zname } {
        set zfile [file normalize ${zname}]
        set fd [::zip::open ${zfile}]
        set items [dict create]
        foreach item [lsort [array names ::zip::$fd.toc]] {
            ::zip::stat ${fd} ${item} stat
            if { $stat(name) ne "" && $stat(ctime) > 0 } {
                set vdict [dict create {*}[array get stat]]
                set name $stat(name)
                dict unset vdict name
                if { [string index ${name} end] eq "/" } {
                    dict set vdict type directory
                    set name [string trimright ${name} "/"]
                }
                dict set items ${name} ${vdict}
            }
        }
        ::zip::_close ${fd}
        return ${items}
    }

    namespace eval v {
        variable fd
        variable base
        variable toc
    }

    proc initialize {fd} {
        set v::fd $fd
        set v::base [tell $fd]
        set v::toc {}
        fconfigure $fd -translation binary -encoding binary
    }

    proc emit {s} {
        puts -nonewline $v::fd $s
    }

    proc dostime {sec} {
        set f [clock format $sec -format {%Y %m %d %H %M %S} -gmt 1]
        regsub -all { 0(\d)} $f { \1} f
        foreach {Y M D h m s} $f break
        set date [expr {(($Y-1980)<<9) | ($M<<5) | $D}]
        set time [expr {($h<<11) | ($m<<5) | ($s>>1)}]
        return [list $date $time]
    }

    proc addentry {name contents {date ""} {force 0}} {
        if {$date == ""} { set date [clock seconds] }
        lassign [dostime $date] date time
        set flag 0
        set type 0 ;# stored
        set fsize [string length $contents]
        set csize $fsize
        set fnlen [string length $name]

        if {$force > 0 && $force != [string length $contents]} {
            set csize $fsize
            set fsize $force
            set type 8 ;# if we're passing in compressed data, it's deflated
        }

        if {[catch { zlib crc32 $contents } crc]} {
            set crc 0
        } elseif {$type == 0} {
            set cdata [zlib deflate $contents]
            if {[string length $cdata] < [string length $contents]} {
                set contents $cdata
                set csize [string length $cdata]
                set type 8 ;# deflate
            }
        }

        lappend v::toc "[binary format a2c6ssssiiiss4ii PK {1 2 20 0 20 0} \
        $flag $type $time $date $crc $csize $fsize $fnlen \
        {0 0 0 0} 128 [tell $v::fd]]$name"

        emit [binary format a2c4ssssiiiss PK {3 4 20 0} \
        $flag $type $time $date $crc $csize $fsize $fnlen 0]
        emit $name
        emit $contents
    }

    proc adddir {name {date ""} {force 0}} {
        set name "${name}/"
        if {$date == ""} { set date [clock seconds] }
        lassign [dostime $date] date time
        set flag 0
        set type 0 ;# stored
        set fsize 0
        set csize 0
        set fnlen [string length $name]

        set crc 0

        lappend v::toc "[binary format a2c6ssssiiiss4ii PK {1 2 20 0 20 0} \
        $flag $type $time $date $crc $csize $fsize $fnlen \
        {0 0 0 0} 128 [tell $v::fd]]$name"

        emit [binary format a2c4ssssiiiss PK {3 4 20 0} \
        $flag $type $time $date $crc $csize $fsize $fnlen 0]
        emit $name
    }

    proc finalize {} {
        set pos [tell $v::fd]

        set ntoc [llength $v::toc]
        foreach x $v::toc { emit $x }
        set v::toc {}

        set len [expr {[tell $v::fd] - $pos}]
        incr pos -$v::base

        emit [binary format a2c2ssssiis PK {5 6} 0 0 $ntoc $ntoc $len $pos 0]

        return $v::fd
    }

}
