#### Text Transformation

| Command or KEY | Description |
| - | - |
| **\~** | Changes case of the current character.  If text is currently selected, all selected characters will have their case changed. |
| _num_**\~** | Changes case of the next _num_ characters starting with the current character. |
| **g\~\~** | Transforms the current line by toggling the case of each character in the line. |
| **g\~**_motion_ | Transforms all text between the cursor and the indicated motion direction to invert the current case. |
| **guu** | Transforms the current line to lower case. |
| **gu**_motion_ | Transforms all text between the cursor and the indicated motion direction to lower case. |
| **gUU** | Transforms the current line to upper case. |
| **gU**_motion_ | Transforms all text between the cursor and the indicated motion direction to upper case. |
| **g??** | Converts the current line by to its rot13 encoding. |
| **g?**_motion_ | Converts all text between the cursor and the indicated motion direction to its rot13 encoding. |