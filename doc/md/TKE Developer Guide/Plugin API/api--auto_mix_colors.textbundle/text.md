## api\::auto\_mix\_colors

Adjusts the hue of the given RGB color by the value of the specified difference.

**Call structure**

`api::auto_mix_colors color type diff`

**Return value**

Returns an RGB color value in the #RRGGBB format.

**Parameters**

The color value is any legal TK RGB color.  The value of type can be either “r”, “g” or “b” which will adjust the RGB color value by the given diff amount.