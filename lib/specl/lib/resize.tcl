###################################################
#
#  Name:         resize
#
#  Decsription:  Copies a source image to a destination
#                image and resizes it using linear interpolation
#
#  Parameters:   newx   - Width of new image
#                newy   - Height of new image
#                src    - Source image
#                dest   - Destination image (optional)
#
#  Returns:      destination image
#
###################################################

set resize_last_update     0
set resize_update_interval 100

proc do_update {} {

  # If the difference between the last update time and the current time exceeds the 
  # maximum allowed update interval, perform the update and save the current time as
  # the last update time.
  if {[expr [set curr_time [clock milliseconds]] - $::resize_last_update] >= $::resize_update_interval} {
    set ::last_update $curr_time
    update idletasks
  }

}

proc image_scale {src newx newy {dest ""} } {
    
  set mx [image width $src]
  set my [image height $src]
    
  if { "$dest" == ""} {
    set dest [image create photo]
  }
  $dest configure -width $newx -height $newy
    
  # Check if we can just zoom using -zoom option on copy
  if { $newx % $mx == 0 && $newy % $my == 0} {
    set ix [expr {$newx / $mx}]
    set iy [expr {$newy / $my}]
    $dest copy $src -zoom $ix $iy
    return $dest
  }

  set ny   0
  set ytot $my
    
  for {set y 0} {$y < $my} {incr y} {
        
    #
    # Do horizontal resize
    #
        
    foreach {pr pg pb} [$src get 0 $y] {break}
        
    set row     [list]
    set thisrow [list]
        
    set nx   0
    set xtot $mx
        
    for {set x 1} {$x < $mx} {incr x} {
            
      # Add whole pixels as necessary
      while { $xtot <= $newx } {
        lappend row     [format "#%02x%02x%02x" $pr $pg $pb]
        lappend thisrow $pr $pg $pb
        incr xtot $mx
        incr nx
      }
            
      # Now add mixed pixels
            
      foreach {r g b} [$src get $x $y] {break}
            
      # Calculate ratios to use
            
      set xtot [expr {$xtot - $newx}]
      set rn   $xtot
      set rp   [expr {$mx - $xtot}]
            
      # This section covers shrinking an image where
      # more than 1 source pixel may be required to
      # define the destination pixel
            
      set xr 0
      set xg 0
      set xb 0
            
      while { $xtot > $newx } {
        incr xr $r
        incr xg $g
        incr xb $b
                
        set xtot [expr {$xtot - $newx}]
        incr x
        foreach {r g b} [$src get $x $y] {break}
      }
            
      # Work out the new pixel colours
    
      set tr [expr {int( ($rn*$r + $xr + $rp*$pr) / $mx)}]
      set tg [expr {int( ($rn*$g + $xg + $rp*$pg) / $mx)}]
      set tb [expr {int( ($rn*$b + $xb + $rp*$pb) / $mx)}]
            
      if {$tr > 255} {set tr 255}
      if {$tg > 255} {set tg 255}
      if {$tb > 255} {set tb 255}
            
      # Output the pixel

      lappend row     [format "#%02x%02x%02x" $tr $tg $tb]
      lappend thisrow $tr $tg $tb
      incr xtot $mx
      incr nx
            
      set pr $r
      set pg $g
      set pb $b
      
    }
        
    # Finish off pixels on this row
    while { $nx < $newx } {
      lappend row     [format "#%02x%02x%02x" $r $g $b]
      lappend thisrow $r $g $b
      incr nx
    }
        
    #
    # Do vertical resize
    #
        
    if {[info exists prevrow]} {
            
      set nrow [list]
            
      # Add whole lines as necessary
      while { $ytot <= $newy } {
                
        $dest put -to 0 $ny [list $prow]
                
        incr ytot $my
        incr ny
        
      }
            
      # Now add mixed line
      # Calculate ratios to use
            
      set ytot [expr {$ytot - $newy}]
      set rn   $ytot
      set rp   [expr {$my - $rn}]
            
      # This section covers shrinking an image
      # where a single pixel is made from more than
      # 2 others.  Actually we cheat and just remove 
      # a line of pixels which is not as good as it should be
            
      while { $ytot > $newy } {     
        set ytot [expr {$ytot - $newy}]
        incr y
        continue
      }
            
      # Calculate new row

      foreach {pr pg pb} $prevrow {r g b} $thisrow {
        set tr [expr {int( ($rn*$r + $rp*$pr) / $my)}]
        set tg [expr {int( ($rn*$g + $rp*$pg) / $my)}]
        set tb [expr {int( ($rn*$b + $rp*$pb) / $my)}]
        lappend nrow [format "#%02x%02x%02x" $tr $tg $tb]
      }
            
      $dest put -to 0 $ny [list $nrow]
            
      incr ytot $my
      incr ny
    }
        
    set prevrow $thisrow
    set prow $row
        
    do_update
  }
    
  # Finish off last rows
  while { $ny < $newy } {
    $dest put -to 0 $ny [list $row]
    incr ny
  }
  do_update

  return $dest

}