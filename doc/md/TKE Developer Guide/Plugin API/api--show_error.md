## api\::show\_error

Takes a user message and optional detail information and displays the message in a popover window.  This window is the standard error window used by TKE internal code and, therefore, is the recommended way to display error information to the user.

**Call Structure**

`api::show_error message ?detail?`

**Return value**

None

**Parameters**

| Parameter | Description |
| - | - |
| message | Short error message. |
| detail | Optional. Detailed error description. |

