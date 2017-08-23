# Ctext Widget

The Ctext widget that is supplied with TKE is a custom version that is originally based on the original 4.0 version of ctext.  Due to the significant number of changes to the usage API, it makes sense to document the widget in this document for purposes of plugin development.

The Ctext widget is essentially a wrapper around the Tk text widget.  All text widget commands and options are valid for the Ctext widget.  The documentation for these options and commands are not provided in this document (read the Tk text documentation for more details).  Instead, all Ctext-specific options and commands will be documented in this appendix.  Any deviations of Tk text options, commands and bindings will also be documented in this appendix.