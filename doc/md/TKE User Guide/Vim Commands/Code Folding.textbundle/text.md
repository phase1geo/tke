#### Code Folding

| Command or KEY | Description |
| - | - |
| **za** | Toggles the fold that is at the current line.  If no fold marker exists on this line, no action will be taken. |
| **zA** | Toggles all folds to the same state. |
| **zc** | Closes one level of folding at the current insertion cursor. |
| _num_**zc** | Closes _num_ levels of folding at the current insertion cursor. |
| **zC** | Closes all levels of folding at the current insertion cursor. |
| **zo** | Opens one level of folding at the current insertion cursor. |
| _num_**zo** | Opens _num_ levels of folding at the current insertion cursor. |
| **zO** | Opens all levels of folding at the current insertion cursor. |
| **zR** | Unfolds all folded code in the current editing buffer. |
| **zM** | Folds all foldable code in the current editing buffer. |
| **zf** | When text is selected and we are in manual folding mode, causes the selected text to be folded. |
| **zf**_num_**j** | When we are in manual folding mode, causes the following _num_ lines to be folded. |
| **zf**_num_**k** | When we are in manual folding mode, causes the previous _num_ lines to be folded. |
| _num_**zF** | When we are in manual folding mode, causes the following _num_ lines to be folded. |
| **zd** | When we are in manual folding mode and the cursor is in a line that contains a fold indicator, the fold indicator will be removed. |
| _num_**zd** | When we are in manual folding mode and the cursor is in a line that contains a fold indicator, _num_ levels of folding will be removed. |
| **zD** | When we are in manual folding mode and the cursor is in a line that contains a fold indicator, the fold indicator and all other folds within the current fold will be removed. |
| **zE** | When we are in manual folding mode, all fold indicators are removed. |
| **zi** | Toggles the value of `foldenable`. If the new `foldenable` state is off, all folds will be opened and the fold UI will be hidden from view. If the new state is on, all previous fold information (if applicable) will be restored and fold markers will be displayed. |
| **zj** | Jumps the cursor to the next folded line in the editing buffer. |
| _num_**zj** | Jumps the cursor to the _num_th folded line in the editing buffer after the insertion cursor. |
| **zk** | Jumps the cursor to the previous folded line in the editing buffer. |
| _num_**zk** | Jumps the cursor to the _num_th folded line in the editing buffer before the insertion cursor. |
| **zn** | Sets the Vim `foldenable` value to 0, causing the current fold information to be hidden and all folded code opened. |
| **zN** | Sets the Vim `foldenable` value to 1, restoring any previous fold information. |
| **zv** | If the cursor is within folded code such that it is not currently visible, this command will open enough folds to make the cursor viewable. |
| **:**_x,y_**fold** | Specifies a range of lines to fold. This is only valid when the foldmethod is set to manual. |
| **:**_x,y_**foldclose**[**!**] | Specifies a range of lines where any opened folds will be closed. If the **!** character is specified, all fold levels will be closed; otherwise, one level of folding will be closed. |
| **:**_x,y_**foldopen**[**!**] | Specifies a range of lines where any closed folds will be opened. If the **!** character is specified, all fold levels will be opened; otherwise, one level of folding will be opened.