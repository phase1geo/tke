## api::edit::toggle\_comment

Toggles the comment status of the currently selected lines.

**Call structure**

`api::edit::toggle_comment`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |

**Example**

	# Toggle comments of the currently selected line
	$txt tag add sel insert "insert lineend"
	api::edit::toggle_comment $txt
