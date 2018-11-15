## syntax addregexp

Specifies a regular expression to apply a syntax highlighting class to. The regular expression is any valid Tcl regular expression which matches text that is limited to a single line of text in the widget.

Any regular expression syntax using parenthesis will cause the matched text positions in the line to be assigned to one of up to nine variables.

Important Note: The `syntax addclass` procedure must be called for the given class prior to calling this procedure.

**Call Structure**

`pathname syntax addregexp type typevalue regexp ?language?`

**Return Value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| _type_ | Must be a value of either **class** or **command**. If a value of **class** is specified, the _typevalue_ parameter must be the name of a highlighting class that will be applied to text matching the regular expression. If a value of **command** is specified, the _typevalue_ parameter must be the name of a Tcl procedure that will be called which will return a list containing a Tcl list containing two items. The first item is a Tcl list in the form of `?classname startpos endpos ...?` which specifies the location of the characters in the current line to highlight with the given class name. The second item specifies the line character index to back the parser to (or the empty string to indicate that we should continue with the character after the last matched character). This command will be given parameters as described in the table below. |
| _typevalue_ | Specifies either the name of a highlighting class to apply to words found in the provided keywordlist or a Tcl procedure that will be called to determine if and what highlighting class will be applied to the text. See the _type_ description above for more information. |
| _regexp_ | A valid Tcl regular expression used to match text. If the _type_ value is set to **command**, each part of the regular expression that is surrounded by parenthesis will have its positional information assigned to a match variable which is passed to the Tcl command. |
| _language_ | Option argument which, if set to a non-empty string value, will only parse for keywords found in the specified embedded language. Embedded languages can be specified with the `syntax addembedlang` command. If this option is not specified, all words in the main language of the ctext widget will be parsed. |

**Highlighting Command Parameters**

| Parameter | Description |
| - | - |
| _win_ | Pathname of text widget being parsed. |
| _row_ | Line row within the text widget of the given keyword. |
| _line_ | Line of text within the text widget containing keyword. |
| _varlist_ | Tcl list containing the list of match variables in the form of: `{matchindex {startpos endpos}} ?...?` |
| _ins_ | Set to 1 if we are syntax highlighting due to text being inserted into the widget; otherwise, this value will be set to 0. |
