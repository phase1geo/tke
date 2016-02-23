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

package require struct

set emmet_value       ""
set emmet_errmsg      ""
set emmet_errstr      ""
set emmet_shift_width 2
set emmet_item_id     0
set emmet_max         1
set emmet_curr        0
set emmet_start       1

array set emmet_lookup {

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
  
  # CSS
  

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

proc emmet_get_depth {tree node} {
  
  set depth 0
  
  foreach node [$tree ancestors $node] {
    if {[$tree get $node type] ne "group"} {
      incr depth
    }
  }
  
  return $depth
  
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
        if {[info exists ::emmet_lookup($ename)]} {
          lassign $::emmet_lookup($ename) ename tagnum attrs
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
  set spaces [string repeat { } [expr [emmet_get_depth $tree $node] * $::emmet_shift_width]]

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
        set attr_val [concat {*}[$tree get $node $attr]]
        append attr_str " [lindex [split $attr ,] 1]=\"$attr_val\""
      }
      if {$tagnum == 0} {
        $tree set $node str "$spaces<$name$attr_str />$value"
      } elseif {$tagnum == 2} {
        $tree set $node str "$spaces<$name$attr_str>$value"
      } elseif {[llength $child_strs] == 0} {
        $tree set $node str "$spaces<$name$attr_str>$value</$name>"
      } else {
        $tree set $node str "$spaces<$name$attr_str>$value\n[join $child_strs \n]\n$spaces</$name>"
      }
    }
    text {
      $tree set $node str "$spaces[$tree get $node value]"
    }
    group {
      $tree set $node str "[join $child_strs \n]"
    }
  }
  
}

proc emmet_generate_html {} {

  # Perform the elaboration
  $::emmet_dom walkproc root -order pre -type dfs emmet_elaborate

  # Generate the code
  $::emmet_elab walkproc root -order post -type dfs emmet_generate
  
  return [$::emmet_elab get root "str"]

}

%}

%token IDENTIFIER NUMBER CHILD SIBLING CLIMB OPEN_GROUP CLOSE_GROUP MULTIPLY
%token OPEN_ATTR CLOSE_ATTR ASSIGN ID CLASS VALUE TEXT

%%

main: expression {
        set ::emmet_value [emmet_generate_html]
      }
    ;

expression: item {
              set _ $1
            }
          | expression CHILD item {
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
          | expression SIBLING item {
              $::emmet_dom move [$::emmet_dom parent $1] end $3
              set _ $3
            }
          | expression CLIMB item {
              set ancestors [$::emmet_dom ancestors $1]
              set parent    [lindex $ancestors [string length $2]]
              $::emmet_dom move $parent end $3
              set _ $3
            }
          ;

item: IDENTIFIER attrs_opt multiply_opt {
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type "ident"
        $::emmet_dom set $node name $1
        foreach {attr_name attr_val} $2 {
          $::emmet_dom lappend $node attr,$attr_name $attr_val
        }
        $::emmet_dom set $node multiplier $3
        set _ $node
      }
    | IDENTIFIER attrs_opt TEXT multiply_opt {
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
    | attrs multiply_opt {
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type "ident"
        $::emmet_dom set $node name ""
        foreach {attr_name attr_val} $1 {
          $::emmet_dom lappend $node "attr,$attr_name" $attr_val
        }
        $::emmet_dom set $node multiplier $2
        set _ $node
      }
    | TEXT multiply_opt {
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type       "text"
        $::emmet_dom set $node value      $1
        $::emmet_dom set $node multiplier $2
        set _ $node
      }
    | OPEN_GROUP expression CLOSE_GROUP multiply_opt {
        set node [$::emmet_dom insert root end]
        $::emmet_dom set $node type       "group"
        $::emmet_dom set $node multiplier $4
        $::emmet_dom move $node end {*}[lrange [$::emmet_dom children root] $1 end-1]
        set _ $node
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
             set _ [list $1 [list $3 {}]]
           }
         | IDENTIFIER ASSIGN IDENTIFIER {
             set _ [list $1 $3]
           }
         | IDENTIFIER {
             set _ [list $1 [list {} {}]]
           }
         ;

attr_items: attr_item {
              set _ $1
            }
          | attr_items attr_item {
              set _ [concat $1 $2]
            }
          ;

attr: OPEN_ATTR attr_items CLOSE_ATTR {
        set _ $2
      }
    | ID IDENTIFIER {
        set _ [list [list id {}] $2]
      }
    | CLASS IDENTIFIER {
        set _ [list [list class {}] $2]
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
