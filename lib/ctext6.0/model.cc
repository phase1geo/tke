/*!
 \file     model.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include "model.h"

void position::adjust_first(
  int from_col,
  int to_col,
  int col_diff
) {

  if( from_col == _scol ) {
    _scol = to_col;
  }

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
  } else {
    _row += row_diff;
  }

}

/* -------------------------------------------------------------- */

void serial::adjust(
  const tindex & from,
  const tindex & to,
  const sindex & start,
  const sindex & end
) {

  /* If we are inserting text at the end, there's nothing left to do here */
  if {start.index == end.index} {
    return
  }

  int col_diff    = to.col - from.col;
  int row_diff    = to.row - from.row;
  int start_index = start.index;

  /*
   If the starting index matches the item in the list, we may not have to
   modify the starting column.
  */
  if( start.matches ) {
    _list[start_index++]->adjust_first( from.col, to.col, col_diff );
  }

  /* Perform the adjustment */
  for( int i=start_index; i<end.index; i++ ) {
    _list[i]->adjust( from.row, row_diff, col_diff );
  }

}

sindex serial::get_index(
  const tindex & index
) {

  sindex retval;
  int    len = _list.size();

  /* Most of the time matches will be false */
  retval.matches = false;

  /* If the item will be the first item, return it */
  if( (len == 0) || (_list[0]->compare( index ) == -1) ) {
    retval.index = 0;
    return( retval );

  /* If the item will be the last item, return it */
  } else if( _list[len-1]->compare( index ) == 1 ) {
    retval.index = len;
    return( retval );

  /* Otherwise, find the position of the item */
  } else {
    int start = 0;
    int end   = len;
    int mid   = end;
    while( (end - start) > 0} {
      mid = int( (end - start) / 2 ) + start;
      switch( _list[mid]->compare( index ) ) {
        case -1 :
          end = mid;
          break;
        case  0 :
          retval.matches = true;
          retval.index   = mid;
          return( retval );
          break;
        case  1 :
          if( start == mid ) {
            retval.index = end;
            return( retval );
          } else {
            start = mid;
          }
          break;
      }
    }
    retval.index = end;
    return( retval );
  } 

}

void serial::insert(
  const vector<tindex> & ranges
) {

  sindex last;

  last.index   = _list.size();
  last.matches = true;

  for( int i=0; i<ranges.size(); i+=2 ) {

    /* Find the range indices */
    sindex index = get_index( ranges[i] );

    /* Adjust the indices */
    adjust_indices( ranges[i], ranges[i+1], index, last );

    /* Save the last index */
    last = start;

  }

}

void serial::delete(
  const vector<tindex> & ranges
) {

  sindex last;

  last.index   = _list.size();
  last.matches = true;

  for( int i=0; i<ranges.size(); i+=2 ) {

    sindex start = get_index( ranges[i] );
    sindex end   = get_index( ranges[i+1] );

    /* Adjust the list */
    adjust( ranges[i+1], ranges[i], end, last );

    if( start != end ) {
      _list.erase( (_list.begin() + start.index), (_list.begin() + (end.index - 1)) );
    }

    last = start;

  }

}

void serial::replace(
  const vector<tindex> & ranges
) {

  sindex last;

  last.index   = _list.size();
  last.matches = true;

  for( int i=0; i<ranges.size(); i+=3 ) {

    sindex start = get_index( ranges[i] );
    sindex end   = get_index( ranges[i+1] );

    /* Adjust the list */
    adjust( ranges[i], ranges[i+2], end, last );

    /* Delete the range of items in the serial list */
    if( start != end ) {
      _list.erase( (_list.begin() + start.index), (_list.begin() + (end.index - 1)) );
    }

    last = start;

  }

}

bool serial::update(
  const tindex             & linestart,
  const tindex             & lineend,
  const list<serial_item*> & elements
) {

  sindex start_index = get_index( linestart );
  sindex end_index   = get_index( lineend );

  if( elements.size() ) {

    /* Delete the range */
    if( start_index != end_index ) {
      _list.erase( (_list.begin() + start_index.index), (_list.begin() + end_index.index) );
    }

    /* Insert the given list */
    _list.splice( (_list.begin() + start_index.index), elements );

    return( true );

  }

  return( false );

}

/* -------------------------------------------------------------- */

void tree::insert_item(
  tnode*            & current,
  position          & lescape,
  const serial_item & item
) {

  tnode* node;

  /* Calculate the starting index and if it is escaped, skip the insertion */
  if {lescape.compare( item.pos() ) ) {
    return;
  }

  /* If the current node is root, add a new node as a child */
  if {current == _tree} {
    switch( item.side() ) {
      case 0 :  insert_root_none(  current, lescape, item );  break;
      case 1 :  insert_root_left(  current, lescape, item );  break;
      case 2 :  insert_root_right( current, lescape, item );  break;
      case 3 :  insert_root_any(   current, lescape, item );  break;
    }

  } else if( !item.comstr() || (current->type() == item.type()) || (item.size() == 0) ) {
    switch( item.side() ) {
      case 0 :  insert_none(  current, lescape, item );  break;
      case 1 :  insert_left(  current, lescape, item );  break;
      case 2 :  insert_right( current, lescape, item );  break;
      case 3 :  insert_any(   current, lescape, item );  break;
    }
  }

}

void tree::insert_root_left(
  tnode*            & current,
  position          & lescape,
  const serial_item & item
) {
  
  add_child_node( current, item );

}

void tree::insert_root_right(
  tnode*            & current,
  position          & lescape,
  const serial_item & item
) {

  tnode* node = current;

  add_child_node( current, item );

  current = node;

}

void tree::insert_root_any(
  tnode*            & current,
  position          & lescape,
  const serial_item & item
) {

  add_child_node( current, item );

}

void tree::insert_root_none(
  tnode*            & current,
  position          & lescape,
  const serial_item & item
) {

  if( item.type() == types::staticObject.get( "escape" ) {
    lescape.incr_col();
  }

}

void tree::insert_left(
  tnode*            & current,
  position          & lescape,
  const serial_item & item
) {

  add_child_node( current, item );

}

void tree::insert_right(
  tnode*            & current,
  position          & lescape,
  const serial_item & item
) {

  if( current->type() == item.type() ) {
    current->right( item );
    current = current->parent();

  } else {

    tnode* tn = current;

    /* Check to see if the matching left already exists */
    while( (tn = current->parent()) != _tree ) {
      if( tn->type() == item.type() ) {
        tn->right( &item );
        current = current->parent();
        return;
      } 
    }

    /*
     If we didn't find it going up, add the item below it but keep
     the current node the current node
    */
    add_child_node( current, item );

  }

}

void tree::insert_any(
  tnode*            & current,
  position          & lescape,
  const serial_item & item
) {

  if( current->type() == item.type() ) {
    current->right( &item );
    item.set_node( current );
    current = current->parent();
  } else {
    add_child_node( current, item );
  }

}

void tree::insert_none(
  tnode*            & current,
  position          & lescape,
  const serial_item & item
) {

  insert_root_none( current, lescape, item );

}

void add_child_node(
  tnode*            & current,
  bool                left,
  const serial_item & item
) {

  tnode* n = tnode( item.type(), types::staticObject().comstr( item.type() ) );

  /* Initialize the node */
  if( left ) {
    n->left( &item );
  } else {
    n->right( &item );
  }

  current->append( n );
  current = n;

  /* Save the node pointer in the serial list item */
  item.set_node( node );

}

void tree::update( const serial & sl ) {

  tnode*   current = _tree;
  position lescape( 0, 0, 0 );

  for( int i=0; i<sl.size(); i++ ) {
    insert_item( current, lescape, sl.get_item() );
  }

}

