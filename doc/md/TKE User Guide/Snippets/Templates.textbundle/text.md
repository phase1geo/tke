## Templates

Templates are essentially files containing valid snippet code. When a template file is created, a new
file can be created using this template file as a starting point and variable substitutions and other
information in the file can be preset using snippet variables and other snippet syntax. Template
files are specially managed by TKE and are saved in the user’s \~/.tke/templates directory (though you should not have to deal with this directory).

To create a new template file, simply create a new file with the needed text or use an existing file
and use the “File / Save As Template…” menu option. This will display an input text field allowing
for a name to be used for the template file. Any name can be used, but if you add an valid file extension that TKE recognizes for syntax highlighting, when the file is created based on the template, that extension’s syntax highlighter will automatically be used on the new file (even though the name of the file will be set to “Untitled” until it is saved).

To create a new file based on a template, choose the “File / New From Template…” menu option. This will display the template chooser. A list of available templates are displayed and the currently
selected file is displayed in the viewer panel of the window. Left-clicking or selecting and hitting
the RETURN key will add a new file editing buffer, insert the template information in the new file,
perform any snippet variable substitutions, and position the cursor in the first input area. Fill in
the file just as you would in a snippet.

To edit the contents of a snippet, use the “Edit / Templates / Edit” menu. This will display the
template chooser window. Select any one of the available templates using the left mouse button or by hitting the RETURN key on a selected template name. This will add the template to the editing buffer where you can edit the template file as you would any other file.

To delete an existing template, use the “Edit / Templates / Delete” menu. This will display the template chooser window. Select any one of the available templates using the left mouse button or by hitting the RETURN key on a selected template name. A confirmation window will be displayed to confirm the deletion. Clicking the “Yes” button will permanently delete the template.
