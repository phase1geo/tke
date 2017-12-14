/*!
 \file     serial.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include "serial.h"
#include "types.h"

using namespace std;
using namespace Tcl;

serial::~serial() {

  /* Deallocate memory */
  for( vector<serial_item*>::iterator it=begin(); it!=end(); it++ ) {
    delete *it;
  }

}

void serial::clear() {

  /* Deallocate memory */
  for( vector<serial_item*>::iterator it=begin(); it!=end(); it++ ) {
    delete *it;
  }

  vector<serial_item*>::clear();

}

void serial::adjust(
  const tindex & from,
  const tindex & to,
  const sindex & start,
  const sindex & end
) {

  /* If we are inserting text at the end, there's nothing left to do here */
  if( start.index() == end.index() ) {
    return;
  }

  int col_diff    = to.col() - from.col();
  int row_diff    = to.row() - from.row();
  int start_index = start.index();

  /*
   If the starting index matches the item in the list, we may not have to
   modify the starting column.
  */
  if( start.matches() ) {
    (*this)[start_index++]->adjust_first( from.col(), to.col(), row_diff, col_diff );
  }

  /* Perform the adjustment */
  for( int i=start_index; i<end.index(); i++ ) {
    (*this)[i]->adjust( from.row(), row_diff, col_diff );
  }

}

sindex serial::get_index(
  const tindex & index
) const {

  int len = size();

  /* If the item will be the first item, return it */
  if( (len == 0) || ((*this)[0]->pos().compare( index ) == -1) ) {
    return( sindex( 0, false ) );

  /* If the item will be the last item, return it */
  } else if( (*this)[len-1]->pos().compare( index ) == 1 ) {
    return( sindex( len, false ) );

  /* Otherwise, find the position of the item */
  } else {
    int start = 0;
    int end   = len;
    int mid   = end;
    while( (end - start) > 0 ) {
      mid = int( (end - start) / 2 ) + start;
      switch( (*this)[mid]->pos().compare( index ) ) {
        case -1 :
          end = mid;
          break;
        case  0 :
          return( sindex( mid, true ) );
          break;
        case  1 :
          if( start == mid ) {
            return( sindex( end, false ) );
          } else {
            start = mid;
          }
          break;
      }
    }
    return( sindex( end, false ) );
  }

}

tnode* serial::find_node(
  const tindex & ti
) const {

  sindex si = get_index( ti );
  tnode* a;
  tnode* b;

  /* If the index exceeds the list size, return 0 */
  if( si.index() == size() ) {
    return( 0 );
  }

  /* Find the exact match or the closest on the right */
  if( (b = (*this)[si.index()]->node()) == 0 ) {
    int i = si.index() + 1;
    while( (i < size()) && ((b = (*this)[i]->node()) == 0) ) { i++; }
    if( i == size() ) {
      return( 0 );
    }
  } else if( si.matches() ) {
    return( b );
  }

  /* Find the closest on the left */
  int i = si.index() - 1;
  while( (i >= 0) && ((a = (*this)[i]->node()) == 0) ) { i--; }
  if( i == -1 ) {
    return( 0 );
  }

  /* Figure out which node to return */
  if( (a == b) || (b->parent() == a) ) {
    return( a );
  } else if( a->parent() == b ) {
    return( b );
  } else {
    return( a->parent() );
  }

}

void serial::insert(
  const vector<tindex> & ranges
) {

  sindex last( size(), true );;

  for( int i=0; i<ranges.size(); i+=2 ) {

    /* Find the range indices */
    sindex index = get_index( ranges[i] );

    /* Adjust the indices */
    adjust( ranges[i], ranges[i+1], index, last );

    /* Save the last index */
    last = index;

  }

}

void serial::remove(
  const vector<tindex> & ranges
) {

  sindex last( size(), true );;

  for( int i=0; i<ranges.size(); i+=2 ) {

    sindex start     = get_index( ranges[i] );
    sindex end       = get_index( ranges[i+1] );
    int    end_index = end.index() + ((!end.matches() || ((*this)[end.index()]->pos().start_col() == ranges[i+1].col())) ? 0 : 1);

    /* Adjust the list */
    adjust( ranges[i+1], ranges[i], end, last );

    if( start != end ) {
      for( vector<serial_item*>::iterator it=(begin() + start.index()); it!=(begin() + end_index); it++ ) { delete *it; }
      erase( (begin() + start.index()), (begin() + end_index) );
    }

    last = start;

  }

}

void serial::replace(
  const vector<tindex> & ranges
) {

  sindex last( size(), true );;

  for( int i=0; i<ranges.size(); i+=3 ) {

    sindex start     = get_index( ranges[i] );
    sindex end       = get_index( ranges[i+1] );
    int    end_index = end.index() + ((!end.matches() || ((*this)[end.index()]->pos().start_col() == ranges[i+1].col())) ? 0 : 1);

    /* Adjust the list */
    adjust( ranges[i+1], ranges[i+2], end, last );

    /* Delete the range of items in the serial list */
    if( start != end ) {
      for( vector<serial_item*>::iterator it=(begin() + start.index()); it!=(begin() + end_index); it++ ) { delete *it; }
      erase( (begin() + start.index()), (begin() + end_index) );
    }

    last = start;

  }

}

void serial::append(
  object item
) {

  interpreter interp( item.get_interp(), false );

  int size = item.length( interp );

  for( int i=0; i<size; i++ ) {
    push_back( new serial_item( item.at( interp, i ) ) );
  }

}

string serial::to_string() const {

  ostringstream oss;
  bool          first = true;

  for( vector<serial_item*>::const_iterator it=begin(); it!=end(); it++ ) {
    if( first ) {
      first = false;
    } else {
      oss << " ";
    }
    oss << (*it)->to_string();
  }

  return( oss.str() );

}

string serial::show() const {

  ostringstream oss;
  int           index = 0;

  for( vector<serial_item*>::const_iterator it=begin(); it!=end(); it++ ) {
    oss << index++ << ": " << (*it)->to_string() << endl;
  }

  return( oss.str() );

}

bool serial::update(
  const tindex & linestart,
  const tindex & lineend,
  serial       & elements
) {

  sindex start_index = get_index( linestart );
  sindex end_index   = get_index( lineend );

  if( elements.size() ) {

    /* Delete the range */
    if( start_index != end_index ) {
      for( vector<serial_item*>::iterator it=(begin() + start_index.index()); it!=(begin() + end_index.index()); it++ ) { delete *it; }
      erase( (begin() + start_index.index()), (begin() + end_index.index()) );
    }

    /* Insert the given list */
    int i = start_index.index();
    for( vector<serial_item*>::iterator it=elements.begin(); it!=elements.end(); it++ ) {
      vector<serial_item*>::insert( (begin() + i++), new serial_item( **it ) );
    }

    return( true );

  }

  return( false );

}

void serial::get_context_items(
  serial & items
) const {

  for( vector<serial_item*>::const_iterator it=begin(); it!=end(); it++ ) {
    if( (*it)->iscontext() ) {
      items.push_back( new serial_item( **it ) );
    }
  }

}

bool serial::is_escaped(
  const tindex & ti
) const {

  sindex si = get_index( ti );

  if( (ti.col() == 0) || (si.index() == 0) || (si.matches() && (ti.col() != (*this)[si.index()]->pos().start_col())) ) {
    return( false );
  }

  serial_item* prev_item = (*this)[si.index()-1];

  return( (prev_item->type() == types::staticObject().get( "escape" )) &&
          ((prev_item->pos().start_col() + 1) == ti.col()) );

}

bool serial::is_index(
  const string & type,
  const tindex & ti
) const {

  sindex si = get_index( ti );

  if( type.substr( 0, 2 ) == "in" ) {
    return( (*this)[si.index()]->node()->is_in_type( type.substr( 2 ) ) );
  } else if( si.matches() ) {
    return( (*this)[si.index()]->type() == types::staticObject().get( type ) );
  }

  return( false );

}

object serial::get_comment_markers(
  const Tcl::object & ranges
) const {

  interpreter interp( ranges.get_interp(), false );
  object      result;
  int         size = ranges.length( interp );

  for( int i=0; i<size; i+=2 ) {
    sindex start = get_index( tindex( ranges.at( interp, (i + 0) ) ) );
    sindex end   = get_index( tindex( ranges.at( interp, (i + 1) ) ) );
    for( int j=start.index(); j<end.index(); j++ ) {
      string name( (*this)[j]->type()->name() );
      if(  (name.substr( 0, 9 ) == "bcomment:") ||
          ((name.substr( 0, 9 ) == "lcomment:") && ((*this)[j]->side() == 1)) ) {
        (*this)[j]->const_pos().to_pair( result );
      }
    }
  }

  return( result );

}
