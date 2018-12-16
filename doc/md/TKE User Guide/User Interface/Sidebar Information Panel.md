### Sidebar Information Panel

When a single file or directory is Control-clicked within the sidebar (or the **Show Info** menu option is selected in the sidebar contextual menu for a single item), a special panel will be displayed at the bottom of the sidebar, displaying additional information about the selected item, including the following:

- Basename of the file/directory
- Default syntax of the given file (file only)
- File size (file only)
- Last modification date of file/directory
- Read, write, execute permissions of file/directory
- File/directory owner
- File/directory group
- MD5 checksum (file only)
- SHA-1 hash (file only)
- SHA-224 hash (file only)
- SHA-256 hash (file only)
- Favorited status of the file/directory

If the selected file is one that is tracked by a version control system, the current version information can also be included in the panel. If the selected file is an image file that TKE can display, a thumbnail image of the file can be displayed along with the image size. If the selected file is a text file, the line count, word count, character count and average reading time can also be displayed. All information displayed in the panel can be shown/hidden within the **Info Panel** tab of the sidebar preference panel.

To control which information is displayed in the information panel, go to Preferences, click on the `Sidebar` panel and select the `Info Panel` tab. Within the `Displayed Information` option group, are all of the possible values that can be displayed. Simply select the items that you would like to see within the panel and remove those that are not useful. Note that the more items that are selected for display, the slower the performance may be when information is changed/updated within the panel.

When the sidebar loses keyboard focus, the information panel will be hidden until the sidebar regains keyboard focus. If you would prefer that the information panel remain visible at all times, this option can be changed within the Preferences window within the Sidebar panel using the **Keep file information panel visible when sidebar doesn’t have focus** checkbox.

To close the information panel, either click on the `x` icon in the upper right corner of the panel or hit the `Escape` key when the sidebar has keyboard input focus. To refresh the contents of the information panel, click on the refresh button to the right of the close button in the information panel. To force the associated file to be visible within the sidebar, click on the "eyeball" icon to the left of the refresh button. All three of these icons will be visible when the mouse cursor enters the information panel area; otherwise, they will be hidden from view to keep the interface as minimalistic as possible.