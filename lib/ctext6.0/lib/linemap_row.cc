/*!
 \file     linemap_row.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
*/

#include "linemap_row.h"

using namespace std;
using namespace Tcl;

object linemap_row::render(
  interpreter                & interp,
  const vector<linemap_col*> & cols
) const {

  object result;

  object row;
  for( int i=0; i<_items.size(); i++ ) {
    if( cols[i] && !cols[i]->hidden() ) {
      if( _items[i] ) {
        row.append( interp, _items[i]->render( interp ) );
      } else {
        row.append( interp, (object)"" );
      }
    }
  }

  result.append( interp, (object)_row );
  result.append( interp, (object)((_marker == "") ? "%n" : "%m") );
  result.append( interp, row );

  return( result );

}

