## api\::show\_info

Takes a user message and a delay time and displays the message in the bottom status bar which will automatically clear from the status bar after the specified period of time has elapsed.  This is useful for communicating status information to the user, but should not be used to indicate error information (the api\::show\_error procedure should be used for this purpose).

**Call structure**

`api::show_info message ?clear_delay?`

**Return value**

None

**Parameters**

| Parameter | Description |
| - | - |
| message | Message to display to user.  It is important that no newline characters are present in this message and that the message is no more than 100 or so characters in length. |
| clear\_delay | Optional value.  Allows for the message to be cleared in “clear\_delay” milliseconds.  By default, this value is set to 3000 milliseconds (i.e., 3 seconds). |

