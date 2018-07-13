

### What is this?

This plugin allows the user to highlight all matches of a word when it's selected by double-clicking.

The plugin is most useful when you want to see all nearby uses of some specific name, e.g. abc parameter ($abc, {abc}, set abc ...) or xyz procedure (proc xyz, [xyz], [list xyz $abc] ...).

Just double-click on a word "abc" or "xyz" to highlight it throughout the text.

"Plugin/ Highlight Matches/ Highlight" menu entry allows to highlight an arbitrary selected text, not only words.

If the cursor is set on a word and there is no selection, all "Plugin/ Highlight Matches" operations would apply to this word.

One character and multiline selections are ignored by the highlight operation. However all jump operations work all the same.

Please, use the plugin with care. If you try to highlight a string with several hundreds (or more) matches you take the risk of waiting for a good while.

Note that the highlighting and the jumpings are case sensitive;


### Menu usage

There is a menu option that allows to restrict the size of text to be involved in the highlighting operation. Open "Plugin/ Highlight Matches/ Options..." menu entry and set the number of rows to be spanned by this operation. At that:
  - empty input means "all rows to be involved";
  - number 0 means  "no rows" which disables the double-click highlight;
  - number N (not 0) means involving N rows around the cursor.

This option allows to quicken the highlighting when you want to view only some neighbouring occurences of the word (say, in the current function and its surroundings). A size of function exceeds rarely 100 lines, so 99 would be a good choice for this option.

Setting this option to 0 disables only double-clicking highlights. All menu "Plugin/ Highlight Matches" operations apply to the whole text at that.

Other entries of "Plugin/ Highlight Matches" menu are following:
  `Jump Backward` means moving the cursor to the previous selection;
  `Jump Forward`  means moving the cursor to the next selection;
  `Jump to First` means moving the cursor to the first selection;
  `Jump to Last`  means moving the cursor to the last selection.

It would be convenient to assign the following shortkeys for the "Plugin/ Highlight Matches" operations:
  *Alt-H*     - Highlight
  *Alt-Left*  - Jump to Backward
  *Alt-Right* - Jump to Forward
  *Alt-Q*     - Jump to First
  *Alt-W*     - Jump to Last
For lefthanders, though, Alt+Q and Alt+W are more convenient than Alt+Arrows. Checked by the plugin author.

While in Vim mode ("Edit/ Preferences/ Editor") you can't highlight a word with double-clicking, so "Plugin/ Highlight Matches/ Highlight" and its shortkey can only help you.


### Tips and traps

You can use TKE's multiple cursors to change the multiple selections available after the highlighting.

Note the cursors at start of highlights. If you mouse-clicked, the multiple selections would go - but the cursors not! So your new input would occur at all the cursors. You can either use or cancel this mode.

Just pressing any of navigation keys will cancel the multiple highlights as well as the multiple cursors. Press Ctrl-Z if you made a blunder anyway.

You can also try this:
  - highlight all occurences of selected text;
  - note the cursors at start of highlights;
  - if you press a key it would replace the starting character of selections; all the following keystrokes would add new characters;
  - use this feature freely: delete the unnecessary, add the necessary;
  - press Right key to restore the single cursor.

The typical scenarios may be such as:
  1. To replace the initial letters of words (say, "l" to convert all "Label" into "label"):
    - double-click the word;
    - enter the initial letter;
    - press Right key to restore the single cursor.
  2. To replace all words with new ones:
    - double-click the word;
    - press Delete;
    - enter new word;
    - press Right key to restore the single cursor.

If there are multiple selections and no more multiple cursors, new keystroke would replace all text from starting to ending selections with the input character. This would occur if you press Esc instead of navigation keys.

You should take this into account while using the highlight feature.


### Example of Usage

We edit the following code:

    set sel [$w get $selected]
    set countList {}
    set startList [$w search -all -regexp -count countList $sel 1.0 end]
    foreach first $startList count $countList {
       $w tag add sel $first [$w index "$first + $count chars"]
    }

After double-clicking on _count_ we get all six _count_ being highlighted.

