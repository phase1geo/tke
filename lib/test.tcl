set auto_path [list [pwd] {*}$auto_path]

package require -exact ctext 5.0

# Create the UI
pack [ctext .t -linemap 1 -linemap_minwidth 2 -diff_mode 1 -wrap none] -fill both -expand yes

# Insert content
if {![catch { open [file join api.tcl] r } rc]} {
  .t insert end [read $rc]
  close $rc
}

# THIS CODE DOES WHAT I WANT THE LIBRARY CODE TO DO
# .t tag add diff:A:S:1 1.0 3.end
# .t tag add diff:A:D:4 4.0 5.end
# .t tag add diff:A:S:4 6.0 end
#
# .t tag add diff:B:S:1  1.0 10.end
# .t tag add diff:B:D:11 11.0 14.end
# .t tag add diff:B:S:11 15.0 end

.t tag add diff:A:S:1 1.0 end
.t tag add diff:B:S:1 1.0 end

proc handle_adds {win line count} {
  
  # Get the current diff:A tag
  set tag [lsearch -inline -glob [$win tag names $line.0] diff:A:*]
  
  # Get the beginning and ending position
  lassign [$win tag ranges $tag] start_pos end_pos
  
  # Replace the diff:A tag
  $win tag remove $tag $start_pos $end_pos
  $win tag add $tag $start_pos $line.0
  
  # Add new tags
  set pos [$win index "$line.0+${count}l linestart"]
  $win tag add diff:A:D:$line $line.0 $pos
  $win tag add diff:A:S:$line $pos $end_pos
  
  # Colorize the *D* tag
  $win tag configure diff:A:D:$line -background "light green"
  $win tag raise diff:A:D:$line
  
  # Update the linemap
  ctext::linemapUpdate $win
  
}

proc handle_subs {win line count str} {
  
  # Get the current diff: tags
  set tagA [lsearch -inline -glob [$win tag names $line.0] diff:A:*]
  set tagB [lsearch -inline -glob [$win tag names $line.0] diff:B:*]
  
  # Get the beginning and ending positions
  lassign [$win tag ranges $tagA] start_posA end_posA
  lassign [$win tag ranges $tagB] start_posB end_posB
  
  # Remove the diff: tags
  $win tag remove $tagA $start_posA $end_posA
  $win tag remove $tagB $start_posB $end_posB
  
  # Insert the string
  $win insert $line.0 $str
  
  # Add the tags
  set pos [$win index "$line.0+${count}l linestart"]
  $win tag add $tagA $start_posA [$win index "$end_posA+${count}l linestart"]
  $win tag add $tagB $start_posB $line.0
  $win tag add diff:B:D:$line $line.0 $pos
  $win tag add diff:B:S:$line $pos [$win index "$end_posB+${count}l linestart"]
  
  # Colorize the *D* tag
  $win tag configure diff:B:D:$line -background pink
  $win tag raise diff:B:D:$line
  
  # Update the linemap
  ctext::linemapUpdate $win
  
}

set adds       0
set subs       0
set total_subs 0
set lineSub    1
set lineAdd    1

if {![catch { exec -ignorestderr hg diff api.tcl } rc]} {
  foreach line [split $rc \n] {
    puts "line: $line"
    if {[regexp {^@@\s+\-(\d+),\d+\s+\+(\d+),\d+\s+@@$} $line -> lineSub lineAdd]} {
      set adds 0
      set subs 0
      set strSub ""
      set lineSub $lineAdd
    } elseif {[regexp {^\+([^+]|$)} $line]} {
      if {$subs > 0} {
        handle_subs .t [expr $lineSub + ($total_subs - $subs)] $subs $strSub
        set subs 0
        set strSub ""
      }
      incr adds
      incr lineSub
      incr lineAdd
    } elseif {[regexp {^\-([^-].*$|$)} $line -> str]} {
      if {$adds > 0} {
        handle_adds .t [expr $lineAdd + ($total_subs - $adds)] $adds
        set adds 0
      }
      append strSub "$str\n"
      incr subs
      incr total_subs
    } else {
      if {$adds > 0} {
        handle_adds .t [expr $lineAdd + ($total_subs - $adds)] $adds
        set adds 0
      } elseif {$subs > 0} {
        handle_subs .t [expr $lineSub + ($total_subs - $subs)] $subs $strSub
        set subs   0
        set strSub ""
      }
      incr lineSub
      incr lineAdd
    }
  }
}
