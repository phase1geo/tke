### What is this?

This url_validator plugin allows the user to quickly and easily validate URLs
that are either embedded in the current file (the file syntax must be either
Markdown or HTML in nature) and all URLs must begin with "http://" syntax and must
conform to proper URL syntax.  The plugin can also check URLs that are selected
in the current file or URLs that are input in an entry field, located at the bottom
of the main window.

All checked URLs will be displayed in a popup window after being checked with the
validation status and return code.

### Example of Usage:

While this file is the current editing buffer, select the **Plugins / URL Validator / Validate file"
menu option.  The resulting popup window will display four URLs found within this file.
Click on found URL to set the insertion marker on the within the associated editing buffer of the file.

---

Here is a URL: http://www.google.com and this is another URL: http://www.bing.com
and this is a bad URL: http://www.buggygubby.com and another bad URL:
http://www.google.com/error.html
