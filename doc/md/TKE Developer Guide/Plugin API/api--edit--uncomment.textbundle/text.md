## api::edit::uncomment

Removes any line comments from selected lines.

**Call structure**

`api::edit::uncomment txt`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to modify. |

**Example**

	Remove comment from current line
	$txt tag add sel insert "insert lineend"
	api::edit::uncomment $txt
