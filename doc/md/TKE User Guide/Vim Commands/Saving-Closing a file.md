#### Saving/Closing a file

| Command or KEY | Description |
| - | - |
| **:w** | Writes file under the original name.  If an original name has not been specified, a “Save As” window will be displayed. |
| **ZZ** or **:wq** or **:wq!** | Writes the file under the original name and closes the current tab.  If an original name has not been specified, a “Save As” window will be displayed. |
| **:wq** _filename_ or **:wq!** _filename_ | Writes the file under the given filename and closes the current tab. |
| **:q** | Closes the current tab.  If the text has been modified since the last save, a prompt will be displayed asking if you would like to save before closing. |
| **:q!** or **:cq** or **ZQ** | Closes the current tab regardless of the modification status.  Changes will not be saved and a prompt will not be displayed. |
| **:w** _filename_ | Writes the current file under the specified filename. |
| **:**_x,y_**w** _filename_ | Writes the specified range of lines to the given filename. |
| **:**_x,y_**w!** _filename_ | Writes the specified range of lines to the given filename overwriting the contents of the file. |

