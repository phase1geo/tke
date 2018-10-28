/*!
 \file     position.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include "position.h"

using namespace std;
using namespace Tcl;

position::position(
  const object & item
) {

  interpreter i( item.get_interp(), false );

  if( item.length( i ) == 2 ) {
    _row = item.at( i, 0 ).get<int>( i );
    object cols = item.at( i, 1 );
    if( cols.length( i ) == 2 ) {
      _scol = cols.at( i, 0 ).get<int>( i );
      _ecol = cols.at( i, 1 ).get<int>( i );
    }
  }

}

string position::to_index(
  bool first_col
) const {

  ostringstream oss;

  oss << _row << "." << (first_col ? _scol : (_ecol + 1));

  return( oss.str() );

}

tindex position::to_tindex(
  bool first_col
) const {

  tindex ti( _row, (first_col ? _scol : (_ecol + 1)) );

  return( ti );

}

void position::to_pair(
  object & pair
) const {

  interpreter   i( pair.get_interp(), false );
  ostringstream sindex;
  ostringstream eindex;

  sindex << _row << "." << _scol;
  eindex << _row << "." << (_ecol + 1);

  pair.append( i, object( sindex.str() ) );
  pair.append( i, object( eindex.str() ) );

}

string position::to_string() const {

  ostringstream oss;

  oss << "{" << _row << " {" << _scol << " " << _ecol << "}}";

  return( oss.str() );

}

void position::adjust_first(
  int from_col,
  int to_col,
  int row_diff,
  int col_diff
) {

  if( from_col == _scol ) {
    _scol = to_col;
  }

  _row  += row_diff;
  _ecol += col_diff;

}

void position::adjust(
  int from_row,
  int row_diff,
  int col_diff
) {

  if( from_row == _row ) {
    _scol += col_diff;
    _ecol += col_diff;
  }

  _row += row_diff;

}

