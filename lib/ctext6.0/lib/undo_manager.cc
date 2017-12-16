/*!
 \file     undo_manager.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
*/

#include "undo_manager.h"

using namespace std;
using namespace Tcl;

void undo_manager::add_change(
  const undo_change & change,
  bool                stop_separate
) {

  /* If we don't have a current change group, create it now */
  if( _uncommitted == 0 ) {
    _uncommitted = new undo_group();
    _uncommitted->push_back( new undo_change( change ) );
    _redo_buffer.clear_buffer();

  /* Attempt to merge -- if unsucessful, add it to the back */
  } else if( !_uncommitted->back()->merge( change ) ) {
    if( _auto_separate && !stop_separate ) {
      _undo_buffer.push_back( _uncommitted );
      _uncommitted = new undo_group();
    }
    _uncommitted->push_back( new undo_change( change ) );
  }

}

void undo_manager::add_insertion(
  const vector<tindex> & ranges,
  const object         & str,
  const object         & cursor
) {

  interpreter interp( str.get_interp(), false );
  string      istr      = str.get<string>( interp );
  tindex      cursorpos( cursor );
  bool        mcursor   = ranges.size() > 2;
  int         size      = ranges.size() - 2;
  int         i;

  /* Handle multiple cursors if we have any */
  for( i=0; i<size; i+=2 ) {
    add_change( undo_change( UNDO_TYPE_INSERT, ranges[i], ranges[i+1], istr, cursorpos, mcursor ), true );
  }

  /* Handle the last range */
  add_change( undo_change( UNDO_TYPE_INSERT, ranges[i], ranges[i+1], istr, cursorpos, mcursor ), false );

}

void undo_manager::add_deletion(
  const vector<tindex> & ranges,
  const object         & strs,
  const object         & cursor
) {

  interpreter interp( strs.get_interp(), false );
  tindex      cursorpos( cursor );
  bool        mcursor = ranges.size() > 2;
  int         size    = ranges.size() - 2;
  int         i, j;

  /* Handle multiple cursors if we have any */
  for( i=0, j=0; i<size; i+=2, j++ ) {
    add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+1], strs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), true );
  }

  /* Handle the last change */
  add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+1], strs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), false );

}

void undo_manager::add_replacement(
  const vector<tindex> & ranges,
  const object         & dstrs,
  const object         & istrs,
  const object         & cursor
) {

  interpreter interp( dstrs.get_interp(), false );
  tindex      cursorpos( cursor );
  bool        mcursor = ranges.size() > 3;
  int         size    = ranges.size() - 3;
  int         i, j;

  /* Handle multiple cursors */
  for( i=0, j=0; i<size; i+=3, j++ ) {
    add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+1], dstrs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), true );
    add_change( undo_change( UNDO_TYPE_INSERT, ranges[i], ranges[i+2], istrs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), true );
  }

  /* Handle the last change */
  add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+1], dstrs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), true );
  add_change( undo_change( UNDO_TYPE_INSERT, ranges[i], ranges[i+2], istrs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), false );

}

void undo_manager::add_separator() {

  if( _uncommitted ) {
    _undo_buffer.push_back( _uncommitted );
    _uncommitted = 0;
  }

}

object undo_manager::undo(
  serial  & ser,
  linemap & lmap
) {

  object      result;
  interpreter interp( result.get_interp(), false );

  /* If we have uncommited changes, commit them now */
  if( _uncommitted ) {
    add_separator();
  }

  /* Only act on the undo buffer if there is something in it */
  if( _undo_buffer.size() > 0 ) {

    /* Render the undo result */
    result.append( interp, _undo_buffer.back()->render( ser, lmap ) );

    /* Push the undo buffer changes to the redo buffer */
    _redo_buffer.push_back( _undo_buffer.back() );

    /* Pop the undo buffer */
    _undo_buffer.pop_back();

    if( _undo_buffer.size() ) {
      result.append( interp, (object)_undo_buffer.back()->last_cursor().to_string() );
    } else {
      result.append( interp, (object)tindex( 1, 0 ).to_string() );
    }

  }

  return( result );

}

object undo_manager::redo(
  serial  & ser,
  linemap & lmap
) {

  object      result;
  interpreter interp( result.get_interp(), false );

  if( _redo_buffer.back() ) {

    tindex cursor( _redo_buffer.back()->first_cursor() );

    /* Generate the redo result */
    result.append( interp, _redo_buffer.back()->render( ser, lmap ) );
    result.append( interp, (object)cursor.to_string() );

    /* Push the redo buffer changes to the undo buffer */
    _undo_buffer.push_back( _redo_buffer.back() );

    /* Remove the top-most entry from the redo buffer */
    _redo_buffer.pop_back();

  }

  return( result );

}

void undo_manager::reset() {

  if( _uncommitted ) {
    delete _uncommitted;
    _uncommitted = 0;
  }

  _undo_buffer.clear_buffer();
  _redo_buffer.clear_buffer();

}

