This plugin is only valid for files that have the language set to either CSS or HTML.

The following types of color identifiers are supported:

  - #RRGGBB
  - #RGB
  - rgb( _red value_, _green value_, _blue value_ )
  - argb( _red value_, _green value_, _blue value_, _alpha value_ )
  - hsl( _hue_, _saturation_%, _lightness_% )
  - ahsl( _hue_, _saturation_%, _lightness_%, _alpha value_ )

Where:

  - _red value_   is an integer value between 0 and 255, inclusive
  - _green value_ is an integer value between 0 and 255, inclusive
  - _blue value_  is an integer value between 0 and 255, inclusive
  - _hue_         is an integer value between 0 and 359, inclusive
  - _saturation_  is an integer value between 0 and 100, inclusive
  - _lightness_   is an integer value between 0 and 100, inclusive
  - _alpha value_ is a floating point value between 0.0 and 1.0, inclusive
  - whitespace in the last four items is ignored

To enable colorizing on strings that match the above syntax, select the
`Plugins / CSS Colorize / Colorize` menu option.  This will colorize all text
background that matches the above patterns with the specified color.  Alpha
values will be applied such that a value of 0.0 will make the color completely
opaque (i.e., as if the alpha channel was not applied) while a value of 1.0 will
make the color invisible, displaying the text editor background color.

Once colorization for an editing buffer has been enabled through the menu,
performing a save of the editing buffer will cause the colorization parser to be
reapplied.
