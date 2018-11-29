## Uninstalling on Linux

To uninstall TKE after it has been installed, simply run the following command:

```
sudo tclsh8.6 <installation_directory>/lib/tke/uninstall.tcl
```

Where <installation_directory> is the base directory that was used when installing the application with the install.tcl script.  This will remove all directories and files that were installed by the install.tcl script.

This command will not remove your TKE home directory, however.  If you want to remove that directory, simply perform the following command in a terminal:

```
rm -rf ~/.tke
```

Deleting the TKE home directory will permanently delete all preferences, installed themes, installed plugins and other important files created and maintained by TKE.