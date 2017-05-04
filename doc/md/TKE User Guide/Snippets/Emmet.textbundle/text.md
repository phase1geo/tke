## Emmet

Emmet is primarily a syntax that allows for the creation of HTML/XML syntax as well as CSS syntax.
It’s minimalistic nature allows for quick generation of lots of code with a minimal number of input
characters. This document will not attempt to describe the Emmet syntax (which can be found at
\<http://docs.emmet.io\> other than to state that TKE has full, built-in support for the Emmet
abbreviation syntax for HTML/XML, Ipsum Lorem text insertion, and full support for CSS syntax.

Once an Emmet abbreviation has been entered in an editing buffer, make sure that the cursor is located at the right-hand side of the text and use the `Edit / Emmet / Expand Abbreviation` file option to expand the syntax (or use Control-E which is the default key binding for this option). If there is an error in the syntax, no expansion will be performed; otherwise, the abbreviation will be removed and its generated content will be inserted in its place (if the generated results span multiple lines, those lines will be preceded by the proper amount of whitespace). Additionally, any tabstop points in the generated text will cause the insertion cursor to be placed at the first tabstop and hitting the TAB key will jump the cursor to the next tabstop until all tabstops have been traversed.

Additionally, you can create your own Emmet abbreviations using the `Edit / Emmet / Edit Custom Abbreviations` menu item. This will display the custom abbreviation file in an editing buffer. The contents of this file are self-documented. Saving the editing buffer will immediately update the available Emmet abbreviations such that restarting the application will not be necessary.

### Emmet Actions

The Emmet specification identifies a number of actions that can be performed on HTML and CSS-like syntaxes. TKE now supports all Emmet actions that can be performed on HTML-like syntax (CSS syntax support will be added in a future release).  See the `Edit / Emmet` submenu for a listing of available Emmet action functions that can be performed.