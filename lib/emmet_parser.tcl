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
set emmet_max         1
set emmet_curr        0
set emmet_start       1
set emmet_prespace    ""

array set emmet_ml_lookup {

  # HTML
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
  link:css             {link       0 {rel "stylesheet" href "{|style}.css"}}
  link:print           {link       0 {rel "stylesheet" href "{|print}.css" media "print"}}
  link:favicon         {link       0 {rel "shortcut icon" type "image/x-icon" href "{|favicon.ico}"}}
  link:touch           {link       0 {rel "apple-touch-icon" href "{|favicon.png}"}}
  link:rss             {link       0 {rel "alternate" type "application/rss+xml" title "RSS" href "{|rss.xml}"}}
  link:atom            {link       0 {rel "alternate" type "application/atom+xml" title "Atom" href "{|atom.xml}"}}
  meta                 {meta       0 {}}
  meta:utf             {meta       0 {http-equiv "Content-Type" content "text/html;charset=UTF-8"}}
  meta:win             {meta       0 {http_equiv "Content-Type" content "text/html;charset=windows-1251"}}
  meta:vp              {meta       0 {name "viewport" content "width={|device-width}, user-scalable={|no}, initial-scale={|1.0}, maximum-scale={|1.0}, minimum-scale={|1.0}"}}
  meta:compat          {meta       0 {http-equiv "X-UA-Compatible" content "{|IE=7}"}}
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
  input                {input      0 {type "{|text}"}}
  inp                  {input      0 {type "{|text}" name "" id ""}}
  input:hidden         {input      0 {type "hidden" name ""}}
  input:h              {input      0 {type "hidden" name ""}}
  input:text           {input      0 {type "{|text}" name "" id ""}}
  input:t              {input      0 {type "{|text}" name "" id ""}}
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
  textarea             {textarea   1 {name "" id "" cols "{|30}" rows "{|10}"}}
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
  tarea                {textarea   1 {name "" id "" cols "{|30}" rows "{|10}"}}
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

  # XSLT
  tm                   {xsl:template               1 {match "" mode ""}}
  tmatch               {xsl:template               1 {match "" mode ""}}
  tn                   {xsl:template               1 {name ""}}
  tname                {xsl:template               1 {name ""}}
  call                 {xsl:call-template          0 {name ""}}
  ap                   {xsl:apply-templates        0 {select "" mode ""}}
  api                  {xsl:apply-imports          0 {}}
  imp                  {xsl:import                 0 {href ""}}
  inc                  {xsl:include                0 {href ""}}
  ch                   {xsl:choose                 1 {}}
  xsl:when             {xsl:when                   1 {test ""}}
  wh                   {xsl:when                   1 {test ""}}
  ot                   {xsl:otherwise              1 {}}
  if                   {xsl:if                     1 {test ""}}
  par                  {xsl:param                  1 {name ""}}
  pare                 {xsl:param                  0 {name "" select ""}}
  var                  {xsl:variable               1 {name ""}}
  vare                 {xsl:variable               0 {name "" select ""}}
  wp                   {xsl:with-param             0 {name "" select ""}}
  key                  {xsl:key                    0 {name "" match "" use ""}}
  elem                 {xsl:element                1 {name ""}}
  attr                 {xsl:attribute              1 {name ""}}
  attrs                {xsl:attribute-set          1 {name ""}}
  cp                   {xsl:copy                   0 {select ""}}
  co                   {xsl:copy-of                0 {select ""}}
  val                  {xsl:value-of               0 {select ""}}
  each                 {xsl:for-each               1 {select ""}}
  for                  {xsl:for-each               1 {select ""}}
  tex                  {xsl:text                   1 {}}
  com                  {xsl:comment                1 {}}
  msg                  {xsl:message                1 {terminate "no"}}
  fall                 {xsl:fallback               1 {}}
  num                  {xsl:number                 0 {value ""}}
  nam                  {namespace-alias            0 {stylesheet-prefix "" result-prefix ""}}
  pres                 {xsl:preserve-space         0 {elements ""}}
  strip                {xsl:strip-space            0 {elements ""}}
  proc                 {xsl:processing-instruction 1 {name ""}}
  sort                 {xsl:sort                   0 {select ""}}
}

array set emmet_inlined {
  a       1
  abbr    1
  acronym 1
  address 1
  b       1
  big     1
  center  1
  cite    1
  code    1
  em      1
  i       1
  kbd     1
  q       1
  s       1
  samp    1
  small   1
  span    1
  strike  1
  strong  1
  sub     1
  sup     1
  tt      1
  u       1
  var     1
}

proc emmet_is_curr {tree node} {

  return [$tree keyexists $node curr]

}

proc emmet_gen_str {format_str values} {

  set vals [list]

  foreach value $values {
    lappend vals [eval {*}$value]
  }

  return [format $format_str {*}$vals]

}

proc emmet_gen_lorem {words} {
  
  set token  [::http::geturl "http://lipsum.com/feed/xml?what=words&amount=$words&start=0"]
  set lipsum ""
  
  if {([::http::status $token] eq "ok") && ([::http::ncode $token] eq "200")} {
    regexp {<lipsum>(.*)</lipsum>} [::http::data $token] -> lipsum
  }
  
  ::http::cleanup $token
  
  return $lipsum
  
}

proc emmet_elaborate {tree node action} {

  # If we are the root node, exit early
  if {$node eq "root"} {
    $::emmet_elab set root curr 0
    $::emmet_elab set root type "group"
    return
  }

  set ::emmet_max [$tree get $node multiplier]

  foreach parent [$::emmet_elab nodes] {

    if {![$::emmet_elab keyexists $parent curr] || ([$tree depth $node] != [expr [$::emmet_elab depth $parent] + 1])} {
      continue
    }

    # Get the parent's current value
    set curr [$::emmet_elab get $parent curr]

    # Clear the parent's current attribute
    if {[expr [$tree index $node] + 1] == [llength [$tree children [$tree parent $node]]]} {
      $::emmet_elab unset $parent curr
    }

    # Create a new node in the elaborated tree
    for {set i 0} {$i < $::emmet_max} {incr i} {

      # Create the new node in the elaboration tree
      set enode [$::emmet_elab insert $parent end]

      # Set the current loop value
      set ::emmet_curr [expr ($::emmet_max == 1) ? $curr : $i]

      # Set the current attribute curr
      if {![$tree isleaf $node]} {
        $::emmet_elab set $enode curr $::emmet_curr
      }

      if {[set type [$tree get $node type]] eq "ident"} {

        # If we have an implictly specified type that hasn't been handled yet, it will be a div
        if {[set name [$tree get $node name]] eq ""} {
          set name [list "div" {}]
        }

        # Calculate the node name
        set ename  [emmet_gen_str {*}$name]
        set tagnum 1

        # Now that the name is elaborated, look it up and update the node, if necessary
        if {[info exists ::emmet_ml_lookup($ename)]} {
          lassign $::emmet_ml_lookup($ename) ename tagnum attrs
          foreach {key value} $attrs {
            $::emmet_elab set $enode attr,$key $value
          }
        }

        # Set the node name and tag number
        $::emmet_elab set $enode name   $ename
        $::emmet_elab set $enode tagnum $tagnum

        # Generate the attributes
        foreach attr [$tree keys $node attr,*] {
          set attr_key [emmet_gen_str {*}[lindex [split $attr ,] 1]]
          $::emmet_elab set $enode attr,$attr_key [list]
          foreach attr_val [$tree get $node $attr] {
            $::emmet_elab lappend $enode attr,$attr_key [emmet_gen_str {*}$attr_val]
          }
        }

      }

      # Set the node type
      $::emmet_elab set $enode type $type

      # Add the node text value, if specified
      if {[$tree keyexists $node value]} {
        $::emmet_elab set $enode value [emmet_gen_str {*}[$tree get $node value]]
      }
      
      # Add the Ipsum Lorem value, if specified
      if {[$tree keyexists $node lorem]} {
        $::emmet_elab set $enode value [emmet_gen_lorem [$tree get $node lorem]]
      }

    }

  }

}

proc emmet_generate {tree node action} {

  # Gather the children lines and indentation information
  set child_lines  [list]
  set child_indent 0
  foreach child [$tree children $node] {
    lappend child_lines {*}[$tree get $child lines]
    if {[$tree get $child indent]} {
      set child_indent 1
    }
  }
  
  # Setup the child lines to be structured properly
  if {[$tree get $node type] ne "group"} {
    if {$child_indent} {
      set spaces [string repeat { } $::emmet_shift_width]
      set i      0
      foreach line $child_lines {
        lset child_lines $i "$spaces$line"
        incr i
      }
    } else {
      set child_lines [join $child_lines {}]
    }
  }

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
        if {[set attr_val [concat {*}[$tree get $node $attr]]] eq ""} {
          set attr_val "{|}"
        }
        append attr_str " [lindex [split $attr ,] 1]=\"$attr_val\""
      }
      if {$tagnum == 0} {
        $tree set $node lines [list "<$name$attr_str />$value"]
      } elseif {$tagnum == 2} {
        $tree set $node lines [list "<$name$attr_str>$value"]
      } elseif {[llength $child_lines] == 0} {
        if {$value eq ""} {
          set value "{|}"
        }
        $tree set $node lines [list "<$name$attr_str>$value</$name>"]
      } else {
        if {$child_indent} {
          $tree set $node lines [list "<$name$attr_str>$value" {*}$child_lines "</$name>"]
        } else {
          $tree set $node lines [list "<$name$attr_str>$value$child_lines</$name>"]
        }
      }
      $tree set $node indent [expr [info exists ::emmet_inlined($name)] ? 0 : 1]
    }
    text {
      $tree set $node lines  [list [$tree get $node value]]
      $tree set $node indent 0
    }
    group {
      $tree set $node lines  $child_lines
      $tree set $node indent $child_indent
    }
  }

}

proc emmet_generate_html {} {

  # Perform the elaboration
  $::emmet_dom walkproc root -order pre -type dfs emmet_elaborate

  # Generate the code
  $::emmet_elab walkproc root -order post -type dfs emmet_generate

  # Substitute carent syntax with tabstops
  if {[$::emmet_elab get root indent]} {
    set str [join [$::emmet_elab get root lines] "\n$::emmet_prespace"]
  } else {
    set str [join [$::emmet_elab get root lines] {}]
  }
  set index 1
  while {[regexp {(.*?)\{\|(.*?)\}(.*)$} $str -> before value after]} {
    if {$value eq ""} {
      set str "$before\$$index$after"
    } else {
      set str "$before\${$index:$value}$after"
    }
    incr index
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
  27:262,target 2
  17:257 reduce
  7:264,target 28
  34:265,target 20
  11:263,target 23
  26:257,target 1
  17:266,target 18
  6:259,target 13
  6:260,target 13
  24:269,target 5
  37:276,target 46
  23:265,target 27
  38:260,target 3
  38:259,target 3
  29:268,target 24
  26:257 shift
  17:266 reduce
  1:279,target 11
  1:280,target 13
  6:259 reduce
  6:260 reduce
  6:261 reduce
  22:261,target 9
  13:269,target 5
  0:275,target 10
  6:0,target 13
  6:263 reduce
  26:262 shift
  6:264 shift
  12:265,target 3
  34:263,target 20
  26:265 shift
  25:272,target 7
  35:257 reduce
  24:0 reduce
  11:261,target 23
  41:0,target 7
  33:258,target 44
  26:268 shift
  26:269 shift
  26:271 shift
  26:272 shift
  23:263,target 27
  10:0,target 2
  6:276 goto
  44:257 reduce
  35:266 reduce
  26:275 goto
  20:271,target 22
  19:271,target 21
  0:273,target 8
  6:276,target 22
  12:263,target 13
  27:257,target 1
  26:279 goto
  26:280 goto
  18:266,target 34
  7:259,target 28
  7:260,target 28
  34:261,target 20
  25:269,target 5
  14:260 reduce
  14:259 reduce
  44:266 reduce
  42:0 reduce
  24:265,target 3
  14:261 reduce
  40:260,target 5
  40:259,target 5
  39:260,target 4
  39:259,target 4
  2:280,target 12
  2:279,target 11
  46:263,target 10
  16:257,target 17
  14:263 reduce
  23:261,target 27
  14:264 shift
  3:257 shift
  30:264,target 21
  29:264,target 24
  13:265,target 3
  28:260,target 8
  28:259,target 8
  23:260 reduce
  23:259 reduce
  20:268,target 22
  19:268,target 21
  0:271,target 6
  26:272,target 7
  23:261 reduce
  14:271 shift
  12:261,target 13
  23:263 reduce
  23:264 reduce
  23:265 reduce
  38:0 reduce
  24:263,target 26
  14:276 goto
  32:260 reduce
  32:259 reduce
  23:268 reduce
  46:261,target 10
  32:261 reduce
  23:269 reduce
  23:271 reduce
  32:263 reduce
  12:279,target 29
  32:264 shift
  13:263,target 25
  0:268,target 4
  3:277 goto
  26:269,target 5
  3:278 goto
  41:260 reduce
  41:259 reduce
  37:0,target 13
  14:0 reduce
  41:261 reduce
  30:0,target 13
  29:0,target 24
  25:265,target 3
  22:0,target 9
  41:263 reduce
  41:260,target 7
  41:259,target 7
  14:0,target 13
  17:257,target 18
  24:261,target 26
  11:259 reduce
  11:260 reduce
  2:275,target 10
  11:261 reduce
  32:276 goto
  11:263 reduce
  30:260,target 13
  30:259,target 13
  29:260,target 24
  29:259,target 24
  1:271,target 26
  0:257 shift
  11:264 reduce
  36:263,target 12
  27:272,target 7
  11:265 reduce
  43:266,target 16
  13:261,target 25
  20:264,target 22
  19:264,target 21
  9:0 reduce
  20:260 reduce
  20:259 reduce
  19:260 reduce
  19:259 reduce
  0:262 shift
  11:0 reduce
  11:268 reduce
  24:279,target 11
  24:280,target 13
  20:261 reduce
  19:261 reduce
  11:269 reduce
  11:271 reduce
  32:0 reduce
  20:263 reduce
  19:263 reduce
  0:265 shift
  20:264 reduce
  19:264 reduce
  3:277,target 17
  20:265 reduce
  19:265 reduce
  0:268 shift
  13:279,target 29
  0:269 shift
  28:260 reduce
  28:259 reduce
  20:268 reduce
  19:268 reduce
  0:271 shift
  28:261 reduce
  20:269 reduce
  19:269 reduce
  14:263,target 13
  0:272 shift
  20:271 reduce
  19:271 reduce
  0:273 goto
  1:268,target 4
  9:259,target 25
  9:260,target 26
  36:261,target 12
  28:263 reduce
  27:269,target 5
  0:274 goto
  0:275 goto
  6:0 reduce
  11:271,target 23
  26:265,target 3
  42:260,target 11
  42:259,target 11
  37:260 reduce
  37:259 reduce
  28:0 reduce
  18:257,target 16
  0:279 goto
  0:280 goto
  7:0,target 28
  37:261 reduce
  32:264,target 21
  37:263 reduce
  30:276,target 41
  37:264 shift
  31:260,target 6
  31:259,target 6
  2:271,target 6
  37:263,target 13
  44:266,target 15
  42:0,target 11
  14:261,target 13
  46:260 reduce
  46:259 reduce
  34:0,target 20
  46:261 reduce
  7:269,target 28
  34:271,target 20
  25:279,target 11
  25:280,target 12
  46:263 reduce
  20:260,target 22
  20:259,target 22
  19:260,target 21
  19:259,target 21
  16:257 reduce
  0:262,target 2
  11:0,target 23
  11:268,target 23
  37:276 goto
  16:267,target 33
  46:0 reduce
  23:271,target 27
  5:257 shift
  15:263,target 32
  25:257 shift
  16:266 reduce
  2:268,target 4
  37:261,target 13
  16:267 shift
  1:264,target 26
  27:265,target 3
  25:262 shift
  34:268,target 20
  25:265 shift
  22:0 reduce
  6:263,target 13
  34:260 reduce
  34:259 reduce
  25:268 shift
  34:261 reduce
  32:260,target 13
  32:259,target 13
  25:269 shift
  23:268,target 27
  38:263,target 3
  25:271 shift
  45:266,target 14
  34:263 reduce
  25:272 shift
  15:261,target 27
  34:264 reduce
  34:265 reduce
  43:257 reduce
  26:279,target 11
  26:280,target 12
  25:275 goto
  12:268,target 4
  34:268 reduce
  7:265,target 28
  43:257,target 16
  34:269 reduce
  25:275,target 38
  34:271 reduce
  25:279 goto
  25:280 goto
  0:257,target 1
  11:264,target 23
  6:261,target 13
  40:0 reduce
  39:0 reduce
  10:259,target 2
  10:260,target 2
  13:259 reduce
  13:260 reduce
  46:0,target 10
  43:266 reduce
  13:261 reduce
  38:0,target 3
  38:261,target 3
  31:0,target 6
  29:269,target 24
  1:281,target 14
  13:263 reduce
  23:0,target 27
  13:264 reduce
  2:257 shift
  13:265 shift
  13:271,target 25
  22:260 reduce
  22:259 reduce
  13:268 shift
  1:260,target 26
  1:259,target 26
  2:262 shift
  22:261 reduce
  13:269 shift
  7:263,target 28
  34:264,target 20
  13:271 reduce
  32:276,target 42
  22:263 reduce
  2:265 shift
  36:0 reduce
  24:268,target 4
  40:263,target 5
  39:263,target 4
  2:268 shift
  2:269 shift
  31:260 reduce
  31:259 reduce
  23:264,target 27
  2:271 shift
  31:261 reduce
  2:272 shift
  27:279,target 11
  27:280,target 12
  13:279 goto
  7:282,target 24
  31:263 reduce
  22:260,target 9
  22:259,target 9
  13:268,target 4
  2:274 goto
  2:262,target 2
  28:263,target 8
  0:274,target 9
  2:275 goto
  44:257,target 15
  35:266,target 19
  26:275,target 39
  12:264,target 21
  7:261,target 28
  12:0 reduce
  40:260 reduce
  40:259 reduce
  39:260 reduce
  39:259 reduce
  25:271,target 6
  2:280 goto
  2:279 goto
  40:261 reduce
  39:261 reduce
  11:259,target 23
  11:260,target 23
  40:263 reduce
  39:263 reduce
  33:257,target 43
  40:261,target 5
  39:261,target 4
  10:259 reduce
  10:260 reduce
  14:271,target 30
  10:261 reduce
  29:265,target 24
  8:0,target 0
  1:0,target 26
  10:263 reduce
  28:261,target 8
  20:269,target 22
  19:269,target 21
  0:272,target 7
  18:257 shift
  7:0 reduce
  7:258,target 23
  34:260,target 20
  34:259,target 20
  25:268,target 4
  41:263,target 7
  30:0 reduce
  29:0 reduce
  24:264,target 26
  20:0,target 22
  19:0,target 21
  7:258 shift
  12:0,target 13
  27:257 shift
  18:266 shift
  7:259 reduce
  7:260 reduce
  23:260,target 27
  23:259,target 27
  7:261 reduce
  30:263,target 13
  29:263,target 24
  45:257,target 14
  27:275,target 40
  7:263 reduce
  27:262 shift
  13:264,target 25
  2:257,target 1
  7:264 reduce
  0:269,target 5
  7:265 reduce
  26:271,target 6
  27:265 shift
  12:259,target 13
  12:260,target 13
  7:268 reduce
  7:269 reduce
  41:261,target 7
  36:260 reduce
  36:259 reduce
  27:268 shift
  18:277 goto
  7:271 reduce
  36:261 reduce
  27:269 shift
  27:271 shift
  36:263 reduce
  27:272 shift
  46:260,target 10
  46:259,target 10
  45:257 reduce
  30:261,target 13
  29:261,target 24
  27:275 goto
  1:0 reduce
  20:265,target 22
  19:265,target 21
  27:279 goto
  27:280 goto
  26:268,target 4
  7:282 goto
  42:263,target 11
  24:281,target 37
  23:0 reduce
  15:260 shift
  15:259 shift
  45:266 reduce
  15:261 shift
  3:278,target 18
  24:260,target 26
  24:259,target 26
  15:263 shift
  31:263,target 6
  2:274,target 15
  4:257 shift
  14:264,target 21
  3:257,target 16
  1:269,target 5
  9:261,target 27
  12:276,target 28
  27:271,target 6
  24:260 reduce
  24:259 reduce
  40:0,target 5
  39:0,target 4
  24:261 reduce
  13:259,target 25
  13:260,target 25
  32:0,target 13
  20:263,target 22
  19:263,target 21
  0:265,target 3
  35:257,target 19
  24:263 reduce
  24:0,target 26
  42:261,target 11
  33:270,target 45
  24:264 reduce
  20:0 reduce
  19:0 reduce
  24:265 shift
  33:257 shift
  25:262,target 2
  41:0 reduce
  33:258 shift
  24:268 shift
  24:269 shift
  31:261,target 6
  2:272,target 7
  37:264,target 21
  36:260,target 12
  36:259,target 12
  27:268,target 4
  18:277,target 35
  7:271,target 28
  42:260 reduce
  42:259 reduce
  20:261,target 22
  19:261,target 21
  11:269,target 23
  42:261 reduce
  33:270 shift
  24:279 goto
  24:280 goto
  42:263 reduce
  24:281 goto
  37:0 reduce
  32:263,target 13
  12:259 reduce
  12:260 reduce
  12:261 reduce
  4:257,target 19
  2:269,target 5
  12:263 reduce
  12:264 shift
  14:260,target 13
  14:259,target 13
  12:265 shift
  1:265,target 3
  1:260 reduce
  1:259 reduce
  21:258 shift
  1:261 reduce
  7:268,target 28
  34:269,target 20
  12:268 shift
  1:263 reduce
  9:0,target 1
  12:269 shift
  13:0 reduce
  26:262,target 2
  1:264 reduce
  6:264,target 21
  1:265 shift
  34:0 reduce
  10:263,target 2
  25:257,target 1
  16:266,target 17
  32:261,target 13
  23:269,target 27
  1:268 shift
  9:259 shift
  9:260 shift
  1:269 shift
  9:261 shift
  12:276 goto
  30:260 reduce
  30:259 reduce
  29:260 reduce
  29:259 reduce
  1:271 reduce
  36:0,target 12
  30:261 reduce
  29:261 reduce
  37:260,target 13
  37:259,target 13
  28:0,target 8
  0:279,target 11
  0:280,target 12
  12:279 goto
  30:263 reduce
  29:263 reduce
  30:264 shift
  29:264 reduce
  1:263,target 26
  12:269,target 5
  13:0,target 25
  29:265 reduce
  8:0 accept
  10:0 reduce
  11:265,target 23
  38:260 reduce
  38:259 reduce
  29:268 reduce
  1:279 goto
  1:280 goto
  38:261 reduce
  31:0 reduce
  29:269 reduce
  1:281 goto
  29:271 reduce
  10:261,target 2
  38:263 reduce
  5:257,target 20
  14:276,target 31
  29:271,target 24
  15:260,target 26
  15:259,target 25
  30:276 goto
  22:263,target 9
  2:265,target 3
  21:258,target 36
  1:261,target 26
}

array set ::emmet_rules {
  27,l 282
  9,l 275
  11,l 275
  15,l 277
  20,l 279
  19,l 278
  2,l 274
  24,l 280
  6,l 275
  28,l 282
  12,l 276
  16,l 277
  21,l 279
  3,l 274
  25,l 281
  7,l 275
  13,l 276
  0,l 283
  17,l 277
  22,l 279
  4,l 274
  26,l 281
  8,l 275
  10,l 275
  14,l 277
  18,l 278
  1,l 273
  23,l 280
  5,l 274
}

array set ::emmet_rules {
  23,dc 1
  5,dc 3
  0,dc 1
  17,dc 1
  12,dc 2
  26,dc 0
  8,dc 2
  21,dc 2
  3,dc 3
  15,dc 3
  10,dc 4
  24,dc 2
  6,dc 3
  18,dc 1
  1,dc 1
  13,dc 0
  27,dc 1
  9,dc 2
  22,dc 2
  4,dc 3
  16,dc 3
  11,dc 4
  25,dc 1
  7,dc 4
  20,dc 3
  19,dc 2
  2,dc 1
  14,dc 3
  28,dc 0
}

array set ::emmet_rules {
  13,line 578
  25,line 624
  7,line 535
  10,line 563
  22,line 611
  4,line 506
  18,line 597
  1,line 478
  15,line 586
  27,line 632
  9,line 552
  12,line 575
  24,line 619
  6,line 524
  21,line 608
  3,line 502
  17,line 592
  14,line 583
  26,line 627
  8,line 545
  11,line 570
  23,line 616
  5,line 512
  20,line 605
  19,line 600
  2,line 483
  16,line 589
  28,line 635
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
                switch [lindex [$::emmet_dom get $1 name] 0] {
                  em       { $::emmet_dom set $3 name [list "span" {}] }
                  table -
                  tbody -
                  thead -
                  tfoot    { $::emmet_dom set $3 name [list "tr" {}] }
                  tr       { $::emmet_dom set $3 name [list "td" {}] }
                  ul -
                  ol       { $::emmet_dom set $3 name [list "li" {}] }
                  select -
                  optgroup { $::emmet_dom set $3 name [list "option" {}] }
                  default  { $::emmet_dom set $3 name [list "div" {}] }
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
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type       "ident"
        $::emmet_dom set $node name       ""
        $::emmet_dom set $node lorem      $2
        foreach {attr_name attr_val} $3 {
          $::emmet_dom lappend $node "attr,$attr_name" $attr_val
        }
        $::emmet_dom set $node multiplier $4
        set _ $node
       }
                    11 { 
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type       "group"
        $::emmet_dom set $node multiplier $4
        $::emmet_dom move $node end {*}[lrange [$::emmet_dom children root] $1 end-1]
        set _ $node
       }
                    12 { 
                set _ $2
               }
                    13 { 
                set _ 1
               }
                    14 { 
             set _ [list $1 $3]
            }
                    15 { 
             set _ [list $1 [list $3 {}]]
            }
                    16 { 
             set _ [list $1 $3]
            }
                    17 { 
             set _ [list $1 [list {} {}]]
            }
                    18 { 
              set _ $1
             }
                    19 { 
              set _ [concat $1 $2]
             }
                    20 { 
        set _ $2
       }
                    21 { 
        set _ [list [list id {}] $2]
       }
                    22 { 
        set _ [list [list class {}] $2]
       }
                    23 { 
         set _ $1
        }
                    24 { 
         set _ [concat $2 $1]
        }
                    25 { 
             set _ $1
            }
                    26 { 
             set _ [list]
            }
                    27 { 
              set _ $1
             }
                    28 { 
              set _ 30
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

proc parse_emmet {str {prespace ""}} {
  
  # Flush the parsing buffer
  EMMET__FLUSH_BUFFER

  # Insert the string to scan
  emmet__scan_string $str

  # Initialize some values
  set ::emmet_begpos   0
  set ::emmet_endpos   0
  set ::emmet_prespace $prespace

  # Create the trees
  set ::emmet_dom  [::struct::tree]
  set ::emmet_elab [::struct::tree]

  # Parse the string
  if {[catch { emmet_parse } rc] || ($rc != 0)} {

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
