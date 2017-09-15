## api::reset\_txt\_focus

Causes the keyboard focus to be set back to the last editing buffer that received focus. If the textwidget parameter is specified, TKE will give the provided text widget keyboard focus.

**Call structure**

`api::reset_text_focus ?textwidget?`
  
**Return value**

None. 

**Parameters**

| Parameter | Description |
| - | - |
| textwidget | Optional parameter that, if specified, causes the specified text widget to receive the keyboard focus. If this option is not specified, the procedure will set the keyboard focus to the editing buffer that last received keyboard focus. |