namespace eval binlist {

  proc is_less {a b} {

    lassign $a arow acol
    lassign $b brow bcol

    return [expr {($arow < $brow) || (($arow == $brow) && ($acol < $bcol))}]

  }

  proc find_insert_point {pbl index} {

    upvar $pbl bl

    set bl_len [llength $bl]

    if {($bl_len == 0) || [is_less $index [lindex $bl 0]]} {
      return 0
    } elseif {![is_less $index [lindex $bl end]]} {
      return $bl_len
    } else {
      set start 0
      set end   $bl_len
      while {($end - $start) > 1} {
        set mid [expr (($end - $start) / 2) + $start]
        if {[is_less $index [lindex $bl $mid]]} {
          set end $mid
        } else {
          set start $mid
        }
      }
      return $end
    }

  }

  proc ofind_insert_point {pbl index} {

    upvar $pbl bl

    return [lsearch [lsort -dictionary [list {*}$bl $index]] $index]

  }

  proc create {pbl} {

    upvar $pbl bl

    set bl [list]

  }

  proc insert {pbl l} {
  
    upvar $pbl bl

    if {$bl eq ""} {
      set bl $l
      return
    }

    set insert [find_insert_point bl [lindex $l 0]]
    set bl     [linsert $bl $insert {*}$l]

  }

  proc oinsert1 {pbl l} {

    upvar $pbl bl

    if {$bl eq ""} {
      set bl $l
      return
    }

    set insert [ofind_insert_point bl [lindex $l 0]]
    set bl     [linsert $bl $insert {*}$l]

  }

  proc oinsert2 {pbl l} {

    upvar $pbl bl

    set bl [lsort -dictionary [concat $bl $l]]

  }

  proc show {pbl} {

    upvar $pbl bl

    puts $bl

  }

}

set l1 [list]
for {set i 1} {$i < 1000} {incr i} {
  for {set j 0} {$j < 10} {incr j} {
    lappend l1 [list $i $j]
  }
}

for {set i 10} {$i < 150} {incr i} {
  lappend l2 [list 900 $i]
}

binlist::create foo
puts [time { binlist::insert foo $l1 }]
puts [time { binlist::insert foo $l2 }]
# binlist::show foo

puts -nonewline "*"
puts [time { set ifoo [binlist::find_insert_point foo [list 710 20]] } 10000]

binlist::create bar
puts [time { binlist::oinsert1 bar $l1 }]
puts [time { binlist::oinsert1 bar $l2 }]
# binlist::show bar

puts -nonewline "*"
puts [time { set ibar [binlist::ofind_insert_point bar [list 710 20]] } 10000]

binlist::create goo
puts [time { binlist::oinsert2 goo $l1 }]
puts [time { binlist::oinsert2 goo $l2 }]
# binlist::show goo

if {($foo ne $bar) || ($foo ne $goo)} {
  puts "Lists don't match!"
}

puts "ifoo: $ifoo ([lrange $foo [expr $ifoo - 1] [expr $ifoo + 1]])"

if {$ifoo ne $ibar} {
  puts "Indices don't match!"
  puts "ifoo: $ifoo ([lrange $foo [expr $ifoo - 1] [expr $ifoo + 1]])"
  puts "ibar: $ibar ([lrange $bar [expr $ibar - 1] [expr $ibar + 1]])"
}
