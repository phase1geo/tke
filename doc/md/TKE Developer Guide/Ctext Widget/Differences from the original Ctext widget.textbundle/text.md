## Differences from the original Ctext widget

Like the original Ctext widget, the main purpose of the new Ctext widget is to allow text to be edited such that syntax highlighting is actively performed while the user enters information in the editor.  It also provides line numbering support.

In addition to these functions, the new Ctext widget provides several new functions:

- Gutter support
	- In addition to line numbers, the Ctext widget provides a set of APIs to add additional programmable gutter information such that each line can be tagged with a symbol and/or colors in the gutter area to convey additional information about the line.  Each symbol displayed can receive on\_leave, on\_enter and on\_click events and execute a command when the user causes any of the events to occur.
	- Each gutter operates independently of other gutters in the same Ctext widget.
	- Gutter tagging stays on the assigned line even if the line changes to a new location due to text being inserted or deleted from the Ctext widget.

- Difference mode
	- Displays a new version of the gutter which shows two sets of line numbers per line.
	- Enables the ‘diff’ command API (more on this command in the command section of this appendix) to allow the developer to mark lines as changed which are displayed visually to the user.
	- Change lines can respond to developer supplied on\_enter, on\_leave, and on\_click events.

- Enhanced syntax highlighting capabilities
	- Though the original Ctext widget provides several syntax highlighting API procedures, languages like HTML, XML and Markdown require more complex syntax highlighting requirements which require more than a single regular expression to properly support.
	- The new Ctext widget provides the ability to handle more complex syntax by specifying a callback procedure that is called when a certain kind of syntax is detected via a regular expression.
	- The return value from the callback procedure can cause the syntax parser current index to be set to a value less than or greater than the index returned from the original regular expression check.
	- In addition to highlighting text, the new Ctext widget can allow text to be clickable, underlined, italicized, emboldened, overstriken, superscripted, subscripted, and sized to six different sizes.  If the gutter is displayed, any line height changes are automatically reflected in the gutter such that all line numbers and symbols in the gutter correlate to the lines in the editing area.

- Customized undo/redo support
	- Due to limitations in the Tk text widget support for the undo/redo buffer, the Ctext widget provides its own undo/redo function that provides an enhanced API for querying information about the undo/redo stack, provides support for cursor memory and re-positioning, and provides all of this while remaining extremely efficient in terms of memory and performance.

- Enhanced <<Modified>> event support
	- The %d variable contains a list of information about what caused the widget to go modified, including:
		- operation:  ‘insert’ or ‘delete’ (replace operations cause two modify events, one for the delete and one for the insert)
		- starting cursor position
		- number of characters inserted or deleted
		- number of lines inserted or deleted
		- an optional, user-specified list of information such that any insert, delete and replace commands can pass specialized information to the callback procedure handling the modified event.
	- Note:  Because TKE specifies the modify callback procedure, this is not a feature that is useful for TKE development but rather for any other project that wishes to use the version of Ctext provided with TKE.

- Optimized
	- The new Ctext widget syntax highlighter and linemap code has been modified to optimize performance while editing to make the widget feel snappier and more usable.
	- Many improvements have been also made to improve the correctness of highlighting and bracket matching.
	- Includes support for the replace command such that undo/redo will behave as expected as well as provides the proper syntax highlighting support.

- New version number
	- The new Ctext widget provided with TKE is set to version 5.0.  The original version set its version number to 4.0.  This allows development environments to use both widgets, if necessary (although 5.0 is a superset of 4.0 such that 4.0 should no longer be necessary to use).