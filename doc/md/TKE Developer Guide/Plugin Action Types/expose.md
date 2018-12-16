## expose

#### Description

All plugins are sandboxed environments such that if a plugin crashes or
otherwise stops running, the plugin does not have a detrimental effect
on the main application and other installed plugins.  It is also important
to sandbox plugins so that they do not have the ability to corrupt each
other.

However, there are times when it is desirable to have a plugin expose some
functionality that can be called by other plugins without allowing any
plugin to call any plugin procedure at any time.

To allow this capability, TKE provides a way to expose Tcl procedures
within the plugin namespace to other plugins through the **expose** action.
This action provides a list of proc names that other plugins may call at
any time.  It is important for the developer who is exposing procedures to
guarantee that calling those procedures does not have a detrimental effect
on the rest of the plugin.

Each exposed plugin must have as its first parameter an _id_ parameter,
TKE will supply this value when calling the exposed procedure on behalf
of the calling plugin.  The _id_ value can be used by exposed procedure
to identify a plugin (each plugin has a unique _id_ value assigned to it).
Any other parameters in an exposed procedure are optional as required by
the exposed procedure.

Another plugin can call an exposed procedure by calling the following
API function:

`api\::plugin::exec_exposed plugin-name::proc-name args`

#### Tcl Registration

```Tcl
{expose proc-name ?proc-name ...?}
```

#### Example

```Tcl
namespace example {

  # This exposed procedure will display the string 'Hello World'
  # followed by an additional message from the calling function.
  proc hello_world {id msg} {
    api::log "Hello world!  $msg"
  }

}

api::register example {
  {expose example::hello_world}
}
```


