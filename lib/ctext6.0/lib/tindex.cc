/*!
 \file     tindex.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
*/

#include "tindex.h"

using namespace std;
using namespace Tcl;

tindex::tindex(
  const object & obj
) {

  interpreter i( obj.get_interp(), false );
  string      value  = obj.get<string>( i );
  int         period = value.find( "." );

  /* If the period cannot be found, throw an error */
  if( period == string::npos ) {
    throw runtime_error( "Specified index is not in a.b format" );
  }

  /* Populate the tindex */
  _row = atoi( value.substr( 0, (period + 1) ).c_str() );
  _col = atoi( value.substr( (period + 1) ).c_str() );

}

