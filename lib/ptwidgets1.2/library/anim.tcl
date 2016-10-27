proc animate_busy {w} {

  set rest [lassign $::busy img]
  set ::busy [concat $rest $img]

  $w configure -image $img

  after 100 [list animate_busy $w]

}

for {set i 1} {$i <= 8} {incr i} {
  lappend busy [image create bitmap -file [file join images busy$i.bmp] -maskfile [file join images busy$i.bmp] -foreground black]
}

pack [ttk::label .l]
after 1000
animate_busy .l
