## api::edit::comment

Comments the currently selected lines using the current language's proper line comment syntax.

**Call structure**

`api::edit::comment txt`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |

**Example**

```Tcl
# Comment out the current paragraph
set startpos [api::edit::get_index $txt paragraph -dir prev]
set endpos [api::edit::get_index $txt paragraph -dir next -startpos $startpos]
	
# Select the text and comment it out
$txt tag add sel $startpos $endpos
api::edit::comment $txt
```
