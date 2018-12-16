### getNextBracket / getPrevBracket

Returns the index of the next or previous bracket of the specified type from a given index.

**Call structure**

`ctext::getNextBracket pathname type ?index?`<br>
`ctext::getPrevBracket pathname type ?index?`

**Return value**

Returns the index of the given bracket type found in the text widget.

**Parameters**

| Parameter | Description |
| - | - |
| pathname | The full pathname of the text widget to check. |
| type | Specifies the type of bracket to find. The following table lists these values. |
| index | The index to start searching at. If this option is not specified, the current insertion cursor index is used. |

| Bracket Type | Description |
| - | - |
| **curlyL** | Left curly bracket: { |
| **curlyR** | Right curly bracket: } |
| **squareL** | Left square bracket: \[ |
| **squareR** | Right square bracket: ] |
| **parenL** | Left parenthesis: ( |
| **parenR** | Right parenthesis: ) |
| **angledL** | Left angled bracket: < |
| **angledR** | Right angled bracket: > |