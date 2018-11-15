## syntax addclass

Adds a new syntax highlighting class with the specified highlighting options. This procedure must be called prior to adding any syntax highlighting rules or indices.

**Call structure**

`pathname syntax addclass classname ?options?`

**Return value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| _classname_ | Name of a syntax highlighting class that will be used in subsequent calls to the other `syntax` calls. |
| _options_ | Zero or more options that are used to customize the look and functionality of text highlighted for this class. The list of options is listed in the table below. |

**Options**

| Option | Description |
| - | - |
| **-fgtheme** _name_ | Specifies the name of a theme color to apply to the foreground of syntax highlighted for this class. The _name_ option may be any value passed to the `-theme` option passed to ctext. If this option is not specified, the text associated with this class will have the default foreground color of the text widget. |
| **-bgtheme** _name_ | Specifies the name of a theme color to apply to the background of syntax highlighted for this class. The _name_ option may be any value passed to the `-theme` option passed to ctext. If this option is not specified, the text associated with this class will have the default background color of the text widget. |
| **-fontopts** _fontoptlist_ | List of options that control the font used to syntax highlight text with this class. The available values for _fontoptlist_ are provided in the table below. If this option is not specified, the text associated with this class will have the default font of the text widget. |
| **-clickcmd** _command_ | Command that will be called when the user right-clicks text with this syntax highlighting class applied. The specified _command_ will be called in the global namespace and will be passed the following arguments: the pathname of the text widget, the starting position of the text tagged with _class_ and the ending position of the text tagged with _class_. If this option is not specified, the text associated with this class will not be clickable. |
| **-priority** _priority_ | Specifies the stacking priority of the class. Higher priority classes will drawn over lower priority classes. If this option is not specified, a default priority will be assigned based on the other options (if -bgtheme is specified, priority **3** will be used; otherwise, if -fgtheme or -fontopts are specified, priority **2** will be used; otherwise, priority **4** will be used. See the table below for a listing of the valid priority values).
| **-immediate** _bool_ | Specifies if we need to apply the class highlighting immediately after all syntax parsing for this class' highlighting criteria or whether we can wait until all syntax parsing has concluded before applying the class highlighting. The default for this value is 0. Setting this value to 1 should not be used unless you know what you are doing as it can have a potential performance impact on the syntax highlighter. |

**Font Options**

| Option | Description |
| - | - |
| **bold** | Applies bold emphasis. |
| **italics** | Applies italicized emphasis. |
| **underline** | Applies a horizontal line under the text. |
| **overstrike** | Applies a horizontal line through the text. |
| **superscript** | Draws the text in a smaller text just above the text baseline. |
| **subscript** | Draws the text in a smaller text just above the text baseline. |
| **h1** | Sizes the text appropriate for an `<h1>` HTML tag. |
| **h2** | Sizes the text appropriate for an `<h2>` HTML tag. |
| **h3** | Sizes the text appropriate for an `<h3>` HTML tag. |
| **h4** | Sizes the text appropriate for an `<h4>` HTML tag. |
| **h5** | Sizes the text appropriate for an `<h5>` HTML tag. |
| **h6** | Sizes the text appropriate for an `<h6>` HTML tag. |

**Priority Values**

| Priority Value | Description |
| - | - |
| **high** | The highest priority value, drawn just below text selection. |
| **1** | Second highest priority value. |
| **2** | Third highest priority value. |
| **3** | Fourth highest priority value. |
| **4** | Fifth highest priority value. Generally used for highlighting classes that are not visible. |