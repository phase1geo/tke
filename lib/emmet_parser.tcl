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

set emmet_value       ""
set emmet_errmsg      ""
set emmet_errstr      ""
set emmet_shift_width 2
set emmet_item_id     0

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

  puts "attr: $attr, value: $value"

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

  puts "items: $items"

  set lines       [list]
  set index       0
  set indent      0
  set item_count  0
  set ident_stack [list]

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
        foreach attr $data {
          puts "attr: $attr"
          emmet_insert_attr lines ident_stack {*}$attr
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
        set ident_stack [list]
        set lines [linsert $lines [expr $index - 1] [list [expr $::emmet_item_id - 1] $indent 2 {*}$data]]
        incr index 1
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
  6:260,target 14
  6:259,target 14
  17:266,target 4
  47:272,target 28
  33:261,target 8
  48:0 reduce
  26:257 shift
  15:257,target 13
  0:275,target 9
  26:262 shift
  26:266 shift
  33:0,target 8
  39:262,target 27
  40:262,target 26
  26:272 shift
  36:269,target 11
  36:270,target 11
  26:275 goto
  18:266,target 3
  48:272,target 16
  34:261,target 9
  16:257,target 3
  41:262,target 8
  32:257 reduce
  37:269,target 6
  37:270,target 6
  50:272,target 18
  8:260,target 19
  8:259,target 18
  19:266,target 3
  20:266,target 3
  49:272,target 17
  32:267 reduce
  35:261,target 10
  35:0 reduce
  17:257,target 4
  47:263,target 28
  2:275,target 9
  9:0 reduce
  0:266,target 3
  42:262,target 9
  38:269,target 7
  38:270,target 7
  51:272,target 19
  9:260,target 2
  9:259,target 2
  36:261,target 11
  37:257 reduce
  18:257,target 1
  37:259 reduce
  37:260 reduce
  48:263,target 16
  37:261 reduce
  37:262 reduce
  49:0 reduce
  50:0 reduce
  37:264 reduce
  31:259,target 15
  31:260,target 15
  37:266 reduce
  1:266,target 12
  37:269 reduce
  37:270 reduce
  43:262,target 10
  37:272 reduce
  10:264,target 25
  39:269,target 27
  39:270,target 27
  40:269,target 26
  40:270,target 26
  25:258,target 40
  37:261,target 6
  19:257,target 1
  20:257,target 1
  49:263,target 17
  50:263,target 18
  2:266,target 3
  43:257 reduce
  44:262,target 11
  43:259 reduce
  43:260 reduce
  43:261 reduce
  11:264,target 13
  0:257,target 1
  41:269,target 8
  41:270,target 8
  43:262 reduce
  13:257 reduce
  43:263 shift
  43:264 reduce
  43:266 reduce
  38:261,target 7
  2:257 shift
  43:269 reduce
  43:270 reduce
  43:272 reduce
  13:267 reduce
  51:263,target 19
  2:262 shift
  13:268 shift
  2:266 shift
  33:259,target 8
  33:260,target 8
  36:0 reduce
  2:270 shift
  2:269 shift
  2:272 shift
  2:274 goto
  2:275 goto
  0:274,target 8
  26:275,target 41
  1:257,target 12
  12:264,target 29
  42:269,target 9
  42:270,target 9
  24:266,target 5
  39:261,target 27
  40:261,target 26
  48:257 reduce
  8:0,target 1
  48:259 reduce
  48:260 reduce
  22:257,target 37
  48:261 reduce
  48:262 reduce
  18:257 shift
  48:263 reduce
  48:264 reduce
  51:0,target 19
  34:259,target 9
  34:260,target 9
  48:266 reduce
  18:262 shift
  10:@,target 25
  48:269 reduce
  48:270 reduce
  51:0 reduce
  18:266 shift
  25:-,target 39
  48:272 reduce
  27:275,target 42
  2:257,target 1
  43:269,target 10
  43:270,target 10
  18:272 shift
  10:272,target 25
  18:275 goto
  41:261,target 8
  23:257,target 38
  35:259,target 10
  35:260,target 10
  32:267,target 24
  47:262,target 28
  2:274,target 12
  28:275,target 43
  3:257,target 13
  24:257 reduce
  44:269,target 11
  44:270,target 11
  29:258,target 44
  30:258,target 45
  24:259 reduce
  24:260 reduce
  47:0,target 28
  24:261 reduce
  11:272,target 13
  24:262 reduce
  26:266,target 3
  16:0,target 3
  24:264 reduce
  42:261,target 9
  24:266 reduce
  24:257,target 5
  24:269 reduce
  24:270 reduce
  8:275,target 24
  24:272 reduce
  36:259,target 11
  36:260,target 11
  6:266,target 14
  48:262,target 16
  37:0 reduce
  4:257,target 16
  1:265,target 10
  12:272,target 6
  27:266,target 3
  43:261,target 10
  10:263,target 25
  29:258 shift
  30:258 shift
  37:259,target 6
  37:260,target 6
  10:0 reduce
  49:262,target 17
  50:262,target 18
  30:271 shift
  5:257,target 17
  16:264,target 3
  28:266,target 3
  44:261,target 11
  11:263,target 13
  10:@ shift
  26:257,target 1
  38:259,target 7
  38:260,target 7
  8:266,target 3
  51:262,target 19
  24:0 reduce
  35:257 reduce
  6:257,target 14
  17:264,target 4
  47:269,target 28
  47:270,target 28
  35:259 reduce
  35:260 reduce
  35:261 reduce
  35:262 reduce
  10:0,target 25
  35:264 reduce
  35:266 reduce
  0:273,target 7
  35:269 reduce
  35:270 reduce
  27:257,target 1
  35:272 reduce
  39:259,target 27
  39:260,target 27
  40:259,target 26
  40:260,target 26
  9:266,target 2
  48:269,target 16
  48:270,target 16
  38:0 reduce
  31:266,target 15
  28:257,target 1
  41:257 reduce
  37:0,target 6
  41:259 reduce
  41:260 reduce
  41:261 reduce
  41:262 reduce
  11:257 reduce
  41:263 shift
  41:259,target 8
  41:260,target 8
  41:264 reduce
  11:260 reduce
  11:259 reduce
  11:261 reduce
  41:266 reduce
  11:262 reduce
  11:263 reduce
  11:264 reduce
  0:257 shift
  41:269 reduce
  41:270 reduce
  11:266 reduce
  41:272 reduce
  50:270,target 18
  50:269,target 18
  8:257,target 1
  49:269,target 17
  49:270,target 17
  11:0 reduce
  0:262 shift
  11:270 reduce
  11:269 reduce
  11:272 reduce
  16:272,target 3
  0:266 shift
  47:261,target 28
  0:270 shift
  0:269 shift
  0:272 shift
  0:273 goto
  0:274 goto
  0:275 goto
  42:259,target 9
  42:260,target 9
  46:257 reduce
  51:270,target 19
  51:269,target 19
  9:257,target 2
  34:0,target 9
  25:- shift
  40:-,target 47
  16:257 reduce
  17:272,target 4
  16:259 reduce
  16:260 reduce
  33:266,target 8
  16:261 reduce
  48:261,target 16
  16:262 reduce
  46:267 reduce
  5:257 shift
  16:264 reduce
  16:266 reduce
  31:257,target 15
  1:264,target 12
  16:269 reduce
  16:270 reduce
  16:272 reduce
  43:259,target 10
  43:260,target 10
  10:262,target 25
  18:272,target 6
  34:266,target 9
  40:- shift
  49:261,target 17
  50:261,target 18
  39:0 reduce
  40:0 reduce
  32:257,target 24
  31:0,target 15
  22:257 shift
  44:259,target 11
  44:260,target 11
  11:262,target 13
  19:272,target 6
  20:272,target 6
  35:266,target 10
  51:261,target 19
  33:257,target 8
  0:272,target 6
  12:262,target 2
  24:264,target 5
  27:257 shift
  36:266,target 11
  27:262 shift
  27:266 shift
  34:257,target 9
  27:272 shift
  1:272,target 12
  27:275 goto
  1:0 reduce
  10:270,target 25
  10:269,target 25
  37:266,target 6
  24:0,target 5
  35:257,target 10
  33:257 reduce
  33:259 reduce
  33:260 reduce
  47:259,target 28
  47:260,target 28
  33:261 reduce
  2:272,target 6
  33:262 reduce
  33:264 reduce
  33:266 reduce
  11:269,target 13
  11:270,target 13
  33:269 reduce
  33:270 reduce
  33:272 reduce
  38:266,target 7
  36:257,target 11
  9:0,target 2
  6:264,target 14
  48:259,target 16
  48:260,target 16
  45:267,target 21
  1:263,target 12
  12:269,target 22
  12:270,target 23
  38:257 reduce
  38:259 reduce
  38:260 reduce
  24:272,target 5
  38:261 reduce
  10:261,target 25
  38:262 reduce
  39:266,target 27
  40:266,target 26
  38:264 reduce
  38:266 reduce
  37:257,target 6
  38:269 reduce
  38:270 reduce
  38:272 reduce
  49:259,target 17
  49:260,target 17
  50:259,target 18
  50:260,target 18
  16:262,target 3
  46:267,target 20
  6:0,target 14
  11:261,target 13
  41:266,target 8
  48:0,target 16
  17:0,target 4
  38:257,target 7
  44:257 reduce
  8:264,target 21
  44:259 reduce
  44:260 reduce
  51:260,target 19
  51:259,target 19
  44:261 reduce
  44:262 reduce
  14:257 reduce
  44:263 shift
  44:264 reduce
  17:262,target 4
  44:266 reduce
  3:257 shift
  44:269 reduce
  44:270 reduce
  44:272 reduce
  14:267 reduce
  26:272,target 6
  12:261,target 28
  42:266,target 9
  39:257,target 27
  40:257,target 26
  9:264,target 2
  3:276 goto
  3:277 goto
  6:272,target 14
  18:262,target 2
  31:264,target 15
  49:257 reduce
  50:257 reduce
  49:259 reduce
  49:260 reduce
  50:259 reduce
  50:260 reduce
  49:261 reduce
  50:261 reduce
  27:272,target 6
  49:262 reduce
  50:262 reduce
  19:257 shift
  20:257 shift
  43:266,target 10
  49:263 reduce
  50:263 reduce
  49:264 reduce
  50:264 reduce
  50:266 reduce
  49:266 reduce
  19:262 shift
  20:262 shift
  50:270 reduce
  50:269 reduce
  8:257 shift
  41:257,target 8
  49:269 reduce
  49:270 reduce
  50:272 reduce
  8:260 shift
  8:259 shift
  19:266 shift
  20:266 shift
  49:272 reduce
  8:261 shift
  8:262 shift
  8:264 shift
  19:272 shift
  20:272 shift
  8:266 shift
  19:262,target 2
  20:262,target 2
  19:275 goto
  20:275 goto
  8:270 shift
  8:269 shift
  8:272 shift
  16:269,target 3
  16:270,target 3
  8:275 goto
  28:272,target 6
  44:266,target 11
  11:0,target 13
  0:262,target 2
  42:257,target 9
  8:272,target 6
  25:258 shift
  6:263,target 14
  17:269,target 4
  17:270,target 4
  33:264,target 8
  1:262,target 12
  43:257,target 10
  10:260,target 25
  10:259,target 25
  38:0,target 7
  9:272,target 2
  34:264,target 9
  31:257 reduce
  31:272,target 15
  16:261,target 3
  31:259 reduce
  31:260 reduce
  1:278,target 11
  31:261 reduce
  31:262 reduce
  2:262,target 2
  13:268,target 30
  31:263 reduce
  31:264 reduce
  44:257,target 11
  31:266 reduce
  11:260,target 13
  11:259,target 13
  31:269 reduce
  31:270 reduce
  31:272 reduce
  35:264,target 10
  35:0,target 10
  17:261,target 4
  47:266,target 28
  45:257,target 21
  0:270,target 5
  0:269,target 4
  12:259,target 26
  12:260,target 27
  36:257 reduce
  36:259 reduce
  36:260 reduce
  36:261 reduce
  24:262,target 5
  36:262 reduce
  36:264 reduce
  36:266 reduce
  36:264,target 11
  36:269 reduce
  36:270 reduce
  33:272,target 8
  36:272 reduce
  48:266,target 16
  31:263,target 15
  46:257,target 20
  1:269,target 12
  1:270,target 12
  37:264,target 6
  42:257 reduce
  34:272,target 9
  50:266,target 18
  42:259 reduce
  42:260 reduce
  49:266,target 17
  16:0 reduce
  42:261 reduce
  42:262 reduce
  12:257 shift
  42:263 shift
  42:264 reduce
  12:259 shift
  12:260 shift
  12:261 shift
  42:266 reduce
  47:257,target 28
  12:262 shift
  2:270,target 5
  2:269,target 4
  1:257 reduce
  12:264 shift
  42:269 reduce
  42:270 reduce
  1:259 reduce
  1:260 reduce
  12:266 shift
  42:272 reduce
  1:261 reduce
  1:262 reduce
  1:263 reduce
  12:269 shift
  12:270 shift
  1:264 reduce
  26:262,target 2
  1:265 shift
  12:272 shift
  1:266 reduce
  12:275 goto
  1:269 reduce
  1:270 reduce
  38:264,target 7
  1:272 reduce
  35:272,target 10
  51:266,target 19
  1:278 goto
  6:262,target 14
  31:0 reduce
  48:257,target 16
  30:271,target 46
  47:257 reduce
  47:259 reduce
  47:260 reduce
  47:261 reduce
  1:261,target 12
  47:262 reduce
  17:257 reduce
  27:262,target 2
  47:263 reduce
  47:264 reduce
  17:259 reduce
  17:260 reduce
  17:261 reduce
  47:266 reduce
  17:262 reduce
  24:269,target 5
  24:270,target 5
  39:264,target 27
  40:264,target 26
  6:257 reduce
  17:264 reduce
  47:269 reduce
  47:270 reduce
  6:260 reduce
  6:259 reduce
  17:266 reduce
  47:272 reduce
  6:261 reduce
  36:272,target 11
  6:262 reduce
  6:263 reduce
  17:269 reduce
  17:270 reduce
  6:264 reduce
  17:272 reduce
  6:266 reduce
  49:257,target 17
  50:257,target 18
  6:270 reduce
  6:269 reduce
  15:276,target 32
  6:272 reduce
  16:259,target 3
  16:260,target 3
  13:267,target 22
  28:262,target 2
  41:264,target 8
  37:272,target 6
  23:257 shift
  8:262,target 2
  51:257,target 19
  17:0 reduce
  17:259,target 4
  17:260,target 4
  14:267,target 23
  42:264,target 9
  38:272,target 7
  24:261,target 5
  9:262,target 2
  6:270,target 14
  6:269,target 14
  3:277,target 15
  15:267,target 31
  28:257 shift
  31:262,target 15
  12:275,target 24
  28:262 shift
  6:0 reduce
  43:264,target 10
  28:266 shift
  10:266,target 25
  7:0,target 0
  39:272,target 27
  40:272,target 26
  28:272 shift
  28:275 goto
  49:0,target 17
  50:0,target 18
  44:264,target 11
  11:266,target 13
  41:272,target 8
  34:257 reduce
  34:259 reduce
  34:260 reduce
  34:261 reduce
  34:262 reduce
  34:264 reduce
  8:270,target 23
  8:269,target 22
  34:266 reduce
  34:269 reduce
  34:270 reduce
  6:261,target 14
  34:272 reduce
  33:262,target 8
  1:259,target 12
  1:260,target 12
  12:266,target 3
  42:272,target 9
  10:257,target 25
  39:263,target 27
  40:263,target 26
  9:270,target 2
  9:269,target 2
  39:257 reduce
  40:257 reduce
  34:262,target 9
  39:259 reduce
  39:260 reduce
  40:259 reduce
  40:260 reduce
  39:261 reduce
  40:261 reduce
  33:0 reduce
  39:262 reduce
  40:262 reduce
  10:257 reduce
  39:263 reduce
  40:263 reduce
  31:269,target 15
  31:270,target 15
  39:264 reduce
  40:264 reduce
  10:260 reduce
  10:259 reduce
  10:261 reduce
  39:266 reduce
  40:266 reduce
  10:262 reduce
  10:263 reduce
  1:0,target 12
  10:264 reduce
  39:269 reduce
  39:270 reduce
  40:269 reduce
  40:270 reduce
  43:272,target 10
  10:266 reduce
  7:0 accept
  39:272 reduce
  40:272 reduce
  10:270 reduce
  10:269 reduce
  11:257,target 13
  41:263,target 48
  10:272 reduce
  8:261,target 20
  35:262,target 10
  47:264,target 28
  47:0 reduce
  44:272,target 11
  45:257 reduce
  12:257,target 1
  15:257 shift
  42:263,target 49
  45:267 reduce
  24:259,target 5
  24:260,target 5
  4:257 shift
  9:261,target 2
  15:267 shift
  36:262,target 11
  39:0,target 27
  40:0,target 26
  33:269,target 8
  33:270,target 8
  48:264,target 16
  3:276,target 14
  15:276 goto
  31:261,target 15
  13:257,target 22
  43:263,target 50
  51:257 reduce
  51:260 reduce
  51:259 reduce
  51:261 reduce
  37:262,target 6
  51:262 reduce
  51:263 reduce
  51:264 reduce
  18:275,target 33
  21:258 shift
  34:269,target 9
  34:270,target 9
  51:266 reduce
  50:264,target 18
  49:264,target 17
  51:270 reduce
  51:269 reduce
  9:257 reduce
  34:0 reduce
  16:266,target 3
  51:272 reduce
  9:260 reduce
  9:259 reduce
  9:261 reduce
  9:262 reduce
  36:0,target 11
  9:264 reduce
  14:257,target 23
  44:263,target 51
  9:266 reduce
  8:0 reduce
  9:270 reduce
  9:269 reduce
  9:272 reduce
  38:262,target 7
  19:275,target 34
  20:275,target 35
  35:269,target 10
  35:270,target 10
  51:264,target 19
  21:258,target 36
}

array set ::emmet_rules {
  27,l 278
  9,l 274
  11,l 274
  15,l 275
  20,l 276
  19,l 275
  2,l 274
  24,l 277
  6,l 274
  28,l 278
  12,l 275
  16,l 275
  21,l 276
  3,l 274
  25,l 278
  7,l 274
  13,l 275
  0,l 279
  17,l 275
  22,l 276
  4,l 274
  26,l 278
  8,l 274
  10,l 274
  14,l 275
  18,l 275
  1,l 273
  23,l 277
  5,l 274
}

array set ::emmet_rules {
  23,dc 1
  5,dc 2
  0,dc 1
  17,dc 5
  12,dc 1
  26,dc 3
  8,dc 3
  21,dc 3
  3,dc 2
  15,dc 3
  10,dc 3
  24,dc 2
  6,dc 3
  18,dc 5
  1,dc 1
  13,dc 2
  27,dc 3
  9,dc 3
  22,dc 1
  4,dc 2
  16,dc 5
  11,dc 3
  25,dc 1
  7,dc 3
  20,dc 3
  19,dc 5
  2,dc 1
  14,dc 1
  28,dc 4
}

array set ::emmet_rules {
  13,line 409
  25,line 451
  7,line 389
  10,line 398
  22,line 438
  4,line 380
  18,line 424
  1,line 369
  15,line 415
  27,line 457
  9,line 395
  12,line 406
  24,line 446
  6,line 386
  21,line 435
  3,line 377
  17,line 421
  14,line 412
  26,line 454
  8,line 392
  11,line 401
  23,line 443
  5,line 383
  20,line 432
  19,line 427
  2,line 374
  16,line 418
  28,line 460
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
        set ::emmet_value [emmet_generate_html $1]
       }
                    2 { 
              set _ [list $1]
             }
                    3 { 
              set _ [list [list id $2]]
             }
                    4 { 
              set _ [list [list class $2]]
             }
                    5 { 
              set _ [concat $1 [list $2]]
             }
                    6 { 
              set _ [concat $1 [list [list id $3]]]
             }
                    7 { 
              set _ [concat $1 [list [list class $3]]]
             }
                    8 { 
              set _ [concat $1 [list child $3]]
             }
                    9 { 
              set _ [concat $1 [list sibling $3]]
             }
                    10 { 
              set _ [concat $1 [list [list climb [string length $2]] $3]]
             }
                    11 { 
              set _ [apply_multiplier $1 $3]
             }
                    12 { 
        set _ [list ident $1]
       }
                    13 { 
        set _ [list ident $1 $2]
       }
                    14 { 
        set _ [list text $1]
       }
                    15 { 
        set _ [list attrs $2]
       }
                    16 { 
        set _ [concat $2 [list child $4]]
       }
                    17 { 
        set _ [concat $2 [list sibling $4]]
       }
                    18 { 
        set _ [concat $2 [list [list climb [string length $3]] $4]]
       }
                    19 { 
        set _ [list [apply_multiplier $2 $4]]
       }
                    20 { 
        set _ [list $1 $3]
       }
                    21 { 
        set _ [list $1 $3]
       }
                    22 { 
        set _ [list $1]
       }
                    23 { 
         set _ [list $1]
        }
                    24 { 
         set _ [list $1 $2]
        }
                    25 { 
             set _ [list $1 1 1]
            }
                    26 { 
             set _ [list $1 $3 1]
            }
                    27 { 
             set _ [list $1 1 -1]
            }
                    28 { 
             set _ [list $1 $3 -1]
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
