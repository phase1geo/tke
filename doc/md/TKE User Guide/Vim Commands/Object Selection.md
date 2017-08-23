#### Object Selection

These motion commands are only valid when we are in visual mode or when they are added to text deletion/transformation commands (i.e., ‘diw’).

| Command or KEY | Description |
| - | - |
| **iw** | Selects the current word. If the insertion cursor is within a space, selects the current space characters. |
| **aw** | Selects the current word and the following space characters. If no space characters follow the current word, selects the space characters before the current word, if applicable. |
| **iW** | Selects the current WORD. If the insertion cursor is within a space, selects the current space characters. |
| **aW** | Selects the current WORD and the following space characters. If no space characters follow the current WORD, selects the space characters before the current WORD, if applicable. |
| **is** | Selects the current sentence. |
| **as** | Selects the current sentence and any space characters following the sentence. |
| **ip** | Selects the current paragraph. |
| **ap** | Selects the current paragraph and any space characters following the paragraph. |
| **it** | Selects the characters between the starting and ending tags within an HTML/XML node. This is only valid for XML-like syntaxes. |
| **at** | Selects the characters of an HTML/XML node, including the starting and ending tags. This is only valid for XML-like syntaxes. |
| **i(** or **i)** or **ib** | Selects all characters within the current parenthesis set, not including the parenthesis. |
| **a(** or **a)** or **ab** | Selects all characters within the current parenthesis set, including the parenthesis. |
| **i[** or **i]** | Selects all characters within the current square bracket set, not including the square brackets. |
| **a[** or **a]** | Selects all characters within the current square bracket set, including the square brackets. |
| **i{** or **i}** or **iB** | Selects all characters within the current curly bracket set, not including the curly brackets. |
| **a{** or **a}** or **aB** | Selects all characters within the current curly bracket set, including the curly brackets. |
| **i\<** or **i\>** | Selects all characters within the current angled bracket set, not including the angled brackets. Only valid for HTML/XML syntax types. |
| **a\<** or **a\>** | Selects all characters within the current angled bracket set, including the angled brackets. Only valid for HTML/XML syntax types. |
| **i”** | Selects all characters within the current double-quoted string, not including the double quote characters. Only valid for syntaxes which highlight double-quoted strings. |
| **a”** | Selects all characters within the current double-quoted string, including the double quote characters. Only valid for syntaxes which highlight double-quoted strings. |
| **i’** | Selects all characters within the current single-quoted string, not including the single quote characters. Only valid for syntaxes which highlight single-quoted strings. |
| **a’** | Selects all characters within the current single-quoted string, including the single quote characters. Only valid for syntaxes which highlight single-quoted strings. |
| **i\`** | Selects all characters within the current back-tick quoted string, not including the back-tick characters. Only valid for syntaxes which highlight back-tick quoted strings. |
| **a\`** | Selects all characters within the current back-tick quoted string, including the back-tick characters. Only valid for syntaxes which highlight back-tick quoted strings. |