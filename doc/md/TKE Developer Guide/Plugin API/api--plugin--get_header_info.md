## api::plugin::get\_header\_info

If the plugin code needs to get access to any of the attributes specified in the plugin's `header.tkedat` file, it is possible to do this using this API procedure call.

**Call Structure**

`api::plugin::get_header_info attribute`

**Return Value**

Returns the value associated with the given header attribute for the calling plugin.

**Attributes**

The following values are valid for the attribute parameter when calling this procedure:

- name
- display_name
- author
- email
- website
- version
- trust_required
- description
- category

Please note that these values cannot be altered by the plugin.  Any changes to these values must be accomplished by editing the `header.tkedat` file itself.