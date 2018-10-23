## Snippet Variables

The following table represents the various variables that can be used within snippet text. Note that all variables are expanded at the time the snippet replacement occurs. Additionally, the DOLLARSIGN ($) and BACKTICK (\`) characters are special characters. If you require these characters to be treated as literal characters in your snippet, you will need to escape these characters by placing a BACKSLASH (\) character just before it.

| Variable | Description |
| - | - |
| **\$SELECTED\_TEXT** | Inserts the currently selected text at this variable’s location. If no text is currently selected, an empty string is inserted in its place. |
| **$CLIPBOARD** | Places the contents that are currently in the clipboard at this variable’s location. |
| <b>$CLIPHIST[</b>_number_<b>]</b> | Places the contents that are in the given location of the clipboard history where a _number_ value of 0 refers to the last item added to the clipboard history queue. |
| **$CURRENT\_LINE** | Places the current line contents (minus the abbreviation) at this variable’s location. |
| **$CURRENT\_WORD** | Places the current word at this variable’s location. |
| **$DIRECTORY** | Places the current directory at this variable’s location. |
| **$FILEPATH** | Places the current file pathname at this variable’s location. |
| **$FILENAME** | Places the root file name at this variable’s location. |
| **$LINE\_INDEX** | Places the position of the current insertion cursor (specified as _line.column_) at this variable’s location. |
| **$LINE\_NUMBER** | Places the line position of the current insertion cursor at this variable’s location. |
| **$CURRENT\_DATE** | Places the current date at this variable’s location. The date is specified as MM/DD/YYYY. |
| **$CURRENT\_DATE2** | Places the current date at this variable's location.  The date is specified as YYYY/MM/DD. |
| **$CURRENT\_TIME** | Places the current time at this variable’s location. The time is specified as HH:MM AM/PM. |
| **$CURRENT\_MON** | Shortened name of the current month (ex., Jan, Feb). |
| **$CURRENT\_MONTH** | Long name of the current month (ex., January, February). |
| **$CURRENT\_MON1** | Numerical value for the current month expressed as either a one or two digit value. |
| **$CURRENT\_MON2** | Numerical value for the current month expressed as a two digit value where the first digit will be a zero, if needed. |
| **$CURRENT\_DAYN** | Shortened name of the current day of the week (ex., Mon, Tue). |
| **$CURRENT\_DAYNAME** | Long name of the current day of the week (ex., Monday, Tuesday). |
| **$CURRENT\_DAY1** | Numerical day of the current month expressed as either a one or two digit number. |
| **$CURRENT\_DAY2** | Numerical day of the current month expressed as a two digit number where the first digit will be zero, if needed. |
| **$CURRENT\_YEAR2** | Two digit representation of the current year where the first digit will be zero, if needed. |
| **$CURRENT\_YEAR** | Four digit representation of the current year. |
| <b> \$0</b> | Places the cursor at this variable’s location after the entire snippet has been expanded. |
| <b> \$</b>_number_ | Places the cursor at this variable's location in the order of number. Hitting the TAB key will jump the cursor to the next cursor stop. For example, if a snippet uses the variables “\$1 … \$2”, the cursor will first be  placed at location “\$1” and when the TAB key is pressed, the cursor will jump to the location of “\$2”. If more than one “\$1” is use within the same snippet, the text that is entered in the first occurrence of this variable will also be entered in all other places within the snippet that share the same number. |
| <b>\${<b>_number_**:**_value_**}** | Places the cursor at this variable's location in the order of number, placing the string value at the cursor’s location. The string value can be used as a placeholder to remind the user what information to insert at that location. The value string will be automatically selected when the snippet is inserted so that immediately typing text will delete the value string with the user’s entered string. |
| **\`**_shell\_command_**\`** | Executes the specified command between the back tick characters. |
| <b>\${</b>_number_**/**_pattern_**/**_format_**/**_opts_**}** | The value of number must be a tabstop previously specified in the snippet. Its value is run through a regular expression match against pattern (the specified options are passed to the regular expression parser (values of g, i and I are supported; see the Vim command for search/replace for a description of these flags). The resulting matches are used with format and the resulting value is inserted. See the following table for a description of format strings. |
| <b>\${</b>_variable_**/**_pattern_**/**_format_**/**_opts_**}** | The value of variable must be one of the above variables (minus the starting dollar sign). Its value is run through a regular expression match against pattern (the specified options are passed to the regular expression parser (values of g, i and I are supported — see the Vim command for search/replace for a description of these flags). The resulting matches are used with format and the resulting value is inserted. See the following table for a description of format strings. |
