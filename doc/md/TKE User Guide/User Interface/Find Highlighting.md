### Find Highlighting

TKE supports searching within a text window via the “Find” menu.  When a string is searched within the text window, all matching text will be highlighted and the insertion cursor will be placed at the beginning of the first matched text.  This allows you to quickly see all matches within the text window.

When either the “Find” or “Find and Replace” functions are invoked, if text is currently selected in the text window, that text will be automatically placed in the search field.

You can change the matching method used within the "Find" or "Find and Replace" UI areas to one of: regexp (Regular Expression matching), glob (Glob-style matching), or exact. If text exists in the Find entry field, changing the search method will cause the find highlighting to reapplied immediately.

You can cause the insertion cursor to jump between highlighted matches by either using the back and forward buttons in the "Find" or "Find and Replace" UI areas or with the `Find / Find Next` and `Find / Find Previous` menu options.