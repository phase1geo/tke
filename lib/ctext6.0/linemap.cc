/*!
 \file     linemap.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
*/

#include "linemap.h"

using namespace std;
using namespace Tcl;

/* -------------------------------------------------------------- */

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

  result.append( interp, (object)(_marker != "") );
  result.append( interp, row );

  return( result );

}

/* -------------------------------------------------------------- */

linemap_colopts::linemap_colopts( Tcl::object opts ) : _symbol( "" ), _color( "" ) {

  interpreter interp( opts.get_interp(), false );

  configure( opts );

}

void linemap_colopts::configure( Tcl::object opts ) {

  interpreter interp( opts.get_interp(), false );

  if( opts.length( interp ) % 2 ) {
    throw runtime_error( "Gutter create value not called with option/value pairs" );
  }

  for( int i=0; i<opts.length( interp ); i+=2 ) {
    string name  = opts.at( interp, (i + 0) ).get<string>( interp );
    string value = opts.at( interp, (i + 1) ).get<string>( interp );
    if( name == "-symbol" ) {
      _symbol = value;
    } else if( name == "-fg" ) {
      _color = value;
    } else if( (name == "-onenter") || (name == "-onleave") ||
               (name == "-onclick") || (name == "-onshiftclick") ||
               (name == "-oncontrolclick") ) {
      map<string,string>::iterator it = _bindings.find( name );
      if( it == _bindings.end() ) {
        _bindings.insert( make_pair( name, value ) );
      } else if( value == "" ) {
        _bindings.erase( it );
      } else {
        it->second = value;
      }
    } else {
      throw runtime_error( "Illegal gutter option " + name );
    }
  }

}

Tcl::object linemap_colopts::cget(
  Tcl::object name_obj
) const {

  interpreter interp( name_obj.get_interp(), false );
  string      name = name_obj.get<string>( interp );

  if( name == "-symbol" ) {
    return( (object)_symbol );
  } else if( name == "-color" ) {
    return( (object)_color );
  } else {
    if( (name == "-onenter") || (name == "-onleave") ||
        (name == "-onclick") || (name == "-onshiftclick") ||
        (name == "-oncontrolclick") ) {
      map<string,string>::const_iterator it = _bindings.find( name );
      if( it == _bindings.end() ) {
        return( (object)"" );
      } else {
        return( (object)(it->second) );
      }
    } else {
      throw runtime_error( "Illegal gutter option name " + name );
    }
  }

}

Tcl::object linemap_colopts::render(
  Tcl::interpreter & interp
) const {

  object result;
  object bindings;

  for( map<string,string>::const_iterator it=_bindings.begin(); it!=_bindings.end(); it++ ) {
    object binding;
    binding.append( interp, (object)it->first );
    binding.append( interp, (object)it->second );
    bindings.append( interp, binding );
  }

  result.append( interp, (object)_symbol );
  result.append( interp, (object)_color );
  result.append( interp, bindings );

  return( result );

}

/* -------------------------------------------------------------- */

linemap_col::linemap_col(
  Tcl::object name,
  Tcl::object opts
) : _hidden( false ) {

  interpreter interp( name.get_interp(), false );

  /* Save the name of the new gutter */
  _name = name.get<string>( interp );

  /* Save the various options */
  for( int i=0; i<opts.length( interp ); i+=2 ) {
    string           optname = opts.at( interp, i ).get<string>( interp );
    linemap_colopts* optvalue = new linemap_colopts( opts.at( interp, (i + 1) ) );
    map<string,linemap_colopts*>::iterator it = _opts.find( optname );
    if( it == _opts.end() ) {
      _opts.insert( make_pair( optname, optvalue ) );
    } else {
      delete it->second;
      it->second = optvalue;
    }
  }

}

linemap_col::~linemap_col() {

  for( map<string,linemap_colopts*>::iterator it=_opts.begin(); it!=_opts.end(); it++ ) {
    delete it->second;
  }

}

const linemap_colopts* linemap_col::get_value(
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

void linemap::set_marker(
  object row_obj,
  object value_obj
) {

  interpreter i( row_obj.get_interp(), false );
  int         row    = row_obj.get<int>( i );
  string      value  = value_obj.get<string>( i );
  int         rindex = get_row_index( row );

  /* Add the row if it does not exist */
  if( (rindex == _rows.size()) || (_rows[rindex]->row() != row) ) {
    _rows.insert( (_rows.begin() + rindex), new linemap_row( row, _cols.size() ) );
  }

  _rows[rindex]->set_marker( value );

}

int linemap::marker_row(
  const std::string & name
) const {

  for( vector<linemap_row*>::const_iterator it=_rows.begin(); it!=_rows.end(); it++ ) {
    if( (*it)->marker() == name ) {
      return( (*it)->row() );
    }
  }

  return( 0 );

}

void linemap::insert(
  const vector<tindex> & ranges
) {

  for( int i=0; i<ranges.size(); i+=2 ) {

    tindex spos = ranges[i];
    tindex epos = ranges[i+1];
    int    diff = epos.row - spos.row;

    if( diff == 0 ) {
      continue;
    }

    /* Increment the rows by the number of newlines */
    int sindex = get_row_index( spos.row );
    for( int i=sindex; i<_rows.size(); i++ ) {
      _rows[i]->increment( diff );
    }

  }

}

void linemap::remove(
  const vector<tindex> & ranges
) {

  for( int i=0; i<ranges.size(); i+=2 ) {

    tindex spos = ranges[i];
    tindex epos = ranges[i+1];
    int    diff = spos.row - epos.row;

    /* If line numbers have not changed, return immediately */
    if( diff == 0 ) {
      continue;
    }

    /* Calculate the starting and ending indices to remove */
    int sindex = get_row_index( spos.row + ((spos.col > 0) ? 1 : 0) );
    int eindex = get_row_index( epos.row );

    /* Remove the entries */
    for( int i=sindex; i<eindex; i++ ) { delete _rows[i]; }
    _rows.erase( (_rows.begin() + sindex), (_rows.begin() + eindex) );

    /* Adjust */
    for( int i=sindex; i<_rows.size(); i++ ) {
      _rows[i]->increment( diff );
    }

  }

}

void linemap::replace(
  const vector<tindex> & ranges
) {

  for( int i=0; i<ranges.size(); i+=3 ) {

    tindex spos = ranges[i];
    tindex epos = ranges[i+1];
    tindex npos = ranges[i+2];
    int    diff = (spos.row - epos.row) + (npos.row - spos.row);

    if( diff == 0 ) {
      continue;
    }

    /* Calculate the starting and ending indices to remove */
    int sindex = get_row_index( spos.row + ((spos.col > 0) ? 1 : 0) );
    int eindex = get_row_index( epos.row );

    /* Remove the entries */
    for( int i=sindex; i<eindex; i++ ) { delete _rows[i]; }
    _rows.erase( (_rows.begin() + sindex), (_rows.begin() + eindex) );

    /* Adjust */
    for( int i=sindex; i<_rows.size(); i++ ) {
      _rows[i]->increment( diff );
    }

  }

}

object linemap::render(
  object first_row,
  object last_row
) const {

  interpreter i( first_row.get_interp(), false );
  int         first = first_row.get<int>( i );
  int         last  = last_row.get<int>( i );
  int         index = get_row_index( first );
  object      result;

  for( int row=first; row<=last; row++ ) {
    if( (index < _rows.size()) && (_rows[index]->row() == row) ) {
      result.append( i, _rows[index++]->render( i, _cols ) );
    } else {
      result.append( i, (object)"" );
    }
  }

  return( result );

}

void linemap::create(
  object name,
  object values
) {

  /* Add the new column to the list of columns */
  _cols.push_back( new linemap_col( name, values ) );

  /* Add the column to each of the existing rows */
  for( vector<linemap_row*>::iterator it=_rows.begin(); it!=_rows.end(); it++ ) {
    (*it)->add_column();
  }

}

void linemap::set(
  Tcl::object name_obj,
  Tcl::object values
) {

  interpreter interp( name_obj.get_interp(), false );
  int         col = get_col_index( name_obj.get<string>( interp ) );

  /* If the column name doesn't exist, return immediately */
  if( col == -1 ) {
    return;
  }

  for( int i=0; i<values.length( interp ); i+=2 ) {
    string value = values.at( interp, (i + 0) ).get<string>( interp );
    object rows  = values.at( interp, (i + 1) );
    const linemap_colopts* colopts = _cols[col]->get_value( value );
    for( int j=0; j<rows.length( interp ); j++ ) {
      int row   = rows.at( interp, j ).get<int>( interp );
      int index = get_row_index( row );
      if( (index == _rows.size()) || (_rows[index]->row() != row) ) {
        _rows.insert( (_rows.begin() + index), new linemap_row( row, _cols.size() ) );
      }
      _rows[index]->set_value( col, colopts );
    }
  }

}

object linemap::names() const {

  object      result;
  interpreter i( result.get_interp(), false );

  for( vector<linemap_col*>::const_iterator it=_cols.begin(); it!=_cols.end(); it++ ) {
    result.append( i, (object)((*it)->name()) );
  }

  return( result );

}

