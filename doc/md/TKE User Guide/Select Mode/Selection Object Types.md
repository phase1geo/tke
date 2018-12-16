## Selection Object Types

Selections can be specified by the selection object type. The following list contains all of the supported selection object types:

| Selection Object Type | Command Key | Description |
| - | - |
| character | **c** | One or more characters |
| word | **w** | One or more words |
| line | **e** | One or more lines |
| lineto | **E** | From current insertion cursor to the beginning or end of a line |
| sentence | **s** | One or more sentences. If the sentence is within a comment, the comment bounds the sentence. |
| paragraph | **p** | One or more paragraphs. If the paragraph is within a comment, the comment bounds the paragraph. |
| node | **n** | XML/HTML node in the form of `<tag ...>...</tag>` or `<tag/>` |
| curly brackets | **{** | All text within a matching pair of curly brackets in the form of `{...}` |
| square brackets | **[** | All text within a matching pair of square brackets in the form of `[...]` |
| parenthesis | **(** | All text within a matching pair of parenthesis in the form of `(...)` |
| angled brackets | **<** | All text within a matching pair of angled brackets in the form of `<...>` |
| comments | **#** | All text within a single line comment (i.e., `//...`) or multiline comment block (i.e., `/*...*/`) |
| double quotes | **"** | All text within a double-quoted string in the form of `"..."` |
| single quotes | **'** | All text within a single-quoted string in the form of `'...'` |
| backticks | **`** | All text within a backtick-quoted string in the form of \`...` |
| all | * | All text in the file |
| allto | **.** _(period)_ | All text from the beginning or end of the file to the current insertion cursor |
| block | **b** | Selects a rectangular block of characters in the file |

When selection mode is entered (using the `Edit / Select Mode` menu option or, better yet, the shortcut Command-A (on Mac) or Control-A), the selection object type is always set to `word`. To change the selection object type, simply enter the key associated with the desired type. For example, to change the object type to `line`, you would enter the **e** key. This will cause the current line to be selected instead of the current word.

You can change the selection object type at any point when working in selection mode.