## api::register\_launcher

Registers a plugin command with the TKE command launcher.  Once a command is registered, the user can invoke the command from the command launcher by entering a portion of the description string that is passed via this command.

**Call structure**

`api::register_launcher description command`

**Return value**

None

**Parameters**

| Parameter | Description |
| - | - |
| description | String that is displayed in the command launcher matched results.  This is also the string that is used to match against. |
| command | Command to run when this entry is executed via the command launcher. |

