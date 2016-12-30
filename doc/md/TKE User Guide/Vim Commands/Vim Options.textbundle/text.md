## Vim Options

Vim options are settings that apply to either the local editing buffer or all editing buffers and are accessed using the the following command:

`:set option?=value? ?option=value…?`

Where the value of option (and optionally value) corresponds to any of the following values.

| Option | Values | Default | Scope | Description |
| - | - | - | - | - |
| **autochdir**/**acd**, **noautochdir**/**noacd** | None | off | Global | When set, the current working directory will automatically change to be the directory containing the currently active file and will change whenever the user makes a new file the active file. |
| **autoindent**/**ai**,**noautoindent**/**noai** | None | off | Local | When set, the indentation mode of the current editing buffer will be set to auto-indent (IND) mode.  When unset, the indentation mode of the current editing buffer will be set OFF. |
| **browsedir**/**bsdir** | **last**, **buffer**, **current**, **directory** | last | Global | When the open file/directory dialog box is displayed, this value dictates the starting directory that will be displayed. (**last** = Last used directory; **buffer** = Directory containing the current file in the editing buffer; **current** = Current working directory; **directory** = Uses the specified pathname as the starting directory location) The default value for this option can be changed using the General/DefaultFileBrowserDirectory preference option.
| **expandtab**/**et**, **noexpandtab**/**noet** | None | on | Local | When set, forces the use spaces instead of tabs when the TAB key is pressed. The number of spaces is determined by the value of the tabstop option (if specified) or the Editor/SpacesPerTab preference value. When unset, forces the use of tabs when the TAB key is pressed. |
| **fileformat**/**ff** | **dos**, **unix**, **mac** | auto determined | Local | Overrides the end-of-line character that is used when saving an editing buffer. By default, this value is determined by Editor/EndOfLineTranslation preference setting. |
| **foldenable**/**fen**, **nofoldenable**/**nofen** | None | None | Local | This is option is only valid when the foldmethod is set to manual. If enabled, all existing folds are closed; otherwise, if unset, all existing folds are opened. |
| **matchpairs**/**mps** | **\{:\}**, **(:)**, **[:]**, **\<:\>** | determined by language | Local | Specifies character pairs that specify auto-completion characters. (Ex: `set mps+=<:>` to add angled brackets; `set mps-=(:),[:]` to remove parenthesis and square brackets); `set mps={:}` to use only curly brackets). |
| **modeline**/**ml**, **nomodeline**/**noml** | None | on | Local | When set, TKE will use any Vim modelines specified at the top of the file. When unset, TKE will ignore Vim modeline syntax. |
| **modelines**/**mls** | Num | determined by preference value | Global | Specifies the number of lines starting at the top of the file that TKE will search for Vim modeline syntax. This value overrides the default value from the Editor/VimModelines preference value. |
| **modifiable**/**ma**, **nomodifiable**/**noma** | None | on | Local | When set, sets the file lock status to locked. When unset, sets the file local status to unlocked. |
| **modified**/**mod**, **nomodified**/**nomod** | None | off | Local | When set, causes the status of the editing buffer to indicate that it is currently modified. When unset, clears the modified state of the editing buffer. |
| **number**/**nu**, **nonumber**/**nonu** | None | on | Local | When set, displays line numbers. When unset, hide the line numbers from view. |
| **numberwidth**/**nuw** | Num | 4 | Global | Specifies the minimum width of the line number gutter in characters. |
| **relativenumber**/**rnu**, **norelativenumber**/**nornu** | None | off | Local | When set, displays the line numbers in relative numbering format. When unset, displays the line numbers in absolute numbering format. |
| **shiftwidth**/**sw** | Num | determined by preference value | Local | Specifies the number of spaces to use when a left or right shift operation or an indentation/unindentation occurs. This overrides the default value specified with the Editor/IndentSpaces preference value. |
| **showmatch**/**sm**, **noshowmatch**/**nosm** | None | on | Global | Specifies whether a matching bracket/quote character will be automatically highlighted when the cursor is on the associated bracket/quote character.
| **smartindent**/**si**, **nosmartindent**/**nosi** | None | on | Local | When set, the indentation mode of the current editing buffer will be set to smart-indent (IND+) mode. When unset, the indentation mode of the current editing buffer will be set to OFF. |
| **splitbelow**/**sb**, **nosplitbelow**/**nosb** | None | off | Local | When set, splits the current editing buffer to provide two views of the same file. When unset, removes split view from the current editing buffer. |
| **syntax**/**syn** | Lang | auto determined by file extension | Local | Overrides the default language syntax highlighting to apply to the current editing buffer with the given language. |
| **tabstop**/**ts** | Num | determined by preference value | Local | Specifies the number of spaces that a TAB in the file counts for. |

