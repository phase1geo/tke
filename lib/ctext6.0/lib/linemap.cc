/*!
 \file     linemap.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
*/

#include "linemap.h"

using namespace std;
using namespace Tcl;

linemap::linemap() {

  _tag_map.insert( make_pair( "open",   0 ) );
  _tag_map.insert( make_pair( "close",  1 ) );
  _tag_map.insert( make_pair( "eopen",  2 ) );
  _tag_map.insert( make_pair( "eclose", 3 ) );
  _tag_map.insert( make_pair( "end",    4 ) );

}

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

int linemap::get_row_index(
  int row
) const {

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

int linemap::get_col_index(
  const string & name
) const {

  for( int i=0; i<_cols.size(); i++ ) {
    if( _cols[i]->name() == name ) {
      return( i );
    }
  }

  return( -1 );

}

void linemap::set_marker(
  const object & row_obj,
  const object & value_obj
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

Tcl::object linemap::get_marker_name(
  const object & row_obj
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

Tcl::object linemap::get_marker_line(
  const object & name_obj
) const {

  interpreter i( name_obj.get_interp(), false );
  string      name = name_obj.get<string>( i );

  /* Find the marker name */
  for( vector<linemap_row*>::const_iterator it=_rows.begin(); it!=_rows.end(); it++ ) {
    if( (*it)->marker() == name ) {
      return( (object)(*it)->row() );
    }
  }

  return( (object)0 );

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
    int    diff = epos.row() - spos.row();

    if( diff == 0 ) {
      continue;
    }

    /* Increment the rows by the number of newlines */
    int sindex = get_row_index( spos.row() + ((spos.col() > 0) ? 1 : 0) );

    /* Increment the row counts by one */
    for( int i=sindex; i<_rows.size(); i++ ) {
      _rows[i]->increment( diff );
    }

  }

}

object linemap::remove(
  const vector<tindex> & ranges
) {

  object      result;
  interpreter interp( result.get_interp(), false );

  for( int i=0; i<ranges.size(); i+=2 ) {

    tindex spos = ranges[i];
    tindex epos = ranges[i+1];
    int    diff = spos.row() - epos.row();

    /* If line numbers have not changed, return immediately */
    if( diff == 0 ) {
      continue;
    }

    /* Calculate the starting and ending indices to remove */
    int adjust = (spos.col() > 0) ? 1 : 0;
    int sindex = get_row_index( spos.row() + adjust );
    int eindex = get_row_index( epos.row() + adjust );

    /* Remove the entries */
    for( int i=sindex; i<eindex; i++ ) {
      result.append( interp, (object)_rows[i]->marker() );
      delete _rows[i];
    }
    _rows.erase( (_rows.begin() + sindex), (_rows.begin() + eindex) );

    /* Adjust */
    for( int i=sindex; i<_rows.size(); i++ ) {
      _rows[i]->increment( diff );
    }

  }

  return( result );

}

object linemap::replace(
  const vector<tindex> & ranges
) {

  object      result;
  interpreter interp( result.get_interp(), false );

  for( int i=0; i<ranges.size(); i+=3 ) {

    tindex spos = ranges[i];
    tindex epos = ranges[i+1];
    tindex npos = ranges[i+2];
    int    diff = (spos.row() - epos.row()) + (npos.row() - spos.row());

    if( diff == 0 ) {
      continue;
    }

    /* Calculate the starting and ending indices to remove */
    int sindex = get_row_index( spos.row() + ((spos.col() > 0) ? 1 : 0) );
    int eindex = get_row_index( epos.row() );

    /* Remove the entries */
    for( int i=sindex; i<eindex; i++ ) {
      result.append( interp, (object)_rows[i]->marker() );
      delete _rows[i];
    }
    _rows.erase( (_rows.begin() + sindex), (_rows.begin() + eindex) );

    /* Adjust */
    for( int i=sindex; i<_rows.size(); i++ ) {
      _rows[i]->increment( diff );
    }

  }

  return( result );

}

object linemap::render(
  const object & first_row,
  const object & last_row
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
  const object & name,
  const object & values
) {

  /* Add the new column to the list of columns */
  _cols.push_back( new linemap_col( name, values ) );

  /* Add the column to each of the existing rows */
  for( vector<linemap_row*>::iterator it=_rows.begin(); it!=_rows.end(); it++ ) {
    (*it)->add_column();
  }

}

void linemap::destroy(
  const object & name
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
  const object & name_obj,
  const object & value_obj
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
  const object & name,
  const object & syms
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
  const object & name_obj,
  const object & values
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

void linemap::set(
  const string & name,
  const string & value,
  int            row
) {

  int col = get_col_index( name );

  if( col == -1 ) {
    return;
  }

  const linemap_colopts* colopts = _cols[col]->get_value( value );
  int                    index   = get_row_index( row );

  if( (index == _rows.size()) || (_rows[index]->row() != row) ) {
    _rows.insert( (_rows.begin() + index), new linemap_row( row, _cols.size() ) );
  }

  _rows[index]->set_value( col, colopts );

}

void linemap::unset(
  const object & name_obj,
  const object & first_obj,
  const object & last_obj
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

void linemap::clear(
  const string & name
) {

  int col = get_col_index( name );

  if( col == -1 ) {
    return;
  }

  /* Clear all rows */
  for( vector<linemap_row*>::iterator it=_rows.begin(); it!=_rows.end(); it++ ) {
    (*it)->set_value( col, 0 );
  }

}

object linemap::get(
  const object & name,
  const object & value,
  const object & valueisint
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

string linemap::get(
  const string & name,
  int            row
) {

  string result( "" );
  int    col = get_col_index( name );

  /* If we could not find the gutter, return the empty string */
  if( col == -1 ) {
    return( "" );
  }

  try {

    const linemap_colopts* symbol;
    vector<string>         syms;
    int                    index = get_row_index( row );

    if( (index < _rows.size()) && (_rows[index]->row() == row) ) {
      symbol = _rows[index]->get_value( col );
      _cols[col]->symbols( syms );
      for( vector<string>::iterator it=syms.begin(); it!=syms.end(); it++ ) {
        if( _cols[col]->get_value( *it ) == symbol ) {
          return( *it );
        }
      }
    }

  } catch( exception & e ) {}

  return( result );

}

object linemap::cget(
  const object & name,
  const object & symbol,
  const object & option
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
  const object & name,
  const object & symbol,
  const object & opts
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

object linemap::fold_delete(
  const object & startline,
  const object & depth_obj
) {

  cout << "In linemap::fold_delete" << endl;

  interpreter interp( startline.get_interp(), false );
  int         col    = get_col_index( "folding" );
  bool        retval = false;
  object      ranges;
  object      result;

  if( col == -1 ) {
    result.append( interp, (object)false );
    return( result );
  }

  cout << "HERE!" << endl;

  tindex line( startline.get<int>( interp ), 0 );
  int    row         = get_row_index( line.row() );
  int    rows        = _rows.size();
  int    depth       = depth_obj.get<int>( interp );
  int    count       = 0;
  int    close_count = 0;
  int    counts[5]   = {1, 1, -1, -1, -1};

  line.inc_row( 1 );
  ranges.append( interp, (object)line.to_string() );

  cout << "  row: " << row << ", depth: " << depth << endl;

  for( int i=row; i<rows; i++ ) {
    const linemap_colopts* value = _rows[i]->get_value( col );
    if( value != 0 ) {
      const string & tag = value->name();
      int            inc = counts[_tag_map.find( tag )->second];
      tindex         line( _rows[i]->row(), 0 );
      cout << "    i: " << i << ", count: " << count << endl;
      if( count < depth ) {
        _rows[i]->set_value( col, 0 );
      } else {
        if( (tag == "close") || (tag == "eclose") ) {
          if( close_count == 0 ) {
            line.inc_row( 1 );
            ranges.append( interp, (object)line.to_string() );
            close_count = count;
          }
        } else if( (tag == "end") && (close_count == (count + inc)) ) {
          ranges.append( interp, (object)line.to_string() );
          close_count = 0;
        }
      }
      if( (count += inc) == 0 ) {
        _rows[i]->set_value( col, 0 );
        ranges.append( interp, (object)line.to_string() );
        retval = true;
        break;
      } else if( count < 0 ) {
        count = 0;
      } else if( (tag == "eopen") || (tag == "eclose") ) {
        count++;
      }
    }
  }

  result.append( interp, (object)retval );
  result.append( interp, ranges );

  return( result );

}

object linemap::fold_delete_range(
  const object & startline,
  const object & endline
) {

  interpreter interp( startline.get_interp(), false );
  int         col    = get_col_index( "folding" );
  bool        retval = false;
  object      ranges;
  object      result;

  if( col == -1 ) {
    result.append( interp, (object)false );
    return( result );
  }

  tindex sline( startline.get<int>( interp ), 0 );
  tindex eline( endline.get<int>( interp ), 0 );
  int    srow      = get_row_index( sline.row() );
  int    rows      = _rows.size();
  int    count     = 0;
  int    counts[5] = {1, 1, -1, -1, -1};

  sline.inc_row( 1 );
  ranges.append( interp, (object)sline.to_string() );

  for( int i=srow; i<rows; i++ ) {
    const linemap_colopts* value = _rows[i]->get_value( col );
    if( value != 0 ) {
      if( (count == 0) && (eline.row() < _rows[i]->row()) ) {
        break;
      }
      const string & tag = value->name();
      int            inc = counts[_tag_map.find( tag )->second];
      tindex         line( _rows[i]->row(), 0 );
      _rows[i]->set_value( col, 0 );
      if( (count += inc) == 0 ) {
        eline  = line;
        retval = true;
      } else if( count < 0 ) {
        count = 0;
      } else if( (tag == "eopen") || (tag == "eclose") ) {
        count++;
      }
    }
  }

  ranges.append( interp, (object)sline.to_string() );
  ranges.append( interp, (object)eline.to_string() );

  result.append( interp, (object)retval );
  result.append( interp, ranges );

  return( result );

}

object linemap::fold_open(
  const object & startline,
  const object & depth_obj
) {

  interpreter interp( startline.get_interp(), false );
  int         col    = get_col_index( "folding" );
  bool        retval = false;
  object      ranges;
  object      result;

  if( col == -1 ) {
    result.append( interp, (object)false );
    return( result );
  }

  tindex                 line( startline.get<int>( interp ), 0 );
  int                    row         = get_row_index( line.row() );
  int                    depth       = depth_obj.get<int>( interp );
  int                    rows        = _rows.size();
  int                    count       = 0;
  int                    close_count = 0;
  const linemap_colopts* open_value  = _cols[col]->get_value( "open" );
  const linemap_colopts* eopen_value = _cols[col]->get_value( "eopen" );
  int                    counts[5]   = {1, 1, -1, -1, -1};

  line.inc_row( 1 );
  ranges.append( interp, (object)line.to_string() );

  for( int i=row; i<rows; i++ ) {
    const linemap_colopts* value = _rows[i]->get_value( col );
    if( value != 0 ) {
      const string & tag = value->name();
      int            inc = counts[_tag_map.find( tag )->second];
      tindex         line( _rows[i]->row(), 0 );
      if( count < depth ) {
        if( tag == "close" ) {
          _rows[i]->set_value( col, open_value );
        } else if( tag == "eclose" ) {
          _rows[i]->set_value( col, eopen_value );
        }
      } else {
        if( (tag == "close") || (tag == "eclose") ) {
          if( close_count == 0 ) {
            line.inc_row( 1 );
            ranges.append( interp, (object)line.to_string() );
            close_count = count;
          }
        } else if( (tag == "end") && (close_count == (count + inc)) ) {
          ranges.append( interp, (object)line.to_string() );
          close_count = 0;
        }
      }
      if( (count += inc) == 0 ) {
        ranges.append( interp, (object)line.to_string() );
        retval = true;
        break;
      } else if( count < 0 ) {
        count = 0;
      } else if( (tag == "eopen") || (tag == "eclose") ) {
        count++;
      }
    }
  }

  if( count != 0 ) {
    ranges.append( interp, (object)"end" );
  }

  result.append( interp, (object)retval );
  result.append( interp, ranges );

  return( result );

}

object linemap::fold_open_range(
  const object & startline,
  const object & endline,
  const object & depth_obj
) {

  interpreter interp( startline.get_interp(), false );
  int         col    = get_col_index( "folding" );
  bool        retval = false;
  object      ranges;
  object      result;

  if( col == -1 ) {
    result.append( interp, (object)false );
    return( result );
  }

  tindex                 sline( startline.get<int>( interp ), 0 );
  tindex                 eline( endline.get<int>( interp ), 0 );
  int                    depth       = depth_obj.get<int>( interp );
  int                    row         = get_row_index( sline.row() );
  int                    rows        = _rows.size();
  int                    count       = 0;
  int                    close_count = 0;
  const linemap_colopts* open_value  = _cols[col]->get_value( "open" );
  const linemap_colopts* eopen_value = _cols[col]->get_value( "eopen" );
  int                    counts[5]   = {1, 1, -1, -1, -1};

  for( int i=row; i<rows; i++ ) {
    const linemap_colopts* value = _rows[i]->get_value( col );
    if( value != 0 ) {
      if( (count == 0) && (eline.row() < _rows[i]->row() ) ) {
        break;
      }
      const string & tag = value->name();
      int            inc = counts[_tag_map.find( tag )->second];
      tindex         line( _rows[i]->row(), 0 );
      if( count < depth ) {
        if( tag == "close" ) {
          _rows[i]->set_value( col, open_value );
        } else if( tag == "eclose" ) {
          _rows[i]->set_value( col, eopen_value );
        }
        if( count == 0 ) {
          line.inc_row( 1 );
          ranges.append( interp, (object)line.to_string() );
        }
      } else {
        if( (tag == "close") || (tag == "eclose") ) {
          if( close_count == 0 ) {
            line.inc_row( 1 );
            ranges.append( interp, (object)line.to_string() );
            close_count = count;
          }
        } else if( (tag == "end") && (close_count == (count + inc)) ) {
          ranges.append( interp, (object)line.to_string() );
          close_count = 0;
        }
      }
      if( (count += inc) == 0 ) {
        ranges.append( interp, (object)line.to_string() );
        retval = true;
      } else if( count < 0 ) {
        count = 0;
      } else if( (tag == "eopen") || (tag == "eclose") ) {
        count++;
      }
    }
  }

  result.append( interp, (object)retval );
  result.append( interp, ranges );

  return( result );

}

object linemap::fold_show_line(
  const object & line
) {

  interpreter interp( line.get_interp(), false );
  int         col = get_col_index( "folding" );
  object      result;

  if( col == -1 ) {
    return( result );
  }

  int row       = get_row_index( line.get<int>( interp ) );
  int count     = 1;
  int counts[5] = {-1, -1, 0, 0, 1};

  for( int i=(row - 1); i>=0; i-- ) {
    const linemap_colopts* value = _rows[i]->get_value( col );
    if( value != 0 ) {
      const string & tag = value->name();
      int            inc = counts[_tag_map.find( tag )->second];
      if( (count += inc) == 0 ) {
        result.append( interp, (object)_rows[i]->row() );
      }
      count = 1;
    }
  }

  return( result );

}

object linemap::fold_close(
  const object & startline,
  const object & depth_obj
) {

  interpreter interp( startline.get_interp(), false );
  int         col    = get_col_index( "folding" );
  bool        retval = false;
  object      ranges;
  object      result;

  if( col == -1 ) {
    result.append( interp, (object)false );
    return( result );
  }

  tindex                 line( startline.get<int>( interp ), 0 );
  int                    row          = get_row_index( line.row() );
  int                    depth        = depth_obj.get<int>( interp );
  int                    rows         = _rows.size();
  int                    count        = 0;
  const linemap_colopts* close_value  = _cols[col]->get_value( "close" );
  const linemap_colopts* eclose_value = _cols[col]->get_value( "eclose" );
  int                    counts[5]    = {1, 1, -1, -1, -1};

  line.inc_row( 1 );
  ranges.append( interp, (object)line.to_string() );

  for( int i=row; i<rows; i++ ) {
    const linemap_colopts* value = _rows[i]->get_value( col );
    if( value != 0 ) {
      const string & tag = value->name();
      int            inc = counts[_tag_map.find( tag )->second];
      tindex         line( _rows[i]->row(), 0 );
      if( count < depth ) {
        if( tag == "open" ) {
          _rows[i]->set_value( col, close_value );
        } else if( tag == "eopen" ) {
          _rows[i]->set_value( col, eclose_value );
        }
      }
      if( (count += inc) == 0 ) {
        ranges.append( interp, (object)line.to_string() );
        retval = true;
        break;
      } else if( count < 0 ) {
        count = 0;
      } else if( (tag == "eopen") || (tag == "eclose") ) {
        count++;
      }
    }
  }

  if( count != 0 ) {
    ranges.append( interp, (object)"end" );
  }

  result.append( interp, (object)retval );
  result.append( interp, ranges );

  return( result );

}

object linemap::fold_close_range(
  const object & startline,
  const object & endline,
  const object & depth_obj
) {

  interpreter interp( startline.get_interp(), false );
  int         col    = get_col_index( "folding" );
  bool        retval = false;
  object      ranges;
  object      result;

  if( col == -1 ) {
    result.append( interp, (object)false );
    return( result );
  }

  tindex                 sline( startline.get<int>( interp ), 0 );
  tindex                 eline( endline.get<int>( interp ), 0 );
  int                    depth        = depth_obj.get<int>( interp );
  int                    row          = get_row_index( sline.row() );
  int                    rows         = _rows.size();
  int                    count        = 0;
  const linemap_colopts* close_value  = _cols[col]->get_value( "close" );
  const linemap_colopts* eclose_value = _cols[col]->get_value( "eclose" );
  int                    counts[5]    = {1, 1, -1, -1, -1};

  for( int i=row; i<rows; i++ ) {
    const linemap_colopts* value = _rows[i]->get_value( col );
    if( value != 0 ) {
      if( (count == 0) && (eline.row() < _rows[i]->row()) ) {
        break;
      }
      const string & tag = value->name();
      int            inc = counts[_tag_map.find( tag )->second];
      tindex         line( _rows[i]->row(), 0 );
      if( count < depth ) {
        if( tag == "open" ) {
          _rows[i]->set_value( col, close_value );
        } else if( tag == "eopen" ) {
          _rows[i]->set_value( col, eclose_value );
        }
        if( count == 0 ) {
          line.inc_row( 1 );
          ranges.append( interp, (object)line.to_string() );
        }
      }
      if( (count += inc) == 0 ) {
        ranges.append( interp, (object)line.to_string() );
        retval = true;
      } else if( count < 0 ) {
        count = 0;
      } else if( (tag == "eopen") || (tag == "eclose") ) {
        count++;
      }
    }
  }

  if( count != 0 ) {
    ranges.append( interp, (object)"end" );
  }

  result.append( interp, (object)retval );
  result.append( interp, ranges );

  return( result );

}

object linemap::fold_find(
  const object & startline,
  const object & dir_obj,
  const object & num_obj
) {

  interpreter interp( startline.get_interp(), false );
  int         sline = startline.get<int>( interp );
  int         row   = get_row_index( sline );
  bool        next  = (dir_obj.get<string>( interp ) == "next");
  int         num   = num_obj.get<int>( interp );
  int         col   = get_col_index( "folding" );
  object      result;

  if( col == -1 ) {
    return( result );
  }

  if( next ) {
    for( int i=row; i<_rows.size(); i++ ) {
      const linemap_colopts* value = _rows[i]->get_value( col );
      if( (value != 0) && (sline < _rows[i]->row()) ) {
        const string & tag = value->name();
        if( tag != "end" ) {
          if( --num == 0 ) {
            result.append( interp, (object)_rows[i]->row() );
            return( result );
          }
        }
      }
    }
  } else {
    for( int i=row; i>=0; i-- ) {
      const linemap_colopts* value = _rows[i]->get_value( col );
      if( (value != 0) && (_rows[i]->row() < sline) ) {
        const string & tag = value->name();
        if( tag != "end" ) {
          if( --num == 0 ) {
            result.append( interp, (object)_rows[i]->row() );
            return( result );
          }
        }
      }
    }
  }

  return( result );

}

