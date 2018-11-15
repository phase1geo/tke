## syntax addcharstart

Specifies a character which will proceed a word of text which, when found, will have a highlighting class applied. Words are any group of consecutive characters that do not contain a list of delimiting characters. The default list of delimiters used by the ctext widget is the following:

`^, whitespace characters, (, {, [, }, ], ), ., ;, :, =, ", ', |, <, >`

However, the delimiter list can be overridden for a ctext instance using the widget's `-delimiters` option. It is important to know that the starting character may not be any of the characters listed in the list of delimiter characters.

Once all of the words in the text widget are retrieved, they are compared to the list of words starting with the specified character. If a word is found in the list and the current language matches the specified language, it will be highlighted with the specified highlighting class.

Important Note: The `syntax addclass` procedure must be called for the given class prior to calling this procedure.

**Call Structure**

`pathname syntax addcharstart type typevalue char ?language?`

**Return Value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| _type_ | Must be a value of either **class** or **command**. If a value of **class** is specified, the _typevalue_ parameter must be the name of a highlighting class that will be applied to words found in keywordlist. If a value of **command** is specified, the _typevalue_ parameter must be the name of a Tcl procedure that will be called which will return a list containing the name of a highlighting class to use as well as the starting and ending positions of the line string to highlight. This command will be given parameters as described in the table below. |
| _typevalue_ | Specifies either the name of a highlighting class to apply to words found in the provided keywordlist or a Tcl procedure that will be called to determine if and what highlighting class will be applied to the text. See the _type_ description above for more information. |
| _char_ | A string character specifying the first character of a word to match against. |
| _language_ | Option argument which, if set to a non-empty string value, will only parse for keywords found in the specified embedded language. Embedded languages can be specified with the `syntax addembedlang` command. If this option is not specified, all words in the main language of the ctext widget will be parsed. |

**Highlighting Command Parameters**

| Parameter | Description |
| - | - |
| _win_ | Pathname of text widget being parsed. |
| _row_ | Line row within the text widget of the given keyword. |
| _line_ | Line of text within the text widget containing keyword. |
| _varlist_ | Tcl list containing two values: a static value of 0 and a Tcl list containing the starting and ending indices of the matched text in the given line. |
| _ins_ | Set to 1 if we are syntax highlighting due to text being inserted into the widget; otherwise, this value will be set to 0. |
