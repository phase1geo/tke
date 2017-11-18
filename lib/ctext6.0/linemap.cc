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

  result.append( interp, (object)_row );
  result.append( interp, (object)((_marker == "") ? "%n" : "%m") );
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
    } else {
      string event;
      if( name == "-onenter" )             { event = "Enter"; }
      else if( name == "-onleave" )        { event = "Leave"; }
      else if( name == "-onclick" )        { event = "Button-1"; }
      else if( name == "-onshiftclick" )   { event = "Shift-Button-1"; }
      else if( name == "-oncontrolclick" ) { event = "Control-Button-1"; }
      else {
        throw runtime_error( "Illegal gutter option " + name );
      }
      map<string,string>::iterator it = _bindings.find( event );
      if( it == _bindings.end() ) {
        _bindings.insert( make_pair( event, value ) );
      } else if( value == "" ) {
        _bindings.erase( it );
      } else {
        it->second = value;
      }
    }
  }

}

Tcl::object linemap_colopts::configure() const {

  object      result;
  interpreter i( result.get_interp(), false );

  result.append( i, (object)"-symbol" );
  result.append( i, (object)_symbol );
  result.append( i, (object)"-fg" );
  result.append( i, (object)_color );
  result.append( i, (object)"-onenter" );
  result.append( i, cget( "-onenter" ) );
  result.append( i, (object)"-onleave" );
  result.append( i, cget( "-onleave" ) );
  result.append( i, (object)"-onclick" );
  result.append( i, cget( "-onclick" ) );
  result.append( i, (object)"-onshiftclick" );
  result.append( i, cget( "-onshiftclick" ) );
  result.append( i, (object)"-oncontrolclick" );
  result.append( i, cget( "-oncontrolclick" ) );

  return( result );

}

Tcl::object linemap_colopts::cget(
  const string & name
) const {

  if( name == "-symbol" ) {
    return( (object)_symbol );
  } else if( name == "-color" ) {
    return( (object)_color );
  } else {
    string event;
    if( name == "-onenter" )             { event = "Enter"; }
    else if( name == "-onleave" )        { event = "Leave"; }
    else if( name == "-onclick" )        { event = "Button-1"; }
    else if( name == "-onshiftclick" )   { event = "Shift-Button-1"; }
    else if( name == "-oncontrolclick" ) { event = "Control-Button-1"; }
    else {
      throw runtime_error( "Illegal gutter option name " + name );
    }
    map<string,string>::const_iterator it = _bindings.find( event );
    if( it == _bindings.end() ) {
      return( (object)"" );
    } else {
      return( (object)(it->second) );
    }
  }

}

Tcl::object linemap_colopts::render(
  Tcl::interpreter & interp
) const {

  object result;
  object bindings;

  for( map<string,string>::const_iterator it=_bindings.begin(); it!=_bindings.end(); it++ ) {
    bindings.append( interp, (object)it->first );
    bindings.append( interp, (object)it->second );
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

  /* Check the option length */
  if( opts.length( interp ) % 2 ) {
    throw runtime_error( "Initializing gutter with odd number of options" );
  }

  /* Save the name of the new gutter */
  _name = name.get<string>( interp );

  /* Save the various options */
  for( int i=0; i<opts.length( interp ); i+=2 ) {
    string           optname  = opts.at( interp, i ).get<string>( interp );
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

void linemap_col::symbols(
  vector<string> & syms
) const {

  for( map<string,linemap_colopts*>::const_iterator it=_opts.begin(); it!=_opts.end(); it++ ) {
    syms.push_back( it->first );
  }

}

const linemap_colopts* linemap_col::get_value(
  const string & sym
) const {

  map<string,linemap_colopts*>::const_iterator it = _opts.find( sym );

  if( it == _opts.end() ) {
    return( 0 );
  } else {
    return( it->second );
  }

}

void linemap_col::clear_value(
  const std::string & sym
) {

  map<string,linemap_colopts*>::const_iterator it = _opts.find( sym );

  if( it != _opts.end() ) {
    delete it->second;
    _opts.erase( it );
  }

}

object linemap_col::cget(
  const string & sym,
  const string & opt
) const {

  map<string,linemap_colopts*>::const_iterator it = _opts.find( sym );

  if( it == _opts.end() ) {
    return( (object)"" );
  } else {
    return( (object)(it->second->cget( opt )) );
  }

}

object linemap_col::configure(
  const string & sym,
  object         opts
) {

  interpreter i( opts.get_interp(), false );

  if( sym.empty() ) {
    object result;
    for( map<string,linemap_colopts*>::iterator it=_opts.begin(); it!=_opts.end(); it++ ) {
      result.append( i, (object)it->first );
      result.append( i, it->second->configure() );
    }
    return( result );
  } else {
    map<string,linemap_colopts*>::iterator it = _opts.find( sym );
    if( it == _opts.end() ) {
      return( (object)"" );
    } else if( opts.get<string>( i ).empty() ) {
      return( it->second->configure() );
    } else {
      it->second->configure( opts );
      return( (object)"" );
    }
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
      } else if( row == _rows[mid]->row() ) {
        return( mid );
      } else if( start == mid ) {
        return( (row > _rows[mid]->row()) ? (mid + 1) : mid );
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

Tcl::object linemap::get_marker(
  object row_obj
) const {

  interpreter i( row_obj.get_interp(), false );
  int         row   = row_obj.get<int>( i );
  int         index = get_row_index( row );

  if( (index == _rows.size()) ||(_rows[index]->row() != row) ) {
    return( (object)"" );
  } else {
    return( (object)(_rows[index]->marker()) );
  }

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
    int sindex = get_row_index( spos.row + ((spos.col > 0) ? 1 : 0) );

    /* Increment the row counts by one */
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
    int adjust = (spos.col > 0) ? 1 : 0;
    int sindex = get_row_index( spos.row + adjust );
    int eindex = get_row_index( epos.row + adjust );

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
  object      cols;

  /* Create a template for rows that are not stored */
  for( int j=0; j<_cols.size(); j++ ) {
    if( !_cols[j]->hidden() ) {
      cols.append( i, (object)"" );
    }
  }

  for( int row=first; row<=last; row++ ) {
    if( (index < _rows.size()) && (_rows[index]->row() == row) ) {
      result.append( i, _rows[index++]->render( i, _cols ) );
    } else {
      object rowobj;
      rowobj.append( i, (object)row );
      rowobj.append( i, (object)"%n" );
      rowobj.append( i, cols );
      result.append( i, rowobj );
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

void linemap::destroy(
  object name
) {

  interpreter i( name.get_interp(), false );
  int         col = get_col_index( name.get<string>( i ) );

  /* If the gutter name cannot be found, just return */
  if( col == -1 ) {
    return;
  }

  /* Delete the gutter column */
  delete _cols[col];
  _cols.erase( _cols.begin() + col );

  /* Remove the column from each row */
  for( vector<linemap_row*>::iterator it=_rows.begin(); it!=_rows.end(); it++ ) {
    (*it)->remove_column( col );
  }

}

bool linemap::hide(
  object name_obj,
  object value_obj
) {

  interpreter interp( name_obj.get_interp(), false );
  int         col   = get_col_index( name_obj.get<string>( interp ) );
  string      value = value_obj.get<string>( interp );

  if( col == -1 ) {
    return( false );
  }

  if( value == "" ) {
    return( _cols[col]->hidden() );
  } else {
    _cols[col]->hidden( value_obj.get<bool>( interp ) );
  }

  return( false );

}

void linemap::delete_symbols(
  Tcl::object name,
  Tcl::object syms
) {

  interpreter interp( name.get_interp(), false );
  int         col = get_col_index( name.get<string>( interp ) );

  /* Return immediately if we could not find the gutter */
  if( col == -1 ) {
    return;
  }

  for( int i=0; i<syms.length( interp ); i++ ) {
    string sym = syms.at( interp, i ).get<string>( interp );
    const linemap_colopts* value = _cols[col]->get_value( sym );
    if( value ) {
      for( int j=0; j<_rows.size(); j++ ) {
        _rows[j]->clear_value( col, value );
      }
    }
    _cols[col]->clear_value( sym );
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

void linemap::unset(
  Tcl::object name_obj,
  Tcl::object first_obj,
  Tcl::object last_obj
) {

  interpreter interp( name_obj.get_interp(), false );
  int         col   = get_col_index( name_obj.get<string>( interp ) );

  /* If the column name doesn't exist, return immediately */
  if( col == -1 ) {
    return;
  }

  int first = first_obj.get<int>( interp );
  int index = get_row_index( first );

  if( last_obj.get<string>( interp ) == "" ) {
    if( _rows[index]->row() == first ) {
      _rows[index]->set_value( col, 0 );
    }
  } else {
    int last_index = get_row_index( last_obj.get<int>( interp ) );
    for( int i=index; i<=last_index; i++ ) {
      _rows[i]->set_value( col, 0 );
    }
  }

}

object linemap::get(
  object name,
  object value,
  object valueisint
) const {

  interpreter interp( name.get_interp(), false );
  int         col = get_col_index( name.get<string>( interp ) );
  object      result;

  /* If we could not find the gutter, return the empty string */
  if( col == -1 ) {
    return( (object)"" );
  }

  string                 val = value.get<string>( interp );
  const linemap_colopts* symbol;

  if( val.empty() ) {

    vector<string> syms;
    _cols[col]->symbols( syms );

    for( vector<string>::iterator it=syms.begin(); it!=syms.end(); it++ ) {
      object lines;
      symbol = _cols[col]->get_value( *it );
      for( int i=0; i<_rows.size(); i++ ) {
        if( _rows[i]->get_value( col ) == symbol ) {
          lines.append( interp, (object)_rows[i]->row() );
        }
      }
      result.append( interp, (object)(*it) );
      result.append( interp, lines );
    }

  } else if( (symbol = _cols[col]->get_value( val )) ) {

    for( int i=0; i<_rows.size(); i++ ) {
      if( _rows[i]->get_value( col ) == symbol ) {
        result.append( interp, (object)_rows[i]->row() );
      }
    }

  } else if( valueisint.get<bool>( interp ) ){

    try {
      vector<string> syms;
      int            row   = value.get<int>( interp );
      int            index = get_row_index( row );

      if( (index < _rows.size()) && (_rows[index]->row() == row) ) {
        symbol = _rows[index]->get_value( col );
        _cols[col]->symbols( syms );
        for( vector<string>::iterator it=syms.begin(); it!=syms.end(); it++ ) {
          if( _cols[col]->get_value( *it ) == symbol ) {
            return( (object)(*it) );
          }
        }
      }
    } catch( exception & e ) {}

  }

  return( result );

}

object linemap::cget(
  object name,
  object symbol,
  object option
) const {

  interpreter i( name.get_interp(), false );
  int         col = get_col_index( name.get<string>( i ) );
  string      opt = option.get<string>( i );
  object      result;

  if( col == -1 ) {
    return( (object)"" );
  }

  /* Get the options */
  return( _cols[col]->cget( symbol.get<string>( i ), option.get<string>( i ) ) );

}

object linemap::configure(
  object name,
  object symbol,
  object opts
) {

  interpreter i( name.get_interp(), false );
  int         col = get_col_index( name.get<string>( i ) );

  if( col == -1 ) {
    return( (object)"" );
  }

  return( _cols[col]->configure( symbol.get<string>( i ), opts ) );

}

object linemap::names() const {

  object      result;
  interpreter i( result.get_interp(), false );

  for( vector<linemap_col*>::const_iterator it=_cols.begin(); it!=_cols.end(); it++ ) {
    result.append( i, (object)((*it)->name()) );
  }

  return( result );

}

