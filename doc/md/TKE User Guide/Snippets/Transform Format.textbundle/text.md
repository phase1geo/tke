## Transform Format

A variable or mirror value text transformation is possible using the last two documented commands in the prior table. The value of format contains the resulting text that will replace the entire transformation string within the snippet. The following table describes valid syntax that can be used in this field.

Any numbers represented in the format text (preceded by a ‘$’ character when used on its own) refer to matched values in the transformation match pattern (represented by “(…)” regular expression syntax). Each match will be assigned to a corresponding match variable which can be referenced using ‘$’ followed by its match number. Any match variables will be substituted with their matched value (or the empty string if the match variable was not assigned).

| Syntax | Description |
| - | - |
| _text_ | Any normal text can be specified. The following characters are special and must be escaped with a BACKSLASH character if the literal value is required: ‘(‘, ‘)’ and ‘\’. |
| **\l** | The case of the character immediately following this character sequence will be changed to lower case. |
| **\u** | The case of the character immediately following this character sequence will be changed to upper case. |
| **\L**…**\E** | The case of all characters between these character sequences will be changed to lower case. |
| **\U**…**\E** | The case of all characters between these character sequences will be changed to upper case. |
| **(?**_number_**:**…**)** | If the corresponding match variable was assigned a value, substitutes this syntax with the format text found to the right of the ‘:’ (colon) character. |
| **(?**_number_**:**…**:**…**)** | If the corresponding match variable was assigned a value, substitutes this syntax with the format text found to the right of the first ‘:’ (colon) character; otherwise, substitutes this syntax with the format text found to the right of the second ‘:’ character.
