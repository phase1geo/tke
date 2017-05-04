## api::edit::get\_index

Returns a text widget index relative to a starting position (by default, the starting position is the current insertion cursor position) based on a position type and associated arguments.

It is highly recommended that you use this procedure for calculating indices as it has bounds checks and takes advantage of some under-the-hood performance enhancements.

**Call structure**

`api::edit::get_index txt position options`

**Return value**

Returns a text widget index.

**Parameters**

| Parameter | Description |
| - | - |
| txt | Pathname to a text widget. |
| position | Type of position relative to a starting index. |
| options | Options that are used in conjunction with the position to calculate the index. |

**Position Values**

| Position | Description |
| - | - |
| left | Index _num_ characters left of the starting position, staying on the same line. |
| right | Index _num_ characters right of the starting position, staying on the same line. |
| up | Index _num_ lines above the starting position, remaining in the same column, if possible. |
| down | Index _num_ lines below the starting position, remaining in the same column, if possible. |
| first | Index of the first line/column in the buffer. |
| last | Index of the last line/column in the buffer. |
| char | Index of the _num_’th character before or after the starting position. |
| dchar | Index of _num_’th character before or after the starting position. |
| findchar | Index of the _num_’th specified character before or after the starting position. |
| firstchar | Index of first non-whitespace character of the line specified by startpos. |
| lastchar | Index of last non-whitespace character of the line specified by startpos. |
| wordstart | Index of the first character of the word which is _num_ words before or after th startpos. |
| wordend | Index of the last character+1 of the word which is _num_ words before or after the startpos. |
| WORDstart | Index of the first character of the WORD which is _num_ WORDs before or after startpos. A WORD is defined as a list of sequential non-whitespace characters. |
| WORDend | Index of the last character+1 of the WORD which is _num_ WORDs before or after startpos. |
| column | Index of the character in the line containing startpos at the _num_’th position. |
| linenum | Index of the first non-whitespace character on the given line. |
| linestart | Index of the beginning of the line containing startpos. |
| lineend | Index of the ending of the line containing startpos. |
| dispstart | Index of the first character that is displayed in the line containing startpos. |
| dispmid | Index of the middle-most character that is displayed in the line containing startpos. |
| dispend | Index of the last character that is displayed in the line containing startpos. |
| screentop | Index of the start of the first line that is displayed in the buffer. |
| screenmid | Index of the start of the middle-most line that is displayed in the buffer. |
| screenbot | Index of the start of the last line that is displayed in the buffer. |
| numberstart | First numerical character of the word containing startpos. |
| numberend | Last numerical character of the word containing startpos. |
| spacestart | First whitespace character of the whitespace containing startpos. |
| spaceend | Last whitespace character of the whitespace containing startpos. |

** Option Values**

| Options | Default | Description |
| - | - |
| **-dir** (**next** or **prev**) | **next** | Specifies direction from starting position. |
| **-startpos** _index_ | **insert** | Specifies the starting index of calculation. |
| **-num** _number_ | 1 | Specifies the number to apply. |
| **-char** _character_ | “” | Used with **findchar** position type.  Specifies the character to find. |
| **-exclusive** (**0** or **1**) | 0 | If set to 1, returns character position before calculated index. |
| **-column** _varname_ | “” | Specifies the name of a variable containing the column to use for **up** and **down** positions. |
| **-adjust** _index\_modifier_ | “” | Adjusts the calculated index by the given value before returning the result. |

**Example**

	proc foobar {} {
	  set file_index [api::file::current_file_index]
	  set txt [api::file::get_info $file_index txt]
	
	  # Get the index of the 10'th character to the right of the insertion cursor
	  set index [api::edit::get_index $txt right -num 10]
	
	  # Move the cursor to the calculated index
	  api::edit::move_cursor $txt $index
	}



