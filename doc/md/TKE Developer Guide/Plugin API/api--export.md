## api\::export

This procedure can be used to export a given string to a file, performing snippet substitutions and Markdown to HTML conversion on the string if the specified language is set to a value of **Markdown**. This is the same functionality that is used by TKE's built-in export.

**Call structure**

`api::export string language filename`

**Return value**

None. Throws an error if there is a problem creating the export file.

**Parameters**

| Parameter | Description |
| - | - |
| string | Specifies a text string to export to a file. The string can contain embedded snippet text and, if they are found for the specified language, they will be expanded prior to being written to the output file. |
| language | Specifies the language to use for snippet expansion. This value would typically represent the syntax contained in the string, but it is not required to be. If this value is set to **Markdown**, Markdown to HTML (or XHMTL if the _filename_ extension is ".html") conversion will take place. |
| filename | Specified the pathname of the file that will be created, containing the exported string. |

**Example**

```Tcl
set str "This string contains an embedded snippet. ;snip"

# Export the string as Markdown
api::export $str Markdown [file join ~ Documents output.html]
```