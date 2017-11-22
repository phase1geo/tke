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
  const object & item
) : _type    ( 0 ),
    _context ( 0 )
{

  interpreter i( item.get_interp(), false );

  if( item.length( i ) == 5 ) {
    _type      = types::staticObject().get( item.at( i, 0 ).get<string>( i ) );
    _side      = get_side( item.at( i, 1 ).get<string>( i ) );
    _pos       = position( item.at( i, 2 ) );
    _iscontext = item.at( i, 3 ).get<bool>( i );
    _node      = 0;
    _context   = types::staticObject().get( item.at( i, 4 ).get<string>( i ) );
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

string serial_item::to_string() const {

  ostringstream oss;
  string        context( _context ? _context->name() : "" );

  if( context.empty() || (context.find( " " ) != string::npos) ) {
    context.insert( 0, "{" );
    context.append( "}" );
  }

  oss << "{" << _type->name() << " " << get_side( _side ) << " " << _pos.to_string() << " " << _iscontext << " " << context << "}";

  return( oss.str() );

}

