/*!
 \file     undo_group.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
*/

#include "undo_group.h"

using namespace std;
using namespace Tcl;

object undo_group::render(
  serial  & ser,
  linemap & lmap
) {

  object      result;
  object      item1, item2;
  interpreter i( result.get_interp(), false );
  undo_group  tmp( *this );
  tindex      last_cursor;

  /* Clear ourselves */
  clear_group();

  /*
   Move all of the items from the copied list back to ourselves, inverting
   the data in the process.
  */
  while( tmp.size() ) {
    tmp.back()->render( item1, ser, lmap );
    tmp.back()->invert_type();
    last_cursor = tmp.back()->cursor();
    push_back( tmp.back() );
    tmp.pop_back();
  }

  item2.assign( (object)last_cursor.to_string() );

  result.append( i, item1 );
  result.append( i, item2 );

  return( result );

}

void undo_group::cursor_history(
  object & result
) const {

  interpreter i( result.get_interp(), false );

  for( vector<undo_change*>::const_reverse_iterator it=rbegin(); it!=rend(); it++ ) {
    result.append( i, (object)(*it)->cursor().to_string() );
  }

}

