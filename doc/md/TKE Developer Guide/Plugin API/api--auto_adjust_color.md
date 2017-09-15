## api::auto\_adjust\_color

Automatically adjusts the given RGB color by a value equal to diff such that if the color is a darker color, the value will be lightened or if a color is a lighter color, the value will be darkened.

**Call structure**

`api::auto_adjust_color color diff ?mode?`

**Return value**

Returns an RGB color value in the #RRGGBB format.

**Parameters**

The color value is any legal RGB color value.  The diff value is an integer value that describes the value difference to create from the color value.  The mode value can be either “auto” (default) or “manual”.  The auto mode will automatically discern the darkness of the color value and lighten or darken the color by the given value of diff.  The manual mode will change the color value by the amount specified by diff (a negative value will darken the value while a positive value will lighten the value).