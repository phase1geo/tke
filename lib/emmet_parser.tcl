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

array set emmet_css_lookup {
  va       {vertical-align: top;}
  va:sup   {vertical-align: super;}
  va:t     {vertical-align: top;}
  va:tt    {vertical-align: text-top;}
  va:m     {vertical-align: middle;}
  va:bl    {vertical-align: baseline;}
  va:b     {vertical-align: bottom;}
  va:tb    {vertical-align: text-bottom;}
  va:sub   {vertical-align: sub;}
  ta       {text-align: |left|;}
  ta:l     {text-align: left;}
  ta:c     {text-align: center;}
  ta:r     {text-align: right;}
  ta:j     {text-align: justify;}
  ta-lst   {text-align-last: |;}
  tal:a    {text-align-last: auto;}
  tal:l    {text-align-last: left;}
  tal:c    {text-align-last: center;}
  tal:r    {text-align-last: right;}
  td       {text-decoration: |none|;}
  td:n     {text-decoration: none;}
  td:u     {text-decoration: underline;}
  td:o     {text-decoration: overline;}
  td:l     {text-decoration: line-through;}
  te       {text-emphasis: |;}
  te:n     {text-emphasis: none;}
  te:ac    {text-emphasis: accent;}
  te:dt    {text-emphasis: dot;}
  te:c     {text-emphasis: circle;}
  te:ds    {text-emphasis: disc;}
  te:b     {text-emphasis: before;}
  te:a     {text-emphasis: after;}
  th       {text-height: |;}
  th:a     {text-height: auto;}
  th:f     {text-height: font-size;}
  th:t     {text-height: text-size;}
  th:m     {text-height: max-size;}
  ti       {text-indent: |;}
  ti:-     {text-indent: -9999px;}
  tj       {text-justify: |;}
  tj:a     {text-justify: auto;}
  tj:iw    {text-justify: inter-word;}
  tj:ii    {text-justify: inter-ideograph;}
  tj:ic    {text-justify: inter-cluster;}
  tj:d     {text-justify: distribute;}
  tj:k     {text-justify: kashida;}
  tj:t     {text-justify: tibetan;}
  to       {text-outline: |;}
  to+      {text-outline: 0 0 #000;}
  to:n     {text-outline: none;}
  tr       {text-replace: |;}
  tr:n     {text-replace: none;}
  tt       {text-transform: |uppercase|;}
  tt:n     {text-transform: none;}
  tt:c     {text-transform: capitalize;}
  tt:u     {text-transform: uppercase;}
  tt:l     {text-transform: lowercase;}
  tw       {text-wrap: |;}
  tw:n     {text-wrap: normal;}
  tw:no    {text-wrap: none;}
  tw:u     {text-wrap: unrestricted;}
  tw:s     {text-wrap: suppress;}
  tsh      {text-shadow: |hoff| |voff| |blur| |#000|;}
  tsh:r    {text-shadow: |h| |v| |blur| rgb(|0|, |0|, |0|);}
  tsh:ra   {text-shadow: |h| |v| |blur| rgb(|0|, |0|, |0|, |.5|);}
  tsh+     {text-shadow: |0| |0| |0| |#000|;}
  tsh:n    {text-shadow: none;}
  lh       {line-height: |;}
  lts      {letter-spacing: |;}
  whs      {white-space: |;}
  whs:n    {white-space: normal;}
  whs:p    {white-space: pre;}
  whs:nw   {white-space: nowrap;}
  whs:pw   {white-space: pre-wrap;}
  whs:pl   {white-space: pre-line;}
  whsc     {white-space-collapse: |;}
  whsc:n   {white-space-collapse: normal;}
  whsc:k   {white-space-collapse: keep-all;}
  whsc:l   {white-space-collapse: loose;}
  whsc:bs  {white-space-collapse: break-strict;}
  whsc:ba  {white-space-collapse: break-all;}
  wob      {word-break: |;}
  wob:n    {word-break: normal;}
  wob:k    {word-break: keep-all;}
  wob:l    {word-break: loose;}
  wob:bs   {word-break: break-strict;}
  wob:ba   {word-break: break-all;}
  wos      {word-spacking: |;}
  wow      {word-wrap: |;}
  wow:nm   {word-wrap: normal;}
  wow:n    {word-wrap: none;}
  wow:u    {word-wrap: unrestricted;}
  wow:s    {word-wrap: suppress;}
  wow:b    {word-wrap: break-word;}
  bg       {background: |;}
  bg+      {background: |#fff| url(|) |0| |0| |no-repeat|;}
  bg:n     {background: none;}
  bgc      {background-color: |#fff|;}
  bgc:t    {background-color: transparent;}
  bgi      {background-image: url(|);}
  bgi:n    {background-image: none;}
  bgr      {background-repeat: |;}
  bgr:n    {background-repeat: no-repeat;}
  bgr:x    {background-repeat: repeat-x;}
  bgr:y    {background-repeat: repeat-y;}
  bgr:sp   {background-repeat: space;}
  bgr:rd   {background-repeat: round;}
  bga      {background-attachment: |;}
  bga:f    {background-attachment: fixed;}
  bga:s    {background-attachment: scroll;}
  bgp      {background-position: |0| |0|;}
  bgpx     {background-position-x: |;}
  bgpy     {background-position-y: |;}
  bgbk     {background-break: |;}
  bgbk:bb  {background-break: bounding-box;}
  bgbk:eb  {background-break: each-box;}
  bgbk:c   {background-break: continuous;}
  bgcp     {background-clip: |padding-box|;}
  bgcp:bb  {background-clip: border-box;}
  bgcp:pb  {background-clip: padding-box;}
  bgcp:cb  {background-clip: content-box;}
  bgcp:nc  {background-clip: no-clip;}
  bgo      {background-origin: |;}
  bgo:pb   {background-origin: padding-box;}
  bgo:bb   {background-origin: border-box;}
  bgo:cb   {background-origin: content-box;}
  bgsz     {background-size: |;}
  bgsz:a   {background-size: auto;}
  bgsz:ct  {background-size: contain;}
  bgsz:cv  {background-size: cover;}
  c        {color: #|000|;}
  c:r      {color: rgb(|0|, |0|, |0|);}
  c:ra     {color: rgb(|0|, |0|, |0|, |.5|);}
  op       {opacity: |;}
  cnt      {content: '|';}
  cnt:n    {content: normal;}
  ct:n     {content: normal;}
  cnt:oq   {content: open-quote;}
  ct:oq    {content: open-quote;}
  cnt:noq  {content: no-open-quote;}
  ct:noq   {content: no-open-quote;}
  cnt:cq   {content: close-quote;}
  ct:cq    {content: close-quote;}
  cnt:ncq  {content: no-close-quote;}
  ct:ncq   {content: no-close-quote;}
  cnt:a    {content: attr(|);}
  ct:a     {content: attr(|);}
  cnt:c    {content: counter(|);}
  ct:c     {content: counter(|);}
  cnt:cs   {content: counters(|);}
  ct:cs    {content: counters(|);}
  ct       {content: |;}
  q        {quotes: |;}
  q:n      {quotes: none;}
  q:ru     {quotes: '\00AB' '\00BB' '\201E' '\201C';}
  q:en     {quotes: '\201C' '\201D' '\2018' '\2019';}
  coi      {counter-increment: |;}
  cor      {counter-reset: |;}
  ol       {outline: |;}
  ol:n     {outline: none;}
  olo      {outline-offset: |;}
  olw      {outline-width: |;}
  ols      {outline-style: |;}
  olc      {outline-color: #|000|;}
  olc:i    {outline-color: invert;}
  tbl      {table-layout: |;}
  tbl:a    {table-layout: auto;}
  tbl:f    {table-layout: fixed;}
  cps      {caption-side: |;}
  cps:t    {caption-side: top;}
  cps:b    {caption-side: bottom;}
  ec       {empty-cells: |;}
  ec:s     {empty-cells: show;}
  ec:h     {empty-cells: hide;}
  bd       {border: |;}
  bd+      {border: |1px| |solid| |#000|;}
  bd:n     {border: none;}
  bdbk     {border-break: |close|;}
  bdbk:c   {border-break: close;}
  bdcl     {border-collapse: |;}
  bdcl:c   {border-collapse: collapse;}
  bdcl:s   {border-collapse: separate;}
  bdc      {border-color: #|000|;}
  bdc:t    {border-color: transparent;}
  bdi      {border-image: url(|);}
  bdi:n    {border-image: none;}
  bdti     {border-top-image: url(|);}
  bdti:n   {border-top-image: none;}
  bdri     {border-right-image: url(|);}
  bdri:n   {border-right-image: none;}
  bdbi     {border-bottom-image: url(|);}
  bdbi:n   {border-bottom-image: none;}
  bdli     {border-left-image: url(|);}
  bdli:n   {border-left-image: none;}
  bdci     {border-corner-image: url(|);}
  bdci:n   {border-corner-image: none;}
  bdci:c   {border-corner-image: continue;}
  bdtli    {border-top-left-image: url(|);}
  bdtli:n  {border-top-left-image: none;}
  bdtli:c  {border-top-left-image: continue;}
  bdtri    {border-top-right-image: url(|);}
  bdtri:n  {border-top-right-image: none;}
  bdtri:c  {border-top-right-image: continue;}
  bdbri    {border-bottom-right-image: url(|);}
  bdbri:n  {border-bottom-right-image: none;}
  bdbri:c  {border-bottom-right-image: continue;}
  bdbli    {border-bottom-left-image: url(|);}
  bdbli:n  {border-bottom-left-image: none;}
  bdbli:c  {border-bottom-left-image: continue;}
  bdf      {border-fit: |repeat|;}
  bdf:c    {border-fit: clip;}
  bdf:r    {border-fit: repeat;}
  bdf:sc   {border-fit: scale;}
  bdf:st   {border-fit: stretch;}
  bdf:ow   {border-fit: overwrite;}
  bdf:of   {border-fit: overflow;}
  bdf:sp   {border-fit: space;}
  bdlen    {border-length: |;}
  bdlen:a  {border-length: auto;}
  bdsp     {border-spacing: |;}
  bds      {border-style: |;}
  bds:n    {border-style: none;}
  bds:h    {border-style: hidden;}
  bds:dt   {border-style: dotted;}
  bds:ds   {border-style: dashed;}
  bds:s    {border-style: solid;}
  bds:db   {border-style: double;}
  bds:dtds {border-style: dot-dash;}
  bds:dtdtds {border-style: dot-dot-dash;}
  bds:w      {border-style: wave;}
  bds:g      {border-style: groove;}
  bds:r      {border-style: ridge;}
  bds:i      {border-style: inset;}
  bds:o      {border-style: outset;}
  bdw        {border-width: |;}
  bdt        {border-top: |;}
  bt         {border-top: |;}
  bdt+       {border-top: |1px| |solid| |#000|;}
  bdt:n      {border-top: none;}
  bdtw       {border-top-width: |;}
  bdts       {border-top-style: |;}
  bdts:n     {border-top-style: none;}
  bdtc       {border-top-color: #|000|;}
  bdtc:t     {border-top-color: transparent;}
  bdr        {border-right: |;}
  br         {border-right: |;}
  bdr+       {border-right: |1px| |solid| |#000|;}
  bdr:n      {border-right: none;}
  bdrw       {border-right-width: |;}
  bdrst      {border-right-style: |;}
  bdrst:n    {border-right-style: none;}
  bdrc       {border-right-color: #|000|;}
  bdrc:t     {border-right-color: transparent;}
  bdb        {border-bottom: |;}
  bb         {border-bottom: |;}
  bdb+       {border-bottom: |1px| |solid| |#000|;}
  bdb:n      {border-bottom: none;}
  bdbw       {border-bottom-width: |;}
  bdbs       {border-bottom-style: |;}
  bdbs:n     {border-bottom-style: none;}
  bdbc       {border-bottom-color: #|000|;}
  bdbc:t     {border-bottom-color: transparent;}
  bdl        {border-left: |;}
  bl         {border-left: |;}
  bdl+       {border-left: |1px| |solid| |#000|;}
  bdl:n      {border-left: none;}
  bdlw       {border-left-width: |;}
  bdls       {border-left-style: |;}
  bdls:n     {border-left-style: none;}
  bdlc       {border-left-color: #|000|;}
  bdlc:t     {border-left-color: transparent;}
  bdrs       {border-radius: |;}
  bdtrrs     {border-top-right-radius: |;}
  bdtlrs     {border-top-left-radius: |;}
  bdbrrs     {border-bottom-right-radius: |;}
  bdblrs     {border-bottom-left-radius: |;}
  lis        {list-style: |;}
  lis:n      {list-style: none;}
  lisp       {list-style-position: |;}
  lisp:i     {list-style-position: inside;}
  lisp:o     {list-style-position: outside;}
  list       {list-style-type: |;}
  list:n     {list-style-type: none;}
  list:d     {list-style-type: disc;}
  list:c     {list-style-type: circle;}
  list:s     {list-style-type: square;}
  list:dc    {list-style-type: decimal;}
  list:dclz  {list-style-type: decimal-leading-zero;}
  list:lr    {list-style-type: lower-roman;}
  list:ur    {list-style-type: upper-roman;}
  lisi       {list-style-image: |;}
  lisi:n     {list-style-image: none;}
  pgbb       {page-break-before: |;}
  pgbb:au    {page-break-before: auto;}
  pgbb:al    {page-break-before: always;}
  pgbb:l     {page-break-before: left;}
  pgbb:r     {page-break-before: right;}
  pgbi       {page-break-inside: |;}
  pgbi:au    {page-break-inside: auto;}
  pgbi:av    {page-break-inside: avoid;}
  pgba       {page-break-after: |;}
  pgba:au    {page-break-after: auto;}
  pgba:al    {page-break-after: always;}
  pgba:l     {page-break-after: left;}
  pgba:r     {page-break-after: right;}
  orp        {orphans: |;}
  wid        {widows: |}
  !          {!important}
  anim       {animation: |;}
  anim-      {animation: |name| |duration| |timing-function| |delay| |iteration| |direction| |fill-mode|;}
  animdel    {animation-delay: |time|;}
  animdir    {animation-direction: |normal|;}
  animdir:a  {animation-direction: alternate;}
  animdir:ar {animation-direction: alternate-reverse;}
  animdir:n  {animation-direction: normal;}
  animdir:r  {animation-direction: reverse;}
  animdur    {animation-duration: |0|s;}
  animfm     {animation-fill-mode: |both|;}
  animfm:b   {animation-fill-mode: backwards;}
  animfm:bt  {animation-fill-mode: both;}
  animfm:bh  {animation-fill-mode: both;}
  animfm:f   {animation-fill-mode: forwards;}
  animic     {animation-iteration-count: |1|;}
  animic:i   {animation-iteration-count: infinite;}
  animn      {animation-name: |none|;}
  animps     {animation-play-state: |running|;}
  animps:p   {animation-play-state: paused;}
  animps:r   {animation-play-state: running;}
  animtf     {animation-timing-function: |linear|;}
  animtf:cb  {animation-timing-function: cubic-bezier(|0.1|, |0.7|, |1.0|, |0.1|);}
  animtf:e   {animation-timing-function: ease;}
  animtf:ei  {animation-timing-function: ease-in;}
  animtf:eio {animation-timing-function: ease-in-out;}
  animtf:eo  {animation-timing-function: ease-out;}
  animtf:l   {animation-timing-function: linear;}
  ap         {appearance: ${none};}
  bg:ie      {filter:progid:DXImateTransform.Microsoft.AlphaImageLoader(src='|x|.png', sizingMethod='|crop|');}
  cm         {/* |${child} */}
  colm       {columns: |;}
  colmc      {column-count: |;}
  colmf      {column-fill: |;}
  colmg      {column-gap: |;}
  colmr      {column-rule: |;}
  colmrc     {column-rule-color: |;}
  colmrs     {column-rule-style: |;}
  colmrw     {column-rule-width: |;}
  colms      {column-span: |;}
  colmw      {column-width: |;}
  mar        {max-resolution: |res|;}
  mir        {min-resolution: |res|;}
  op:ie      {filter:progid:DXImageTransform.Microsoft.Alpha(Opacity=100);}
  op:ms      {-ms-filter:'progid:DXImageTransform.Microsoft.Alpha(Opacity=100)';}
  ori        {orientation: |;}
  ori:l      {orientation: landscape;}
  ori:p      {orientation: portrait;}
  tov        {text-overflow: ${ellipsis};}
  tov:c      {text-overflow: clip;}
  tov:e      {text-overflow: ellipsis;}
  trf        {transform: |;}
  trf:r      {transform: rotate(|angle|);}
  trf:sc     {transform: scale(|x|, |y|);}
  trf:scx    {transform: scaleX(|x|);}
  trf:scy    {transform: scaleY(|y|);}
  trf:skx    {transform: skewX(|angle|);}
  trf:sky    {transform: skewY(|angle|);}
  trf:t      {transform: translate(|x|, |y|);}
  trf:tx     {transform: translateX(|x|);}
  trf:ty     {transform: translateY(|y|);}
  trfo       {transform-origin: |;}
  trfs       {transform-style: |preserve-3d|;}
  trs        {transition: |prop| |time|;}
  trsde      {transition-delay: |time|;}
  trsdu      {transition-duration: |time|;}
  trsp       {transition-property: |prop|;}
  trstf      {transition-timing-function: |tfunc|;}
  us         {user-select: ${none};}
  wfsm       {-webkit-font-smoothing: ${antialiased};}
  wfsm:a     {-webkit-font-smoothing: antialiased;}
  wfsm:n     {-webkit-font-smoothing: none;}
  wfsm:s     {-webkit-font-smoothing: subpixel-antialiased;}
  wfsm:sa    {-webkit-font-smoothing: subpixel-antialiased;}
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
        if {[set attr_val [concat {*}[$tree get $node $attr]]] eq ""} {
          set attr_val "{|}"
        }
        append attr_str " [lindex [split $attr ,] 1]=\"$attr_val\""
      }
      if {$tagnum == 0} {
        $tree set $node str "$spaces<$name$attr_str />$value"
      } elseif {$tagnum == 2} {
        $tree set $node str "$spaces<$name$attr_str>$value"
      } elseif {[llength $child_strs] == 0} {
        if {$value eq ""} {
          set value "{|}"
        }
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

  # Substitute carent syntax with tabstops
  set str   [$::emmet_elab get root "str"]
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
  13,line 903
  25,line 947
  7,line 866
  10,line 890
  22,line 936
  4,line 837
  18,line 920
  1,line 809
  15,line 909
  9,line 883
  12,line 898
  24,line 944
  6,line 855
  21,line 931
  3,line 833
  17,line 917
  14,line 906
  8,line 876
  11,line 895
  23,line 939
  5,line 843
  20,line 928
  19,line 925
  2,line 814
  16,line 912
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
        $::emmet_dom set $node type       "group"
        $::emmet_dom set $node multiplier $4
        $::emmet_dom move $node end {*}[lrange [$::emmet_dom children root] $1 end-1]
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
             set _ [list $1 [list $3 {}]]
            }
                    15 { 
             set _ [list $1 $3]
            }
                    16 { 
             set _ [list $1 [list {} {}]]
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
        set _ [list [list id {}] $2]
       }
                    21 { 
        set _ [list [list class {}] $2]
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
