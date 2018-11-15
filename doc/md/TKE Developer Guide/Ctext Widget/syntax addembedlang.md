## syntax addembedlang

If you have a language which allows for other languages to be embedded in that language (i.e., HTML language allows embedding PHP code that is encapsulated within a `<?` and `?>` character bracket, this command will allow you to define what embedded languages exist and how the parser can identify which text in the file belongs to which language.  The ctext widget will display embedded languages using a different background color than that used for the main language, helping the user to identify syntax differences.  It can also perform language-specific syntax highlighting based on the current language context.

It is important to note that the ctext widget does not support embedded languages deeper than a single level.  In other words, you can only embed languages within the main language.  You may not embed languages within an embedded language.

**Call Structure**

`pathname syntax addembedlang language {startpattern endpattern ?startpattern endpattern ...?}`

**Return Value**

None.

**Parameters**

| Parameter | Description |
| - | - |
| _language_ | Name of language to embed within the main language.  The value used in this parameter can be used in the other `syntax add*` commands but the language name must match exactly (case-sensitive). |
| _startpattern_ | Regular expression describing the syntax that begins an embedded language. |
| _endpattern_ | Regular expression describing the syntax that ends an embedded language. |