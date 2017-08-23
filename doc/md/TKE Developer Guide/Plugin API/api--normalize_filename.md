## api\::normalize\_filename

Takes a NFS-attached host where the file resides along with the pathname on that host where the file resides and returns the normalized filename to access the file on the current host.

**Call structure**

`api::normalize_filename host filename`

**Return value**

Returns the normalized pathname of the given file relative to the current host machine.

**Parameters**

| Parameter | Description |
| - | - |
| host | Name of host server where the file actually resides.
| filename | Name of file on the host server. |

