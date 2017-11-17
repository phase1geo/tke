/*!
 \file     undo.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
*/

#include "undo.h"

void undo_manager::add_insert_change(
  object startpos,
  object str,
  object cursors
) {
  
  interpreter    interp( startpos.get_interp(), false );
  tindex         spos = object_to_tindex( startpos );
  string         text = str.get<string>( interp );
  vector<tindex> cursor_list;
  
  for( int i=0; i<cursors.length( interp ); i++ ) {
    cursor_list.push_back( object_to_tindex( cursors.at( interp, i ) ) );
  }
  
  /* If we don't have a current change group, create it now */
  if( _group == 0 ) {
    _group = new undo_group();
  }
  
  /* Add the change to the list */
  _group->push( new insert_change( spos, text, cursor_list ) );
  
}

void undo_manager::add_delete_change(
  object startpos,
  object endpos,
  object cursors
) {
  
  interpreter    interp( startpos.get_interp(), false );
  tindex         spos = object_to_tindex( startpos );
  tindex         epos = object_to_tindex( endpos );
  vector<tindex> cursor_list;
  
  for( int i=0; i<cursors.length( interp ); i++ ) {
    cursor_list.push_back( object_to_tindex( cursors.at( interp, i ) ) );
  }
  
  /* If we don't have a current change group, create it now */
  if( _group == 0 ) {
    _group = new undo_group();
  }
  
  /* Add the change to the list */
  _group->push( new delete_change( spos, epos, cursor_list ) );
  
}
    
object undo() {
  
  object result;
  
  if( _group ) {
    
    /* Create the return result */
    result = _group->render();
    
    /* Adding the current group to the redo buffer */
    
  } else if( _undo_buffer->top() ) {
    
    /* Create the return result */
    result = _undo_buffer->top()->render();
    
    /* */
    
  }
  
  return( result );
  
}
    
object redo() {
  
  if( _group ) {
    
  } else {
    
  }
  
}
    
object cursor_history() const {
  
  /* TBD */
  
}

