#softwareupdate.tcl  routines to manage spoftware updates

#  Copyright (C) 2014  WordTech Communications LLC

#Proprietary to WordTech Communications LLC. Redistribution prohibited.

package provide softwareupdate 1.4
package require http
package require tdom

namespace eval softwareupdate {

    if {![info exists library]} {
	variable library [file dirname [info script]]
    }


    variable icon

    #check version of installed software
    proc checkVersion {app version} {
	variable appversion
	variable appname
	variable currentversion
	variable versionnumber
	variable appcast
	variable sparkledata
	variable changedata


	set appname $app

	set iconfile [file join [softwareupdate::findCurrentInstallation] "Contents" "Resources" $app.icns]

	tk::mac::iconBitmap myicon 64 64 -imageFile $iconfile

	softwareupdate::checkingForUpdates

	set appcast http://www.codebykevin.com/[string tolower $appname].xml
	http::config -useragent "$appname Update Check"

	set xml [http::data [http::geturl $appcast]]

	if [catch {http::geturl $appcast} msg] {
	    puts "error: $msg"
	    tk_messageBox -icon info -title "" -message "Update Error!" -detail "An error occurred in retrieving update information.\nPlease try again later."
	    return
	} 

	dom parse $xml sparkledata
	set versionnumber [string trim [$sparkledata selectNodes -namespaces [list x "http://www.andymatuschak.org/xml-namespaces/sparkle"] {string(//enclosure/@x:version)}] .0]

	set changedata [$sparkledata selectNodes {string(//description/text())}]

	set minOS [$sparkledata selectNodes -namespaces [list x "http://www.andymatuschak.org/xml-namespaces/sparkle"] {string(//x:minimumSystemVersion)}]

	set hostOS [exec sw_vers -productVersion]

	if {![package vsatisfies $hostOS $minOS]} {
	    tk_messageBox -icon warning -message "Error!" -detail "$appname is not supported on Mac OS X $hostOS. The minimum supported OS version is $minOS." 
	    return
	}
	
	if {[expr $currentversion < $versionnumber]} {
	    softwareupdate::updatePitch
	} else {
	    softwareupdate::upToDate
	}
    }
    
    #define the current version of the software
    proc setVersion {app number} {
	variable currentversion
	variable appname
	set currentversion $number
	set appname $app
	
    }
    

    #get the current installation path
    proc findCurrentInstallation {} {
	variable currentinstall
	set approot [info nameofexecutable]
	set apppath [split $approot /]
	set currentinstall [join [lrange $apppath 0 [lsearch $apppath "*.app"]] / ]
	return $currentinstall

    }

    #prompt user to update
    proc updatePitch {} {
	variable appname
	variable myicon
	variable changedata
	variable currentversion
	variable versionnumber

	catch {destroy .updateprogress}

	catch {destroy .update}
	

	toplevel .update
	wm title .update "Software Update"

	wm withdraw .update

	frame .update.f -bg gray95
	pack .update.f -fill both -expand yes

	frame .update.f.top -bg gray95
	pack .update.f.top -fill both -expand yes

	label .update.f.top.i -bitmap myicon -bg gray95 -relief flat -highlightthickness 0
	pack .update.f.top.i -side left -fill both -expand yes

	frame .update.f.top.r -bg gray95
	pack .update.f.top.r -side right -fill both -expand yes

	label .update.f.top.r.title -text "A new version of $appname is available!" -font {-weight bold} -bg gray95 -relief flat -highlightthickness 0
	pack .update.f.top.r.title -fill both -expand yes -side top

	label .update.f.top.r.msg -text "$appname $versionnumber is available--you have $currentversion. Would you like to download it now?" -font {-size 10} -bg gray95 -relief flat -highlightthickness 0
	pack .update.f.top.r.msg -fill both -expand yes -side top

	label .update.f.top.r.release -text "Release Notes:" -font {-size 10 -weight bold} -relief flat -highlightthickness 0 -bg gray95 
	pack .update.f.top.r.release -side top -fill both -expand yes

	text .update.f.top.r.text -font TkDefaultFont
	pack .update.f.top.r.text -side top -fill both -expand yes

	ttk::frame .update.f.top.r.bottom -padding 5
	pack .update.f.top.r.bottom -side bottom -fill both -expand yes

	ttk::button .update.f.top.r.bottom.skip -text "Skip This Version" -command {destroy .update}

	ttk::button .update.f.top.r.bottom.install -text "Install Update" -default active -command softwareupdate::installUpdate
	
	pack .update.f.top.r.bottom.install .update.f.top.r.bottom.skip  -side right  -fill both -expand yes

        .update.f.top.r.text insert end $changedata

	.update.f.top.r.text configure -state disabled

	wm resizable .update 0 0
	wm deiconify .update
	raise .update
	wm transient .update .

    }


    #"busy" dialog
    proc checkingForUpdates {} {

	variable appname

	catch {destroy .updateprogress}

	toplevel .updateprogress 
	wm title .updateprogress "Updating $appname"

	wm withdraw .updateprogress
	update idletasks

	ttk::frame .updateprogress.f -padding 5
	pack .updateprogress.f -fill both -expand yes

	label .updateprogress.f.l -bg gray95 -bitmap myicon -bd 0 -relief flat -highlightthickness 0
	pack .updateprogress.f.l -side left -fill both -expand yes

	frame .updateprogress.f.r -bg gray95 -bd 0 -highlightcolor gray95
	pack .updateprogress.f.r -side right -fill both -expand yes
	
	
	ttk::label .updateprogress.f.r.t -text "Checking for updates..." -padding 5
	pack .updateprogress.f.r.t -side top -fill both -expand yes

	ttk::frame .updateprogress.f.r.f -padding 5
	pack .updateprogress.f.r.f -side top -fill both -expand yes
	
	ttk::progressbar .updateprogress.f.r.f.progress -mode indeterminate -orient horizontal
	pack .updateprogress.f.r.f.progress -fill both -expand yes -side top

	.updateprogress.f.r.f.progress start

	ttk::button .updateprogress.f.r.f.b -text "Cancel" -command {destroy .updateprogress}

	pack .updateprogress.f.r.f.b -side bottom -fill both -expand no

	wm geometry .updateprogress 400x100
	wm resizable .updateprogress 0 0

	wm deiconify .updateprogress
	raise .updateprogress

	wm transient .updateprogress .

    }
    
    #dialog if current version is installed
    proc upToDate {} {
	variable appname
	variable versionnumber

	catch {destroy .updateprogress}

	tk_messageBox  -icon info -message "You're up to date!" -detail "$appname $versionnumber is the currently the newest version available."

    }

    #show progress of installation
    proc progressDialog {} {

	variable appname
	variable status

	catch {destroy .downloadprogress}

	toplevel .downloadprogress
	wm title .downloadprogress "Updating $appname"

	wm transient .downloadprogress .

	label .downloadprogress.label -bitmap myicon   -anchor w -bg gray95 -highlightthickness 0

	pack .downloadprogress.label -side left -fill both -expand yes


	ttk::frame .downloadprogress.frame -padding 5
	pack .downloadprogress.frame -side right -fill both -expand yes

	ttk::label .downloadprogress.frame.l -textvariable softwareupdate::status -width 40 -text ""
	pack .downloadprogress.frame.l -side top -fill both -expand yes

	ttk::progressbar .downloadprogress.frame.bar -mode indeterminate -orient horizontal  -maximum 100
	pack .downloadprogress.frame.bar -side top -fill both -expand yes

	.downloadprogress.frame.bar start
	update

	ttk::button .downloadprogress.frame.b -text "Cancel" -command {destroy .updateprogress}
	pack .downloadprogress.frame.b -side right -fill both -expand no

	wm geometry .downloadprogress 400x100
        wm resizable .downloadprogress 0 0
	
    }

    #download and install the update
    proc installUpdate {} {
	variable currentinstall
	variable status
	variable appname

	catch {destroy .update}

	softwareupdate::findCurrentInstallation

	variable appname
	variable status


        softwareupdate::progressDialog
	set status "Downloading update for $appname"
	http::geturl http://www.codebykevin.com/updates/[list $appname].tgz -channel [open /tmp/$appname.tgz w] 
	update
	after 1000
	cd /tmp
	set status "Unpacking update for $appname"
	update
	after 1000
	catch {exec tar xvfz [list $appname].tgz}
	set status "Ready to install"
	.downloadprogress.frame.bar configure -mode determinate
	.downloadprogress.frame.bar configure -value 100
	.downloadprogress.frame.bar stop
	destroy .downloadprogress.frame.b 
	pack [	ttk::button .downloadprogress.frame.b -text "Install and Relaunch" -command softwareupdate::launchUpdate] -side right -fill both -expand no
	return
    }


    #launch the update
    proc launchUpdate {}  {

	variable currentinstall
	variable appname

	catch {destroy .downloadprogress}

	if {[catch {exec codesign -v /tmp/$appname.app} msg]} {
	    bgerror $msg
	    tk_messageBox -icon warning -message "Error!" -detail "An error occurred in the installation of $appname. Please try again later."
	    return
	} else {

	    file rename -force $currentinstall [file join /Users [exec whoami] .Trash [file tail $currentinstall]]

	    file rename -force /tmp/$appname.app $currentinstall

	    exec $currentinstall/Contents/MacOS/$appname &

	    exit
	}

    }

    

    namespace export *

}
