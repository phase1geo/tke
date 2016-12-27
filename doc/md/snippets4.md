## Creating Snippets

Snippets are maintained in individual files according to the syntax language of the buffer that uses
them. Therefore, all Tcl snippets will be placed in a Tcl.snippets file within your \~/.tke/snippets
directory while C++ snippets will be placed in a C++.snippets file in the same directory. In addition,
each user also has a global snippets file which is available in all buffers. These snippets are stored
in \~/.tke/snippets/user.snippets.

To create or edit a snippet for a specific language, make sure that
the current editor language is set to the language of the snippet being created or modified and select
the “Edit / Snippets / Edit Language” menu command. This will add the language-specific snippets file
from your ~/.tke/snippets directory via the preferences window. If the file doesn’t yet exist, TKE
will automatically create it for you.

The following image shows what the snippets editing pane looks like.

IMAGE

At the top left is a search bar that will display all snippet text within the table that matches the
entered text. The search results are updated as you type. To view all items in the table, clear the
search text.

At the top right is the language selection menu. To view/edit snippets in a different
language, select the menu button and select a new language from the available list. If you would like
to create a language agnostic snippet (i.e., a snippet that is available from any language), select
the language menu button and choose the <All> language option.

The main table displays the available
snippets in the given language along with their associated keyword and the first four lines of the
snippet text. To view/edit the snippet, double-click the snippet in the table. This will display the
snippet editor pane within the preferences UI. To add a new snippet, click the “Add” button (which
will also display the snippet editor pane). To delete a snippet, select the snippet to delete and
click the “Delete” button. A confirmation will be displayed to confirm the deletion.

The snippet editor pane is depicted as shown.

IMAGE

The top entry allows you to associate a snippet keyword. Whenever this keyword is entered in an editing
buffer, the keyword will be replaced with the associated snippet text. Make sure that the keyword that
you use is meaningful but not a string that you normally enter when editing files.

The main editing area allows you to enter the snippet text. All code entered in the text field will
be syntax highlighted in the current language to help with readability. In addition, auto-indentation
will be applied to the file using the syntax rules and preference settings. It is important to note
that when the snippet is inserted in an editing buffer that the inserted text will be automatically
indented to match the current indentation.

At the bottom of the snippet editor pane is the button bar. The “Insert” button will display a menu
containing a series of snippet syntax that can be inserted into the text field. Selecting an item from
this list will insert the item at the current insertion cursor position. If current snippet has both
a valid keyword and a non-empty snippet string entered, the “Save” button will be enabled. Clicking
this button will save the snippet and return you to the snippet table view. To cancel adding/editing
the current snippet, click on the “Cancel” button. This will also return you back to the snippet table view.

As soon as a snippet has been edited and saved, it will be immediately ready to be used within the application.
