### syntax search

If the user wants to perform a search of the entire text widget using a given search string, this command should be used for this purpose.  It will automatically create a highlight class for the search using the given _classname_ parameter value, making sure that the applied syntax highlighting is higher in priority than any other highlighting class.

It will then immediately perform a search of that text, highlighting all found cases with the given highlight class.  If the user makes any additional edits that cause new text to be matched to this class, that text will be immediately highlighted as well.

Search highlighting will only stop when the `syntax delete` call is made.

**Call Structure**

`pathname syntax search classname searchstring ?searchopts?`

**Return Value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| _classname_ | Name of highlight class to use for highlighting search results. |
| _searchstring_ | A search string to use to match text for highlighting. |
| _searchopts_ | Options passed to the Tcl text widget search function to indicate how to perform the search. 
