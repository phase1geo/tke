### Publish Markdown Plugin

This plugin can be used to generate a single Markdown file from a directory hierarchy by appending all Markdown files found in that hierarchy into a single Markdown file.  The plugin can do one of the following with the resulting file:

1. Save the file to a location in the local filesystem.
2. Run the Markdown through an HTML processor and save the resulting HTML code to a file in the local filesystem.
3. Pass the Markdown to another application for viewing and/or further processing.

#### How do I run the plugin?

The plugin is accessible from the sidebar within a file or directory contextual menu.  If a directory or file is selected in the sidebar and the right mouse button is clicked, the **Publish Markdown** menu option will be listed at the bottom of the menu.

The plugin option will only be enabled for a file if the file has the ".md" or ".markdown" file extensions.  You can extend this extension list via the plugin's preference pane located in the Preferences window (see below).  For directories, the plugin option will only be enabled if the directory's sort method is set to "manual" (you can set the directory's sort method by right-clicking on the directory in the sidebar and selecting the **Sort / Manually** menu option.  Once a directory's sort method is set to "manual", you can rearrange the files/directories listed within the directory by dragging and dropping the files into a new order.  Files will be appended to the resulting file in the order listed within the sidebar.

If one or more files/directories are selected, one output file per selected item will be generated, allowing you to batch out several jobs at once.

#### Plugin Dialog Window

When the plugin menu option is invoked, the publish markdown window will be displayed.  There are two publishing options available:

1. Save the resulting Markdown file to a directory in the local file system.
    - The name of the file saved to the selected directory will be the same as the basename of the file/directory with the ".md" extension.
    - If the **Export HTML** option is selected within the dialog window, the file will be passed to either the built-in Markdown processor or, if specified, the processor listed within the plugin preferences pane.
    - To select a directory, click on the **Browse...** button, select the directory using the standard choose directory dialog, and select the **Choose** button.
    - The **Publish** button will be enabled only after a directory location has been selected when this action is selected.

2. Pass the resulting Markdown file to another application.
    - The possible applications will be listed in the associated menu button list.
    - If this option is not available, it is because there are no applications specified in the plugin preference "Open In" application list. Add applications in the preferences to enable this option.
    - The **Publish** button will be enabled only after an application has been selected when this action is selected.

Once you have made the appropriate dialog selections and the **Publish** button is enabled, click it to create the published output.

#### How do I configure options for the plugin?

The plugin's configuration options are available in the Preferences window in the **Plugins** pane. Select the **publish_markdown** option from the menu button within that pane to view/edit this plugin's items.  Each option is documented within the pane.
