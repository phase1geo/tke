namespace eval ::exp {
    variable dll
    if {![info exist dll]} {
	switch -- $::tcl_platform(platform) {
	    "windows" { set dll expect543.dll }
	}
    }
    variable library
    if {![info exist library]} {
	if {[llength [glob -nocomplain -type f $dll]] == 1} {
	    ### development environment
	    set library	    [pwd]
	} else {
	    ### install environment
	    set library	    [file dirname [info script]]
	}
    }

    ### Where is the injector.dll?
    variable injector_path
    set      injector_path [file nativename $library]

    ### Should I display the spawned app to assist debugging?
    variable winnt_debug
    set      winnt_debug      0
}

# ### ######### ###########################
##
# Initialization code for expect on windows.  Expect requires the use
# of a supplemental dll, which is not a tcl package. This dll has to
# be explicitly copied out of the virtual filesystem for the OS to
# pick up (For a tcl package Tcl would have done this for us
# underneath).
##
# ### ######### ###########################

proc ::exp::injector_setup {} {
    rename ::exp::injector_setup {}

    # Check if there is a need to copy the injector dll into a native
    # location.

    variable library
    if {[lindex [file system $library] 0] eq "native"} return

    variable injector_path

    package require starkit
    set destdir       [file dirname $starkit::topdir]
    set injector_path [file nativename $destdir]

    set src [file join $library injector.dll]
    set dst [file join $destdir injector.dll]

    if {![file exists $dst]} {
	file copy -force $src $dst
    }

    return
}

::exp::injector_setup

# ### ######### ###########################

load [file join $::exp::library $::exp::dll]
