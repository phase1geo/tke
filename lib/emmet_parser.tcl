# TKE - Advanced Programmer's Editor
# Copyright (C) 2014-2016  Trevor Williams (phase1geo@gmail.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

######################################################################
# Name:    snip_parser.tac
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    8/10/2015
# Brief:   Parser for snippet syntax.
######################################################################

source [file join $::tke_dir lib emmet_lexer.tcl]

package require struct

set emmet_value       ""
set emmet_errmsg      ""
set emmet_errstr      ""
set emmet_shift_width 2
set emmet_item_id     0

array set emmet_lookup {
  a                    {a          1 {href ""}}
  a:link               {a          1 {href "http://"}}
  a:mail               {a          1 {href "mailto:"}}
  abbr                 {abbr       1 {title ""}}
  acronym              {acronym    1 {title ""}}
  base                 {base       1 {href ""}}
  basefont             {basefont   0 {}}
  br                   {br         0 {}}
  frame                {frame      0 {}}
  hr                   {hr         0 {}}
  bdo                  {bdo        1 {dir ""}}
  bdo:r                {bdo        1 {dir "rtl"}}
  bdo:l                {bdo        1 {dir "ltr"}}
  col                  {col        0 {}}
  link                 {link       0 {rel "stylesheet" href ""}}
  link:css             {link       0 {rel "stylesheet" href "style.css"}}
  link:print           {link       0 {rel "stylesheet" href "print.css" media "print"}}
  link:favicon         {link       0 {rel "shortcut icon" type "image/x-icon" href "favicon.ico"}}
  link:touch           {link       0 {rel "apple-touch-icon" href "favicon.png"}}
  link:rss             {link       0 {rel "alternate" type "application/rss+xml" title "RSS" href "rss.xml"}}
  link:atom            {link       0 {rel "alternate" type "application/atom+xml" title "Atom" href "atom.xml"}}
  meta                 {meta       0 {}}
  meta:utf             {meta       0 {http-equiv "Content-Type" content "text/html;charset=UTF-8"}}
  meta:win             {meta       0 {http_equiv "Content-Type" content "text/html;charset=windows-1251"}}
  meta:vp              {meta       0 {name "viewport" content "width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0"}}
  meta:compat          {meta       0 {http-equiv "X-UA-Compatible" content "IE=7"}}
  style                {style      1 {}}
  script               {script     1 {}}
  script:src           {script     1 {src ""}}
  img                  {img        0 {src "" alt ""}}
  iframe               {iframe     1 {src "" frameborder "0"}}
  embed                {embed      1 {src "" type ""}}
  object               {object     1 {data "" type ""}}
  param                {param      0 {name "" value ""}}
  map                  {map        1 {name ""}}
  area                 {area       0 {shape "" coords "" href "" alt ""}}
  area:d               {area       0 {shape "default" href "" alt ""}}
  area:c               {area       0 {shape "circle" coords "" href "" alt ""}}
  area:r               {area       0 {shape "rect" coords "" href "" alt ""}}
  area:p               {area       0 {shape "poly" coords "" href "" alt ""}}
  form                 {form       1 {action ""}}
  form:get             {form       1 {action "" method "get"}}
  form:post            {form       1 {action "" method "post"}}
  label                {form       1 {for ""}}
  input                {input      0 {type "text"}}
  inp                  {input      0 {type "text" name "" id ""}}
  input:hidden         {input      0 {type "hidden" name ""}}
  input:h              {input      0 {type "hidden" name ""}}
  input:text           {input      0 {type "text" name "" id ""}}
  input:t              {input      0 {type "text" name "" id ""}}
  input:search         {input      0 {type "search" name "" id ""}}
  input:email          {input      0 {type "email" name "" id ""}}
  input:url            {input      0 {type "url" name "" id ""}}
  input:password       {input      0 {type "password" name "" id ""}}
  input:p              {input      0 {type "password" name "" id ""}}
  input:datetime       {input      0 {type "datetime" name "" id ""}}
  input:date           {input      0 {type "date" name "" id ""}}
  input:datetime-local {input      0 {type "datetime-local" name "" id ""}}
  input:month          {input      0 {type "month" name "" id ""}}
  input:week           {input      0 {type "week" name "" id ""}}
  input:time           {input      0 {type "time" name "" id ""}}
  input:number         {input      0 {type "number" name "" id ""}}
  input:color          {input      0 {type "color" name "" id ""}}
  input:checkbox       {input      0 {type "checkbox" name "" id ""}}
  input:c              {input      0 {type "checkbox" name "" id ""}}
  input:radio          {input      0 {type "radio" name "" id ""}}
  input:r              {input      0 {type "radio" name "" id ""}}
  input:range          {input      0 {type "range" name "" id ""}}
  input:file           {input      0 {type "file" name "" id ""}}
  input:f              {input      0 {type "file" name "" id ""}}
  input:submit         {input      0 {type "submit" value ""}}
  input:s              {input      0 {type "submit" value ""}}
  input:image          {input      0 {type "image" src "" alt ""}}
  input:i              {input      0 {type "image" src "" alt ""}}
  input:button         {input      0 {type "button" value ""}}
  input:b              {input      0 {type "button" value ""}}
  isindex              {isindex    0 {}}
  input:reset          {input      0 {type "reset" value ""}}
  select               {select     1 {name "" id ""}}
  option               {option     1 {value ""}}
  textarea             {textarea   1 {name "" id "" cols "30" rows "10"}}
  menu:context         {menu       1 {type "context"}}
  menu:c               {menu       1 {type "context"}}
  menu:toolbar         {menu       1 {type "toolbar"}}
  menu:t               {menu       1 {type "toolbar"}}
  video                {video      1 {src ""}}
  audio                {audio      1 {src ""}}
  html:xml             {html       1 {xmlns "http://www.w3.org/1999/xhtml"}}
  keygen               {keygen     0 {}}
  command              {command    0 {}}
  bq                   {blockquote 1 {}}
  acr                  {acronym    1 {title ""}}
  fig                  {figure     1 {}}
  figc                 {figcaption 1 {}}
  ifr                  {iframe     1 {src "" frameborder "0"}}
  emb                  {embed      0 {src "" type ""}}
  obj                  {object     1 {data "" type ""}}
  src                  {source     1 {}}
  cap                  {caption    1 {}}
  colg                 {colgroup   1 {}}
  fst                  {fieldset   1 {}}
  fset                 {fieldset   1 {}}
  btn                  {button     1 {}}
  btn:b                {button     1 {type "button"}}
  btn:r                {button     1 {type "reset"}}
  btn:s                {button     1 {type "submit"}}
  optg                 {optgroup   1 {}}
  opt                  {option     1 {value ""}}
  tarea                {textarea   1 {name "" id "" cols "30" rows "10"}}
  leg                  {legend     1 {}}
  sect                 {section    1 {}}
  art                  {article    1 {}}
  hdr                  {header     1 {}}
  ftr                  {footer     1 {}}
  adr                  {address    1 {}}
  dlg                  {dialog     1 {}}
  str                  {strong     1 {}}
  prog                 {progress   1 {}}
  datag                {datagrid   1 {}}
  datal                {datalist   1 {}}
  kg                   {keygen     1 {}}
  out                  {output     1 {}}
  det                  {details    1 {}}
  cmd                  {command    0 {}}
  !!!                  {!doctype   2 {html}}
  !!!4t                {!DOCTYPE   2 {HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"}}
  !!!4s                {!DOCTYPE   2 {HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"}}
  !!!xt                {!DOCTYPE   2 {html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"}}
  !!!xs                {!DOCTYPE   2 {html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"}}
  !!!xxs               {!DOCTYPE   2 {html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"}}
  c                    {!--        2 {${child} --}}
}

proc emmet_do_lookup {name} {

  if {[info exists ::emmet_lookup($name)]} {
    return $::emmet_lookup($name)
  } else {
    return [list $name 1 {}]
  }

}

proc apply_multiplier {items multiplier} {

  # Get the last item of the list (the multiplier will be applied to it)
  set last_item [lindex $items end]

  # Make all of the items siblings of each other
  set last_item [join [lrepeat $multiplier [list $last_item]] " sibling "]

  # Atomize the last item
  set last_item [emmet_atomize_html $last_item]

  # Add the new items to the end of the list
  set items [lreplace $items end end]
  lappend items $last_item

  return $items

}

proc emmet_insert_attr {plines pstack attr {value ""}} {

  upvar $plines lines
  upvar $pstack stack

  # Get the last index in the stack
  set index [lindex $stack end]

  # Get the list of existing attributes for the item at the given index
  set attrs [lindex $lines $index 4]

  if {[llength $attrs] == 0 } {
    set attrs "$attr=\"$value\""
  } elseif {[set i [lsearch $attrs $attr=*]] == -1} {
    lappend attrs "$attr=\"$value\""
  } elseif {[regexp {^.*="(.*)"$} [lindex $attrs $i] -> values]} {
    if {$values eq ""} {
      lset attrs $i "$attr=\"$value\""
    } else {
      lset attrs $i "$attr=\"$values $value\""
    }
  }

  # Put the attributes back
  lset lines $index 4 $attrs

}

proc emmet_atomize_html {items} {

  set lines       [list]
  set index       0
  set indent      0
  set item_count  0
  set ident_stack [list]
  set last_rel    ""

  foreach item $items {
    set data [lassign $item type]
    switch $type {
      id {
        if {[llength $ident_stack] == 0} {
          # TBD
        } else {
          emmet_insert_attr lines ident_stack "id" $data
        }
      }
      class {
        if {[llength $ident_stack] == 0} {
          # TBD
        } else {
          emmet_insert_attr lines ident_stack "class" $data
        }
      }
      attrs {
        if {[llength $ident_stack] == 0} {
          # TBD
        } else {
          foreach {attr val} {*}$data {
            emmet_insert_attr lines ident_stack $attr $val
          }
        }
      }
      ident {
        lassign [emmet_do_lookup [lindex $data 0]] tag tag_type attrs
        lappend ident_stack $index
        switch $tag_type {
          0 {
            set lines [linsert $lines $index [list $::emmet_item_id $indent 3 $tag $attrs]]
            incr index
          }
          1 {
            set lines [linsert $lines $index [list $::emmet_item_id $indent 0 $tag $attrs] [list $::emmet_item_id $indent 1 $tag {}]]
            incr index 2
          }
          2 {
            set lines [linsert $lines $index [list $::emmet_item_id $indent 0 $tag $attrs]]
            incr index
          }
        }
        incr ::emmet_item_id
      }
      text {
        set prev_item [lindex $items [expr $item_count - 1] 0]
        set tmp_index [expr $index - 1]
        if {($prev_item eq "child") || ($prev_item eq "sibling")} {
          set tmp_index $index
        }
        set lines [linsert $lines $tmp_index [list [expr $::emmet_item_id - 1] $indent 2 {*}$data]]
        incr index 1
        set ident_stack [list]
      }
      child {
        incr index -1
        incr indent
      }
      sibling {
        set ident_stack [list]
      }
      climb {
        set indent [expr (($indent - $data) < 0) ? 0 : ($indent - $data)]
        set index  [expr [lsearch -index 1 -start $index $lines $indent] + 1]
        set ident_stack [list]
      }
      multiply {
        # TBD
        set ident_stack [list]
      }
      atom {
        set datalen [llength $data]
        for {set i 0} {$i < $datalen} {incr i} {
          lset data $i 1 [expr [lindex $data $i 1] + $indent]
        }
        set lines [linsert $lines $index {*}$data]
        incr index $datalen
        set ident_stack [list]
      }
      default {
        set data    [lindex [emmet_atomize_html $item] 1]
        set datalen [llength $data]
        for {set i 0} {$i < $datalen} {incr i} {
          lset data $i 1 [expr [lindex $data $i 1] + $indent]
        }
        set lines [linsert $lines $index {*}$data]
        incr index $datalen
        set ident_stack [list]
      }
    }
    incr item_count
  }

  return [list atom $lines]

}

proc emmet_elaborate {tree node action} {

  if {$node eq "root"} {
    $tree set $node elab root
    return
  }

  if {$action eq "enter"} {

    # Get the parent node in the elaborated tree
    set elab_parent [$tree get [$tree parent $node] elab]

    # Create a new node in the elaborated tree
    $tree set $node elab [$::emmet_elab insert $elab_parent end]

  } else {

    set enode [$tree get $node elab]

    if {[set type [$tree get $node type]] eq "ident"} {

      set name   [$tree get $node name]
      set tagnum 2

      # If we have an implictly specified type that hasn't been handled yet, it will be a div
      if {$name eq ""} {
        set name "div"
      }

      # Now that the name is elaborated, look it up and update the node, if necessary
      if {[info exists ::emmet_lookup($name)]} {
        lassign $::emmet_lookup($name) name tagnum attrs
        foreach {key value} $attrs {
          $::emmet_elab set $enode attr,$key $value
        }
      }

      $::emmet_elab set $enode name   $name
      $::emmet_elab set $enode tagnum $tagnum

      foreach attr [$tree keys $node attr,*] {
        $::emmet_elab set $enode $attr [lindex [$tree get $node $attr] 0]
      }

    }

    $::emmet_elab set $enode type $type

    if {[$tree keyexists $node value]} {
      $::emmet_elab set $enode value [lindex [$tree get $node value] 0]
    }

  }

}

proc emmet_generate {tree node action} {

  # Gather the children string values
  set child_strs [list]
  foreach child [$tree children $node] {
    lappend child_strs [$tree get $child str]
  }

  # If we are the root node, we won't have any information so just concatenate
  # the children strings.
  if {$node eq "root"} {
    $tree set $node "str" [join $child_strs \n]
    return
  }

  # Get the node depth
  set spaces [string repeat { } [expr ([$tree depth $node] - 1) * $::emmet_shift_width]]

  # Otherwise, insert our information along with the children in the proper order
  switch [$tree get $node type] {
    ident {
      set name     [$tree get $node name]
      set tagnum   [$tree get $node tagnum]
      set attr_str ""
      set value    ""
      if {[$tree keyexists $node value]} {
        set value [$tree get $node value]
      }
      foreach attr [$tree keys $node attr,*] {
        append attr_str " [lindex [split $attr ,] 1]=\"[$tree get $node $attr]\""
      }
      if {$tagnum == 0} {
        $tree set $node str "$spaces<$name$attr_str />$value"
      } elseif {[llength $child_strs] == 0} {
        $tree set $node str "$spaces<$name$attr_str>$value</$name>"
      } else {
        $tree set $node str "$spaces<$name$attr_str>$value\n[join $child_strs \n]\n$spaces</$name>"
      }
    }
    text {
      $tree set $node str [$tree get $node value]
    }
  }

}

proc emmet_generate_html {} {

  # Perform the elaboration
  $::emmet_dom walkproc root -order both -type dfs emmet_elaborate

  # Generate the code
  $::emmet_elab walkproc root -order post -type dfs emmet_generate

  return [$::emmet_elab get root "str"]

}


######
# Begin autogenerated taccle (version 1.1) routines.
# Although taccle itself is protected by the GNU Public License (GPL)
# all user-supplied functions are protected by their respective
# author's license.  See http://mini.net/tcl/taccle for other details.
######

proc EMMET_ABORT {} {
    return -code return 1
}

proc EMMET_ACCEPT {} {
    return -code return 0
}

proc emmet_clearin {} {
    upvar emmet_token t
    set t ""
}

proc emmet_error {s} {
    puts stderr $s
}

proc emmet_setupvalues {stack pointer numsyms} {
    upvar 1 1 y
    set y {}
    for {set i 1} {$i <= $numsyms} {incr i} {
        upvar 1 $i y
        set y [lindex $stack $pointer]
        incr pointer
    }
}

proc emmet_unsetupvalues {numsyms} {
    for {set i 1} {$i <= $numsyms} {incr i} {
        upvar 1 $i y
        unset y
    }
}

array set ::emmet_table {
  18:271,target 20
  17:257 shift
  11:263,target 12
  27:0 reduce
  17:266,target 31
  6:259,target 12
  6:260,target 12
  33:261,target 11
  24:269,target 5
  23:265,target 3
  38:260,target 10
  38:259,target 10
  17:266 shift
  1:279,target 12
  1:280,target 13
  6:259 reduce
  6:260 reduce
  15:257,target 16
  6:261 reduce
  26:260 reduce
  26:259 reduce
  26:261 reduce
  6:0,target 12
  6:263 reduce
  6:264 shift
  26:263 reduce
  12:265,target 3
  27:260,target 12
  27:259,target 12
  26:264 reduce
  18:268,target 20
  34:263,target 3
  26:265 reduce
  41:266,target 13
  11:261,target 12
  17:276 goto
  35:260 reduce
  35:259 reduce
  26:268 reduce
  35:261 reduce
  33:0,target 11
  31:271,target 19
  26:269 reduce
  22:279,target 11
  26:271 reduce
  25:0,target 8
  35:263 reduce
  6:275 goto
  10:0,target 22
  19:271,target 21
  0:273,target 8
  12:263,target 24
  34:261,target 3
  21:0 reduce
  14:260 shift
  14:259 shift
  24:265,target 3
  14:261 shift
  31:268,target 19
  2:279,target 11
  16:257,target 17
  14:263 shift
  3:257 shift
  29:264,target 20
  23:257 shift
  28:260,target 6
  28:259,target 6
  19:268,target 21
  0:271,target 6
  35:263,target 4
  23:262 shift
  12:261,target 24
  18:264,target 20
  23:265 shift
  23:279,target 11
  38:0 reduce
  32:257 reduce
  40:257,target 14
  39:257,target 15
  23:268 shift
  23:269 shift
  23:271 shift
  23:274 goto
  13:263,target 12
  3:276 goto
  41:257 reduce
  32:266 reduce
  0:268,target 4
  3:277 goto
  8:259,target 22
  8:260,target 23
  11:275,target 25
  35:261,target 4
  26:269,target 23
  37:0,target 7
  29:0,target 12
  23:278 goto
  10:271,target 22
  23:279 goto
  35:0 reduce
  17:257,target 15
  11:259 reduce
  11:260 reduce
  41:266 reduce
  31:264,target 19
  11:261 reduce
  11:263 reduce
  29:260,target 12
  29:259,target 12
  1:271,target 25
  0:257 shift
  11:264 shift
  36:263,target 5
  11:265 shift
  13:261,target 12
  20:258 shift
  19:264,target 21
  9:0 reduce
  19:260 reduce
  19:259 reduce
  17:276,target 32
  0:262 shift
  11:0 reduce
  11:268 shift
  24:279,target 11
  19:261 reduce
  11:269 shift
  18:260,target 20
  18:259,target 20
  10:268,target 22
  25:263,target 8
  19:263 reduce
  0:265 shift
  41:257,target 13
  32:266,target 18
  19:264 reduce
  3:277,target 17
  19:265 reduce
  15:267,target 30
  0:268 shift
  8:259 shift
  8:260 shift
  11:275 goto
  22:271,target 6
  0:269 shift
  2:273,target 14
  8:261 shift
  28:260 reduce
  28:259 reduce
  19:268 reduce
  0:271 shift
  28:261 reduce
  19:269 reduce
  14:263,target 29
  0:272 goto
  11:278 goto
  30:257,target 39
  19:271 reduce
  1:268,target 4
  0:273 goto
  9:259,target 2
  9:260,target 2
  36:261,target 5
  28:263 reduce
  0:274 goto
  6:0 reduce
  26:265,target 23
  0:278 goto
  37:260 reduce
  37:259 reduce
  28:0 reduce
  0:279 goto
  7:0,target 0
  37:261 reduce
  25:261,target 8
  37:263 reduce
  31:260,target 19
  31:259,target 19
  22:268,target 4
  2:271,target 6
  37:263,target 7
  14:261,target 24
  34:0,target 3
  26:0,target 23
  18:0,target 20
  19:260,target 21
  19:259,target 21
  16:257 reduce
  0:262,target 2
  11:0,target 12
  11:268,target 4
  26:263,target 23
  25:0 reduce
  10:264,target 22
  23:271,target 6
  5:257 shift
  16:266 reduce
  2:268,target 4
  13:275,target 28
  37:261,target 7
  25:260 reduce
  25:259 reduce
  25:261 reduce
  1:264,target 25
  12:271,target 24
  25:263 reduce
  26:261,target 23
  6:263,target 12
  34:260 reduce
  34:259 reduce
  34:261 reduce
  23:268,target 4
  38:263,target 10
  34:263 reduce
  0:278,target 10
  21:260,target 9
  21:259,target 9
  12:268,target 4
  27:263,target 12
  18:0 reduce
  0:257,target 1
  11:264,target 20
  6:261,target 12
  24:271,target 6
  10:259,target 22
  10:260,target 22
  13:259 reduce
  13:260 reduce
  13:261 reduce
  38:0,target 10
  32:257,target 18
  38:261,target 10
  31:0,target 19
  30:270,target 41
  13:263 reduce
  2:257 shift
  13:264 shift
  22:262,target 2
  13:271,target 27
  22:257 shift
  1:260,target 25
  1:259,target 25
  2:262 shift
  27:261,target 12
  18:269,target 20
  22:262 shift
  13:271 shift
  2:265 shift
  36:0 reduce
  33:260,target 11
  33:259,target 11
  24:268,target 4
  22:265 shift
  2:268 shift
  13:275 goto
  2:269 shift
  31:260 reduce
  31:259 reduce
  22:268 shift
  2:271 shift
  31:261 reduce
  22:269 shift
  1:278,target 10
  22:271 shift
  2:273 goto
  31:263 reduce
  2:274 goto
  2:262,target 2
  31:264 reduce
  28:263,target 6
  0:274,target 9
  31:265 reduce
  22:274 goto
  40:257 reduce
  39:257 reduce
  12:264,target 24
  2:278 goto
  12:0 reduce
  31:268 reduce
  2:279 goto
  31:269 reduce
  22:278 goto
  11:259,target 12
  11:260,target 12
  33:0 reduce
  31:271 reduce
  22:279 goto
  31:269,target 19
  22:278,target 10
  10:259 reduce
  10:260 reduce
  40:266 reduce
  39:266 reduce
  23:262,target 2
  10:261 reduce
  8:0,target 1
  1:0,target 25
  10:263 reduce
  22:257,target 1
  10:264 reduce
  28:261,target 6
  19:269,target 21
  0:272,target 7
  10:265 reduce
  11:278,target 26
  6:275,target 21
  7:0 accept
  18:265,target 20
  18:260 reduce
  18:259 reduce
  10:268 reduce
  34:260,target 3
  34:259,target 3
  18:261 reduce
  10:269 reduce
  35:0,target 4
  29:0 reduce
  10:271 reduce
  27:0,target 12
  18:263 reduce
  19:0,target 21
  18:264 reduce
  18:265 reduce
  2:278,target 10
  12:0,target 24
  29:263,target 12
  27:260 reduce
  27:259 reduce
  18:268 reduce
  27:261 reduce
  27:275,target 37
  18:269 reduce
  18:271 reduce
  2:257,target 1
  13:264,target 20
  27:263 reduce
  0:269,target 5
  8:261,target 24
  27:264 shift
  26:271,target 23
  12:259,target 24
  12:260,target 24
  18:263,target 20
  26:0 reduce
  36:260 reduce
  36:259 reduce
  23:278,target 10
  36:261 reduce
  24:262,target 2
  36:263 reduce
  31:265,target 19
  22:274,target 34
  23:257,target 1
  29:261,target 12
  27:275 goto
  9:263,target 2
  12:278,target 26
  1:0 reduce
  19:265,target 21
  35:260,target 4
  35:259,target 4
  26:268,target 23
  15:257 reduce
  18:261,target 20
  10:269,target 22
  31:263,target 19
  2:274,target 9
  4:257 shift
  24:257 shift
  15:266 reduce
  3:257,target 15
  30:258,target 40
  15:267 shift
  1:269,target 5
  9:261,target 2
  13:259,target 12
  13:260,target 12
  24:262 shift
  19:263,target 21
  0:265,target 3
  24:278,target 10
  19:0 reduce
  24:265 shift
  23:274,target 35
  3:276,target 16
  33:260 reduce
  33:259 reduce
  24:268 shift
  33:261 reduce
  24:269 shift
  24:257,target 1
  15:266,target 16
  31:261,target 19
  24:271 shift
  22:269,target 5
  33:263 reduce
  24:274 goto
  36:260,target 5
  36:259,target 5
  19:261,target 21
  11:269,target 5
  26:264,target 23
  24:278 goto
  24:279 goto
  10:265,target 22
  37:0 reduce
  25:260,target 8
  25:259,target 8
  12:259 reduce
  12:260 reduce
  29:275,target 38
  12:261 reduce
  4:257,target 18
  2:269,target 5
  12:263 reduce
  12:264 reduce
  14:260,target 23
  14:259,target 22
  12:265 shift
  21:263,target 9
  1:265,target 3
  1:260 reduce
  1:259 reduce
  1:261 reduce
  21:260 reduce
  21:259 reduce
  12:268 shift
  21:261 reduce
  20:258,target 33
  1:263 reduce
  9:0,target 2
  12:269 shift
  13:0 reduce
  1:264 reduce
  6:264,target 20
  12:271 reduce
  24:274,target 36
  21:263 reduce
  1:265 shift
  34:0 reduce
  10:263,target 22
  16:266,target 17
  30:257 shift
  23:269,target 5
  1:268 shift
  9:259 reduce
  9:260 reduce
  30:258 shift
  1:269 shift
  9:261 reduce
  29:260 reduce
  29:259 reduce
  1:271 reduce
  36:0,target 5
  29:261 reduce
  22:265,target 3
  9:263 reduce
  12:278 goto
  37:260,target 7
  37:259,target 7
  28:0,target 6
  0:279,target 11
  29:263 reduce
  21:0,target 9
  29:264 shift
  21:261,target 9
  1:263,target 25
  12:269,target 5
  13:0,target 12
  27:264,target 20
  8:0 reduce
  10:0 reduce
  1:278 goto
  11:265,target 3
  38:260 reduce
  38:259 reduce
  26:260,target 23
  26:259,target 23
  1:279 goto
  1:280 goto
  38:261 reduce
  33:263,target 11
  31:0 reduce
  30:270 shift
  40:266,target 14
  39:266,target 15
  10:261,target 22
  38:263 reduce
  5:257,target 19
  29:275 goto
  2:265,target 3
  1:261,target 25
}

array set ::emmet_rules {
  9,l 274
  11,l 275
  15,l 276
  20,l 278
  19,l 278
  2,l 273
  24,l 280
  6,l 274
  12,l 275
  16,l 276
  21,l 278
  3,l 273
  25,l 280
  7,l 274
  13,l 276
  0,l 281
  17,l 277
  22,l 279
  4,l 273
  8,l 274
  10,l 274
  14,l 276
  18,l 277
  1,l 272
  23,l 279
  5,l 273
}

array set ::emmet_rules {
  23,dc 2
  5,dc 3
  0,dc 1
  17,dc 1
  12,dc 0
  8,dc 2
  21,dc 2
  3,dc 3
  15,dc 3
  10,dc 4
  24,dc 1
  6,dc 3
  18,dc 2
  1,dc 1
  13,dc 3
  9,dc 2
  22,dc 1
  4,dc 3
  16,dc 1
  11,dc 2
  25,dc 0
  7,dc 4
  20,dc 2
  19,dc 3
  2,dc 1
  14,dc 3
}

array set ::emmet_rules {
  13,line 550
  25,line 594
  7,line 515
  10,line 537
  22,line 583
  4,line 486
  18,line 567
  1,line 458
  15,line 556
  9,line 532
  12,line 545
  24,line 591
  6,line 504
  21,line 578
  3,line 482
  17,line 564
  14,line 553
  8,line 525
  11,line 542
  23,line 586
  5,line 492
  20,line 575
  19,line 572
  2,line 463
  16,line 559
}

proc emmet_parse {} {
    set emmet_state_stack {0}
    set emmet_value_stack {{}}
    set emmet_token ""
    set emmet_accepted 0
    while {$emmet_accepted == 0} {
        set emmet_state [lindex $emmet_state_stack end]
        if {$emmet_token == ""} {
            set ::emmet_lval ""
            set emmet_token [emmet_lex]
            set emmet_buflval $::emmet_lval
        }
        if {![info exists ::emmet_table($emmet_state:$emmet_token)]} {
            # pop off states until error token accepted
            while {[llength $emmet_state_stack] > 0 && \
                       ![info exists ::emmet_table($emmet_state:error)]} {
                set emmet_state_stack [lrange $emmet_state_stack 0 end-1]
                set emmet_value_stack [lrange $emmet_value_stack 0 \
                                       [expr {[llength $emmet_state_stack] - 1}]]
                set emmet_state [lindex $emmet_state_stack end]
            }
            if {[llength $emmet_state_stack] == 0} {
                emmet_error "parse error"
                return 1
            }
            lappend emmet_state_stack [set emmet_state $::emmet_table($emmet_state:error,target)]
            lappend emmet_value_stack {}
            # consume tokens until it finds an acceptable one
            while {![info exists ::emmet_table($emmet_state:$emmet_token)]} {
                if {$emmet_token == 0} {
                    emmet_error "end of file while recovering from error"
                    return 1
                }
                set ::emmet_lval {}
                set emmet_token [emmet_lex]
                set emmet_buflval $::emmet_lval
            }
            continue
        }
        switch -- $::emmet_table($emmet_state:$emmet_token) {
            shift {
                lappend emmet_state_stack $::emmet_table($emmet_state:$emmet_token,target)
                lappend emmet_value_stack $emmet_buflval
                set emmet_token ""
            }
            reduce {
                set emmet_rule $::emmet_table($emmet_state:$emmet_token,target)
                set emmet_l $::emmet_rules($emmet_rule,l)
                if {[info exists ::emmet_rules($emmet_rule,e)]} {
                    set emmet_dc $::emmet_rules($emmet_rule,e)
                } else {
                    set emmet_dc $::emmet_rules($emmet_rule,dc)
                }
                set emmet_stackpointer [expr {[llength $emmet_state_stack]-$emmet_dc}]
                emmet_setupvalues $emmet_value_stack $emmet_stackpointer $emmet_dc
                set _ $1
                set ::emmet_lval [lindex $emmet_value_stack end]
                switch -- $emmet_rule {
                    1 { 
        set ::emmet_value [emmet_generate_html]
       }
                    2 { 
              set _ $1
             }
                    3 { 
              $::emmet_dom move $1 end $3
              if {[$::emmet_dom keyexists $3 name] && ([$::emmet_dom get $3 name] eq "")} {
                switch [$::emmet_dom get $1 name] {
                  em       { $::emmet_dom set $3 name "span" }
                  table -
                  tbody -
                  thead -
                  tfoot    { $::emmet_dom set $3 name "tr" }
                  tr       { $::emmet_dom set $3 name "td" }
                  ul -
                  ol       { $::emmet_dom set $3 name "li" }
                  select -
                  optgroup { $::emmet_dom set $3 name "option" }
                  default  { $::emmet_dom set $3 name "div" }
                }
              }
              set _ $3
             }
                    4 { 
              $::emmet_dom move [$::emmet_dom parent $1] end $3
              set _ $3
             }
                    5 { 
              set ancestors [$::emmet_dom ancestors $1]
              set parent    [lindex $ancestors [string length $2]]
              $::emmet_dom move $parent end $3
              set _ $3
             }
                    6 { 
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type "ident"
        $::emmet_dom set $node name $1
        foreach {attr_name attr_val} $2 {
          $::emmet_dom lappend $node attr,$attr_name $attr_val
        }
        $::emmet_dom set $node multiplier $3
        set _ $node
       }
                    7 { 
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type  "ident"
        $::emmet_dom set $node name  $1
        $::emmet_dom set $node value $3
        foreach {attr_name attr_val} $2 {
          $::emmet_dom lappend $node attr,$attr_name $attr_val
        }
        $::emmet_dom set $node multiplier $4
        set _ $node
       }
                    8 { 
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type "ident"
        $::emmet_dom set $node name ""
        foreach {attr_name attr_val} $1 {
          $::emmet_dom lappend $node "attr,$attr_name" $attr_val
        }
        $::emmet_dom set $node multiplier $2
        set _ $node
       }
                    9 { 
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type       "text"
        $::emmet_dom set $node value      $1
        $::emmet_dom set $node multiplier $2
        set _ $node
       }
                    10 { 
        set node [lindex [$::emmet_dom ancestors $2] end-1]
        $::emmet_dom set $node multiplier $4
        set _ $node
       }
                    11 { 
                set _ $2
               }
                    12 { 
                set _ 1
               }
                    13 { 
             set _ [list $1 $3]
            }
                    14 { 
             set _ [list $1 $3]
            }
                    15 { 
             set _ [list $1 $3]
            }
                    16 { 
             set _ [list $1]
            }
                    17 { 
              set _ $1
             }
                    18 { 
              set _ [concat $1 $2]
             }
                    19 { 
        set _ $2
       }
                    20 { 
        set _ [list id $2]
       }
                    21 { 
        set _ [list class $2]
       }
                    22 { 
         set _ $1
        }
                    23 { 
         set _ [concat $2 $1]
        }
                    24 { 
             set _ $1
            }
                    25 { 
             set _ [list]
            }
                }
                emmet_unsetupvalues $emmet_dc
                # pop off tokens from the stack if normal rule
                if {![info exists ::emmet_rules($emmet_rule,e)]} {
                    incr emmet_stackpointer -1
                    set emmet_state_stack [lrange $emmet_state_stack 0 $emmet_stackpointer]
                    set emmet_value_stack [lrange $emmet_value_stack 0 $emmet_stackpointer]
                }
                # now do the goto transition
                lappend emmet_state_stack $::emmet_table([lindex $emmet_state_stack end]:$emmet_l,target)
                lappend emmet_value_stack $_
            }
            accept {
                set emmet_accepted 1
            }
            goto -
            default {
                puts stderr "Internal parser error: illegal command $::emmet_table($emmet_state:$emmet_token)"
                return 2
            }
        }
    }
    return 0
}

######
# end autogenerated taccle functions
######

rename emmet_error emmet_error_orig

proc emmet_error {s} {

  set ::emmet_errstr "[string repeat { } $::emmet_begpos]^"
  set ::emmet_errmsg $s

}

proc parse_emmet {str} {

  # Flush the parsing buffer
  EMMET__FLUSH_BUFFER

  # Insert the string to scan
  emmet__scan_string $str

  # Initialize some values
  set ::emmet_begpos 0
  set ::emmet_endpos 0

  # Create the trees
  set ::emmet_dom  [::struct::tree]
  set ::emmet_elab [::struct::tree]

  # Parse the string
  if {[catch { emmet_parse } rc] || ($rc != 0)} {

    puts "ERROR: "
    puts $str
    puts $::emmet_errstr
    puts $::emmet_errmsg
    puts "rc: $rc"
    puts "$::errorInfo"

    # Destroy the trees
    $::emmet_dom  destroy
    $::emmet_elab destroy

    return -code error $rc

  }

  # Destroy the trees
  $::emmet_dom  destroy
  $::emmet_elab destroy

  return $::emmet_value

}
