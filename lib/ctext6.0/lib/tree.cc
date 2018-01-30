 /*!
 \file     tree.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include "tree.h"
#include "types.h"

using namespace std;
using namespace Tcl;

tree::~tree() {

  /* Destroy the tree */
  delete _tree;

}

void tree::clear() {

  /* Clear the tree */
  _tree->clear();

}

void tree::insert_item(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item,
  const types & typs
) {

  tnode* node;

  /* Calculate the starting index and if it is escaped, skip the insertion */
  if( item.pos().compare( lescape ) == 0 ) {
    return;
  }

  /* If the current node is root, add a new node as a child */
  if( current == _tree ) {
    switch( item.side() ) {
      case 0 :  insert_none(       current, lescape, item, typs );  break;
      case 1 :  insert_root_left(  current, lescape, item );  break;
      case 2 :  insert_root_right( current, lescape, item );  break;
      case 3 :  insert_root_any(   current, lescape, item );  break;
    }

  } else if( !typs.is_comstr( current->type() ) || (current->type() & item.type()) || (item.side() == 0) ) {
    switch( item.side() ) {
      case 0 :  insert_none(  current, lescape, item, typs );  break;
      case 1 :  insert_left(  current, lescape, item );  break;
      case 2 :  insert_right( current, lescape, item );  break;
      case 3 :  insert_any(   current, lescape, item );  break;
    }
  }

}

void tree::insert_root_left(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  add_child_node( current, true, item );

}

void tree::insert_root_right(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  tnode* node = current;

  add_child_node( current, false, item );

  current = node;

}

void tree::insert_root_any(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  add_child_node( current, true, item );

}

void tree::insert_left(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  add_child_node( current, true, item );

}

void tree::insert_right(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  if( current->type() & item.type() ) {
    current->right( &item );
    item.set_node( current );
    current = current->parent();

  } else {

    tnode* tn = current;

    /* Check to see if the matching left already exists */
    while( (tn = tn->parent()) != _tree ) {
      if( tn->type() & item.type() ) {
        tn->right( &item );
        item.set_node( tn );
        current = current->parent();
        return;
      }
    }

    /*
     If we didn't find it going up, add the item below it but keep
     the current node the current node
    */
    add_child_node( current, false, item );

  }

}

void tree::insert_any(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  if( current->type() & item.type() ) {
    current->right( &item );
    item.set_node( current );
    current = current->parent();
  } else {
    add_child_node( current, true, item );
  }

}

void tree::insert_none(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item,
  const types & typs
) {

  if( item.type() & typs.type( "escape" ) ) {
    lescape = tindex( item.pos().row(), item.pos().start_col() + 1 );
  }

}

void tree::add_child_node(
  tnode*      & current,
  bool          left,
  serial_item & item
) {

  tnode* n = new tnode( item.type() );

  /* Initialize the node */
  if( left ) {
    n->left( &item );
  } else {
    n->right( &item );
  }

  current->add_child( n );
  current = n;

  /* Save the node pointer in the serial list item */
  item.set_node( n );

}

void tree::update(
  serial      & sl,
  const types & typs
) {

  tnode* current = _tree;
  tindex lescape = {0, 0};

  /* Clear the tree */
  _tree->clear();

  for( int i=0; i<sl.size(); i++ ) {
    insert_item( current, lescape, *(sl[i]), typs );
  }

}

void tree::folds_set_indent(
  linemap & lmap,
  int       line,
  int       depth
) {

  string line_type = lmap.get( "folding", line );

  if( line_type == "" ) {
    lmap.set( "folding", "open", line );
  } else if( line_type == "end" ) {
    lmap.set( "folding", "", line );
  }

}

void tree::folds_set_unindent(
  linemap & lmap,
  int       line
) {

  string line_type = lmap.get( "folding", line );

  if( line_type == "" ) {
    lmap.set( "folding", "end", line );
  } else if( line_type == "open" ) {
    lmap.set( "folding", "", line );
  }

}

void tree::add_folds_helper(
  linemap     & lmap,
  tnode*        node,
  int           depth,
  const types & typs
) {

  vector<tnode*> & children = node->children();

  /* If the node is an indent type, set the indent/unindent in the linemap */
  if( typs.is_indent( node->type() ) && node->left() ) {
    folds_set_indent( lmap, node->left()->const_pos().row(), ++depth );
    if( node->right() ) {
      folds_set_unindent( lmap, node->right()->const_pos().row() );
    }
  }

  /* Do the same for all children */
  for( vector<tnode*>::const_iterator it=children.begin(); it!=children.end(); it++ ) {
    add_folds_helper( lmap, *it, depth, typs );
  }

}

void tree::add_folds(
  linemap     & lmap,
  const types & typs
) {

  vector<tnode*> & children = _tree->children();

  /* Clear the folding gutter */
  lmap.clear( "folding" );

  for( vector<tnode*>::const_iterator it=children.begin(); it!=children.end(); it++ ) {
    add_folds_helper( lmap, *it, 0, typs );
  }

}

object tree::is_in_index(
  const string & type,
  bool           inner,
  const tindex & ti,
  const types  & typs
) const {

  const tnode*           node;
  const vector<tnode*> & children = _tree->const_children();
  object                 retval;
  object                 range;
  interpreter            interp( retval.get_interp(), false );
  bool                   found = false;

  for( vector<tnode*>::const_iterator it=children.begin(); it!=children.end(); it++ ) {
    if( (node = (*it)->get_node_containing( ti )) ) {
      if( (found = node->is_in_type( type, typs )) ) {
        if( inner ) {
          range.append( interp, (object)node->left()->const_pos().to_tindex( false ).to_string() );
          range.append( interp, (object)node->right()->const_pos().to_tindex( true ).to_string() );
        } else {
          range.append( interp, (object)node->left()->const_pos().to_tindex( true ).to_string() );
          range.append( interp, (object)node->right()->const_pos().to_tindex( false ).to_string() );
        }
      }
      break;
    }
  }

  /* Indicate that the range was not found */
  retval.append( interp, range );
  retval.append( interp, (object)found );

  return( retval );

}

