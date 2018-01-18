/*!
 \file     serial_item.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include "serial_item.h"
#include "types.h"

using namespace std;
using namespace Tcl;

serial_item::serial_item(
  const object & item,
  const types  & typs
) : _type    ( 0 ),
    _context ( 0 )
{

  interpreter i( item.get_interp(), false );

  if( item.length( i ) == 5 ) {
    _type      = typs.type( item.at( i, 0 ).get<string>( i ) );
    _side      = get_side( item.at( i, 1 ).get<string>( i ) );
    _pos       = position( item.at( i, 2 ) );
    _iscontext = item.at( i, 3 ).get<bool>( i );
    _node      = 0;
    _context   = typs.type( item.at( i, 4 ).get<string>( i ) );
  }

}

serial_item::serial_item(
  const serial_item & si
) : _type      ( si._type ),
    _side      ( si._side ),
    _pos       ( si._pos ),
    _iscontext ( si._iscontext ),
    _node      ( si._node ),
    _context   ( si._context )
{}

bool serial_item::merge(
  const serial_item & si
) {

  if( (_pos.row() == si.const_pos().row()) && (_pos.start_col() == si.const_pos().start_col()) ) {
    _type |= si.type();
    if( ((_side == 0) || (_side == 3)) && ((si.side() == 1) || (si.side() == 2)) ) {
      _side = si.side();
    }
    return( true );
  }

  return( false );

}

string serial_item::to_string(
  const types & typs
) const {

  ostringstream oss;

  oss << "{" << hex << _type << " (" << typs.names( _type ) << ") " << get_side( _side )
      << " " << _pos.to_string() << " " << _iscontext << " " << _context << "}";

  return( oss.str() );

}

