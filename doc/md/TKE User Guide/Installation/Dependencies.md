## Dependencies

The installation of TKE has a few dependencies that will need to be preinstalled before the application can begin to work.  The dependencies are listed in the table below along with the URL path to find the source packages.  The installation of these packages is outside the scope of this document.  Please refer to each packages installation notes for this information.

| Package | Required? | Download URL | Synaptic Package |
| - | - | - |
| **Tcl** (8.6.x versions) | Yes | http://sourceforge.net/projects/tcl/files/Tcl/ | tcl8.6 |
| **Tk** (8.6.x versions) | Yes | http://sourceforge.net/projects/tcl/files/Tcl/ | tk8.6 |
| **Tcllib** | Yes | https://sourceforge.net/projects/tcllib/files/tcllib/ | tcllib |
| **Tklib** | Yes | https://sourceforge.net/projects/tcllib/files/tklib/ | tklib |
| **Extended Tcl** (Library should be installed in one of the standard Tcl paths) | Yes | http://sourceforge.net/projects/tclx/files/TclX/ | tclx8.4 |
| **Tkdnd** (allows drag-and-drop support) | No | https://sourceforge.net/projects/tkdnd/files/?source=navbar | tkdnd |
| **Expect** (used to help provide SFTP support - not necessary for macOS) | No | https://sourceforge.net/projects/expect/files/ | expect |
| **PuTTY PSFTP client** (Windows only - used for SFTP support) | No | http://www.chiark.greenend.org.uk/\~sgtatham/putty/download.html | _NA_ |
| **TLS** | Yes | https://sourceforge.net/projects/tls/files/ | tls |
| **TkImg** | No | https://sourceforge.net/projects/tkimg/files/ | |
| **VFS** | No | https://sourceforge.net/projects/tclvfs/files | tcl-vfs |

All other Tcl/Tk packages required by TKE have been bundled in the TKE package
