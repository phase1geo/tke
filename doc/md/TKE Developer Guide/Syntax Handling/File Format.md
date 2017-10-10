## File Format

The format of the syntax file is essentially a Tcl list containing key-value pairs.  As such, all values need to be surrounded by curly brackets (i.e, \{..\}).  Tcl command calls are not allowed in the file (i.e., no evaluations or substitutions are performed).

The following subsections describe the individual components of this file along with examples.

#### filepatterns

The filepatterns value is a list of file extension patterns that are used to automatically identify the type of file to associate the syntax rules to.  Whenever a file is opened in the editor, the file’s extension is compared against all of the syntax extensions.  A match causes the associated language syntax highlighting rules to be used.  If a syntax cannot be found, the default “\<None\>” syntax is used (essentially no syntax highlighting is applied to the file).  The format of this list should look as follows:

`filepatterns {extension …}`

Each extension value must contain a PERIOD (.) followed by a legal filesystem extension (ex., “.cc” “.tcl” “.php”, etc.)  Zero or more extension values are allowed in the extension list.

#### vimsyntax

The vimsyntax value is a list of one or more names that match the corresponding \*.vim syntax file (this can be found in the /usr/share/vim/vim\_version\_/syntax directory of your system, minus the .vim extension) that can also be used for syntax highlighting. This value is compared to any “syntax=name” Vim modeline information to determine which syntax highlighting language to use for the given file.

`vimsyntax {name …}`

#### reference

The reference value is a list of one or more name/URL pairings where each URL specifies the location of documentation pertaining to the given language. The associated name is displayed in the `Help/Language Documentation` submenu. If the name contains spaces, the full name should be encapsulated in curly braces. Typically, one of the reference items should be a language reference link.  However, other URLs can also be specified such as links to supporting documentation.

	reference {
	 {name url}+
	}

If a URL contains the syntax `{query}` within it, TKE will create a new URL by replacing this portion of the URL string with text that is either selected within the editing buffer or using the keyword that is beneath the insertion cursor. This allows user’s to use the Vim `K` command to perform language-specific documentation search. If no URLs are provided with this string embedded, the Vim `K` command will not be available for that syntax.

#### embedded

The embedded value is used to describe one or more language syntaxes that are either embedded in the language syntax between starting/ending syntax (ex., PHP within HTML) or are mixed in with the current language syntax (ex., C within C\++). The value is made up of a list of embedded language descriptions where each language description contains either one or three elements as follows:

	embedded {
	  {language ?start_expression end_expression?}+
	}

The specified language must be an existing language syntax that is provided natively with TKE or is provided via a plugin. The start\_expression and end\_expression values are regular expressions that describe the syntax for the start and end of the language syntax (if the language is embedded in the parent language as a block). If the embedded language is intermixed in syntax with the parent language (as is the case with C/C\++), then no start\_expression and end\_expression values should be specified for the language description. For examples of embedded language description, see the HTML.syntax and C\++.syntax files in the data/syntax installation directory.

#### matchcharsallowed

Specifies a list of characters that will be automatically, smartly inserted into or deleted from the editing buffer when its counterpart is inserted/deleted.

`matchcharsallowed { ?value …? }`

The following is the list of legal values:

| Value | Description |
| - | - |
| curly | Left curly bracket (\{) insertion/deletion will cause the right curly bracket (\}) to be added/removed. |
| square | Left square bracket ([) insertion/deletion will cause the right square bracket (]) to be added/removed. |
| paren | Left parenthesis (() insertion/deletion will cause the right parenthesis ()) to be added/removed. |
| angled | Left angled bracket (\<) insertion/deletion will cause the right angled bracket (\>) to be added/removed. |
| double | Double quote (“) insertion/deletion will cause another double quote to be added/removed. |
| single | Single quote (‘) insertion/deletion will cause another single quote to be added/removed. |
| btick | Backtick (\`) insertion/deletion will cause another backtick to be added/removed. |

#### escapes

The escapes value is used to indicate to the syntax highlighter whether or not the escape character (\\) should be treated as a C escape character (i.e., the character immediately following the escape character should not be considered its normal value) or as just another character in the syntax.  A value of 1 is the default (consider the escape as in C).

`escapes {0|1}`

#### tabsallowed

The tabsallowed value is used to determine whether any TAB characters entered in the editor should be inserted as a TAB or should have the TAB substituted as space characters.  It is recommended that unless the file type requires TAB characters in the syntax (ex., Makefiles) that this value should be set to false (0). This value should be either 0 (false) or 1 (true) and should be specified as follows:

`tabsallowed {0|1}`

#### linewrap

The line wrap value is used to specify if the editing buffer for the language should enable (1) or disable (0) line wrapping by default. For example, syntaxes that support writing should potentially enable line wrapping by default; however, programming languages should not.

`linewrap {0|1}`
 
#### casesensitive

The casesensitive value specifies if the language is case sensitive (1) or not (0).  If the language is not case sensitive, TKE will perform any keyword/expression matching using a case insensitive method.  This value should be either 0 or 1 and should be specified as follows:

`casesensitive {0|1}`

#### delimiters

The delimiters value allows a syntax specification to provide a custom regular expression that is used for determining word boundaries.  This value is optional as a default delimiter expression will be used if this value is not specified.  The default expression is as follows:

`[^\s\(\{\[\}\]\)\.\t\n\r;:=\”'\|,<>]+`

The following specifies the syntax for this element:

`delimiters {regular_expression}`

#### indent

The indent value is a list of language syntax elements that should be used to cause a level of indentation to be automatically added when a newline character is inserted after a syntax match occurs.  Each element in the list should be surrounded by curly brackets (ex., \{…\}) with whitespace added between elements.  Any curly brackets used within an element should be escaped with the BACKSPACE (\\) character (ex., \\\{).

Any Tcl regular expressions can be specified for an indent element.

The following specifies the syntax for this element:

`indent {{indentation_expression} *}`

#### unindent

The unindent value is a list of language syntax elements that should be used to cause a level of indentation to be automatically removed when a matching syntax is found.  Each element in the list should be surrounded by curly brackets (ex., \{…\}) with whitespace added between elements.  Any curly brackets used within an element should be escaped with the BACKSPACE (\\) character (ex. \\\}\}).

Any Tcl regular expressions can be specified for an unindent element.

The following specifies the syntax for this element:

`unindent {{unindentation_expression} *}`

#### reindent

The reindent value is a list of language syntax elements that may cause both an unindent followed by an indent such as the case of C/C\++ switch..case syntax.  Each element of the list consists of a starting regexp element that starts the sequence of indentations.  Each element in the list after it are potential reindent syntax where the first occurrence of the reindent element will not be unindented but all occurrences of one of the reindent elements afterwards (but in the same statement block as the the first occurrence) will be unindented.

This feature allows for proper automatic indentation in the syntax like C/C\++ switch and C\++ classes (code following “public”, “private” and “protected” lines will be indented) as the following example code shows:

	switch( a ) {
	  case 0 :
	… // This code will be auto-indented properly
	break;
	  case 1 :  // ‘case’ will be unindented automatically
	… // This line will be indented
	break;
	}

See the C\++.syntax file in the \<TKE\>/data/syntax directory for an example of what this code would look like to handle a switch/class case using reindent.

The following specifies the syntax for this element:

`reindent {{start_expression expression …} *}`

#### icomment

The icomment value is a list of one or two elements that represent the character string to insert a comment when the user selects the “Text / Comment” menu item.  If the list contains one character sequence, the sequence is assumed to be used as a line comment (i.e., it is inserted before each line of selected text at the beginning of the line).  If the list contains two character sequences, the sequences are treated as the beginning and end of a block comment (i.e., the first character sequence will be inserted before a block of selected text while the second sequence will be inserted after a block of selected text).  Note that the “Text / Uncomment” menu item will not use these values for removing comment characters, instead it uses a combination of the “lcomments” and “bcomments” regular expressions for comment parsing.

#### lcomments

The lcomments value is a list of language syntax elements that indicate a line comment.  Whenever a match in the file occurs, the syntax and all other syntax after it until the newline character is found is syntax highlighted as a comment.  Each element in the list should be surrounded by curly brackets (ex., \{…\}) with whitespace characters added between elements.  Any curly brackets used within an element should be escaped with the BACKSPACE (\\) character (ex., \\\{\{).

Any Tcl regular expressions can be specified for an lcomments element.

The following specifies the syntax for this element:

`lcomments {{element} *}`

#### bcomments

The bcomments value is a list of language syntax element pairs that indicate the starting syntax and ending syntax elements to define a block comment.  All text between these syntax elements are highlighted as comments.  Each pair in the list should be surrounded by curly brackets (ex., \{…\}) as well as each element in the pair.  All elements must contain whitespace between them and any curly brackets used within an element should be escaped with the BACKSPACE (\) character (ex., \\\{\{).

Any Tcl regular expressions can be specified for elements in each bcomments pair.

The following specified the syntax for this element:

`bcomments {{{start_element} {end_element}} *}`

#### strings

The strings value is a list of language syntax elements that indicate the start and end of a string.  All text found between two occurrences of an element will be highlighted as a string.  Each element in the list should be surrounded by curly brackets (ex., \{…\}) with whitespace characters added between elements.

Any Tcl regular expressions can be specified for an strings element.

The following specifies the syntax for this element:

`strings {{element} *}`

#### keywords

The keywords value is a list of syntax keywords supported by the language.  Each keyword must be a literal value (no regular expressions can be specified) and must be parseable as a word.  All elements in the list must be separated by whitespace.

The following specifies the syntax for this element:

`keywords {{keyword} *}`

#### symbols

The symbols value is a list of syntax keywords and/or regular expressions that represent special markers in the code.  The name of the symbol is the first word following this keyword/expression.  The user can find all symbols within the language and jump to them in the source code by specifying the ‘@‘ symbol in the command launcher and typing in the name of the symbol to search for.

For example, to make all Tcl procedures a symbol, a value of “proc” would be specified in the symbol keyword list.  The list of symbols would then be the name of all procedures in the source code.

Whitespace must be used to separate all symbol values in the list.

The following specifies the syntax for this element:

	symbols {
	  {HighlightKeywords {symbol_keyword *}} *
	  {HighlightClassForRegexp {regular_expression} {processing_procedure}} *
	}

The value of _symbol\_keyword_ must be a literal value.  The value of _regular\_expression_ must be a valid Tcl regular expression.  You can have any number of HighlightClass and/or HighlightClassForRegexp lists in the symbols list.

The value of _processing\_procedure_ is used in the same way as those specified in the advanced section of the syntax file. See the advanced section for details on the makeup of this procedure. If a processing procedure is not necessary, simply pass the empty Tcl list (`{}`) in its place.

#### numbers

The numbers value is a list of regular expressions that represent all valid numbers in the syntax.  Any text matching one of these regular expressions will be highlighted with the number syntax color.  Whitespace must be used to separate all number expressions in the list.

The following specifies the syntax for this element:

	numbers {
	  {HighlightClassForRegexp {regular_expression} {processing_procedure}} *
	}

#### punctuation

The punctuation value is a list of regular expressions that represent all valid punctuation in the syntax.  Any text matching one of these regular expressions will be highlighted with the punctuation syntax color.  Whitespace must be used to separate all regular expressions in the list.

The following specifies the syntax for this element:

	punctuation {
	  {HighlightClassForRegexp {regular_expression} {processing_procedure}} *
	}

#### precompile

The precompile value is a list of regular expressions that represent all valid precompiler syntax in the language (if the language supports it).  Any text matching one of these regular expressions will be highlighted with the precompile syntax color.  Whitespace must be used to separate all regular expressions in the list.

The following specifies the syntax for this element:

	precompile {
	  {HighlightClassForRegexp {regular_expression} {processing_procedure}} *
	  {HighlightClassStartWithChar {character} {processing_procedure}} *
	}

The _regular\_expression_ value must be a valid Tcl expression.  The character value must be a single keyboard character.  The HighlightClassStartWithChar is a special case regular expression that finds a non-whitespace list of characters that starts with the given character and highlights it.  From a performance perspective, it is faster to use this call than a regular expression if your situation can take advantage of it.

#### miscellaneous1, miscellaneous2, miscellaneous3

The miscellaneous values are a list of literal keyword values or regular expressions that either don’t fit in with any of the categories above or an additional color is desired.  Each miscellaneous group is associated with its own color.  Any values and/or regular expressions that match these values will be highlighted with the corresponding color.  Whitespace is required between all values in this list.

The following specifies the syntax for this element:

	miscellaneous {
	  {HighlightKeywords {{keyword} *}}
	  {HighlightClassForRegexp {regular_expression} {processing_procedure}} *
	  {HighlightClassStartsWithChar {character} {processing_procedure}} *
	}

#### highlight

The highlight section allows text to be syntax highlighted by colorizing the background color instead of the foreground color.  The foreground color of this text will be the same as the background color of the editing window.

The following specifies the syntax for this element:

	highlighter {
	  {HighlightClassForRegexp {regular_expression} {processing_procedure}} *
	  {HighlightClassStartWithChar {character} {processing_procedure}} *
	}

#### meta

The meta section allows text to be syntax highlighted with a color that matches the warning width and line numbers.  Any text matched with this type has the special ability to be shown or hidden by the user based on the setting of the View menu option.  An example of where this is used is in marking up Markdown characters used for formatting purposes.  Since the formatted text is viewable with Markdown, the formatting characters can be hidden to help make the document even easier to read.

The following specifies the syntax for this element:

	meta {
	  {HighlightClassForRegexp {regular_expression} {processing_procedure}} *
	  {HighlightClassStartWithChar {character} {processing_procedure}} *
	}

#### readmeta

The readmeta section acts exactly the same as the meta section described above with the only exception being that the theme coloring used to color the foreground of tagged text will differ from meta syntax. The idea is that the meta color should be only slightly different than the background color but the readmeta color should have a higher contrast to the background to make it more readable. Typically, things like Markdown URLs or image file locations would be marked with this type instead of meta. Both meta and readmeta classes are hidden or shown with the "View / Show/Hide Meta Characters" menu option.

#### advanced

The advanced section allows for more complex language parsing scenarios (beyond what can be handled with a regular expression only) and allows the user to change the font rendering (i.e., bold, italics, underline, overstrike, superscript, subscript, and font size) and handle mouse clicks.

The advanced section is comprised of two or three parts: highlight classes, regular expressions and processing procedures.

##### Highlight Classes

The first part is a list of highlight classes that are user-defined.  A highlight class is defined using the following syntax:

`HighlightClass class_name syntax_key {render_options}`

where _class\_name_ is a user-defined name that will be rendered with the color of the _syntax\_key_ and the options associated with _render\_options_.  The value of _syntax\_key_ can be any of the highlight classes for a syntax file (i.e., strings, keywords, symbols, numbers, punctuation, precompile, miscellaneous1, miscellaneous2, miscellaneous3).  The list of _render\_options_ is a space-separated list of any of the following values:

| Value(s) | Description |
| - | - |
| bold | Any text tagged with the associated _class\_name_ will be emboldened. |
| italics | Any text tagged with the associated _class\_name_ will be italicized. |
| underline | Any text tagged with the associated _class\_name_ will be underlined. |
| h1, h2, h3, h4, h5, h6 | Any text tagged with the associated _class\_name_ will have its font rendered the the specified font size where a value of h1 is the largest font while h6 is a font size one point size greater than the normal font size used in the editor. |
| overstrike | Any text tagged with the associated _class\_name_ will be overstriken. |
| superscript | Any text tagged with the associated _class\_name_ will be written in superscript. |
| subscript | Any text tagged with the associated _class\_name_ will be written in subscript. |
| click | Any text tagged with the associated _class\_name_ will be clickable.  Any left-clicks associated with the text will call a specified Tcl procedure. |

##### Regular Expressions

The second section in the advanced section is a list of highlight calls, associating values/regular expressions with Tcl procedure calls that will be executed whenever text is found that matches the value/regular expression.  The highlight calls are defined using the following syntax:

	HighlightRegexp             {regular_expression} processing_procedure
	HighlightClassStartWithChar {character}          processing_procedure

##### Processing Procedures

For user-created syntax files, the location of the processing procedures will either be within the main.tcl plugin file or within the syntax file itself.  The purposes of the Tcl procedure is to take the matching contents of the text widget and return a list containing a list of tags, their starting positions in the text widget, their ending positions in the text widget, and any Tcl procedures to call (if the tag is clickable) along with an optional new starting position in the text widget to begin parsing (default is to start at the character just after the input matching text.

The following is a representation of this Tcl procedure:

	proc foobar {txt start_pos end_pos ins} {
	  return [list [list [list tag new_start new_end cmd]] “”]
	}

where the value of tag is one of the user-defined class names within the syntax advanced section, the value of _new\_start_ and _new\_end_ is a legal index value for a Tcl text widget, and the value of cmd is a Tcl procedure along with any parameters to pass when it is called.  The last element of the list is a legal Tcl text widget index value to begin parsing in the main syntax parser.  If this value is the empty string, the parser will resume parsing at the _end\_pos_ character passed to this function.

The parameters of the procedure include _txt_ which is the name of the text widget, _start\_pos_ and _end\_pos_ which indicate the range of text that matched the HighlightRegexp or HighlightClassStartWithChar, and _ins_ indicates if the procedure callback was due to text being inserted (1) or not (0).

The body of the function should perform some sort of advanced parsing of the given text that ultimately produces the return list.  Care should be taken in the body of this function to produce as efficient of code as possible as this procedure could be called often by the syntax parser.

For an example of how to write your own advanced parsing code, refer to the _markdown\_color_ plugin located in the installation directory (_installation\_directory_/plugins/\_markdown\_color\_).

In addition to writing the processing procedures outside of the syntax file, you can also embed the processing procedures directly in the syntax file itself using the following syntax:

	HighlightProc name {
	 # Body of procedure
	 # Four variables are automatically available:
	 #   - $txt = refers to the text widget containing the matched text
	 #   - $startpos = starting position of the matched text
	 #   - $endpos = ending position of the matched text
	 #   - $insert = Set to 1 if we are syntax highlighting due to inserting text; otherwise, it will be set to 0.
	} HighlightEndProc

All text between `HighlightProc` and `HighlightEndProc` will be highlighted by TKE as Tcl syntax.  The body of the function works the same as the processing procedure that was previously described.

If you want to include additional Tcl syntax within the file that is not directly called by the TKE highlighter, you can include this code within the syntax advanced section by wrapping it with a `TclBegin`/`TclEnd` block as shown below.

	TclBegin {
	 var exampleVar;
	 proc example_proc {} { ... }
	} TclEnd

The code inserted in the `TclBegin` block will be syntax highlighted and will be inserted into the syntax::`lang` namespace, where `lang` matches the lowercase base name of the language syntax file (i.e., HTML.syntax exists in the `syntax::html` namespace).

Additionally, you can ignore any blocks within the advanced section by wrapping them with an `IgnoreBegin` and `IgnoreEnd` block as shown below.

	advanced {
	 IgnoreBegin {
	   HighlightRegexp {...} {}
	 } IgnoreEnd
	 HighlightRegexp {...} {}
	}

The `IgnoreBegin`/`IgnoreEnd` block is useful when you are testing syntax code, especially when you are trying different strategies and would like the ability to "comment out" code temporarily.  It is good practice to remove all ignore blocks when you are using the syntax in production.

#### formatting

Specifies one or more supported syntax formatting by associating a TKE formatting template. The information specified in this section is used by TKE’s `Edit/Formatting` menu.

This section must be specified as follows:

	formatting {
	 type {(word|line) text_template}+
	}

The valid values for `type` are as follows:

- bold
- italics
- underline
- strikethrough
- highlight
- superscript
- subscript
- code
- header1, header2, header3, header4, header5, header6
- ordered
- unordered
- checkbox
- link
- image

A value of `word` should be used if the currently selected text should be inserted into the template. A value of `line` should be used if the entire line should be inserted into the template.

The template is a single string containing all of the formatting syntax required. It may include two special strings within it:

- `{TEXT}` = Replaces this string with the selected or dropped text in the editing buffer. If no text is selected or dropped, TKE will place the insertion cursor at this point.
- `{REF}` = Replaces this string with information that is requested from the user. Only formatting types of "link" and "image" may use this string within the formatting template. In the case of "link", the {REF} value will be the link URL value. In the case of "image", the {REF} value will be the URL of the image file.

The formatting template may contain newlines (using the Enter key and not '\n'). When the formatting template is inserted into the text, TKE will perform auto-indentation based on the syntax and user preference information.