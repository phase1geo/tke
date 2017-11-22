/*!
 \file     tnode.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include <iomanip>

#include "tnode.h"

using namespace std;
using namespace Tcl;

void tnode::clear() {

  for( vector<tnode*>::iterator it=_children.begin(); it!=_children.end(); it++ ) {
    delete *it;
  }

  /* Clear the children list */
  _children.clear();

}

void tnode::get_mismatched(
  object & mismatched
) const {

  /* If we are mismatched, update the object */
  if( incomplete() ) {
    if( _left ) {
      _left->const_pos().to_pair( mismatched );
    } else {
      _right->const_pos().to_pair( mismatched );
    }
  }

  /* Search the children */
  for( vector<tnode*>::const_iterator it=_children.begin(); it!=_children.end(); it++ ) {
    (*it)->get_mismatched( mismatched );
  }

}

bool tnode::get_match_pos(
  const serial_item*   si,
  position           & pos
) const {

  if( _left && (_left == si) ) {
    if( _right ) {
      pos = _right->pos();
      return( true );
    }
  } else if( _left ) {
    pos = _left->pos();
    return( true );
  }

  return( false );

}

int tnode::index() const {

  int i = 0;

  for( vector<tnode*>::const_iterator it=_parent->_children.begin(); it!=_parent->_children.end(); it++ ) {
    if( *it == this ) {
      return( i );
    }
    i++;
  }

  return( -1 );

}

int tnode::depth() const {

  if( isroot() ) {
    return( 0 );
  } else {
    return( _parent->depth() + 1 );
  }

}

int tnode::depth(
  const type_data* type
) const {

  if( isroot() ) {
    return( 0 );
  } else {
    return( _parent->depth() + ((_type == type) ? 1 : 0) );
  }

}

string tnode::to_string() const {

  if( isroot() ) {
    return( "(root)" );
  }

  ostringstream oss;

  oss << "(" << ((_left  == 0) ? "??" : _left->pos().to_index())
      << "-" << ((_right == 0) ? "??" : _right->pos().to_index())
      << " {" <<  _type->name() << "})";

  return( oss.str() );

}

string tnode::tree_string() const {

  ostringstream oss;
  int           width = 30;

  if( !isroot() && (index() > 0) ) {
    oss << setfill(' ') << setw(width * (depth() + 1)) << to_string();
  } else {
    oss << setfill(' ') << setw(width) << to_string();
  }

  if( _children.size() == 0 ) {
    oss << endl;
  } else {
    for( vector<tnode*>::const_iterator it=_children.begin(); it!=_children.end(); it++ ) {
      oss << (*it)->tree_string();
    }
  }

  return( oss.str() );

}

