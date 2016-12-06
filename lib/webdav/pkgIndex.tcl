package ifneeded webdav 0.7 [list source [file join $dir webdav.tcl]]
package ifneeded vfs::dav 0.7 [list source [file join $dir davvfs.tcl]]
package ifneeded vfs::urltype 1.0 [list source [file join $dir vfsUrl.tcl]]
