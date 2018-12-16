# Plugin Development

This document is written for anyone who is interested in writing plugins for TKE.

TKE contains a plugin framework that allows external Tcl/Tk code to be included and executed in a TKE application.  Plugins can be attached to the GUI via various menus, text bindings, the command launcher, and events.  This document aims to document the plugin framework, how it works, and, most importantly, how to create new plugins using TKE’s plugin API.