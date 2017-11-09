/*!
 \file     model.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include "model.h"
#include <iostream>

using namespace std;
using namespace Tcl;

position::position( object item ) {

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

  oss << _row << "." << _scol;

  return( oss.str() );

}

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

serial_item::serial_item(
  object item
) {

  interpreter i( item.get_interp(), false );

  cout << "serial_item constructor, length: " << item.length( i ) << endl;

  if( item.length( i ) == 5 ) {
    _type      = types::staticObject().get( item.at( i, 0 ).get<string>( i ) );
    _side      = item.at( i, 1 ).get<int>( i );
    _pos       = position( item.at( i, 2 ) );
    _iscontext = item.at( i, 3 ).get<bool>( i );
    _node      = 0;
    _context   = types::staticObject().get( item.at( i, 4 ).get<string>( i ) );
  }

}

/* -------------------------------------------------------------- */

serial::~serial() {

  /* Deallocate memory */
  for( vector<serial_item*>::iterator it=begin(); it!=end(); it++ ) {
    delete *it;
  }

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

  int col_diff    = to.col - from.col;
  int row_diff    = to.row - from.row;
  int start_index = start.index();

  /*
   If the starting index matches the item in the list, we may not have to
   modify the starting column.
  */
  if( start.matches() ) {
    (*this)[start_index++]->adjust_first( from.col, to.col, col_diff );
  }

  /* Perform the adjustment */
  for( int i=start_index; i<end.index(); i++ ) {
    (*this)[i]->adjust( from.row, row_diff, col_diff );
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

    sindex start = get_index( ranges[i] );
    sindex end   = get_index( ranges[i+1] );

    /* Adjust the list */
    adjust( ranges[i+1], ranges[i], end, last );

    if( start != end ) {
      erase( (begin() + start.index()), (begin() + (end.index() - 1)) );
    }

    last = start;

  }

}

void serial::replace(
  const vector<tindex> & ranges
) {

  sindex last( size(), true );;

  for( int i=0; i<ranges.size(); i+=3 ) {

    sindex start = get_index( ranges[i] );
    sindex end   = get_index( ranges[i+1] );

    /* Adjust the list */
    adjust( ranges[i], ranges[i+2], end, last );

    /* Delete the range of items in the serial list */
    if( start != end ) {
      erase( (begin() + start.index()), (begin() + (end.index() - 1)) );
    }

    last = start;

  }

}

void serial::append(
  object item
) {

  interpreter interp( item.get_interp(), false );

  int size = item.length( interp );

  cout << "Appending to serial, size: " << size << endl;

  for( int i=0; i<size; i++ ) {
    push_back( new serial_item( item.at( interp, i ) ) );
  }

}

bool serial::update(
  const tindex & linestart,
  const tindex & lineend,
  serial*        elements
) {

  sindex start_index = get_index( linestart );
  sindex end_index   = get_index( lineend );

  if( elements->size() ) {

    /* Delete the range */
    if( start_index != end_index ) {
      erase( (begin() + start_index.index()), (begin() + end_index.index()) );
    }

    /* Insert the given list */
    vector<serial_item*>::insert( (begin() + start_index.index()), elements->begin(), elements->end() );

    return( true );

  }

  return( false );

}

/* -------------------------------------------------------------- */

void tnode::destroy() {

  for( vector<tnode*>::iterator it=_children.begin(); it!=_children.end(); it++ ) {
    (*it)->destroy();
    delete *it;
  }

}

void tnode::get_mismatched(
  object & mismatched
) const {

  cout << "Evaluating tnode: " << this << endl;

  /* If we are mismatched, update the object */
  if( incomplete() ) {
    if( _left ) {
      _left->const_pos().to_pair( mismatched );
    } else {
      _right->const_pos().to_pair( mismatched );
    }
  }

  /* Search the children */
  for( vector<tnode*>::const_iterator it=_children.begin(); it!=_children.end(); it++ ) {
    (*it)->get_mismatched( mismatched );
  }

}

/* -------------------------------------------------------------- */

tree::~tree() {

  /* Destroy the tree */
  _tree->destroy();

  delete _tree;

}

void tree::insert_item(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  tnode* node;

  cout << "In insert_item, item pos: " << item.pos().to_string() << endl;

  /* Calculate the starting index and if it is escaped, skip the insertion */
  if( item.pos().compare( lescape ) == 0 ) {
    return;
  }

  cout << "HERE!" << endl;

  /* If the current node is root, add a new node as a child */
  if( current == _tree ) {
    cout << "We are root!, side: " << item.side() << endl;
    switch( item.side() ) {
      case 0 :  insert_none( current, lescape, item );  break;
      case 1 :  insert_root_left(  current, lescape, item );  break;
      case 2 :  insert_root_right( current, lescape, item );  break;
      case 3 :  insert_root_any(   current, lescape, item );  break;
    }

  } else if( !current->comstr() || (current->type() == item.type()) || (item.side() == 0) ) {
    cout << "HERE B" << endl;
    switch( item.side() ) {
      case 0 :  insert_none(  current, lescape, item );  break;
      case 1 :  insert_left(  current, lescape, item );  break;
      case 2 :  insert_right( current, lescape, item );  break;
      case 3 :  insert_any(   current, lescape, item );  break;
    }
  }

}

void tree::insert_root_left(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {
  
  add_child_node( current, true, item );

}

void tree::insert_root_right(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  tnode* node = current;

  add_child_node( current, false, item );

  current = node;

}

void tree::insert_root_any(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  add_child_node( current, true, item );

}

void tree::insert_left(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  add_child_node( current, true, item );

}

void tree::insert_right(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  if( current->type() == item.type() ) {
    current->right( &item );
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
    add_child_node( current, false, item );

  }

}

void tree::insert_any(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  if( current->type() == item.type() ) {
    current->right( &item );
    item.set_node( current );
    current = current->parent();
  } else {
    add_child_node( current, true, item );
  }

}

void tree::insert_none(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  if( item.type() == types::staticObject().get( "escape" ) ) {
    lescape.col++;
  }

}

void tree::add_child_node(
  tnode*      & current,
  bool          left,
  serial_item & item
) {

  tnode* n = new tnode( item.type(), types::staticObject().comstr( item.type() ) );

  cout << "Adding child node: " << n << endl;

  /* Initialize the node */
  if( left ) {
    n->left( &item );
  } else {
    n->right( &item );
  }

  current->add_child( n );
  current = n;

  /* Save the node pointer in the serial list item */
  item.set_node( n );

}

void tree::update(
  serial & sl
) {

  tnode* current = _tree;
  tindex lescape = {0, 0};

  cout << "Updating tree (size: " << sl.size() << ")" << endl;

  for( int i=0; i<sl.size(); i++ ) {
    insert_item( current, lescape, *(sl[i]) );
  }

}

/* -------------------------------------------------------------- */

bool model::update(
  object  linestart,
  object  lineend,
  serial* elements
) {

  interpreter i( linestart.get_interp(), false );
  tindex      lstart;
  tindex      lend;

  lstart.row = linestart.at( i, 0 ).get<int>( i );
  lstart.col = linestart.at( i, 1 ).get<int>( i );
  lend.row   = lineend.at( i, 0 ).get<int>( i );
  lend.col   = lineend.at( i, 1 ).get<int>( i );

  /* Update the serial list */
  if( _serial.update( lstart, lend, elements ) ) {
    _tree.update( _serial );
    return( true );
  }

  return( false );

}

object model::get_mismatched() const {

  object mismatched;

  _tree.get_mismatched( mismatched );

  return( mismatched );

}

/* -------------------------------------------------------------- */

CPPTCL_MODULE(Model, i) {

  /* Define the serial class */
  i.class_<serial>("serial")
    .def("append", &serial::append);

  /* Define the model class */
  i.class_<model>("model")
    .def("update", &model::update)
    .def("mismatched", &model::get_mismatched);

  /* Add functions */
  i.def("add_type", add_type );

 // i.def("makePerson", makePerson, factory("Person"));
 // i.def("killPerson", killPerson, sink(1));

}

