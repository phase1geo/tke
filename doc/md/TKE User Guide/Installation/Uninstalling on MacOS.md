## Uninstalling on MacOS

To uninstall the TKE application on macOS, simply drag the /Applications/TKE.app bundle to the trash.  This will delete all files that were created during the installation process.

This command will not remove your TKE home directory, however.  If you want to remove that directory, simply perform the following command in a terminal:

```
rm -rf ~/.tke
```

Deleting the TKE home directory will permanently delete all preferences, installed themes, installed plugins and other important files created and maintained by TKE
