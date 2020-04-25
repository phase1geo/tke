Welcome!

This source directory contains all necessary files for running the
TKE source code development editor.  For installation and usage
information, read the User's Guide in doc/UserGuide.pdf.

If you have any issues, please submit a bug report in the SourceForge
bug tracker at:

    http://sourceforge.net/p/tke/tickets/

If you have a question, you can contact via e-mail at:

    phase1geo at gmail dot dom


# Installation


## Dependencies

The installation of TKE has a few dependencies that will need to be preinstalled before the application can begin to work.  The dependencies are listed in the table below along with the URL path to find the source packages.  The installation of these packages is outside the scope of this document.  Please refer to each packages installation notes for this information.

| Package | Required? | Download URL |
| - | - | - |
| **Tcl** (8.6.x versions) | Yes | http://sourceforge.net/projects/tcl/files/Tcl/ |
| **Tk** (8.6.x versions) | Yes | http://sourceforge.net/projects/tcl/files/Tcl/ |
| **Tcllib** | Yes | https://sourceforge.net/projects/tcllib/files/tcllib/ |
| **Tklib** | Yes | https://sourceforge.net/projects/tcllib/files/tklib/ |
| **Extended Tcl** (Library should be installed in one of the standard Tcl paths) | Yes | http://sourceforge.net/projects/tclx/files/TclX/ |
| **Tkdnd** (allows drag-and-drop support) | No | https://sourceforge.net/projects/tkdnd/files/?source=navbar |
| **Expect** (used to help provide SFTP support - not necessary for macOS) | No | https://sourceforge.net/projects/expect/files/ |
| **PuTTY PSFTP client** (Windows only - used for SFTP support) | No | http://www.chiark.greenend.org.uk/\~sgtatham/putty/download.html |
| **TLS** | Yes | https://sourceforge.net/projects/tls/files/ |
| **TkImg** | No | https://sourceforge.net/projects/tkimg/files/ |

All other Tcl/Tk packages required by TKE have been bundled in the TKE package.


## Installing for Linux

Prior to downloading/installing the TKE package, you will need to make sure that you have all of the required packages installed on your system.  Because various Linux distributions have different package managers, I will leave the exact details of how to accomplish this up to you.  However, if you have an Ubuntu-based distribution, you can get the needed packages by performing the following command:

`sudo apt-get install tcl8.6 tk8.6 tclx8.4 tcllib tklib tkdnd expect tcl-tls`

The TKE installation package is downloaded in a gzipped tarball.  You can get the latest version of this tarball from the following URL:  [TKE Download](http://sourceforge.net/projects/tke/files/).

Select a tarball (i.e., \*.tar.gz file) to download within this page and save the resulting tarball into a temporary directory.  After the download has completed, unzip and untar the file using the given command:

`gzip -dc <tarball_filename> | tar xvf -`

After the tke directory has been untarballed, you can delete the original tarball using the following command:

`rm -rf <tarball_filename>`

After all of the files have been uncompressed, change the working directory to the resulting “tke-X.X” directory using the following command:

`cd tke-X.X`

Once inside the TKE source directory, run the installation script found in that directory using the following command:

`tclsh8.6 install.tcl`

At the beginning of the installation process, the install script will check to make sure that you have both Tcl and Tk 8.6 installed along with a usable version of TclX.  If all checks are good, the installation will continue; otherwise, it will provide an error message indicating the offending check.  After the checks occur, you will be asked to provide a root directory to install both the TKE library directories/files and the TKE binary file.  This can be any directory in your filesystem; however, popular directories are:

- /usr/local
- /usr

After specifying a file system directory, TKE will indicate the names of the directory and binary file that it will install.  If everything looks okay, answer “Y” or “y” (or just hit the RETURN key); otherwise, hit the “N” or “n” keys to enter a different directory.  Once you enter a directory, the installation script will check to see if a previous version of TKE has been installed at that directory location.  If one is found, it will ask if you would like to replace the old version with the new version.  Hit the “Y” or “y” key (or just hit the RETURN key) to confirm the replacement.  To cancel the installation and select a new directory, hit the “N” or “n” key.  If you have specified that the given directory should be replaced (or no replacement was necessary), the script will continue with the full installation.  At any time you can quit the installation script by entering the CONTROL-c key combination.


## Installing for MacOS

If you only plan on running tke from a terminal and are satisfied with running the application through the X11 server that runs on Mac, you can follow the same installation steps that is used for Linux-based systems.  However, if you would like to install TKE like a native Mac OS X application (i.e., application available in the Applications folder, TKE icon displayed in the dock, etc.), follow these installation steps.

After downloading the TKE disk image into the Downloads folder, double-click the disk image file and then drag and drop the TKE application icon in the resulting window to the Applications directory.

**Important Note:**
You will also need to make sure that Tcl/Tk version 8.6 or higher is installed on your system as Xcode command-line utilities only comes with an 8.5 version.  You can install the latest 8.6 Tcl/Tk version by visiting http://www.tcl.tk and either download/install/build from source or install the ActiveState version prior to launching TKE.

**Another Important Note:** The wish shell that is used is based on Cocoa and, as such, for Mac OS X versions 10.7 (Lion) and later have a feature that stops certain keys from being automatically repeated when its key is held down.  This will make Vim-mode on these systems from working as expected.  To disable this on your system, enter the following command within the Terminal application prior to starting TKE:

`defaults write -g ApplePressAndHoldEnabled -bool false`


## Installing for Windows

The easiest installation process for Windows is fairly straightforward and creates a native Windows application on your machine. Download the TKE Windows executable installer from the SourceForge website, run the resulting download file, and follow the installation wizard steps.  The application will then be available through the start window and, if enabled in the installation process, through a desktop shortcut.

You can alternatively install a Unix-like environment such as Cygwin and then install the tarball in a similar manner to installing for Linux (with the exception that Cygwin does not have a software update tool like ‘apt-get’ but rather maintains its own software packages available through the Cygwin installer).  The process of installing Cygwin and configuring its environment properly for TKE is beyond the scope of this document.

It is important to note that on Windows, the in-app update mechanism is not available.  Only stable releases of TKE will be available and only from the SourceForge website.  Updating the application will require downloading and running the new installer.
