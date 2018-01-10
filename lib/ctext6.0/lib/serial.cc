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
      for( vector<serial_item*>::iterator it=(begin() + start.index()); it!=(begin() + end_index); it++ ) {
        _context_removed |= (*it)->iscontext();
        delete *it;
      }
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
      for( vector<serial_item*>::iterator it=(begin() + start.index()); it!=(begin() + end_index); it++ ) {
        _context_removed |= (*it)->iscontext();
        delete *it;
      }
      erase( (begin() + start.index()), (begin() + end_index) );
    }

    last = start;

  }

}

void serial::append(
  const object & item,
  const types  & typs
) {

  interpreter interp( item.get_interp(), false );

  int size = item.length( interp );

  for( int i=0; i<size; i++ ) {
    push_back( new serial_item( item.at( interp, i ), typs ) );
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
  const tindex & ti,
  const types  & typs
) const {

  sindex si = get_index( ti );

  if( (ti.col() == 0) || (si.index() == 0) || (si.matches() && (ti.col() != (*this)[si.index()]->pos().start_col())) ) {
    return( false );
  }

  serial_item* prev_item = (*this)[si.index()-1];

  return( (prev_item->type() == typs.get( "escape" )) &&
          ((prev_item->pos().start_col() + 1) == ti.col()) );

}

bool serial::is_index(
  const string & type,
  const tindex & ti,
  const types  & typs
) const {

  sindex si = get_index( ti );

  if( si.matches() ) {
    return( (*this)[si.index()]->type() == typs.get( type ) );
  }

  return( false );

}

object serial::get_comment_markers(
  const Tcl::object & ranges,
  const types       & typs
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

int serial::next_startindex(
  const tindex & ti
) const {

  sindex si = get_index( ti );

  return( (!si.matches() || (*this)[si.index()]->pos().compare( ti )) ? si.index() : (si.index() + 1) );

}

int serial::next_endindex(
  const tindex & ti
) const {

  sindex si = get_index( ti );

  return( (!si.matches() || (*this)[si.index()]->pos().matches_tindex( ti )) ? (si.index() + 1) : si.index() );

}

int serial::prev_startindex(
  const tindex & ti
) const {

  sindex si = get_index( ti );

  return( (!si.matches() || (*this)[si.index()]->pos().matches_tindex( ti )) ? (si.index() - 1) : si.index() );

}

int serial::prev_endindex(
  const tindex & ti
) const {

  sindex si = get_index( ti );

  return( (!si.matches() || (*this)[si.index()]->pos().matches_tindex( ti )) ? si.index() : (si.index() - 1) );

}

int serial::nextindex(
  const tindex &   start,
  const type_data* type
) const {

  int ei = size();

  for( int i=next_startindex( start ); i<ei; i++ ) {
    if( (*this)[i]->type() == type ) {
      return( i );
    }
  }

  return( -1 );

}

int serial::nextindex(
  const tindex &   start,
  const tindex &   end,
  const type_data* type
) const {

  int ei = next_endindex( end );

  for( int i=next_startindex( start ); i<ei; i++ ) {
    if( (*this)[i]->type() == type ) {
      return( i );
    }
  }

  return( -1 );

}

int serial::nextindex_indent(
  const tindex & start,
  int            side,
  const types  & typs
) const {

  int ei = size();

  for( int i=next_startindex( start ); i<ei; i++ ) {
    if( (*this)[i]->matches_indent( side, typs ) ) {
      return( i );
    }
  }

  return( -1 );

}

int serial::nextindex_indent(
  const tindex & start,
  const tindex & end,
  int            side,
  const types  & typs
) const {

  int ei = next_endindex( end );

  for( int i=next_startindex( start ); i<ei; i++ ) {
    if( (*this)[i]->matches_indent( side, typs ) ) {
      return( i );
    }
  }

  return( -1 );

}

int serial::previndex_reindentStart(
  const tindex & start,
  const types  & typs
) const {

  for( int i=prev_startindex( start ); i>=0; i-- ) {
    if( typs.is_reindentStart( (*this)[i]->type() ) ) {
      return( i );
    }
  }

  return( -1 );

}

int serial::previndex_reindent(
  const tindex & start,
  const types  & typs
) const {

  for( int i=prev_startindex( start ); i>=0; i-- ) {
    if( typs.is_reindent( (*this)[i]->type() ) ) {
      return( i );
    }
  }

  return( -1 );

}

int serial::previndex_reindent(
  const tindex & start,
  const tindex & end,
  const types  & typs
) const {

  int ei = prev_endindex( end );

  for( int i=prev_startindex( start ); i>=ei; i-- ) {
    if( typs.is_reindent( (*this)[i]->type() ) ) {
      return( i );
    }
  }

  return( -1 );

}

int serial::previndex_indent(
  const tindex & start,
  int            side,
  const types  & typs
) const {

  for( int i=prev_startindex( start ); i>=0; i-- ) {
    if( (*this)[i]->matches_indent( side, typs ) ) {
      return( i );
    }
  }

  return( -1 );

}

int serial::previndex_indent(
  const tindex & start,
  const tindex & end,
  int            side,
  const types  & typs
) const {

  int ei = prev_endindex( end );

  for( int i=prev_startindex( start ); i>=ei; i-- ) {
    if( (*this)[i]->matches_indent( side, typs ) ) {
      return( i );
    }
  }

  return( -1 );

}

bool serial::is_unindent_after_reindent (
  const tindex & ti,
  const types  & typs
) const {

  int rs, ri;

  if( (rs = previndex_reindentStart( ti, typs )) != -1 ) {

    /* If the starting reindent is also an indent, return 1 (TBD - Not sure if this is relevant) */
    // if {[lsearch [$txtt tag names $spos] _indent*] != -1} {
    //  return 2
    //}

    /* Get the starting position of the previous reindent string */
    if( ((ri = previndex_reindent( ti, typs )) != -1) && (ri > rs) ) {

      int index;

      /* Find the indent symbol that is just after the reindentStart symbol */
      return( ((index = nextindex_indent( (*this)[rs]->pos().to_tindex(), get_side( "left" ), typs )) != -1) && (index < ri) );

    }

  }

  return( false );

}

bool serial::line_contains_indentation(
  const tindex & ti,
  const types  & typs
) const {

  tindex te( ti.row(), 0 );
  int    ii, ui;

  if( (ii = previndex_indent( ti, te, get_side( "left" ), typs ) ) != -1 ) {
    return( ((ui = previndex_indent( ti, te, get_side( "right" ), typs )) == -1) || (ii > ui) );
  }

  return( previndex_reindent( ti, te, typs ) != -1 );

}

object serial::indent_newline(
  const object & prev_ti,
  const object & first_ti,
  const object & indent_space,
  const object & shift_width,
  const types  & typs
) const {

  interpreter interp( first_ti.get_interp(), false );
  tindex prev( prev_ti );
  tindex first( first_ti );
  int    space       = indent_space.get<int>( interp );
  int    shift       = shift_width.get<int>( interp );
  sindex first_index = get_index( first );
  bool   add_nl      = false;
  object retval;

  /* If the previous line indicates an indentation is required */
  if( line_contains_indentation( prev, typs ) ) {
    space += shift;
  }

  /* If the first index matches a stored value, interrogate it */
  if( first_index.matches() ) {

    /*
     Remove any leading whitespace and update indentation level
     (if the first non-whitespace char is a closing bracket)
    */
    if( (*this)[first_index.index()]->matches_indent( get_side( "right" ), typs ) ) {
      space -= shift;
      add_nl = true;

    /*
     Otherwise, if the first non-whitepace characters match a reindent pattern, lessen the
     indentation by one
    */
    } else if( typs.is_reindent( (*this)[first_index.index()]->type() ) && is_unindent_after_reindent( first, typs ) ) {
      space -= shift;
    }

  }

  /* Construct the return value */
  retval.append( interp, (object)(space - first.col()) );
  retval.append( interp, (object)add_nl );
  return( retval );

}

object serial::indent_check_unindent(
  const object & first_ti,
  const object & curr_ti,
  const types  & typs
) const {

  interpreter interp( curr_ti.get_interp(), false );
  tindex   first( first_ti );
  tindex   curr( curr_ti );
  position pos;
  object   retval;
  int      type;

  /* If the cursor is at the beginning of the line, return immediately */
  if( curr.col() == 0 ) {
    return( retval );
  }

  tindex ti( curr.row(), (curr.col() - 1) );
  sindex index = get_index( ti );

  /* If we did not match something in the serial list, return immediately */
  if( !index.matches() ) {
    return( retval );
  }

  const serial_item* item = (*this)[index.index()];

  /*
   If the current line contains an unindent expression, is not within a comment or string,
   and is preceded in the line by only whitespace, replace the whitespace with the proper
   indentation whitespace.
  */
  if( item->matches_indent( get_side( "right" ), typs ) ) {

    /* If the unindent is the first item on the line, continue */
    if( first.col() == item->const_pos().start_col() ) {

      /* Find the matching indentation index */
      if( item->const_node()->get_match_pos( item, pos ) ) {
        retval.append( interp, (object)pos.to_index() );
        retval.append( interp, (object)0 );
      } else {
        retval.append( interp, curr_ti );
        retval.append( interp, (object)0 );
      }

    }

  /* If we just finished editing a reindentation which is not the first, we will also unindent */
  } else if( typs.is_reindent( item->type() ) &&
             (type = is_unindent_after_reindent( item->const_pos().to_tindex(), typs )) ) {

    /* If the reindent is the first item on the line, continue */
    if( first.col() == item->const_pos().start_col() ) {

      if( type == 1 ) {

        ostringstream oss;
        bool reindent_not_in_prev_line = previndex_reindent( tindex( curr.row(), 0 ), tindex( (curr.row() - 1), 0 ), typs ) == -1;

        retval.append( interp, (object)oss.str() );
        retval.append( interp, (object)reindent_not_in_prev_line );

      } else {

        int reindent_start = previndex_reindentStart( ti, typs );

        retval.append( interp, (object)(*this)[reindent_start]->pos().to_index() );
        retval.append( interp, (object)0 );

      }

    }

  }

  return( retval );

}
