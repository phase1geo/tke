%{
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

package require struct::tree
package require struct::list

set emmet_value       ""
set emmet_errmsg      ""
set emmet_errstr      ""
set emmet_shift_width 2
set emmet_item_id     0
set emmet_node        root

# Create the DOM
::struct::tree emmet_dom

array set emmet_lookup {
  a                    {a          1 {href=""}}
  a:link               {a          1 {href="http://"}}
  a:mail               {a          1 {href="mailto:"}}
  abbr                 {abbr       1 {title=""}}
  acronym              {acronym    1 {title=""}}
  base                 {base       1 {href=""}}
  basefont             {basefont   0 {}}
  br                   {br         0 {}}
  frame                {frame      0 {}}
  hr                   {hr         0 {}}
  bdo                  {bdo        1 {dir=""}}
  bdo:r                {bdo        1 {dir="rtl"}}
  bdo:l                {bdo        1 {dir="ltr"}}
  col                  {col        0 {}}
  link                 {link       0 {rel="stylesheet" href=""}}
  link:css             {link       0 {rel="stylesheet" href="style.css"}}
  link:print           {link       0 {rel="stylesheet" href="print.css" media="print"}}
  link:favicon         {link       0 {rel="shortcut icon" type="image/x-icon" href="favicon.ico"}}
  link:touch           {link       0 {rel="apple-touch-icon" href="favicon.png"}}
  link:rss             {link       0 {rel="alternate" type="application/rss+xml" title="RSS" href="rss.xml"}}
  link:atom            {link       0 {rel="alternate" type="application/atom+xml" title="Atom" href="atom.xml"}}
  meta                 {meta       0 {}}
  meta:utf             {meta       0 {http-equiv="Content-Type" content="text/html;charset=UTF-8"}}
  meta:win             {meta       0 {http_equiv="Content-Type" content="text/html;charset=windows-1251"}}
  meta:vp              {meta       0 {name="viewport" content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0"}}
  meta:compat          {meta       0 {http-equiv="X-UA-Compatible" content="IE=7"}}
  style                {style      1 {}}
  script               {script     1 {}}
  script:src           {script     1 {src=""}}
  img                  {img        0 {src="" alt=""}}
  iframe               {iframe     1 {src="" frameborder="0"}}
  embed                {embed      1 {src="" type=""}}
  object               {object     1 {data="" type=""}}
  param                {param      0 {name="" value=""}}
  map                  {map        1 {name=""}}
  area                 {area       0 {shape="" coords="" href="" alt=""}}
  area:d               {area       0 {shape="default" href="" alt=""}}
  area:c               {area       0 {shape="circle" coords="" href="" alt=""}}
  area:r               {area       0 {shape="rect" coords="" href="" alt=""}}
  area:p               {area       0 {shape="poly" coords="" href="" alt=""}}
  form                 {form       1 {action=""}}
  form:get             {form       1 {action="" method="get"}}
  form:post            {form       1 {action="" method="post"}}
  label                {form       1 {for=""}}
  input                {input      0 {type="text"}}
  inp                  {input      0 {type="text" name="" id=""}}
  input:hidden         {input      0 {type="hidden" name=""}}
  input:h              {input      0 {type="hidden" name=""}}
  input:text           {input      0 {type="text" name="" id=""}}
  input:t              {input      0 {type="text" name="" id=""}}
  input:search         {input      0 {type="search" name="" id=""}}
  input:email          {input      0 {type="email" name="" id=""}}
  input:url            {input      0 {type="url" name="" id=""}}
  input:password       {input      0 {type="password" name="" id=""}}
  input:p              {input      0 {type="password" name="" id=""}}
  input:datetime       {input      0 {type="datetime" name="" id=""}}
  input:date           {input      0 {type="date" name="" id=""}}
  input:datetime-local {input      0 {type="datetime-local" name="" id=""}}
  input:month          {input      0 {type="month" name="" id=""}}
  input:week           {input      0 {type="week" name="" id=""}}
  input:time           {input      0 {type="time" name="" id=""}}
  input:number         {input      0 {type="number" name="" id=""}}
  input:color          {input      0 {type="color" name="" id=""}}
  input:checkbox       {input      0 {type="checkbox" name="" id=""}}
  input:c              {input      0 {type="checkbox" name="" id=""}}
  input:radio          {input      0 {type="radio" name="" id=""}}
  input:r              {input      0 {type="radio" name="" id=""}}
  input:range          {input      0 {type="range" name="" id=""}}
  input:file           {input      0 {type="file" name="" id=""}}
  input:f              {input      0 {type="file" name="" id=""}}
  input:submit         {input      0 {type="submit" value=""}}
  input:s              {input      0 {type="submit" value=""}}
  input:image          {input      0 {type="image" src="" alt=""}}
  input:i              {input      0 {type="image" src="" alt=""}}
  input:button         {input      0 {type="button" value=""}}
  input:b              {input      0 {type="button" value=""}}
  isindex              {isindex    0 {}}
  input:reset          {input      0 {type="reset" value=""}}
  select               {select     1 {name="" id=""}}
  option               {option     1 {value=""}}
  textarea             {textarea   1 {name="" id="" cols="30" rows="10"}}
  menu:context         {menu       1 {type="context"}}
  menu:c               {menu       1 {type="context"}}
  menu:toolbar         {menu       1 {type="toolbar"}}
  menu:t               {menu       1 {type="toolbar"}}
  video                {video      1 {src=""}}
  audio                {audio      1 {src=""}}
  html:xml             {html       1 {xmlns="http://www.w3.org/1999/xhtml"}}
  keygen               {keygen     0 {}}
  command              {command    0 {}}
  bq                   {blockquote 1 {}}
  acr                  {acronym    1 {title=""}}
  fig                  {figure     1 {}}
  figc                 {figcaption 1 {}}
  ifr                  {iframe     1 {src="" frameborder="0"}}
  emb                  {embed      0 {src="" type=""}}
  obj                  {object     1 {data="" type=""}}
  src                  {source     1 {}}
  cap                  {caption    1 {}}
  colg                 {colgroup   1 {}}
  fst                  {fieldset   1 {}}
  fset                 {fieldset   1 {}}
  btn                  {button     1 {}}
  btn:b                {button     1 {type="button"}}
  btn:r                {button     1 {type="reset"}}
  btn:s                {button     1 {type="submit"}}
  optg                 {optgroup   1 {}}
  opt                  {option     1 {value=""}}
  tarea                {textarea   1 {name="" id="" cols="30" rows="10"}}
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

proc emmet_generate_html {items} {

  set lines [lindex [emmet_atomize_html $items] 1]

  set last_id -1
  set str     ""
  foreach line $lines {
    lassign $line id indent type data attrs
    if {$attrs ne ""} {
      append tmp " " [join $attrs " "]
      set attrs $tmp
    }
    switch $type {
      0 { set data "<$data$attrs>" }
      1 { set data "</$data>" }
      3 { set data "<$data />" }
    }
    if {$last_id == -1} {
      set str $data
    } elseif {$id == $last_id} {
      append str $data
    } else {
      set space [expr {($indent == 0) ? "" : [string repeat " " [expr $indent * $::emmet_shift_width]]}]
      append str "\n" $space $data
    }
    set last_id $id
  }

  return $str

}

%}

%token IDENTIFIER NUMBER CHILD SIBLING CLIMB OPEN_GROUP CLOSE_GROUP MULTIPLY
%token OPEN_ATTR CLOSE_ATTR ASSIGN ID CLASS VALUE TEXT

%%

main: expression {
        set ::emmet_value [emmet_generate_html $1]
      }
    ;

expression: item {
              set _ $1
            }
          | expression CHILD item {
              $::emmet_dom move $1 end $3
              if {[$::emmet_dom get $3 name] eq ""} {
                switch [$::emmet_dom get $1 name] {
                  em      { $::emmet_dom set $1 "name" "span" }
                  table   { $::emmet_dom set $1 "name" "tr" }
                  tr      { $::emmet_dom set $1 "name" "td" }
                  ul -
                  ol      { $::emmet_dom set $1 "name" "li" }
                  default { $::emmet_dom set $1 "name" "div" }
                }
              }
              set _ $3
            }
          | expression SIBLING item {
              set _ [$::emmet_dom move [$::emmet_dom parent $1] end $3]
            }
          | expression CLIMB item {
              set parent [$::emmet_dom parent $1]
              for {set i 0} {$i < [string length $2]} {incr i} {
                if {$parent eq "root"} {
                  break
                } else {
                  set parent [$::emmet_dom parent $parent]
                }
              }
              set _ [$::emmet_dom move $parent end $3]
            }
          ;

item: IDENTIFIER attrs_opt multiply_opt {
        set ::emmet_node [$::emmet_dom insert root end]
        $::emmet_dom set $::emmet_node "type" "ident"
        $::emmet_dom set $::emmet_node "name" $1
        foreach {attr_name attr_val} $2 {
          $::emmet_dom set $::emmet_node "attr,$attr_name" $attr_val
        }
        $::emmet_dom set $::emmet_node "multiplier" $3
        set _ $::emmet_node
      }
    | attrs multiply_opt {
        set ::emmet_node [$::emmet_dom insert root end]
        $::emmet_dom set $::emmet_node "type" "ident"
        $::emmet_dom set $::emmet_node "name" ""
        foreach {attr_name attr_val} $1 {
          $::emmet_dom set $::emmet_node "attr,$attr_name" $attr_val
        }
        $::emmet_dom set $::emmet_node "multiplier" $2
        set _ $::emmet_node
      }
    | TEXT multiply_opt {
        set ::emmet_node [$::emmet_dom insert root end]
        $::emmet_dom set $::emmet_node "type" "text"
        $::emmet_dom set $::emmet_node "value" [lindex $1 1]
        $::emmet_dom set $::emmet_node "multiplier" [lindex $1 2]
        set _ $::emmet_node
      }
    | OPEN_GROUP expression CLOSE_GROUP multiply_opt {
        # TBD
        set _ $2
      }
    ;

multiply_opt: MULTIPLY NUMBER {
                set _ $2
              }
            | {
                set _ 1
              }
            ;

attr_item: IDENTIFIER ASSIGN VALUE {
             set _ [list $1 $3]
           }
         | IDENTIFIER ASSIGN NUMBER {
             set _ [list $1 $3]
           }
         | IDENTIFIER {
             set _ [list $1]
           }
         ;

attr_items: attr {
              set _ $1
            }
          | attrs attr {
              set _ [concat $1 $2]
            }
          ;

attr: OPEN_ATTR attr_items CLOSE_ATTR {
        set _ $2
      }
    | ID IDENTIFIER {
        set _ [list id $2]
      }
    | CLASS IDENTIFIER {
        set _ [list class $2]
      }
    ;

attrs: attr {
         set _ $1
       }
     | attrs attr {
         set _ [concat $2 $1]
       }
     ;

attrs_opt: attrs {
             set _ $1
           }
         | {
             set _ [list]
           }
         ;

%%

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

  # Parse the string
  if {[catch { emmet_parse } rc] || ($rc != 0)} {
    puts "ERROR: "
    puts $str
    puts $::emmet_errstr
    puts $::emmet_errmsg
    puts "rc: $rc"
    return ""
  }

  return $::emmet_value

}
