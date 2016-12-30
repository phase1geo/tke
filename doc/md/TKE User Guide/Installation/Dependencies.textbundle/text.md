## Dependencies

The installation of TKE has a few dependencies that will need to be preinstalled before the application can begin to work.  The dependencies are listed in the table below along with the URL path to find the source packages.  The installation of these packages is outside the scope of this document.  Please refer to each packages installation notes for this information.

| Package | Download URL |
| - | - |
| Tcl (8.5.x or 8.6.x versions) | http://sourceforge.net/projects/tcl/files/Tcl/ |
| Tk (8.5.x or 8.6.x versions) | http://sourceforge.net/projects/tcl/files/Tcl/ |
| Tcllib | https://sourceforge.net/projects/tcllib/files/tcllib/ |
| Tklib | https://sourceforge.net/projects/tcllib/files/tklib/ |
| Extended Tcl (Library should be installed in one of the standard Tcl paths) | http://sourceforge.net/projects/tclx/files/TclX/ |
| Tkdnd (optional) | https://sourceforge.net/projects/tkdnd/files/?source=navbar |
| Expect (optional - used to help provide SFTP support - not necessary for macOS) | https://sourceforge.net/projects/expect/files/ |
| PuTTY PSFTP client (Windows only, optional - used for SFTP support) | http://www.chiark.greenend.org.uk/\~sgtatham/putty/download.html |

**Important Note:** Tcl/Tk version 8.5.19 or later is recommended to avoid application crashes during editing.

All other Tcl/Tk packages required by TKE have been bundled in the TKE package.