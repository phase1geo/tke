## text\_binding

#### Description

The text\_binding plugin action creates a unique bindtag to all of the text and Ctext pathnames in the entire UI based on the location and name suffix specified and calls a plugin provided procedure with the name of that binding.  The procedure can then add whatever bindings are required on the given bindtag name.  This allows a plugin to handle various keyboard, focus, configuration, mapping and mouse events that occur in any editor.

#### Tcl Registration

`{text_binding location bindtag_suffix bind_type do_procedure}`

The value of _location_ is either the value “pretext” or “posttext”.  If a value of “pretext” is specified, any bindings on the text widget will be called prior to the text/cursor being applied to the text widget.  If a value of “posttext” is specified, any bindings on the text widget will be called after the text/cursor has been applied to the widget.

The value of _bindtag\_suffix_ is any unique name for the plugin (i.e., if the plugin specifies more than one text\_binding action, each action must have a different value specified for _bindtag\_suffix_).

The value of _bind\_type_ is either “all” or “only”.  A value of all means that the text binding will be added to all text widgets in the window.  A value of “only” means that the text binding will only be added to the text widgets that have a tag list containing the value of _bindtag\_suffix_ (see api\::file\::add\_buffer or api\::file\::add\_file procedure for details about the -tag option.  Using a value of “only” can only be used if the same plugin adds a file/buffer of its own.

The value of _do\_procedure_ is the name of the procedure that is called when a text widget is adding bindtags and bindings to itself and the given bindtag name has not been previously created.

#### Tcl Procedures

**The “do” Procedure**

The “do” procedure is called when the associated text bindtag is being initially created.  The name of the associated bindtag created and applied by the plugin framework is passed to the procedure.  The return value of the procedure is ignored.  This procedure should only add various text bindings to associate functionality with different events that will occur on the text widgets.

The following example allows any changes to the cursor to invoke the procedure called “update\_line”.

	namespace eval current_line {
	 proc do_cline {btag} {
		      bind $btag <<Modified>>    “after idle [list current_line::update_line %W]”
		      bind $btag <ButtonPress-1> “after idle [list current_line::update_line %W]”
		      bind $btag <B1-Motion>     “after idle [list current_line::update_line %W]”
		      bind $btag <KeyPress>      “after idle [list current_line::update_line %W]”
	 }
	 proc update_line {txt} {
		      …
	 }
	}
	
	api::register current_line {
	 {text_binding pretext cline all current_line::do_cline}
	}