# Menu Binding

The menu binding capability within TKE simply allows any user to customize the keyboard shortcuts to launch any menu command. By default, TKE contains a minimal set of menu bindings; however, any of the menu items can be overridden.

The default (global) menu binding file is located in the TKE installation directory (in data/bindings/menu\_bindings.windowingsystem.tkedat). In addition to the global file, each user will have their own menu binding file which overrides the global file settings. This file is located at \~/.tke/menu_bindings.windowingsystem.tkedat.

You can change the menu shortcuts by either starting the Preferences via the “Edit / Preferences / Edit User - Global” menu option and selecting the Shortcuts panel or via the “Edit / Menu Bindings / Edit User” menu option which will display the preferences GUI with the Shortcuts panel immediately displayed. A representation of the Sharing panel is displayed below.

![][image-1]

To the upper left, there is a search entry field which allows you to show only menu items in the table that match the given search criteria. The table will be updated as you type. To show all elements in the table, clear the search text.

To add or change a shortcut value, select a menu item in the shortcut table. This will display the shortcut editor below the table. Simply select a modifier combination and key via the two dropdown lists (the values available in the list boxes are automatically updated to guarantee that any available values will result in a unique key combination for the shortcut) and click on the “Set” button. To remove an existing shortcut, select it in the table and click on the “Clear” button. Click on the “Cancel” button or another table item to remove the menu item from being edited.

To quickly edit the shortcut on Linux systems, you can hold down the Control button while selecting
any menu item in the main menu. This will automatically display the preference GUI and select the
given menu item for editing purposes in the Shortcuts panel.

[image-1]:	assets/DraggedImage.png