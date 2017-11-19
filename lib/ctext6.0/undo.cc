/*!
 \file     undo.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
*/

#include "undo.h"

using namespace std;
using namespace Tcl;

void undo_change::render(
  object & result
) const {

  interpreter i( result.get_interp(), false );
  object      item1, item2;

  /* Render the insertion/deletion command */
  if( _type == UNDO_TYPE_INSERT ) {
    item1.append( i, (object)"insert" );
    item1.append( i, (object)tindex_to_string( _startpos ) );
    item1.append( i, (object)_str );
  } else {
    item1.append( i, (object)"delete" );
    item1.append( i, (object)tindex_to_string( _startpos ) );
    item1.append( i, (object)tindex_to_string( _endpos ) );
  }
  result.append( i, item1 );

  /* Render the cursor positioning */
  item2.append( i, (object)"mark" );
  item2.append( i, (object)"set" );
  item2.append( i, (object)"insert" );
  item2.append( i, (object)tindex_to_string( _cursor ) );
  result.append( i, item2 );

}

/* --------------------------------------------------- */

object undo_group::render() {

  object      result;
  interpreter i( result.get_interp(), false );
  undo_group  tmp = *this;

  /* Clear ourselves */
  clear_group();

  /*
   Move all of the items from the copied list back to ourselves, inverting
   the data in the process.
  */
  while( tmp.back() ) {
    tmp.back()->render( result );
    tmp.back()->invert_type();
    push_back( tmp.back() );
    tmp.pop_back();
  }

  return( result );

}

void undo_group::cursor_history(
  object & result
) const {

  interpreter i( result.get_interp(), false );

  for( vector<undo_change*>::const_reverse_iterator it=rbegin(); it!=rend(); it++ ) {
    result.append( i, (object)tindex_to_string( (*it)->cursor() ) );
  }

}

/* --------------------------------------------------- */

object undo_buffer::cursor_history() const {

  object result;

  for( vector<undo_group*>::const_reverse_iterator it=rbegin(); it!=rend(); it++ ) {
    (*it)->cursor_history( result );
  }

  return( result );

}

/* --------------------------------------------------- */

void undo_manager::add_change(
  int    type,
  object startpos,
  object endpos,
  object str,
  object cursor,
  object mcursor
) {
  
  interpreter interp( startpos.get_interp(), false );
  tindex      spos  = object_to_tindex( startpos );
  tindex      epos  = object_to_tindex( endpos );
  string      text  = str.get<string>( interp );
  tindex      cur   = object_to_tindex( cursor );
  bool        multi = mcursor.get<bool>( interp );
  
  /* If we don't have a current change group, create it now */
  if( _uncommitted == 0 ) {
    _uncommitted = new undo_group();
    _redo_buffer.clear_buffer();
  }
  
  /* Add the change to the list */
  _uncommitted->push_back( new undo_change( type, spos, epos, text, cur, multi ) );
  
}

void undo_manager::add_separator() {

  if( _uncommitted ) {
    _undo_buffer.push_back( _uncommitted );
    _uncommitted = 0;
  }

}

object undo_manager::undo() {
  
  object result;
  
  /* If we have uncommited changes, commit them now */
  if( _uncommitted ) {
    add_separator();
  }
 
  /* Only act on the undo buffer if there is something in it */
  if( _undo_buffer.back() ) {

    /* Render the undo result */
    result = _undo_buffer.back()->render();

    /* Push the undo buffer changes to the redo buffer */
    _redo_buffer.push_back( _undo_buffer.back() );

    /* Pop the undo buffer */
    _undo_buffer.pop_back();
    
  }
  
  return( result );
  
}
    
object undo_manager::redo() {
  
  object result;

  if( _redo_buffer.back() ) {

    /* Generate the redo result */
    result = _redo_buffer.back()->render();

    /* Push the redo buffer changes to the undo buffer */
    _undo_buffer.push_back( _redo_buffer.back() );

    /* Remove the top-most entry from the redo buffer */
    _redo_buffer.pop_back();

  }

  return( result );

}
    
object undo_manager::cursor_history() const {
  
  return( _undo_buffer.cursor_history() );
  
}

