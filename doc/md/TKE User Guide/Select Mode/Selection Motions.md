## Selection Motions

Each selection object type selects a single object that is on or closest to the current insertion cursor position. However, once a single object is selected, you can change the selection using the selection motion keys. Each selection object type selection motions that are specific to it.

The following table lists the available selection motions.

| Motion | Command Key | Associated Object Types | Description |
| - | - | - | - |
| next / right | **l** | char<br> word<br> line<br> lineto<br> sentence<br> paragraph<br> node<br> curly<br> square<br> parenthesis<br> angled<br> block | If the selection anchor is at the beginning of the selection, adds the next object occurrence to the current selection. If the selection anchor is at the end of the selection, removes the next object occurrence from the current selection. |
| previous / left | **h** | char<br> word<br> line<br> lineto<br> sentence<br> paragraph<br> node<br> curly<br> square<br> paren<br> angled<br> block | If the selection anchor is at the beginning of the selection, removes the previous object occurrence from the current selection. If the selection anchor is at the end of the selection, adds the previous object occurrence to the current selection. |
| up / previous sibling | **k** | char<br> node<br> curly<br> square<br> parenthesis<br> angled<br> block<br> | For **char** and **block** types, moves the selection end up by a line. For the other types, adds the previous sibling object to the selection if the anchor is at the end of the selection or removes the previous sibling object from the selection if the anchor is at the beginning of the selection. |
| down / next sibling | **j** | char<br> node<br> curly<br> square<br> parenthesis<br> angled<br> block<br> | For **char** and **block** types, moves the selection end down by a line. For the other types, adds the next sibling object to the selection if the anchor is at the beginning of the selection or removes the next sibling object from the selection if the anchor is at the end of the selection. |
| shift right | **L** | Here | Shifts the selection to the left by one selection object type. |
| shift left | **H** | HERE | Shifts the selection to the right by one selection object type. |
| shift up | **K** | here | Shifts the selection up by one selection object. |
| shift down | **J** | here | Shifts the selection down by one selection object. |
