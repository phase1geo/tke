## api::utils::open\_file

Opens a file in the default external web browser.

**Call structure**

`api::utils::open_file filename ?in_background?`

**Return value**

Returns a boolean value of true if the file was successfully opened; otherwise, returns false.

**Parameters**

| Parameter | Description |
| - | - |
| filename | Name of file to display in an external web browser. |
| in\_background | Optional.  If set to a boolean value of true, keeps the focus within TKE (i.e., opening web browser in the background).  If set to a bool value of false, changes the focus to the web browser window. |

