## api::show\_info

Takes a user message and a delay time and displays the message in the bottom status bar which will automatically clear from the status bar after the specified period of time has elapsed.  This is useful for communicating status information to the user, but should not be used to indicate error information (the `api::show_error` procedure should be used for this purpose).

**Call structure**

`api::show_info message ?-clear_delay milliseconds? ?-win path?`

**Return value**

None

**Parameters**

| Parameter | Description |
| - | - |
| message | Message to display to user.  It is important that no newline characters are present in this message and that the message is no more than 100 or so characters in length. |
| **-clear\_delay** _milliseconds_ | Optional value.  Allows for the message to be cleared in a given number of milliseconds.  By default, this value is set to 3000 milliseconds (i.e., 3 seconds). If this value is set to 0, the displayed message will remain in the information bar until another message is displayed. |
| **-win** _path_ | Optional value. If specified, the given message will be remembered for the associated text widget such that if the associated text widget loses input focus and then later regains input focus, the message will automatically be redisplayed to the user. |

