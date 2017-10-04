if {![package vsatisfies [package provide Tcl] 8.5]} {return}
package ifneeded Expect 5.45     [list load [file join $dir libexpect5.45.dylib]]
