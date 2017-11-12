/*!
 \file     model.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include "model.h"

using namespace std;
using namespace Tcl;

static tindex object_to_tindex( const object & obj ) {

  interpreter i( obj.get_interp(), false );
  string      value  = obj.get<string>( i );
  int         period = value.find( "." );
  tindex ti;

  if( period == string::npos ) {
    /* Throw an error */
    return( ti );
  }

  /* Populate the tindex */
  ti.row = atoi( value.substr( 0, (period + 1) ).c_str() );
  ti.col = atoi( value.substr( (period + 1) ).c_str() );

  return( ti );

}

static string tindex_to_string( const tindex & ti ) {

  ostringstream oss;

  oss << ti.row << "." << ti.col;

  return( oss.str() );

}

int get_side( std::string name ) {

  static map<string,int> side_values;

  if( side_values.size() == 0 ) {
    side_values.insert( make_pair( "none",  0 ) );
    side_values.insert( make_pair( "left",  1 ) );
    side_values.insert( make_pair( "right", 2 ) );
    side_values.insert( make_pair( "any",   3 ) );
  }

  map<string,int>::iterator it = side_values.find( name );

  if( it == side_values.end() ) {
    return( -1 );
  } else {
    return( it->second );
  }

}

std::string get_side( int value ) {

  static map<int,std::string> side_names;

  if( side_names.size() == 0 ) {
    side_names.insert( make_pair( 0, "none" ) );
    side_names.insert( make_pair( 1, "left" ) );
    side_names.insert( make_pair( 2, "right" ) );
    side_names.insert( make_pair( 3, "any" ) );
  }

  map<int,string>::iterator it = side_names.find( value );

  if( it == side_names.end() ) {
    return( "" );
  } else {
    return( it->second );
  }

}

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

string position::to_index() const {

  ostringstream oss;

  oss << _row << "." << _scol;

  return( oss.str() );

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

/* -------------------------------------------------------------- */

serial_item::serial_item(
  object item
) {

  interpreter i( item.get_interp(), false );

  if( item.length( i ) == 5 ) {
    _type      = types::staticObject().get( item.at( i, 0 ).get<string>( i ) );
    _side      = get_side( item.at( i, 1 ).get<string>( i ) );
    _pos       = position( item.at( i, 2 ) );
    _iscontext = item.at( i, 3 ).get<bool>( i );
    _node      = 0;
    _context   = types::staticObject().get( item.at( i, 4 ).get<string>( i ) );
  }

}

string serial_item::to_string() const {

  ostringstream oss;
  string        context = types::staticObject().get( _context );

  if( context.empty() || (context.find( " " ) != string::npos) ) {
    context.insert( 0, "{" );
    context.append( "}" );
  }

  oss << "{" << types::staticObject().get( _type ) << " " << get_side( _side ) << " " << _pos.to_string() << " " << _iscontext << " " << context << "}";

  return( oss.str() );

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
    (*this)[start_index++]->adjust_first( from.col, to.col, row_diff, col_diff );
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
    int    end_index = end.index() + ((!end.matches() || ((*this)[end.index()]->pos().start_col() == ranges[i+1].col)) ? 0 : 1);

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
    int    end_index = end.index() + ((!end.matches() || ((*this)[end.index()]->pos().start_col() == ranges[i+1].col)) ? 0 : 1);

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

  if( (ti.col == 0) || (si.index() == 0) || (si.matches() && (ti.col != (*this)[si.index()]->pos().start_col())) ) {
    return( false );
  }

  serial_item* prev_item = (*this)[si.index()-1];

  return( (prev_item->type() == types::staticObject().get( "escape" )) &&
          ((prev_item->pos().start_col() + 1) == ti.col) );

}

/* -------------------------------------------------------------- */

void tnode::clear() {

  for( vector<tnode*>::iterator it=_children.begin(); it!=_children.end(); it++ ) {
    delete *it;
  }

  /* Clear the children list */
  _children.clear();

}

void tnode::get_mismatched(
  object & mismatched
) const {

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

bool tnode::get_match_pos(
  const serial_item*   si,
  position           & pos
) const {

  if( _left && (_left == si) ) {
    if( _right ) {
      pos = _right->pos();
      return( true );
    }
  } else if( _left ) {
    pos = _left->pos();
    return( true );
  }

  return( false );

}

int tnode::index() const {

  int i = 0;

  for( vector<tnode*>::const_iterator it=_parent->_children.begin(); it!=_parent->_children.end(); it++ ) {
    if( *it == this ) {
      return( i );
    }
    i++;
  }

  return( -1 );

}

int tnode::depth(
  int type
) const {

  if( isroot() ) {
    return( 0 );
  } else {
    return( _parent->depth() + (((type == -1) || (_type == type)) ? 1 : 0) );
  }

}

string tnode::to_string() const {

  if( isroot() ) {
    return( "(root)" );
  }

  ostringstream oss;

  oss << "(" << ((_left  == 0) ? "??" : _left->pos().to_index())
      << "-" << ((_right == 0) ? "??" : _right->pos().to_index())
      << " {" << types::staticObject().get( _type ) << "})";

  return( oss.str() );

}

string tnode::tree_string() const {

  ostringstream oss;
  int           width = 30;

  if( !isroot() && (index() > 0) ) {
    oss << setfill(' ') << setw(width * (depth() + 1)) << to_string();
  } else {
    oss << setfill(' ') << setw(width) << to_string();
  }

  if( _children.size() == 0 ) {
    oss << endl;
  } else {
    for( vector<tnode*>::const_iterator it=_children.begin(); it!=_children.end(); it++ ) {
      oss << (*it)->tree_string();
    }
  }

  return( oss.str() );

}

/* -------------------------------------------------------------- */

tree::~tree() {

  /* Destroy the tree */
  delete _tree;

}

void tree::insert_item(
  tnode*      & current,
  tindex      & lescape,
  serial_item & item
) {

  tnode* node;

  /* Calculate the starting index and if it is escaped, skip the insertion */
  if( item.pos().compare( lescape ) == 0 ) {
    return;
  }

  /* If the current node is root, add a new node as a child */
  if( current == _tree ) {
    switch( item.side() ) {
      case 0 :  insert_none(       current, lescape, item );  break;
      case 1 :  insert_root_left(  current, lescape, item );  break;
      case 2 :  insert_root_right( current, lescape, item );  break;
      case 3 :  insert_root_any(   current, lescape, item );  break;
    }

  } else if( !current->comstr() || (current->type() == item.type()) || (item.side() == 0) ) {
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
    item.set_node( current );
    current = current->parent();

  } else {

    tnode* tn = current;

    /* Check to see if the matching left already exists */
    while( (tn = current->parent()) != _tree ) {
      if( tn->type() == item.type() ) {
        tn->right( &item );
        item.set_node( tn );
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
    lescape.row = item.pos().row();
    lescape.col = item.pos().start_col() + 1;
  }

}

void tree::add_child_node(
  tnode*      & current,
  bool          left,
  serial_item & item
) {

  tnode* n = new tnode( item.type(), types::staticObject().comstr( item.type() ) );

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

  /* Clear the tree */
  _tree->clear();

  for( int i=0; i<sl.size(); i++ ) {
    insert_item( current, lescape, *(sl[i]) );
  }

}

/* -------------------------------------------------------------- */

void model::object_to_ranges(
  object ranges,
  vector<tindex> & vec
) {

  interpreter i( ranges.get_interp(), false );
  int         size = ranges.length( i );

  for( int j=0; j<size; j++ ) {
    vec.push_back( object_to_tindex( ranges.at( i, j ) ) );
  }

}

bool model::update(
  object linestart,
  object lineend,
  object elements
) {

  interpreter i( elements.get_interp(), false );
  tindex lstart = object_to_tindex( linestart );
  tindex lend   = object_to_tindex( lineend );
  serial elems;

  elems.append( elements );

  /* Update the serial list */
  if( _serial.update( lstart, lend, elems ) ) {
    // _tree.update( _serial );
    return( true );
  }

  return( false );

}

object model::get_mismatched() const {

  object mismatched;

  _tree.get_mismatched( mismatched );

  return( mismatched );

}

int model::get_depth(
  object index,
  object type
) {

  interpreter i( index.get_interp(), false );
  tindex      ti = object_to_tindex( index );
  int         typ;
  tnode*      node;

  if( type.get<string>( i ).empty() ) {
    typ = -1;
  } else {
    typ = types::staticObject().get( type.get<string>( i ) );
  }

  if( (node = _serial.find_node( ti )) == 0 ) {
    return( 0 );
  } else {
    return( node->depth( typ ) );
  }

}

object model::get_match_char(
  object ti
) {

  sindex si = _serial.get_index( object_to_tindex( ti ) );
  object retval;

  if( si.matches() ) {
    serial_item* sitem = _serial[si.index()];
    position     pos;
    if( sitem->node()->get_match_pos( sitem, pos ) ) {
      pos.to_pair( retval );
    }
  }

  return( retval );

}

string model::get_context_items(
  object linestart,
  object lineend,
  object tags
) const {

  serial citems;
  serial titems;

  _serial.get_context_items( citems );

  titems.append( tags );
  citems.update( object_to_tindex( linestart ), object_to_tindex( lineend ), titems );

  return( citems.to_string() );

}

bool model::is_escaped(
  object ti
) const {

  return( _serial.is_escaped( object_to_tindex( ti ) ) );

}

/* -------------------------------------------------------------- */

Tcl::object request::execute(
  bool & update_needed
) {

  interpreter i( _args.get_interp(), false );

  switch( _command ) {
    case REQUEST_INSERT     :  (model*)_inst->insert( _args );  break;
    case REQUEST_DELETE     :  (model*)_inst->remove( _args );  break;
    case REQUEST_REPLACE    :  (model*)_inst->replace( _args );  break;
    case REQUEST_UPDATE     :
      if( (model*)_inst->update( _args.at( i, 0 ), _args.at( i, 1 ), _args.at( i, 2 ) ) ) {
        update_needed = true;
      }
      break;
    case REQUEST_SHOWSERIAL :  (model*)_inst->show_serial();  break;
    case REQUEST_SHOWTREE   :  (model*)_inst->show_tree();  break;
    case REQUEST_MISMATCHED :  (model*)_inst->get_mismatched();  break;
    case REQUEST_MATCHINDEX :
      return( (model*)_inst->get_match_char( _args ) );
      break;
    case REQUEST_DEPTH :
      return( (model*)_inst->get_depth( _args.at( i, 0 ), _args.at( i, 1 ) ) );
      break;
    case REQUEST_GETCONTEXTS :
      return( (model*)_inst->get_context_items( _args.at( i, 0 ), _args.at( i, 1 ), _args.at( i, 2 ) );
      break;
    case REQUEST_ISESCAPED :
      return( (model*)_inst->is_escaped( _args ) );
      break;
    default :
      throw runtime_error( "Unknown command" );
  }

  return( 0 );

}

/* -------------------------------------------------------------- */

static void model_execute(
  mailbox & mbox
) {

  mbox.execute();

}

void mailbox::add_request(
  int                 command,
  const Tcl::object & args,
  bool                block
) {

  /* Create the request and add it to the fifo */
  _requests.push_back( new request( inst, command, args, block ) );

  /* If the processing thread is currently running, start it now */
  if( !_thread_active ) {
    _thread_active = true;
    thread( mailbox_execute, *this ).detach();
  }

}

void mailbox::execute() {

  bool update_needed = false;

  while( !_requests.empty() && !_requests.front()->block() ) {
    _requests.front()->execute( _model, update_needed );
  }

  /* If the serial list was updated while executing, update the tree */
  if( update_needed ) {
    m.update_tree();
  }

  /* Specify that we are no longer running */
  _thread_active = false;

}

void mailbox::insert(
  object ranges
) {

  add_request( REQUEST_INSERT, ranges, false );

}

void mailbox::remove(
  object ranges
) {

  add_request( REQUEST_DELETE, ranges, false );

}

void mailbox::replace(
  object ranges
) {

  add_request( REQUEST_REPLACE, ranges, false );

}

void mailbox::update(
  object linestart,
  object lineend,
  object elements
) {

  interpreter i( linestart.get_interp(), false ):
  object      args

  args.append( i, linestart );
  args.append( i, lineend );
  args.append( i, elements );

  add_request( REQUEST_UPDATE, args, false );

}

void mailbox::show_serial() {

  object none;

  add_request( REQUEST_SHOWSERIAL, none, false );

}

void mailbox::show_tree() {

  object none;

  add_request( REQUEST_SHOWTREE, none, true );

}

void mailbox::get_mismatched() {

  object none;

  add_request( REQUEST_MISMATCHED, none, true );

}

void mailbox::get_match_char(
  object ti
) {

  add_request( REQUEST_MATCHCHAR, ti, true );

}

void mailbox::get_depth(
  object ti
) {

  add_request( REQUEST_DEPTH, ti, true );

}

void mailbox::is_escaped(
  object ti
) {

  add_request( REQUEST_ISESCAPED, ti, false );

}

void mailbox::get_context_items() {
  object linestart,
  object lineend,
  object tags
) {

  interpreter i( linestart.get_interp(), false );
  object      args;

  args.append( i, linestart );
  args.append( i, lineend );
  args.append( i, tags );

  add_request( REQUEST_GETCONTEXTS, args, false );

}

/* -------------------------------------------------------------- */

CPPTCL_MODULE(Model, i) {

  /* Define the serial class */
  i.class_<serial>("serial")
    .def( "append", &serial::append )
    .def( "get",    &serial::to_string );

  /* Define the model class */
  i.class_<mailbox>("model")
    .def( "insert",      &mailbox::insert )
    .def( "delete",      &mailbox::remove )
    .def( "replace",     &mailbox::replace )
    .def( "update",      &mailbox::update )
    .def( "showserial",  &mailbox::show_serial )
    .def( "showtree",    &mailbox::show_tree )
    .def( "mismatched",  &mailbox::get_mismatched )
    .def( "matchindex",  &mailbox::get_match_char )
    .def( "depth",       &mailbox::get_depth )
    .def( "getcontexts", &mailbox::get_context_items )
    .def( "isescaped",   &mailbox::is_escaped );

  /* Add functions */
  i.def("add_type", add_type );

}

