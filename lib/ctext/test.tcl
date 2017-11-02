lappend auto_path [pwd]

package require ctext 6.0

pack [ctext .t] -fill both -expand yes

# Initialize the ctext widget
ctext::initialize .t

ctext::addHighlightClass    .t keywords "red"
ctext::addHighlightKeywords .t {hello trevor} class keywords
ctext::setContextPatterns   .t bcomment comment "" {{{/\*} {\*/}}} "grey"
ctext::setBrackets          .t "" {curly square paren double single} "green"

source model.tcl

proc show_tree {} {

  model::load_all .t
  model::debug_show_tree
  model::destroy .t
  
}