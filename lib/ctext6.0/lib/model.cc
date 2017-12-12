/*!
 \file     model.cc
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     11/8/2017
*/

#include <stack>

#include "model.h"
#include "types.h"

using namespace std;
using namespace Tcl;

void model::object_to_ranges(
  const object   & ranges,
  vector<tindex> & vec
) {

  interpreter i( ranges.get_interp(), false );
  int         size = ranges.length( i );

  for( int j=0; j<size; j++ ) {
    vec.push_back( tindex( ranges.at( i, j ) ) );
  }

}

bool model::update(
  const object & linestart,
  const object & lineend,
  const object & elements
) {

  interpreter i( elements.get_interp(), false );
  tindex lstart( linestart );
  tindex lend( lineend );
  serial elems;

  elems.append( elements );

  /* Update the serial list */
  return( _serial.update( lstart, lend, elems ) );

}

object model::get_mismatched() const {

  object mismatched;

  _tree.get_mismatched( mismatched );

  return( mismatched );

}

int model::get_depth(
  const object & index,
  const object & type
) {

  interpreter i( index.get_interp(), false );
  tnode*      node;
  tindex      ti( index );
  string      type_str = type.get<string>( i );

  if( (node = _serial.find_node( ti )) == 0 ) {
    return( 0 );
  } else if( type_str.empty() ) {
    return( node->depth() );
  } else {
    return( node->depth( types::staticObject().get( type_str ) ) );
  }

}

object model::get_match_char(
  const object & ti
) {

  sindex si = _serial.get_index( tindex( ti ) );
  object retval;

  if( si.matches() ) {
    serial_item* sitem = _serial[si.index()];
    position     pos;
    if( sitem->type()->matching() && sitem->node()->get_match_pos( sitem, pos ) ) {
      pos.to_pair( retval );
    }
  }

  return( retval );

}

void model::add_tag_index(
  interpreter        & i,
  map<string,object> & ranges,
  const string       & tag,
  const string       & index
) {

  map<string,object>::iterator it = ranges.find( tag );

  if( it == ranges.end() ) {
    ranges.insert( make_pair( tag, (object)index ) );
  } else {
    it->second.append( i, (object)index );
  }

}

object model::render_contexts(
  const object & linestart,
  const object & lineend,
  const object & tags
) {

  interpreter                  i( linestart.get_interp(), false );
  serial                       citems;
  serial                       titems;
  std::stack<const type_data*> context;
  const type_data*             ltype  = types::staticObject().get( "" );
  const type_data*             escape = types::staticObject().get( "escape" );
  int                          lrow   = 0;
  int                          lcol   = 0;
  map<string,object>           ranges;

  context.push( ltype );

  /* Get the context items from the model */
  _serial.get_context_items( citems );

  /* Merge the context items with the tags */
  titems.append( tags );
  citems.update( tindex( linestart ), tindex( lineend ), titems );

  /* Create the non-overlapping ranges for each of the context tags */
  for( vector<serial_item*>::iterator it=citems.begin(); it!=citems.end(); it++ ) {
    if( ((*it)->type() != escape) && ((ltype != escape) || (lrow != (*it)->pos().row()) || (lcol != ((*it)->pos().start_col() - 1))) ) {
      const string & tagname = (*it)->type()->tagname();
      if( (context.top() == (*it)->context()) && ((*it)->side() & 1) ) {
        context.push( (*it)->type() );
        add_tag_index( i, ranges, tagname, (*it)->pos().to_index( true ) );
      } else if( (context.top() == (*it)->type()) && ((*it)->side() & 2) ) {
        context.pop();
        add_tag_index( i, ranges, tagname, (*it)->pos().to_index( false ) );
      } else {
        map<string,object>::iterator it = ranges.find( tagname );
        if( it == ranges.end() ) {
          ranges.insert( make_pair( tagname, object() ) );
        }
      }
    }
    ltype = (*it)->type();
    lrow  = (*it)->pos().row();
    lcol  = (*it)->pos().start_col();
  }

  /* Render the ranges */
  object result;
  for( map<string,object>::iterator it=ranges.begin(); it!=ranges.end(); it++ ) {
    result.append( i, (object)it->first );
    result.append( i, it->second );
  }

  return( result );

}

bool model::is_escaped(
  const object & ti
) const {

  return( _serial.is_escaped( tindex( ti ) ) );

}

bool model::is_index(
  const object & type,
  const object & ti
) const {

  interpreter interp( type.get_interp(), false );
  string      typ = type.get<string>( interp );

  if( typ.substr( 0, 2 ) == "in" ) {
    return( _tree.is_index_in( typ.substr( 2 ), tindex( ti ) ) );
  } else {
    return( _serial.is_index( typ, tindex( ti ) ) );
  }

}

object model::indent_line_start(
  const object & indent_index
) const {

  tindex ti( indent_index );
  int    row = ti.row();
  tnode* node;

  if( (node = _serial.find_node( tindex( ti ) )) ) {
    int              index    = node->index() - 1;
    vector<tnode*> & siblings = node->parent()->children();
    while( (index >= 0) && (siblings[index]->right()->const_pos().row() == row) ) {
      row = siblings[index]->left()->const_pos().row();
      index--;
    }
  }

  return( (object)row );

}
