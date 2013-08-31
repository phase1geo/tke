# This code is a modified version based on the ButtonNotebook widget
# available at:  http://paste.tclers.tk/895?v=raw
#
# Replace the standard notebook tab with one that includes a close
# button.  To use, create a ttk::notebook widget and set the -style
# option to BNotebook.
#
# In future versions of ttk this will be supported more directly when
# the identify command will be able to identify parts of the tab.

namespace eval BNotebook {

  # Tk 8.6 has the Visual Styles element engine on windows. If this is
  # available we use it to get proper windows close buttons.
  #
  proc CreateElements {} {
    if {[lsearch -exact [ttk::style element names] close] == -1} {
      if {[catch {
        # WINDOW WP_SMALLCLOSEBUTTON (19)
        # WINDOW WP_MDICLOSEBUTTON (20)
        # WINDOW WP_MDIRESTOREBUTTON (22)
        ttk::style element create close vsapi \
          WINDOW 20 {disabled 4 {active pressed} 3 active 2 {} 1}
      }]} then {
        CreateImageElements
      }
    }
  }
   
  proc CreateImageElements {} {
    # Create two image based elements to provide buttons to close the
    # tabs or to display an image which provides user-defined functionality.
    namespace eval ::img {}
    set imgdir [file join $::tke_dir images]
    image create bitmap ::img::blank       -file [file join $imgdir blank.bmp]
    image create bitmap ::img::close       -file [file join $imgdir close.bmp] -foreground grey50
    image create bitmap ::img::closeactive -file [file join $imgdir close.bmp] -foreground grey10
    if {[lsearch -exact [ttk::style element names] close] == -1} {
      if {[catch {
        ttk::style element create close image \
          [list ::img::close \
            {active pressed !disabled} ::img::closeactive] \
          -padding 8 -sticky {}
      } err]} { puts stderr $err }
    }
  }
   
  proc Init {{pertab 0}} {
    CreateElements
    
    # This places the buttons on the right end of the tab area -- but in
    # Tk 8.5 we cannot identify these elements.
    if {!$pertab} {
      ttk::style layout BNotebook {
        BNotebook.client -sticky nswe
        BNotebook.close  -side right -sticky ne
      }
    }
    
    # This places the button elements on each tab which uses quite a
    # lot of space but we can identify the elements. Changes to the 
    # widget state affect all the button elements though.
    if {$pertab} {
      ttk::style layout BNotebook {
        BNotebook.client -sticky nswe
      }
      ttk::style layout BNotebook.Tab {
        BNotebook.tab -sticky nswe -children {
          BNotebook.padding -side top -sticky nswe -children {
            BNotebook.focus -side top -sticky nswe -children {
              BNotebook.label -side left -sticky {}
              BNotebook.close -side left -sticky {}
            }
          }
        }
      }
    }
    
    if {$::ttk::currentTheme eq "xpnative"} {
      ttk::style configure BNotebook.Tab -width -8
    }
    # bind TNotebook <ButtonPress-1> {+::BNotebook::Press %W %x %y}
    # bind TNotebook <ButtonRelease-1> {+::BNotebook::Release %W %x %y}
    bind TNotebook <Motion> {+::BNotebook::Motion %W %x %y}
    bind TNotebook <<ThemeChanged>> [namespace code [list Init $pertab]]
  }
   
  # Hook in some event extras:
  # set the state to pressed if button down over a button element.
  proc Motion {w x y} {
    set e [$w identify $x $y]
    if {[string match "*close" $e]} {
      $w state pressed
    } else {
      $w state !pressed
    }
  }
   
  # Initialize the BNotebook namespace
  BNotebook::Init 1

}

