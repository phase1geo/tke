/*!
 \file     undo_change.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
*/

#include "undo_change.h"

using namespace std;
using namespace Tcl;

void undo_change::render(
  object  & result,
  serial  & ser,
  linemap & lmap
) const {

  interpreter    i( result.get_interp(), false );
  object         item1, item2;
  vector<tindex> vec;

  vec.push_back( _startpos );
  vec.push_back( _endpos );

  item2.append( i, (object)"tag" );
  item2.append( i, (object)"add" );
  item2.append( i, (object)"hl" );

  /* Render the insertion/deletion command */
  if( _type == UNDO_TYPE_DELETE ) {
    item1.append( i, (object)"insert" );
    item1.append( i, (object)_startpos.to_string() );
    item1.append( i, (object)_str );
    item2.append( i, (object)(_startpos.to_string() + " linestart") );
    item2.append( i, (object)(_endpos.to_string()   + " lineend" ) );
    ser.insert( vec );
    lmap.insert( vec );
  } else {
    item1.append( i, (object)"delete" );
    item1.append( i, (object)_startpos.to_string() );
    item1.append( i, (object)_endpos.to_string() );
    item2.append( i, (object)(_startpos.to_string() + " linestart") );
    item2.append( i, (object)(_startpos.to_string() + " lineend" ) );
    ser.remove( vec );
    lmap.remove( vec );
  }

  result.append( i, item1 );
  result.append( i, item2 );

}

bool undo_change::merge(
  const undo_change & uc
) {

  if( _type == UNDO_TYPE_INSERT ) {
    if( (uc._type == UNDO_TYPE_INSERT) &&
         ((_endpos == uc._startpos) || 
          (((_endpos.row() + 1) == uc._startpos.row()) && (uc._startpos.col() == 0) && (_str.back() == '\n'))) ) {
      _endpos = uc._endpos;
      _str   += uc._str;
      return( true );
    } else if( (uc._type == UNDO_TYPE_DELETE) && ((_endpos == uc._endpos) && (_startpos < uc._startpos)) ) {
      int index = 0;
      int start = 0;
      _str    = _str.substr( 0, (_str.size() - uc._str.size()) );
      _endpos = _startpos;
      while( (index = _str.find( "\n", start )) != string::npos ) {
        _endpos = tindex( _endpos.row() + 1, 0 );
        start   = index + 1;
      }
      _endpos = tindex( _endpos.row(), (_endpos.col() + (_str.size() - start)) );
      return( true );
    }
  } else if( _type == UNDO_TYPE_DELETE ) {
    if( (uc._type == UNDO_TYPE_DELETE) && (_startpos == uc._endpos) ) {
      _startpos = uc._startpos;
      _str      = uc._str + _str;
      return( true );
    }
  }

  return( false );

}

