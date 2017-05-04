## api::edit::format

Adds text formatting syntax to current word of the given type.  If text is currently selected, the formatting will be applied to all of the selected text.

**Call structure**

`api::edit::format txt type`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname of text widget to format. |
| type | Type of formatting to apply. Only values that are supported by the current syntax are applied. |

** Type Values **

| Type | Description |
| - | - |
| **bold** | Emboldens text. |
| **italics** | Italicizes text. |
| **underline** | Underlines text. |
| **strikethrough** | Draws line through text. |
| **highlight** | Adds highlight color to background of text. |
| **superscript** | Superscripts text. |
| **subscript** | Subscripts text. |
| **code** | Specifies that the text should be displayed as code. |
| **header1** | HTML header1 |
| **header2** | HTML header2 |
| **header3** | HTML header3 |
| **header4** | HTML header4 |
| **header5** | HTML header5 |
| **header6** | HTML header6 |
| **unordered** | Unordered list item |
| **ordered** | Ordered list item |

**Example**

	# Add <b></b> (bold) around the current HTML word
	api::edit::format $txt bold
