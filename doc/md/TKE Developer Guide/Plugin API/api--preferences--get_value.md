## api\::preferences\::get\_value

Returns the current value of the input plugin preference.

**Call structure**

`api::preferences::get_value prefname`

**Return value**

Returns the current value of the associated preference item.

**Parameters**

The _prefname_ specifies the preference item name to lookup. This must be one of the names returned from the on\_pref\_load plugin action. If the value of _prefname_ was not found, returns an error.