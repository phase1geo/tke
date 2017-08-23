## Vim Modelines

By default, TKE will parse the first few lines of each opened file for Vim modeline syntax. If a valid modeline is found, the recognized Vim options within the modeline are parsed and applied. A valid modeline is one of the following formats.

| Mode Line Syntax |
| - |
| ** vi:set** _opts_**:** |
| ** vim:set** _opts_**:** |
| ** vim**_version_**:set** _opts_**:** |
| ** vim\<**_version_**:set** _opts_**:** |
| ** vim=**_version_**:set** _opts_**:** |
| ** vim\>**_version_**:set** _opts_**:** |
| ** ex:set** _opts_**:** |
| ** vi:**_opts_ |
| ** vim:**_opts_ |
| ** vim**_version_**:**_opts_ |
| ** vim\<**_version_**:**_opts_ |
| ** vim=**_version_**:**_opts_ |
| ** vim\>**_version_**:**_opts_ |
| ** ex:**_opts_ |

The value of _opts_ is a list of Vim options separated by colon or space characters. The spaces listed above are required, including the space prior to the beginning of the Vim options. The _version_ value is disregarded though the syntax is parsed.

As an example of a valid Vim modeline, consider the following line which sets the tabstop value to 4, adds an angled bracket match pair and sets line numbering to relative.

`// vim:ts=4 mps+=<\:> rnu`

Only local options will be used in the Vim modeline.  Global options will be ignored without error.