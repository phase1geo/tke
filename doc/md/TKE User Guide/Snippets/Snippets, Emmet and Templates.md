# Snippets, Emmet and Templates

Snippets allow the user to enter a short bit of text (herein called the _abbreviation_) which will be
replaced by a larger piece of text (called the _snippet_) when a whitespace character (selectable in
the preference file) is entered. For example, suppose we have defined an abbreviation called “hw”
which is assigned the snippet text “Hello, world!”. If we enter the following string in an editor:

`cout << "hw`

and follow it with hitting either the SPACE, RETURN or TAB key, the editor will replace the abbreviation
to look like the following:

`cout << "Hello World!`

In addition to simple ascii text, the snippet text can contain various styles of variables. For example,
suppose we are editing a file called “foobar.cc” and have defined an abbreviation called “cf” which is
assigned the snippet text “$FILENAME”. If we enter the following string in an editor:

`File: cf`

and follow it with hitting either the SPACE, RETURN or TAB key, the editor will replace the abbreviation
to look like the following:

`File: foobar.cc`
