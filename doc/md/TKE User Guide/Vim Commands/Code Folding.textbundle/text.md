#### Code Folding

| Command or KEY | Description |
| - | - |
| **za** | Toggles the fold that is at the current line.  If no fold marker exists on this line, no action will be taken. |
| **zA** | Toggles all folds to the same state. |
| **zc** | Closes one level of folding at the current insertion cursor. |
| **zC** | Closes all levels of folding at the current insertion cursor. |
| **zo** | Opens one level of folding at the current insertion cursor. |
| **zO** | Opens all levels of folding at the current insertion cursor. |
| **zR** | Unfolds all folded code in the current editing buffer. |
| **zM** | Folds all foldable code in the current editing buffer. |
| **zf** | When text is selected and we are in manual folding mode, causes the selected text to be folded. |
| **zf**_num_**j** | When we are in manual folding mode, causes the following _num_ lines to be folded. |
| **zf**_num_**k** | When we are in manual folding mode, causes the previous _num_ lines to be folded. |
| **zd** | When we are in manual folding mode and the cursor is in a line that contains a fold indicator, the fold indicator will be removed. |
| **zE** | When we are in manual folding mode, all fold indicators are removed. |
| **zi** | Toggles all folds by one level to the same state. |
| **zj** | Jumps the cursor to the next folded line indicator. |
| **zk** | Jumps the cursor to the previous folded line indicator. |
| **zv** | If the cursor is within folded code such that it is not currently visible, this command will open enough folds to make the cursor viewable. |
| **:**_x,y_**fold** | Specifies a range of lines to fold. This is only valid when the foldmethod is set to manual. |
| **:**_x,y_**foldclose**[**!**] | Specifies a range of lines where any opened folds will be closed. If the **!** character is specified, all fold levels will be closed; otherwise, one level of folding will be closed. |
| **:**_x,y_**foldopen**[**!**] | Specifies a range of lines where any closed folds will be opened. If the **!** character is specified, all fold levels will be opened; otherwise, one level of folding will be opened.

