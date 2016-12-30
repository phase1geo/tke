## Installing for Linux

Prior to downloading/installing the TKE package, you will need to make sure that you have all of the required packages installed on your system.  Because various Linux distributions have different package managers, I will leave the exact details of how to accomplish this up to you.  However, if you have an Ubuntu-based distribution, you can get the needed packages by performing the following command:

`sudo apt-get install tcl8.5 tk8.5 tclx8.4 tcllib tklib tkdnd expect`
OR
`sudo apt-get install tcl8.6 tk8.6 tclx8.4 tcllib tklib tkdnd expect`

The TKE installation package is downloaded in a gzipped tarball.  You can get the latest version of this tarball from the following URL:  [TKE Download][1].

Select a tarball (i.e., \*.tar.gz file) to download within this page and save the resulting tarball into a temporary directory.  After the download has completed, unzip and untar the file using the given command:

`gzip -dc <tarball_filename> | tar xvf -`

After the tke directory has been untarballed, you can delete the original tarball using the following command:

`rm -rf <tarball_filename>`

After all of the files have been uncompressed, change the working directory to the resulting “tke-X.X” directory using the following command:

`cd tke-X.X`

Once inside the TKE source directory, run the installation script found in that directory using the following command:

`tclsh8.5 install.tcl`
OR
`tclsh8.6 install.tcl`

At the beginning of the installation process, the install script will check to make sure that you have both Tcl and Tk 8.5 installed along with a usable version of TclX.  If all checks are good, the installation will continue; otherwise, it will provide an error message indicating the offending check.  After the checks occur, you will be asked to provide a root directory to install both the TKE library directories/files and the TKE binary file.  This can be any directory in your filesystem; however, popular directories are:

- /usr/local
- /usr

After specifying a file system directory, TKE will indicate the names of the directory and binary file that it will install.  If everything looks okay, answer “Y” or “y” (or just hit the RETURN key); otherwise, hit the “N” or “n” keys to enter a different directory.  Once you enter a directory, the installation script will check to see if a previous version of TKE has been installed at that directory location.  If one is found, it will ask if you would like to replace the old version with the new version.  Hit the “Y” or “y” key (or just hit the RETURN key) to confirm the replacement.  To cancel the installation and select a new directory, hit the “N” or “n” key.  If you have specified that the given directory should be replaced (or no replacement was necessary), the script will continue with the full installation.  At any time you can quit the installation script by entering the CONTROL-c key combination.

[1]:	http://sourceforge.net/projects/tke/files/