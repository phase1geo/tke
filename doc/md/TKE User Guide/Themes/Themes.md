# Themes

TKE has the ability to change the look of both the window elements as well as the syntax highlighter via themes. A single theme provides various controls for describing how all elements within TKE will look. By putting information about both the windowing elements (buttons, scrollbars, sidebar, etc.) and the syntax highlighting colors within the same file allows the theme creator to tightly control the look of the entire application.

## Changing Themes

The user can change themes at any time by using the `View/Set Theme` menu. Changing the theme using this mechanism will change the current theme for the current application setting only. Once the application is exited and restarted, the default theme will be used. To change the default theme, start the preferences window using the `Edit/Preferences/Edit User - Global` menu, select the `Appearance` panel in the sidebar and switch the value using the `Theme` menubutton. This will change the current theme to the selected value immediately and for all future application sessions.

## Adding Themes

Though TKE comes with many themes built-in, new TKE themes can also be installed. TKE theme files have a `.tkethemz` file extension. You can download themes from the [TKE theme webpage](http://tke.sourceforge.net/themes.html). You can access this webpage from the `Manage Themes` tab by clicking on the `Get More Themes` button. This will show the theme webpage in your browser. Simply download a theme from that page using its associated download button to get the theme package onto your local filesystem.

You can install a TKE theme file in several ways (and depending on the operating system that you are using), including the following:

- Double click on the file (macOS only)
- Drag and drop the file onto the TKE application icon (macOS only)
- Drag and drop the file into the sidebar or editing buffer of TKE (any system in which TkDND is installed).
- Via the Theme Editor (all platforms; described below in the Theme Editor)
- Via the Global Preferences window in the `Manage Themes` tab in the `Appearance` panel. Click on the plus button at the bottom of the syntax table and select a theme file from the file system to install (all platforms).

Once a theme has been installed, it will be available for immediate use without requiring the application to be restarted.

## Deleting/Hiding Themes

You can permanently delete any theme that the user installed (this does not include preinstalled themes) within the `Manage Themes` tab within the `Appearance` global preference window. Simply select a theme from the table and click on the minus button. A dialog window will be displayed to confirm the deletion.

If you would prefer to keep the theme installed in the file system but removed from the list of available themes within the `Set Theme` menu and command launcher list of syntaxes, you can hide/show themes by toggling the `Visibility` checkbox in the `Manage Themes` table.
