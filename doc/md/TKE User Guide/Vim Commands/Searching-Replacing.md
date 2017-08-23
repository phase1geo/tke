#### Searching/Replacing

| Command or KEY | Description |
| - | - |
| **/**_string_ | Finds all occurrences of the given string, jumping the cursor to the first occurrence below the current line. |
| **?**_string_ | Finds all occurrences of the given string, jumping the cursor to the first occurrence above the current line. |
| **n** | Repeats the last ‘/‘ or ‘?’ operation. |
| _num_**n** | Repeats the last '/' or '?' operation _num_ times. |
| **N** | Repeats the last '/' or '?' operation in the opposite direction. |
| _num_**N** | Repeats the last '/' or '?' operation in the opposite directory _num_ times. |
| **?** | Jumps to the previous occurrence of the previous search. |
| **:**_x,y_**s/**_oldstring_**/**_newstring_**/**_flags_ | Finds and replaces one or more occurrences of _oldstring_ with _newstring_ where _oldstring_ can be any Tcl regular expression. The _flags_ value if empty, causes only the first match to be replaced in the given range.  The following flags are valid: **g** = all matches are replaced in the given range, **i** = ignores case in matching, **I** = case sensitive matching. |
| **\*** | Searches the text for the next occurrence of the current word. |

