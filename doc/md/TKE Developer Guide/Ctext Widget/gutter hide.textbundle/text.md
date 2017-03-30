### gutter hide

Sets the hide state of the named gutter. If set to a value of 1, the associated gutter will not be displayed; however, all state information associated with the named gutter will remain. If set to a value of 0, the gutter will be redisplayed with the current gutter information.

**Call structure**

`pathname gutter hide name ?value?`

**Return value**

If the _value_ parameter is not specified, returns the current hide state of the named buffer as a boolean value.

**Parameters**

| Parameter | Description |
| - | - |
| name | Name of gutter to change hide state. |
| value | Optional value. If specified, sets the hide state of the named gutter and immediately applies the effect to the gutter. If not specified, returns the current hide state value of the named gutter. |