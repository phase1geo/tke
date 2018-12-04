## Installing for MacOS

If you only plan on running tke from a terminal and are satisfied with running the application through the X11 server that runs on Mac, you can follow the same installation steps that is used for Linux-based systems.  However, if you would like to install TKE like a native Mac OS X application (i.e., application available in the Applications folder, TKE icon displayed in the dock, etc.), follow these installation steps.

After downloading the TKE disk image into the Downloads folder, double-click the disk image file and then drag and drop the TKE application icon in the resulting window to the Applications directory.

**Important Note:**
You will also need to make sure that Tcl/Tk version 8.6 or higher is installed on your system as Xcode command-line utilities only comes with an 8.5 version.  You can install the latest 8.6 Tcl/Tk version by visiting http://www.tcl.tk and either download/install/build from source or install the ActiveState version prior to launching TKE.

**Another Important Note:** The wish shell that is used is based on Cocoa and, as such, for Mac OS X versions 10.7 (Lion) and later have a feature that stops certain keys from being automatically repeated when its key is held down.  This will make Vim-mode on these systems from working as expected.  To disable this on your system, enter the following command within the Terminal application prior to starting TKE:

`defaults write -g ApplePressAndHoldEnabled -bool false`
