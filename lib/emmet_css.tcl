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
# Name:    emmet_css.tcl
# Author:  Trevor Williams  (phase1geo@gmail.com)
# Date:    03/17/2016
# Brief:   Namespace containing Emmet CSS-related functionality.
######################################################################

namespace eval emmet_css {

  array set lookup {
    pos      {position: {|relative}}
    pos:s    {position: static}
    pos:a    {position: absolute}
    pos:r    {position: relative}
    pos:f    {position: fixed}
    t        {top: {|}}
    t:a      {top: auto}
    r        {right: {|}}
    r:a      {right: auto}
    b        {bottom: {|}}
    b:a      {bottom: auto}
    l        {left: {|}}
    l:a      {left: auto}
    z        {z-index: {|}}
    z:a      {z-index: auto}
    fl       {float: {|left}}
    fl:n     {float: none}
    fl:l     {float: left}
    fl:r     {float: right}
    cl       {clear: {|both}}
    cl:n     {clear: none}
    cl:l     {clear: left}
    cl:r     {clear: right}
    cl:b     {clear: both}
    d        {display: {|block}}
    d:n      {display: none}
    d:b      {display: block}
    d:i      {display: inline}
    d:ib     {display: inline-block}
    d:li     {display: list-item}
    d:cp     {display: compact}
    d:tb     {display: table}
    d:itb    {display: inline-table}
    d:tbcp   {display: table-caption}
    d:tbcl   {display: table-column}
    d:tbclg  {display: table-column-group}
    d:tbhg   {display: table-header-group}
    d:tbfg   {display: table-footer-group}
    d:tbr    {display: table-row}
    d:tbrg   {display: table-row-group}
    d:tbc    {display: table-cell}
    d:rb     {display: ruby}
    d:rbb    {display: ruby-base}
    d:rbbg   {display: ruby-base-group}
    d:rbt    {display: ruby-text}
    d:rbtg   {display: ruby-text-group}
    v        {visibility: {|hidden}}
    v:v      {visibility: visible}
    v:h      {visibility: hidden}
    v:c      {visibility: collapse}
    ov       {overflow: {|hidden}}
    ov:v     {overflow: visible}
    ov:h     {overflow: hidden}
    ov:s     {overflow: scroll}
    ov:a     {overflow: auto}
    ovx      {overflow-x: {|hidden}}
    ovx:v    {overflow-x: visible}
    ovx:h    {overflow-x: hidden}
    ovx:s    {overflow-x: scroll}
    ovx:a    {overflow-x: auto}
    ovy      {overflow-y: {|hidden}}
    ovy:v    {overflow-y: visible}
    ovy:h    {overflow-y: hidden}
    ovy:s    {overflow-y: scroll}
    ovy:a    {overflow-y: auto}
    ovs      {overflow-style: {|scrollbar}}
    ovs:a    {overflow-style: auto}
    ovs:s    {overflow-style: scrollbar}
    ovs:p    {overflow-style: panner}
    ovs:m    {overflow-style: move}
    ovs:mq   {overflow-style: marquee}
    zoo      {zoom: 1}
    zm       {zoom: 1}
    cp       {clip: {|}}
    cp:a     {clip: auto}
    cp:r     {clip: rect({|top}, {|right}, {|bottom}, {|left})}
    rsz      {resize: {|}}
    rsz:n    {resize: none}
    rsz:b    {resize: both}
    rsz:h    {resize: horizontal}
    rsz:v    {resize: vertical}
    cur      {cursor: ${pointer}}
    cur:a    {cursor: auto}
    cur:d    {cursor: default}
    cur:c    {cursor: crosshair}
    cur:ha   {cursor: hand}
    cur:he   {cursor: help}
    cur:m    {cursor: move}
    cur:p    {cursor: pointer}
    cur:t    {cursor: text}
    m        {margin: {|}}
    m:a      {margin: auto}
    mt       {margin-top: {|}}
    mt:a     {margin-top: auto}
    mr       {margin-right: {|}}
    mr:a     {margin-right: auto}
    mb       {margin-bottom: {|}}
    mb:a     {margin-bottom: auto}
    ml       {margin-left: {|}}
    ml:a     {margin-left: auto}
    p        {padding: {|}}
    pt       {padding-top: {|}}
    pr       {padding-right: {|}}
    pb       {padding-bottom: {|}}
    pl       {padding-left: {|}}
    bxz      {box-sizing: {|border-box}}
    bxz:cb   {box-sizing: content-box}
    bxz:bb   {box-sizing: border-box}
    bxsh     {box-shadow: {|inset} {|hoff} {|voff} {|blur} {|color}}
    bxsh:r   {box-shadow: {|inset} {|hoff} {|voff} {|blur} {|spread} rgb({|0}, {|0}, {|0})}
    bxsh:ra  {box-shadow: {|inset} {|h} {|v} {|blur} {|spread} rgba({|0}, {|0}, {|0}, {|.5})}
    bxsh:n   {box-shadow: none}
    w        {width: {|}}
    w:a      {width: auto}
    h        {height: {|}}
    h:a      {height: auto}
    maw      {max-width: {|}}
    maw:n    {max-width: none}
    mah      {max-height: {|}}
    mah:n    {max-height: none}
    miw      {min-width: {|}}
    mih      {min-height: {|}}
    f        {font: {|}}
    f+       {font: {|1em} {|Arial,sans-serif}}
    fw       {font-weight: {|}}
    fw:n     {font-weight: none}
    fw:b     {font-weight: bold}
    fw:br    {font-weight: bolder}
    fw:lr    {font-weight: lighter}
    fs       {font-style: {|italic}}
    fs:n     {font-style: normal}
    fs:i     {font-style: italic}
    fs:o     {font-style: oblique}
    fv       {font-variant: {|}}
    fv:sc    {font-variant: small-caps}
    fz       {font-size: {|}}
    fza      {font-size-adjust: {|}}
    fza:n    {font-size-adjust: none}
    ff       {font-family: {|}}
    ff:s     {font-family: serif}
    ff:ss    {font-family: sans-serif}
    ff:c     {font-family: cursive}
    ff:f     {font-family: fantasy}
    ff:m     {font-family: monospace}
    ff:a     {font-family: Arial, "Helvetica Neue", Helvetica, sans-serif}
    fef      {font-effect: {|}}
    fef:n    {font-effect: none}
    fef:eg   {font-effect: engrave}
    fef:eb   {font-effect: emboss}
    fef:o    {font-effect: outline}
    fem      {font-emphasize: {|}}
    femp     {font-emphasize-position: {|}}
    femp:b   {font-emphasize-position: before}
    femp:a   {font-emphasize-position: after}
    fems     {font-emphasize-style: {|}}
    fems:n   {font-emphasize-style: none}
    fems:ac  {font-emphasize-style: accent}
    fems:dt  {font-emphasize-style: dot}
    fems:c   {font-emphasize-style: circle}
    fems:ds  {font-emphasize-style: disc}
    fsm      {font-smooth: {|}}
    fsm:a    {font-smooth: auto}
    fsm:n    {font-smooth: never}
    fsm:aw   {font-smooth: always}
    fst      {font-stretch: {|}}
    fst:n    {font-stretch: normal}
    fst:uc   {font-stretch: ultra-condensed}
    fst:ec   {font-stretch: extra-condensed}
    fst:c    {font-stretch: condensed}
    fst:sc   {font-stretch: semi-condensed}
    fst:se   {font-stretch: semi-expanded}
    fst:e    {font-stretch: expanded}
    fst:ee   {font-stretch: extra-expanded}
    fst:ue   {font-stretch: ultra-expanded}
    va       {vertical-align: top}
    va:sup   {vertical-align: super}
    va:t     {vertical-align: top}
    va:tt    {vertical-align: text-top}
    va:m     {vertical-align: middle}
    va:bl    {vertical-align: baseline}
    va:b     {vertical-align: bottom}
    va:tb    {vertical-align: text-bottom}
    va:sub   {vertical-align: sub}
    ta       {text-align: {|left}}
    ta:l     {text-align: left}
    ta:c     {text-align: center}
    ta:r     {text-align: right}
    ta:j     {text-align: justify}
    ta-lst   {text-align-last: {|}}
    tal:a    {text-align-last: auto}
    tal:l    {text-align-last: left}
    tal:c    {text-align-last: center}
    tal:r    {text-align-last: right}
    td       {text-decoration: {|none}}
    td:n     {text-decoration: none}
    td:u     {text-decoration: underline}
    td:o     {text-decoration: overline}
    td:l     {text-decoration: line-through}
    te       {text-emphasis: {|}}
    te:n     {text-emphasis: none}
    te:ac    {text-emphasis: accent}
    te:dt    {text-emphasis: dot}
    te:c     {text-emphasis: circle}
    te:ds    {text-emphasis: disc}
    te:b     {text-emphasis: before}
    te:a     {text-emphasis: after}
    th       {text-height: {|}}
    th:a     {text-height: auto}
    th:f     {text-height: font-size}
    th:t     {text-height: text-size}
    th:m     {text-height: max-size}
    ti       {text-indent: {|}}
    ti:-     {text-indent: -9999px}
    tj       {text-justify: {|}}
    tj:a     {text-justify: auto}
    tj:iw    {text-justify: inter-word}
    tj:ii    {text-justify: inter-ideograph}
    tj:ic    {text-justify: inter-cluster}
    tj:d     {text-justify: distribute}
    tj:k     {text-justify: kashida}
    tj:t     {text-justify: tibetan}
    to       {text-outline: {|}}
    to+      {text-outline: 0 0 #000}
    to:n     {text-outline: none}
    tr       {text-replace: {|}}
    tr:n     {text-replace: none}
    tt       {text-transform: {|uppercase}}
    tt:n     {text-transform: none}
    tt:c     {text-transform: capitalize}
    tt:u     {text-transform: uppercase}
    tt:l     {text-transform: lowercase}
    tw       {text-wrap: {|}}
    tw:n     {text-wrap: normal}
    tw:no    {text-wrap: none}
    tw:u     {text-wrap: unrestricted}
    tw:s     {text-wrap: suppress}
    tsh      {text-shadow: {|hoff} {|voff} {|blur} {|#000}}
    tsh:r    {text-shadow: {|h} {|v} {|blur} rgb({|0}, {|0}, {|0})}
    tsh:ra   {text-shadow: {|h} {|v} {|blur} rgb({|0}, {|0}, {|0}, {|.5})}
    tsh+     {text-shadow: {|0} {|0} {|0} {|#000}}
    tsh:n    {text-shadow: none}
    lh       {line-height: {|}}
    lts      {letter-spacing: {|}}
    whs      {white-space: {|}}
    whs:n    {white-space: normal}
    whs:p    {white-space: pre}
    whs:nw   {white-space: nowrap}
    whs:pw   {white-space: pre-wrap}
    whs:pl   {white-space: pre-line}
    whsc     {white-space-collapse: {|}}
    whsc:n   {white-space-collapse: normal}
    whsc:k   {white-space-collapse: keep-all}
    whsc:l   {white-space-collapse: loose}
    whsc:bs  {white-space-collapse: break-strict}
    whsc:ba  {white-space-collapse: break-all}
    wob      {word-break: {|}}
    wob:n    {word-break: normal}
    wob:k    {word-break: keep-all}
    wob:l    {word-break: loose}
    wob:bs   {word-break: break-strict}
    wob:ba   {word-break: break-all}
    wos      {word-spacking: {|}}
    wow      {word-wrap: {|}}
    wow:nm   {word-wrap: normal}
    wow:n    {word-wrap: none}
    wow:u    {word-wrap: unrestricted}
    wow:s    {word-wrap: suppress}
    wow:b    {word-wrap: break-word}
    bg       {background: {|}}
    bg+      {background: {|#fff} url({|}) {|0} {|0} {|no-repeat}}
    bg:n     {background: none}
    bgc      {background-color: {|#fff}}
    bgc:t    {background-color: transparent}
    bgi      {background-image: url({|})}
    bgi:n    {background-image: none}
    bgr      {background-repeat: {|}}
    bgr:n    {background-repeat: no-repeat}
    bgr:x    {background-repeat: repeat-x}
    bgr:y    {background-repeat: repeat-y}
    bgr:sp   {background-repeat: space}
    bgr:rd   {background-repeat: round}
    bga      {background-attachment: {|}}
    bga:f    {background-attachment: fixed}
    bga:s    {background-attachment: scroll}
    bgp      {background-position: {|0} {|0}}
    bgpx     {background-position-x: {|}}
    bgpy     {background-position-y: {|}}
    bgbk     {background-break: {|}}
    bgbk:bb  {background-break: bounding-box}
    bgbk:eb  {background-break: each-box}
    bgbk:c   {background-break: continuous}
    bgcp     {background-clip: {|padding-box}}
    bgcp:bb  {background-clip: border-box}
    bgcp:pb  {background-clip: padding-box}
    bgcp:cb  {background-clip: content-box}
    bgcp:nc  {background-clip: no-clip}
    bgo      {background-origin: {|}}
    bgo:pb   {background-origin: padding-box}
    bgo:bb   {background-origin: border-box}
    bgo:cb   {background-origin: content-box}
    bgsz     {background-size: {|}}
    bgsz:a   {background-size: auto}
    bgsz:ct  {background-size: contain}
    bgsz:cv  {background-size: cover}
    c        {color: {|#000}}
    c:r      {color: rgb({|0}, {|0}, {|0})}
    c:ra     {color: rgb({|0}, {|0}, {|0}, {|.5})}
    op       {opacity: {|}}
    cnt      {content: '{|}'}
    cnt:n    {content: normal}
    ct:n     {content: normal}
    cnt:oq   {content: open-quote}
    ct:oq    {content: open-quote}
    cnt:noq  {content: no-open-quote}
    ct:noq   {content: no-open-quote}
    cnt:cq   {content: close-quote}
    ct:cq    {content: close-quote}
    cnt:ncq  {content: no-close-quote}
    ct:ncq   {content: no-close-quote}
    cnt:a    {content: attr({|})}
    ct:a     {content: attr({|})}
    cnt:c    {content: counter({|})}
    ct:c     {content: counter({|})}
    cnt:cs   {content: counters({|})}
    ct:cs    {content: counters({|})}
    ct       {content: {|}}
    q        {quotes: {|}}
    q:n      {quotes: none}
    q:ru     {quotes: '\00AB' '\00BB' '\201E' '\201C'}
    q:en     {quotes: '\201C' '\201D' '\2018' '\2019'}
    coi      {counter-increment: {|}}
    cor      {counter-reset: {|}}
    ol       {outline: {|}}
    ol:n     {outline: none}
    olo      {outline-offset: {|}}
    olw      {outline-width: {|}}
    ols      {outline-style: {|}}
    olc      {outline-color: #{|000}}
    olc:i    {outline-color: invert}
    tbl      {table-layout: {|}}
    tbl:a    {table-layout: auto}
    tbl:f    {table-layout: fixed}
    cps      {caption-side: {|}}
    cps:t    {caption-side: top}
    cps:b    {caption-side: bottom}
    ec       {empty-cells: {|}}
    ec:s     {empty-cells: show}
    ec:h     {empty-cells: hide}
    bd       {border: {|}}
    bd+      {border: {|1px} {|solid} {|#000}}
    bd:n     {border: none}
    bdbk     {border-break: {|close}}
    bdbk:c   {border-break: close}
    bdcl     {border-collapse: {|}}
    bdcl:c   {border-collapse: collapse}
    bdcl:s   {border-collapse: separate}
    bdc      {border-color: #{|000}}
    bdc:t    {border-color: transparent}
    bdi      {border-image: url({|})}
    bdi:n    {border-image: none}
    bdti     {border-top-image: url({|})}
    bdti:n   {border-top-image: none}
    bdri     {border-right-image: url({|})}
    bdri:n   {border-right-image: none}
    bdbi     {border-bottom-image: url({|})}
    bdbi:n   {border-bottom-image: none}
    bdli     {border-left-image: url({|})}
    bdli:n   {border-left-image: none}
    bdci     {border-corner-image: url({|})}
    bdci:n   {border-corner-image: none}
    bdci:c   {border-corner-image: continue}
    bdtli    {border-top-left-image: url({|})}
    bdtli:n  {border-top-left-image: none}
    bdtli:c  {border-top-left-image: continue}
    bdtri    {border-top-right-image: url({|})}
    bdtri:n  {border-top-right-image: none}
    bdtri:c  {border-top-right-image: continue}
    bdbri    {border-bottom-right-image: url({|})}
    bdbri:n  {border-bottom-right-image: none}
    bdbri:c  {border-bottom-right-image: continue}
    bdbli    {border-bottom-left-image: url({|})}
    bdbli:n  {border-bottom-left-image: none}
    bdbli:c  {border-bottom-left-image: continue}
    bdf      {border-fit: {|repeat}}
    bdf:c    {border-fit: clip}
    bdf:r    {border-fit: repeat}
    bdf:sc   {border-fit: scale}
    bdf:st   {border-fit: stretch}
    bdf:ow   {border-fit: overwrite}
    bdf:of   {border-fit: overflow}
    bdf:sp   {border-fit: space}
    bdlen    {border-length: {|}}
    bdlen:a  {border-length: auto}
    bdsp     {border-spacing: {|}}
    bds      {border-style: {|}}
    bds:n    {border-style: none}
    bds:h    {border-style: hidden}
    bds:dt   {border-style: dotted}
    bds:ds   {border-style: dashed}
    bds:s    {border-style: solid}
    bds:db   {border-style: double}
    bds:dtds {border-style: dot-dash}
    bds:dtdtds {border-style: dot-dot-dash}
    bds:w      {border-style: wave}
    bds:g      {border-style: groove}
    bds:r      {border-style: ridge}
    bds:i      {border-style: inset}
    bds:o      {border-style: outset}
    bdw        {border-width: {|}}
    bdt        {border-top: {|}}
    bt         {border-top: {|}}
    bdt+       {border-top: {|1px} {|solid} {|#000}}
    bdt:n      {border-top: none}
    bdtw       {border-top-width: {|}}
    bdts       {border-top-style: {|}}
    bdts:n     {border-top-style: none}
    bdtc       {border-top-color: #{|000}}
    bdtc:t     {border-top-color: transparent}
    bdr        {border-right: {|}}
    br         {border-right: {|}}
    bdr+       {border-right: {|1px} {|solid} {|#000}}
    bdr:n      {border-right: none}
    bdrw       {border-right-width: {|}}
    bdrst      {border-right-style: {|}}
    bdrst:n    {border-right-style: none}
    bdrc       {border-right-color: #{|000}}
    bdrc:t     {border-right-color: transparent}
    bdb        {border-bottom: {|}}
    bb         {border-bottom: {|}}
    bdb+       {border-bottom: {|1px} {|solid} {|#000}}
    bdb:n      {border-bottom: none}
    bdbw       {border-bottom-width: {|}}
    bdbs       {border-bottom-style: {|}}
    bdbs:n     {border-bottom-style: none}
    bdbc       {border-bottom-color: #{|000}}
    bdbc:t     {border-bottom-color: transparent}
    bdl        {border-left: {|}}
    bl         {border-left: {|}}
    bdl+       {border-left: {|1px} {|solid} {|#000}}
    bdl:n      {border-left: none}
    bdlw       {border-left-width: {|}}
    bdls       {border-left-style: {|}}
    bdls:n     {border-left-style: none}
    bdlc       {border-left-color: #{|000}}
    bdlc:t     {border-left-color: transparent}
    bdrs       {border-radius: {|}}
    bdtrrs     {border-top-right-radius: {|}}
    bdtlrs     {border-top-left-radius: {|}}
    bdbrrs     {border-bottom-right-radius: {|}}
    bdblrs     {border-bottom-left-radius: {|}}
    lis        {list-style: {|}}
    lis:n      {list-style: none}
    lisp       {list-style-position: {|}}
    lisp:i     {list-style-position: inside}
    lisp:o     {list-style-position: outside}
    list       {list-style-type: {|}}
    list:n     {list-style-type: none}
    list:d     {list-style-type: disc}
    list:c     {list-style-type: circle}
    list:s     {list-style-type: square}
    list:dc    {list-style-type: decimal}
    list:dclz  {list-style-type: decimal-leading-zero}
    list:lr    {list-style-type: lower-roman}
    list:ur    {list-style-type: upper-roman}
    lisi       {list-style-image: {|}}
    lisi:n     {list-style-image: none}
    pgbb       {page-break-before: {|}}
    pgbb:au    {page-break-before: auto}
    pgbb:al    {page-break-before: always}
    pgbb:l     {page-break-before: left}
    pgbb:r     {page-break-before: right}
    pgbi       {page-break-inside: {|}}
    pgbi:au    {page-break-inside: auto}
    pgbi:av    {page-break-inside: avoid}
    pgba       {page-break-after: {|}}
    pgba:au    {page-break-after: auto}
    pgba:al    {page-break-after: always}
    pgba:l     {page-break-after: left}
    pgba:r     {page-break-after: right}
    orp        {orphans: {|}}
    wid        {widows: {|}}
    !          {!important}
    anim       {animation: {|}}
    anim-      {animation: {|name} {|duration} {|timing-function} {|delay} {|iteration} {|direction} {|fill-mode}}
    animdel    {animation-delay: {|time}}
    animdir    {animation-direction: {|normal}}
    animdir:a  {animation-direction: alternate}
    animdir:ar {animation-direction: alternate-reverse}
    animdir:n  {animation-direction: normal}
    animdir:r  {animation-direction: reverse}
    animdur    {animation-duration: {|0}s}
    animfm     {animation-fill-mode: {|both}}
    animfm:b   {animation-fill-mode: backwards}
    animfm:bt  {animation-fill-mode: both}
    animfm:bh  {animation-fill-mode: both}
    animfm:f   {animation-fill-mode: forwards}
    animic     {animation-iteration-count: {|1}}
    animic:i   {animation-iteration-count: infinite}
    animn      {animation-name: {|none}}
    animps     {animation-play-state: {|running}}
    animps:p   {animation-play-state: paused}
    animps:r   {animation-play-state: running}
    animtf     {animation-timing-function: {|linear}}
    animtf:cb  {animation-timing-function: cubic-bezier({|0.1}, {|0.7}, {|1.0}, {|0.1})}
    animtf:e   {animation-timing-function: ease}
    animtf:ei  {animation-timing-function: ease-in}
    animtf:eio {animation-timing-function: ease-in-out}
    animtf:eo  {animation-timing-function: ease-out}
    animtf:l   {animation-timing-function: linear}
    ap         {appearance: ${none}}
    bg:ie      {filter:progid:DXImateTransform.Microsoft.AlphaImageLoader(src='{|x}.png', sizingMethod='{|crop}')}
    cm         {/* {|}${child} */}
    colm       {columns: {|}}
    colmc      {column-count: {|}}
    colmf      {column-fill: {|}}
    colmg      {column-gap: {|}}
    colmr      {column-rule: {|}}
    colmrc     {column-rule-color: {|}}
    colmrs     {column-rule-style: {|}}
    colmrw     {column-rule-width: {|}}
    colms      {column-span: {|}}
    colmw      {column-width: {|}}
    mar        {max-resolution: {|res}}
    mir        {min-resolution: {|res}}
    op:ie      {filter:progid:DXImageTransform.Microsoft.Alpha(Opacity=100)}
    op:ms      {-ms-filter:'progid:DXImageTransform.Microsoft.Alpha(Opacity=100)'}
    ori        {orientation: {|}}
    ori:l      {orientation: landscape}
    ori:p      {orientation: portrait}
    tov        {text-overflow: ${ellipsis}}
    tov:c      {text-overflow: clip}
    tov:e      {text-overflow: ellipsis}
    trf        {transform: {|}}
    trf:r      {transform: rotate({|angle})}
    trf:sc     {transform: scale({|x}, {|y})}
    trf:scx    {transform: scaleX({|x})}
    trf:scy    {transform: scaleY({|y})}
    trf:skx    {transform: skewX({|angle})}
    trf:sky    {transform: skewY({|angle})}
    trf:t      {transform: translate({|x}, {|y})}
    trf:tx     {transform: translateX({|x})}
    trf:ty     {transform: translateY({|y})}
    trfo       {transform-origin: {|}}
    trfs       {transform-style: {|preserve-3d}}
    trs        {transition: {|prop} {|time}}
    trsde      {transition-delay: {|time}}
    trsdu      {transition-duration: {|time}}
    trsp       {transition-property: {|prop}}
    trstf      {transition-timing-function: {|tfunc}}
    us         {user-select: ${none}}
    wfsm       {-webkit-font-smoothing: ${antialiased}}
    wfsm:a     {-webkit-font-smoothing: antialiased}
    wfsm:n     {-webkit-font-smoothing: none}
    wfsm:s     {-webkit-font-smoothing: subpixel-antialiased}
    wfsm:sa    {-webkit-font-smoothing: subpixel-antialiased}
  }

  array set vendor_props {
    accelerator                {s}
    accesskey                  {o}
    animation                  {wo}
    animation-delay            {wmo}
    animation-direction        {wmo}
    animation-duration         {wmo}
    animation-fill-mode        {wmo}
    animation-iteration-count  {wmo}
    animation-name             {wmo}
    animation-play-state       {wmo}
    animation-timing-function  {wmo}
    appearance                 {wm}
    backface-visibility        {wms}
    background-clip            {wm}
    background-composite       {w}
    background-inline-policy   {m}
    background-origin          {w}
    background-position-y      {s}
    background-size            {w}
    behavior                   {s}
    binding                    {m}
    block-progression          {s}
    border-bottom-colors       {m}
    border-fit                 {w}
    border-horizontal-spacing  {w}
    border-image               {wmo}
    border-left-colors         {m}
    border-radius              {wm}
    border-right-colors        {m}
    border-top-colors          {m}
    border-vertical-spacing    {w}
    box-align                  {wms}
    box-direction              {wms}
    box-flex                   {wms}
    box-flex-group             {w}
    box-line-progression       {s}
    box-lines                  {ws}
    box-ordinal-group          {wms}
    box-orient                 {wms}
    box-pack                   {wms}
    box-reflect                {w}
    box-shadow                 {wm}
    box-sizing                 {wm}
    color-correction           {w}
    column-break-after         {w}
    column-break-before        {w}
    column-break-inside        {w}
    column-count               {wm}
    column-gap                 {wm}
    column-rule-color          {wm}
    column-rule-style          {wm}
    column-rule-width          {wm}
    column-span                {w}
    column-width               {wm}
    content-zoom-boundary      {s}
    content-zoom-boundary-max  {s}
    content-zoom-boundary-min  {s}
    content-zoom-chaining      {s}
    content-zoom-snap          {s}
    content-zoom-snap-points   {s}
    content-zoom-snap-type     {s}
    content-zooming            {s}
    dashboard-region           {wo}
    filter                     {s}
    float-edge                 {m}
    flow-from                  {s}
    flow-into                  {s}
    font-feature-settings      {ms}
    font-language-override     {m}
    font-smooting              {w}
    force-broken-image-icon    {m}
    grid-column                {s}
    grid-column-align          {s}
    grid-column-span           {s}
    grid-columns               {s}
    grid-layer                 {s}
    grid-row                   {s}
    grid-row-align             {s}
    grid-row-span              {s}
    grid-rows                  {s}
    high-contrast-adjust       {s}
    highlight                  {w}
    hyphenate-character        {w}
    hyphenate-limit-after      {w}
    hyphenate-limit-before     {w}
    hyphenate-limit-chars      {s}
    hyphenate-limit-lines      {s}
    hyphenate-limit-zone       {s}
    hyphens                    {wms}
    image-region               {m}
    ime-mode                   {s}
    input-format               {o}
    input-required             {o}
    interpolation-mode         {s}
    layout-flow                {s}
    layout-grid                {s}
    layout-grid-char           {s}
    layout-grid-line           {s}
    layout-grid-mode           {s}
    layout-grid-type           {s}
    line-box-contain           {w}
    line-break                 {ws}
    line-clamp                 {w}
    link                       {o}
    link-source                {o}
    locale                     {w}
    margin-after-collapse      {w}
    margin-before-collapse     {w}
    marquee-dir                {o}
    marquee-direction          {w}
    marquee-increment          {w}
    marquee-loop               {o}
    marquee-repetition         {w}
    marquee-speed              {o}
    marquee-style              {wo}
    mask-attachment            {w}
    mask-box-image             {w}
    mask-box-image-outset      {w}
    mask-box-image-repeat      {w}
    mask-box-image-slice       {w}
    mask-box-image-source      {w}
    mask-box-image-width       {w}
    mask-clip                  {w}
    mask-composite             {w}
    mask-image                 {w}
    mask-origin                {w}
    mask-position              {w}
    mask-repeat                {w}
    mask-size                  {w}
    nbsp-mode                  {w}
    object-fit                 {o}
    object-position            {o}
    orient                     {m}
    outline-radius-bottomleft  {m}
    outline-radius-bottomright {m}
    outline-radius-topleft     {m}
    outline-radius-topright    {m}
    overflow-style             {s}
    perspective                {wms}
    perspective-origin         {wms}
    perspective-origin-x       {s}
    perspective-origin-y       {s}
    rtl-ordering               {w}
    scroll-boundary            {s}
    scroll-boundary-bottom     {s}
    scroll-boundary-left       {s}
    scroll-boundary-right      {s}
    scroll-boundary-top        {s}
    scroll-chaining            {s}
    scroll-rails               {s}
    scroll-snap-points-x       {s}
    scroll-snap-points-y       {s}
    scroll-snap-type           {s}
    scroll-snap-x              {s}
    scroll-snap-y              {s}
    scrollbar-arrow-color      {s}
    scrollbar-base-color       {s}
    scrollbar-darkshadow-color {s}
    scrollbar-face-color       {s}
    scrollbar-highlight-color  {s}
    scrollbar-shadow-color     {s}
    scrollbar-track-color      {s}
    stack-sizing               {m}
    svg-shadow                 {w}
    tab-size                   {mo}
    table-baseline             {o}
    text-align-last            {s}
    text-autospace             {s}
    text-blink                 {m}
    text-combine               {w}
    text-decoration-color      {m}
    text-decoration-line       {m}
    text-decoration-style      {m}
    text-decorations-in-effect {w}
    text-emphasis-color        {w}
    text-emphasis-position     {w}
    text-emphasis-style        {w}
    text-fill-color            {w}
    text-justify               {s}
    text-kashida-space         {s}
    text-orientation           {w}
    text-security              {w}
    text-size-adjust           {ms}
    text-stroke-color          {w}
    text-stroke-width          {w}
    text-overflow              {s}
    text-underline-position    {s}
    touch-action               {s}
    transform                  {wmso}
    transform-origin           {wmso}
    transform-origin-x         {s}
    transform-origin-y         {s}
    transform-origin-z         {s}
    transform-style            {wms}
    transition                 {wmso}
    transition-delay           {wmso}
    transition-duration        {wmso}
    transition-property        {wmso}
    transition-timing-function {wmso}
    user-drag                  {w}
    user-focus                 {m}
    user-input                 {m}
    user-modify                {wm}
    user-select                {wms}
    window-shadow              {m}
    word-break                 {s}
    wrap-flow                  {s}
    wrap-margin                {s}
    wrap-through               {s}
    writing-mode               {ws}

  }

  array set unitless {
    z-index:     1
    line-height: 1
    opacity:     1
    font-weight: 1
  }

  array set prefixes {
    w -webkit-
    m -moz-
    s -ms-
    o -o-
  }

  ######################################################################
  # Parses the given Emmet string and returns the generated code version.
  proc parse {str} {

    set lines [list]
    set line  [list]

    # Set the string to lowercase
    set str [string tolower $str]

    while {[string length $str] > 0} {
      if {[regexp {^-([wmso]+)-([a-z:]+\+?|[a-z]+:-)(.*)$} $str -> prefix word str]} {
        lappend line word $word prefix $prefix
      } elseif {[regexp {^-([a-z:]+\+?|[a-z]+:-)(.*)$} $str -> word str]} {
        lappend line hyphen 1 word $word
      } elseif {[regexp {^([a-z:]+\+?|[a-z]+:-)(.*)$} $str -> word str]} {
        lappend line word $word
      } elseif {[regexp {^(-?[0-9]+\.[0-9]+)(.*)$} $str -> num str]} {
        lappend line float $num
      } elseif {[regexp {^(-?[0-9]+)(.*)$} $str -> num str]} {
        lappend line number $num
      } elseif {[regexp {^#([0-9a-fA-F]+)(.*)$} $str -> color str]} {
        switch [string length $color] {
          1 { lappend line color #[string repeat $color 6] }
          2 { lappend line color #[string repeat $color 3] }
          3 { lappend line color #[string repeat [string index $color 0] 2][string repeat [string index $color 1] 2][string repeat [string index $color 2] 2] }
          6 { lappend line color #$color }
        }
      } elseif {[regexp {^!(.*)$} $str -> str]} {
        lappend line important {}
      } else {
        if {$line ne [list]} {
          lappend lines [generate_line $line]
        }
        set line [list]
        set str  [string range $str 1 end]
      }
    }

    if {$line ne ""} {
      lappend lines [generate_line $line]
    }

    return [join $lines \n]

  }

  ######################################################################
  # Returns the CSS that is generates from the given line list.
  proc generate_line {line_list} {

    variable lookup
    variable unitless
    variable prefixes
    variable vendor_props

    # puts "In generate_line, line_list: $line_list"

    set line          [list]
    set important     0
    set command       ""
    set val           ""
    set suffix        ""
    set suffix_needed 0
    set prefix_list   [list]
    set hyphen        0

    foreach {type value} $line_list {
      switch $type {
        number -
        float {
          set val $value
          if {($command eq "") || ![info exists unitless([lindex $command 0])]} {
            set suffix        [expr {($type eq "number") ? "px" : "em"}]
            set suffix_needed 1
          } elseif {$command eq ""} {
            lappend line $val
          } else {
            set command [insert_value $command $val]
          }
        }
        hyphen {
          set hyphen 1
        }
        prefix {
          set prefix_list [list]
          foreach prefix [split $value {}] {
            if {[info exists prefixes($prefix)]} {
              lappend prefix_list $prefixes($prefix)
            }
          }
        }
        word {
          if {$suffix_needed} {
            switch $value {
              p       { set suffix "%" }
              e       { set suffix "em" }
              x       { set suffix "ex" }
              default { set suffix $value }
            }
            set suffix_needed 0
            if {$command ne ""} {
              set command [insert_value $command $val$suffix]
            } else {
              lappend line $value$suffix
            }
          } elseif {[info exists lookup($value)]} {
            set command $lookup($value)
            set value   [string range [lindex $command 0] 0 end-1]
            if {[info exists vendor_props($value)]} {
              set default_prefix $vendor_props($value)
            } elseif {$hyphen} {
              set default_prefix "wmso"
            } else {
              set default_prefix ""
            }
            foreach prefix [split $default_prefix {}] {
              lappend prefix_list $prefixes($prefix)
            }
          } elseif {$command ne ""} {
            set command [insert_value $command $value]
          } else {
            lappend line $value
          }
        }
        color {
          if {$suffix_needed} {
            set command       [insert_value $command $val$suffix]
            set suffix_needed 0
          }
          set command [insert_value $command $value]
        }
        important {
          set important 1
        }
      }
    }

    if {$suffix_needed} {
      if {$command ne ""} {
        set command [insert_value $command $val$suffix]
      }
    } else {
      lappend line $val$suffix
    }

    if {$important} {
      if {$command ne ""} {
        set command [insert_value $command "!important"]
      } else {
        lappend line "!important"
      }
    }

    if {$command ne ""} {
      set index 1
      while {[regexp {(.*?)\{\|(.*?)\}(.*)$} $command -> before value after]} {
        if {$value eq ""} {
          set command "$before\$$index$after"
        } else {
          set command "$before\${$index:$value}$after"
        }
        incr index
      }
      set lines [list]
      lappend prefix_list ""
      foreach prefix $prefix_list {
        lappend lines "$prefix$command;"
      }
      return [join $lines \n]
    } else {
      return "$line;"
    }

  }

  ######################################################################
  # Inserts the given value into the given command list.
  proc insert_value {command value} {

    if {[regexp {^(.*)\{\|.*?\}(.*)$} $command -> before after]} {
      return $before$value$after
    }

    return "$command $value"

  }

}
