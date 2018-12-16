#### Repeating a command

| Command or KEY | Description |
| - | - |
| _count_**.** | Repeats the last command that changed the buffer _count_ times (defaults to once if _count_ is not specified). |
| **q**_a-z_ | Starts recording the following keystrokes to the specified buffer labeled _a_ through _z_.  To stop recording to this buffer, enter **q** when in command mode.  When you are recording, the information bar will display this state information and specify the buffer label storing the keystrokes.  If **q** is entered immediately following the buffer label, it will effectively delete the buffer contents. |
| **@**_a-z_ | Replays the stored keystrokes in the specified buffer. |
| **@:** | Replays the last colon command entered. |
