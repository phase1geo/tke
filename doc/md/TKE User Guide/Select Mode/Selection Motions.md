## Selection Motions

Each selection object type selects a single object that is on or closest to the current insertion cursor position. However, once a single object is selected, you can change the selection using the selection motion keys. Each selection object type selection motions that are specific to it.

The following table lists the available selection motions.

| Motion | Command Key | Associated Object Types | Anchor at Start Description | Anchor at End Description |
| - | - | - | - | - |
| right | **l** | block | Adds a character column of text to the right of the current selection. | Removes one character column of text from the current selection from the left of the selection. |
| left | **h** | block | Removes a character column of text from the right of the current selection. | Adds one character column of text to the right of the current selection. |
| up | **k** | char <br>line <br>block | Removes a line of text from the bottom of the selection, moving the cursor up by one line. | Adds a line of text to the top of the selection, moving the cursor up by one line. |
| down | **j** |char <br>line <br>block | Adds a line of text to the bottom of the selection, moving the cursor down by one line. | Removes a line of text from the top of the selection, moving the cursor down by one line. |
| next | **l** | char <br>word <br>line <br>lineto <br>sentence <br>paragraph | Adds the next text object to the selection. In the case of the `lineto` type, adds all text from the current cursor to the end of the line. | Removes the next text object from the selection. In the case of the `lineto` type, removes all text from the current cursor to the end of the line. |
| prev | **h** | char <br>word <br>line <br>lineto <br>sentence <br>paragraph | Removes the previous text object from the selection. In the case of the `lineto` type, removes all text from the current cursor to the beginning of the current line. | Adds the previous text object from the selection. In the case of the `lineto` type, adds all text from the current cursor to the beginning of the current line. |
| parent | **h** or **H** | node <br>curly <br>square <br>parenthesis <br>angled | Moves selection up by one level. ||
| child | **l** or **L** | node <br>curly <br>square <br>parenthesis <br>angled | Moves selection down by one level, selecting the first child. | Moves selection down by one level, selecting the last child. |
| next sibling | **j** | node <br>curly <br>square <br>parenthesis <br>angled | Adds the next sibling XML node or bracketed text to the current selection. | Removes the next sibling XML node or bracketed text from the current selection. |
| previous sibling | **k** | node <br>curly <br>square <br>parenthesis <br>angled | Removes the previous sibling XML node or bracketed text to the current selection. | Adds the previous sibling XML node or bracketed text from the current selection. |
| shift right | **L** | char <br>word <br>sentence <br>paragraph <br>block | Shifts the selection to the right by one text object type. ||
| shift left | **H** | char <br>word <br>sentence <br>paragraph <br>block | Shifts the selection to the left by one selection object type. ||
| shift up | **K** | char <br>line <br>lineto <br>block | Shifts the selection up by one line. ||
| shift down | **J** | char <br>line <br>lineto <br>block | Shifts the selection down by one line. ||
| Toggle quote inclusion | **i** | single <br> double<br> backtick <br>comment | By default, only the text between the surrounding quote/comment characters are included in the selection when one of these selection types is chosen. This causes the surrounding characters to be included in the selection or removed from the selection. ||
