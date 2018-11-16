# Packages

The following is a list of of available packages to the plugin code that is already included in TKE.

## Tclx

Documentation for the tclx package can be found at [http://www.tcl.tk/man/tclx8.2/TclX.n.html](http://www.tcl.tk/man/tclx8.2/TclX.n.html)

## Tablelist

Documentation for the tablelist package can be found at [http://www.nemethi.de/tablelist/index.html](http://www.nemethi.de/tablelist/index.html).  TKE currently uses version 6.3.

## tooltip

Documentation for the tooltip package can be found at [http://docs.activestate.com/activetcl/8.5/tklib/tooltip/tooltip.html](http://docs.activestate.com/activetcl/8.5/tklib/tooltip/tooltip.html)

## msgcat

Documentation for the msgcat package can be found at [http://www.tcl.tk/man/tcl8.6/TclCmd/msgcat.htm](http://www.tcl.tk/man/tcl8.6/TclCmd/msgcat.htm)

## tokenentry

Documentation for the tokenentry package can be found at [http://ptwidgets.sourceforge.net/resources/tokenentry.html](http://ptwidgets.sourceforge.net/resources/tokenentry.html)

## wmarkentry

Documentation for the wmarkentry package can be found at [http://ptwidgets.sourceforge.net/resources/wmarkentry.html](http://ptwidgets.sourceforge.net/resources/wmarkentry.html)

## tabbar

Documentation for the tabbar package can be found at [http://ptwidgets.sourceforge.net/resources/tabbar.html](http://ptwidgets.sourceforge.net/resources/tabbar.html)

## fontchooser

The fontchooser packet provides a UI for selecting a font.  If the window is canceled, an empty string is returned; otherwise, the font value of the selected font is returned.  The returned font will be in the option/value Tcl font form.  This package provides a single user command:

`fontchooser ?option value …?`

The available options are specified as follows:

| Option | Description |
| - | - |
| **-parent** _window_ | Makes window the logical parent of the fontchooser dialog.  The file dialog is displayed on top of its parent window. |
| **-initialfont** _font_ | Specifies the initial font to display in the window.  The value of font can be any legal Tcl font description. |
| **-title** _titleString_ | Specifies a string to display as the title of the dialog box.  If this option is not specified, no title is displayed. |

## base64

Documentation for the base64 package can be found at [http://core.tcl.tk/tcllib/doc/trunk/embedded/www/tcllib/files/modules/base64/base64.html](http://core.tcl.tk/tcllib/doc/trunk/embedded/www/tcllib/files/modules/base64/base64.html)