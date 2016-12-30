### Safe (Untrusted) Interpreter Description

Safe interpreters all their plugins to view and modify files within three directories:

- \~/.tke/plugins/_plugin\_name_
- _installation\_directory_/plugins/_plugin\_name_
- _installation\_directory_/plugins/images

Where _installation\_directory_ is the pathname to the directory where TKE is installed and _plugin\_name_ is the name of the plugin.  The filenames of these directories are managed in such a way that the “\~/.tke/plugins” and “_installation\_directory_/plugins” pathnames are hidden encoded is such a way that they cannot be discerned by the plugin.  Specifying any of these directories or files/subdirectories within these directories in any Tcl/Tk command that uses filenames will decode the full pathname within the TKE master interpreter and handle their usage in that interpreter.

The following table lists the differences in standard Tcl commands within a safe plugin interpreter to their standard counterparts.

| Command | Difference Description |
| - | - |
| cd | This command is unavailable. |
| encoding | You may get the system encoding value, but you may not set the system encoding value.  All other encoding subcommands are allowed. |
| exec | This command is unavailable. |
| exit | This command is unavailable. |
| fconfigure | This command is unavailable. |
| file atime, file attributes, file exists, file executable, file isdirectory, file isfile, file mtime, file owned, file readable, file size, file type, file writable | The name argument passed must be a file/directory that exists under one of the sandboxed directories. |
| file delete | Only names passed to the delete command that exist under one of the sandboxed directories will be deleted. |
| file dirname | If the resulting directory of this call is a directory under one of the sandboxed directories (or the a sandboxed directory itself), the name of the directory will be returned in encoded form. |
| file mkdir | Only names that exist under one of the sandboxed directories will be created. |
| file join, file extension, file rootname, file tail, file separator, file split | These can be called with any pathname since they neither operate on a file system directory/file nor require a valid directory/file for their operation to perform. |
| file channels, file copy, file link, file lstat, file nativename, file normalize, file pathtype, file readlink, file rename, file stat, file system, file volumes | These commands are not available. |
| glob | Only names that exist under one of the sandboxed directories (specified with the -directory or -path options) will be checked. |
| load | The requested file, a shared object file, is dynamically loaded into the safe interpreter if it is found. The filename exist in one of the sandboxed directories. Additionally, the shared object file must contain a safe entry point; see the manual page for the load command for more details. |
| open | You may only open files that exist under one of the three sandboxed directories. |
| pwd | This command is unavailable. |
| socket | This command is unavailable. |
| source | The given filename must exist under one of the sandboxed directories.  Additionally, the name of the source file must not be longer than 14 characters, cannot contain more than one period (.) and must end in either .tcl or be named tclIndex. |
| unload | This command is unavailable. |

