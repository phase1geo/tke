proc convert {dir} {

  foreach item [glob -nocomplain -directory $dir *] {

    # If we find a textbundle, restructure
    if {[file extension $item] eq ".textbundle"} {

      # Move the assets over if any exist
      if {[file exists [set assets_dir [file join $item assets]]]} {
        file mkdir [set new_assets [file join $dir assets]]
        foreach asset [glob -nocomplain -directory $assets_dir *] {
          file copy $asset $new_assets
        }
      }

      # Copy the markdown file
      file copy [file join $item text.md] [file rootname $item].md

      # Delete the textbundle directory
      file delete -force -- $item

    # If the item is a directory, convert that directory
    } elseif {[file isdirectory $item]} {
      convert $item
    }

  }

}

# Start with the current directory
convert [pwd]
