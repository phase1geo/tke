# Plugin namespace
namespace eval markdown_color {

  array set linkrefs {}
  
  ######################################################################
  # Returns the information for the given Markdown code string.
  proc get_ccode {txt startpos endpos ins} {
    
    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-3c"] ne "\\")} {
      $txt tag remove _code $startpos $endpos
      return [list [list [list ccode [$txt index "$startpos+2c"] [$txt index "$endpos-2c"] [list]] \
                         [list codemarkers $startpos [$txt index "$startpos+2c"] [list]] \
                         [list codemarkers [$txt index "$endpos-2c"] $endpos [list]]] ""]
    }
    
    return ""
    
  }
  
  ######################################################################
  # Returns the information for the given Markdown code string.
  proc get_code {txt startpos endpos ins} {
  
    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-2c"] ne "\\")} {
      if {([lsearch [$txt tag names $startpos]    _codemarkers] == -1) && \
          ([lsearch [$txt tag names "$endpos-1c"] _codemarkers] == -1)} {
        return [list [list [list code [$txt index "$startpos+1c"] [$txt index "$endpos-1c"] [list]]] ""]
      } else {
        return [list [list] [$txt index "$startpos+2c"]]
      }
    }
    
    return ""
  
  }
  
  ######################################################################
  # Returns the information for the given Markdown header string.
  proc get_header {txt startpos endpos ins} {
    
    if {[regexp {(#{1,6})[^#]+} [$txt get $startpos $endpos] all hashes]} {
      set num [string length $hashes]
      return [list [list [list h$num [$txt index "$startpos+${num}c"] [$txt index "$startpos+[string length $all]c"] [list]]] ""]
    }
    
    return ""
    
  }
  
  ######################################################################
  # Returns the information for the given Markdown bold string.
  proc get_bold {txt startpos endpos ins} {
    
    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-3c"] ne "\\")} {
      $txt tag remove _italics $startpos $endpos
      return [list [list [list bold        [$txt index "$startpos+2c"] [$txt index "$endpos-2c"] [list]] \
                         [list boldmarkers $startpos [$txt index "$startpos+2c"] [list]] \
                         [list boldmarkers [$txt index "$endpos-2c"] $endpos [list]]] ""]
    }
    
    return ""
    
  }
  
  ######################################################################
  # Returns the information for the given Markdown italics string.
  proc get_italics {txt startpos endpos ins} {
    
    if {([$txt get "$startpos-1c"] ne "\\") && ([$txt get "$endpos-2c"] ne "\\")} {
      if {([lsearch [$txt tag names $startpos]    _boldmarkers] == -1) && \
          ([lsearch [$txt tag names "$endpos-1c"] _boldmarkers] == -1)} {
        return [list [list [list italics [$txt index "$startpos+1c"] [$txt index "$endpos-1c"] [list]]] ""]
      } else {
        return [list [list] [$txt index "$startpos+2c"]]
      }
    }
    
    return ""
    
  }

  ######################################################################
  # Returns the information for the given Markdown link string.
  proc get_link {txt startpos endpos ins} {
    
    if {[$txt get "$startpos-1c"] ne "\\"} {
      if {[regexp {^\[(.+?)\](\s*\[(.*?)\]|\((.*?)\))} [$txt get $startpos $endpos] -> label ref linkref url]} {
        if {[string index [string trim $ref] 0] eq "\["} {
          if {$linkref eq ""} {
            set cmd "markdown_color::handle_reflink_click $txt [string tolower $label]" 
          } else {
            set cmd "markdown_color::handle_reflink_click $txt [string tolower $linkref]"
          }
        } else {
          set cmd "api::utils::open_file [lindex $url 0]"
        }
        return [list [list [list link [$txt index "$startpos+1c"] [$txt index "$startpos+[expr [string length $label] + 1]c"] $cmd]] ""]
      }
    }
    
    return ""
  
  }
  
  ######################################################################
  # Returns the information for the given Markdown link reference.
  proc get_linkref {txt startpos endpos ins} {
    
    variable linkrefs
    
    if {[$txt get "$startpos-1c"] ne "\\"} {
      if {[regexp {^\s*\[(.+?)\]:\s+(\S+)} [$txt get $startpos $endpos] -> linkref url]} {
        set linkrefs($txt,[string tolower $linkref]) $url
      }
    }
    
    return ""
    
  }
  
  ######################################################################
  # Handles a user click on a references link.
  proc handle_reflink_click {txt ref} {
    
    variable linkrefs
    
    if {[info exists linkrefs($txt,$ref)]} {
      api::utils::open_file $linkrefs($txt,$ref)
    }
    
  }

}

# Register all plugin actions
api::register markdown_color {
  {syntax Markdown_color.syntax}
}
