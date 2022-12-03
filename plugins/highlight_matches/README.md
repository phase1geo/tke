
# What is this?


This plugin allows the user to highlight all (or nearby) matches of a word when it's selected by double-clicking.

The plugin is most useful when you want to see quickly the nearby occurences of some specific name, e.g. abc parameter ($abc, {abc}, set abc ...) or xyz procedure (proc xyz, [xyz], [list xyz $abc] ...).

Just double-click on a word "abc" or "xyz" to highlight it throughout the text.

"Plugin/ Highlight Matches/ Highlight" menu entry allows to highlight an arbitrary selected text, not only words.

If the cursor is set on a word and there is no selection, all "Plugin/ Highlight Matches" operations would apply to this word.

Also, the plugin allows to jump to a previous/next/first/last occurence of a word under cursor. Think of this plugin as "quick though moderate search".

The one character and multiline selections are ignored by the highlight operation. However all jump operations work all the same.

Note that if you try to highlight a string with several hundreds (or more) matches you take the risk of waiting for a good while. Though, you can restrict the span of lines for the highlighting.

The highlightings and the jumpings are case sensitive.

Note:
The plugin was tested under Linux (Debian) and Windows. All bug fixes and corrections for other platforms would be appreciated at aplsimple$mail.ru.


# Menu usage


There is an option that allows to restrict the size of text to be involved in the highlighting operation. Open the "Edit/ Preferences/ Edit user - Global/ Plugins/" menu entry, select the highlight_matches plugin and set the number of rows to be spanned by this operation. At that:
   -1 or empty input means involving all rows to be highlighted;
   0 means "no rows" which disables the plugin;
   N>0 means involving N rows around the cursor.

This option allows to quicken the highlighting when you want to view only some neighbouring occurences of the word (say, in the current function and its surroundings). A size of function exceeds rarely 100 lines. Probably, 100, 150 or 200 would be a good choice for this option.

Note however that the Plugin/ Highlight Matches/ Do Highlight *menu action* doesn't regard the restriction of span and selects all occurences.

Setting this option to 0 disables only double-clicking highlights. All menu "Plugin/ Highlight Matches" operations apply to the whole text at that.

Other entries of "Plugin/ Highlight Matches" menu are following:
  *Jump Back* means moving the cursor to the previous selection;
  *Jump Forth*  means moving the cursor to the next selection;
  *Jump to First* means moving the cursor to the first selection;
  *Jump to Last*  means moving the cursor to the last selection.

It would be convenient to assign the following shortkeys for the "Plugin/ Highlight Matches" operations:
  *Alt-H*     - Do Highlight
  *Alt-Left*  - Jump Back
  *Alt-Right* - Jump Forth
  *Alt-Q*     - Jump to First
  *Alt-W*     - Jump to Last
For lefthanders, though, Alt+Q and Alt+W are more convenient than Alt+Arrows. Checked by the plugin author:)

While in Vim mode ("Edit/ Preferences/ Editor") you can't highlight a word with double-clicking, so "Plugin/ Highlight Matches/ Do Highlight" and its shortkey can only help you.


# Note

In the *Highlight Matches* plugin v2.0, some of its menu items had been renamed. Thus, if you had defined the items' key shortcuts, redefine the shortcuts and restart TKE to enable them.


# Example of Usage


We edit the following code:

    set sel [$w get $selected]
    set countList {}
    set startList [$w search -all -regexp -count countList $sel 1.0 end]
    foreach first $startList count $countList {
       $w tag add sel $first [$w index "$first + $count chars"]
    }

After double-clicking on *count* we get all six *count* highlighted.

