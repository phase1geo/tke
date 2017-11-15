/*!
 \file     linemap.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
*/

#include "linemap.h"

/* -------------------------------------------------------------- */

object linemap_row::render(
  interpreter                & interp,
  const vector<linemap_col*> & cols
) const {

  object result;

  object row;
  for( int i=0; i<_items.size(); i++ ) {
    if( cols[i] && !cols[i]->hidden() ) {
      row.append( interp, _items[i]->render( interp ) );
    }
  }

  result.append( interp, _row );
  result.append( interp, row );

  return( result );

}

/* -------------------------------------------------------------- */

Tcl::object linemap_colopts::render(
  Tcl::interpreter & interp
) const {

  object result;
  object bindings;

  for( map<string,string>::const_iterator it=_bindings.begin(); it!=_bindings.end(); it++ ) {
    object binding;
    binding.append( interp, it->first );
    binding.append( interp, it->second );
    bindings.append( interp, binding );
  }

  result.append( interp, _symbol );
  result.append( interp, _color );
  result.append( interp, bindings );

  return( result );

}

/* -------------------------------------------------------------- */

linemap_col::~linemap_col() {

  for( map<string,linemap_colopts*>::iterator it=_opts.begin(); it!=_opts.end(); it++ ) {
    delete *it;
  }

}

linemap_colopts* linemap_col::get_value(
  const std::string & value
) const {

  map<string,linemap_colopts*>::const_iterator it = _opts.find( value );

  if( it == _opts.end() ) {
    return( 0 );
  } else {
    return( it->second );
  }

}

/* -------------------------------------------------------------- */

linemap::~linemap() {

  /* Deallocate the rows */
  for( vector<linemap_row*>::iterator it=_rows.begin(); it!=_rows.end(); it++ ) {
    delete *it;
  }

  /* Deallocate the columns */
  for( vector<linemap_col*>::iterator it=_cols.begin(); it!=_cols.end(); it++ ) {
    delete *it;
  }

}

int linemap::get_row_index( int row ) const {

  int len = _rows.size();

  /* If the row is before the first row, return 0 */
  if( (len == 0) || (row < _rows[0]->row()) ) {
    return( 0 );

  /* If the row is after the last stored row, return the size of the rows */
  } else if( row > _rows[len-1]->row() ) {
    return( len );

  /* Otherwise, find the position of the item */
  } else {
    int start = 0;
    int end   = len;
    int mid   = end;
    while( (end - start) > 0 ) {
      mid = int( (end - start) / 2 ) + start;
      if( row < _rows[mid]->row() ) {
        end = mid;
      } else if( (row == _rows[mid]->row()) || (start == mid) ) {
        return( mid );
      } else {
        start = mid;
      }
    }
    return( end );
  }

}

int linemap::get_col_index( const std::string & name ) const {

  for( int i=0; i<_cols.size(); i++ ) {
    if( _cols[i]->name() == name ) {
      return( i );
    }
  }

  return( -1 );

}

void linemap::set_item(
  const std::string & name,
  int                 row,
  const std::string & value
) {

  int index = get_row_index( row );

  if( _rows[index]->row() != row ) {
    _rows.insert( (_rows.begin() + index), new linemap_row( _cols.size() ) );
  }

  map<string,linemap_colopts*>::iterator it = _col

  /* Set the row value */
  _rows[index]->set_value( get_col_index( name ), linemap_colopts* );
    void set_value( int col, linemap_colopts* value ) { _items[col] = value; }

}

int linemap::marker_row(
  const std::string & name
) const {

  for( vector<linemap_row*>::iterator it=_rows.begin(); it!=_rows.end(); it++ ) {
    if( (*it)->marker() == name ) {
      return( (*it)->row() );
    }
  }

  return( 0 );

}

object linemap::render(
  object first_row,
  object last_row
) {

  interpreter i( first_row.get_interp(), false );
  int         first = first_row.get<int>( i );
  int         last  = last_row.get<int>( i );
  int         index = get_row_index( first );
  object      result;

  while( _rows[index]->row() <= last ) {
    result.append( i, _rows[index]->render( i, _cols ) );
    index++;
  }

  return( result );

}
