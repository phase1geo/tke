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

bool undo_change::merge(
  const undo_change & uc
) {

  if( _type == UNDO_TYPE_INSERT ) {
    if( (uc._type == UNDO_TYPE_INSERT) &&
        (((_endpos.row == uc._startpos.row) && (_endpos.col == uc._startpos.col)) ||
         (((_endpos.row + 1) == uc._startpos.row) && (uc._startpos.col == 0) && (_str.back() == '\n'))) ) {
      _endpos.col = uc._endpos.col;
      _str       += uc._str;
      return( true );
    } else if( (uc._type == UNDO_TYPE_DELETE) &&
               ((_endpos.row == uc._endpos.row) && (_endpos.col == uc._endpos.col)) &&
               ((_startpos.row < uc._startpos.row) || ((_startpos.row == uc._startpos.row) && (_startpos.col < uc._startpos.col))) ) {
      int index = 0;
      int start = 0;
      _str.substr( 0, (_str.size() - uc._str.size()) );
      _endpos = _startpos;
      while( (index = _str.find( "\n", start )) != string::npos ) {
        _endpos.row++;
        _endpos.col = 0;
        start = index + 1;
      }
      _endpos.col += (_str.size() - index);
      return( true );
    }
  }

  return( false );

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
  object                 str,
  object                 cursor
) {

  interpreter interp( str.get_interp(), false );
  string      istr      = str.get<string>( interp );
  tindex      cursorpos = object_to_tindex( cursor );
  bool        mcursor   = ranges.size() > 2;
  int         size      = ranges.size() - 2;
  int         i;

  /* Handle multiple cursors if we have any */
  for( i=0; i<size; i+=2 ) {
    add_change( undo_change( UNDO_TYPE_INSERT, ranges[i], ranges[i+1], istr, cursorpos, mcursor ), false );
  }

  /* Handle the last range */
  add_change( undo_change( UNDO_TYPE_INSERT, ranges[i], ranges[i+1], istr, cursorpos, mcursor ), true );

}

void undo_manager::add_deletion(
  const vector<tindex> & ranges,
  object                 strs,
  object                 cursor
) {

  interpreter interp( strs.get_interp(), false );
  tindex      cursorpos = object_to_tindex( cursor );
  bool        mcursor   = ranges.size() > 2;
  int         size      = ranges.size() - 2;
  int         i, j;

  /* Handle multiple cursors if we have any */
  for( i=0, j=0; i<size; i+=2, j++ ) {
    add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+1], strs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), false );
  }

  /* Handle the last change */
  add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+1], strs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), true );

}

void undo_manager::add_replacement(
  const vector<tindex> & ranges,
  object                 dstrs,
  object                 istr,
  object                 cursor
) {

  interpreter interp( dstrs.get_interp(), false );
  string      ins_str   = istr.get<string>( interp );
  tindex      cursorpos = object_to_tindex( cursor );
  bool        mcursor   = ranges.size() > 3;
  int         size      = ranges.size() - 3;
  int         i, j;

  /* Handle multiple cursors */
  for( i=0, j=0; i<size; i+=3, j++ ) {
    add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+1], dstrs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), true );
    add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+2], ins_str, cursorpos, mcursor ), false );
  }

  /* Handle the last change */
  add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+1], dstrs.at( interp, j ).get<string>( interp ), cursorpos, mcursor ), true );
  add_change( undo_change( UNDO_TYPE_DELETE, ranges[i], ranges[i+2], ins_str, cursorpos, mcursor ), true );

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

void undo_manager::reset() {

  if( _uncommitted ) {
    delete _uncommitted;
    _uncommitted = 0;
  }

  _undo_buffer.clear_buffer();
  _redo_buffer.clear_buffer();

}

