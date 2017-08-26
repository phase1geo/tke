## api\::preferences\::widget

Creates a preferences widget which controls the display and manipulation of one plugin preference value. The created widget is automatically added for searching within the preferences window and it is packed into the plugin’s preference panel using either pack (default) or grid (using the **-grid 1** option). Several types of widgets are supported:

- checkbutton
- radiobutton
- menubutton
- spinbox
- tokenentry
- entry
- text
- colorpicker
- table

There is also a spacer widget for creating additional vertical division between components for improving readability within the panel.

**Call Structure**

`api::preferences::widget type parentwin prefname message options`

**Return Value**

Returns the pathname of the main widget which allows you to customize the widget details, if desired.

**Parameters**

| Parameter | Description |
| - | - |
| type | Specifies the type of widget to create and pack. See the table below for the list of legal values. |
| parentwin | Pathname of parent window to pack the widget into. |
| prefname | Name of preference value that is controlled by this widget. Note: This field is not valid for the spacer type. |
| message | Message to display in the widget. |

**Widget Types**

| Widget | Usage |
| - | - |
| **checkbutton** | Useful for preference items that have a boolean (on or off) value. |
| **radiobutton** | Useful for preference items that have a relatively small number of enumerated values. |
| **menubutton** | Useful for preference items that have a relatively large number of enumerated values. |
| **spinbox** | Useful for preference items that have an integer value within a specified range. |
| **entry** | Useful for preference items that have a single string value that can be input in a single line. |
| **token** | Useful for preference items that have one or more string values that are not enumerated. |
| **text** | Useful for preference items that have a single string value that may require newlines. |
| **colorpicker** | Useful for selecting a color value from the system's color picker. |
| **table** | Useful for displaying and editing textual table information. Tables are implemented using the [tablelist](http://http://www.nemethi.de/tablelist/tablelistWidget.html) widget. |
| **spacer** | Only used for inserting vertical whitespace in the preference panel. This widget does not represent a preference value. |

**Options**

| Option | Default Value | Description |
| - | - | - |
| **-value** _value_ | none | Only valid for the radiobutton type.  This value will be assigned to the preference item if the radiobutton is selected. |
| **-values** _value\_list_ | none | Only valid for the menubutton type. The list of values will be displayed in the dropdown menu when the menubutton is clicked. The selected value will be assigned to the preference item. |
| **-watermark** _string_ | none | Only valid for the entry and token types. This string will be displayed in the entry field when no other text is entered. |
| **-from** _number_ | none | Only valid for the spinbox type. Specifies the lowest legal value that the spinbox can be set to. |
| **-to** _number_ | none | Only valid for the spinbox type. Specifies the highest legal value that the spinbox can be set to. |
| **-increment** _number_ | 1 | Only valid for the spinbox type. Specifies the amount that will be added/subtracted from the current value when the up/down arrow is clicked in the spinbox. |
| **-grid** _number_ | 0 | If set to 0, the widget will be packed using the Tk pack manager. If set to 1, the widget will be packed using the Tk grid manager. |
| **-ending** _string_ | none | Only valid for spinbox types. If specified, this string will be displayed on the right side of the spinbox value. |
| **-height** _number_ | 4 | Only valid for text and table widgets. Determines the minimum height of the widget in rows. |
| **-columns** _list_ | none | Only valid for the table widget and _must_ be specified. The list is in the form of {_columnwidth_ _columntitle_ ?**left**\|**right**\|**center**? ...} where _columnwidth_ is the number of characters to display (0 allows the column width to be determined automatically). See the [tablelist](http://www.nemethi.de/tablelist/tablelistWidget.html) widget for more details. |

**Message Display**

The following table describes how the message parameter will be displayed in relation to its widget.

| Widget | Message Layout |
| - | - |
| checkbutton | Message is displayed to the left of the check box. |
| radiobutton | Message is displayed to the left of the radio button. |
| menubutton | Message is displayed to the left of the menu button. |
| spinbox | Message is displayed to the left of the spin box. |
| entry | Message is displayed just above the entry field. |
| token | Message is displayed just above the entry field. |
| text | Message is displayed just above the text field. |
| colorpicker | Message is displayed to the left of the color picker button. |
| table | Message is displayed just above the table. |
