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

void model::clear() {

  _serial.clear();
  _tree.clear();
  _linemap.clear( "folding" );
  _types.clear();

}

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
  const object & args
) {

  interpreter interp( args.get_interp(), false );
  bool        retval = false;

  for( int i=0; i<args.length( interp ); i+=3 ) {

    tindex lstart( args.at( interp, (i + 0) ) );
    tindex lend( args.at( interp, (i + 1) ) );
    serial elems;

    elems.append( args.at( interp, (i + 2) ), _types );
    retval |= _serial.update( lstart, lend, elems );

  }

  return( retval );

}

object model::get_mismatched() const {

  object mismatched;

  _tree.get_mismatched( mismatched );

  return( mismatched );

}

int model::get_depth(
  const object & args
) {

  interpreter interp( args.get_interp(), false );
  tnode*      node;
  tindex      ti( args.at( interp, 0 ) );
  string      type_str = args.at( interp, 1 ).get<string>( interp );

  if( (node = _serial.find_node( ti )) == 0 ) {
    return( 0 );
  } else if( type_str.empty() ) {
    return( node->depth() );
  } else {
    return( node->depth( _types.type( type_str ) ) );
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
    if( _types.is_matching( sitem->type() ) && sitem->node() && sitem->node()->get_match_pos( sitem, pos ) ) {
      return( (object)pos.to_tindex().to_string() );
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
  const object & args
) {

  interpreter        interp( args.get_interp(), false );
  object             result;
  object             contexts;
  serial             citems;
  std::stack<int>    context;
  int                ltype  = 0;
  int                escape = _types.type( "escape" );
  int                lrow   = 0;
  int                lcol   = 0;
  map<string,object> ranges;
  bool               tags_found = false;

  /* Get the context items from the model */
  _serial.get_context_items( citems );

  /* Merge the context items with the tags */
  for( int i=0; i<args.length( interp ); i+=3 ) {
    serial titems;
    titems.append( args.at( interp, (i + 2) ), _types );
    tags_found |= citems.update( tindex( args.at( interp, (i + 0) ) ), tindex( args.at( interp, (i + 1) ) ), titems );
  }

  /* If the tags list is empty and no context chars were previously removed, return with the empty list */
  if( !_serial.context_removed() && !tags_found ) {
    return( result );
  }

  context.push( ltype );

  /* Create the non-overlapping ranges for each of the context tags */
  for( vector<serial_item*>::iterator it=citems.begin(); it!=citems.end(); it++ ) {
    if( (((*it)->type() & escape) == 0) && (((ltype & escape) == 0) || (lrow != (*it)->pos().row()) || (lcol != ((*it)->pos().start_col() - 1))) ) {
      const string & tag = _types.tag( (*it)->type() );
      if( ((context.top() & (*it)->context()) || (context.top() == (*it)->context())) && ((*it)->side() & 1) ) {
        context.push( (*it)->type() );
        add_tag_index( interp, ranges, tag, (*it)->pos().to_index( true ) );
      } else if( (context.top() & (*it)->type()) && ((*it)->side() & 2) ) {
        context.pop();
        add_tag_index( interp, ranges, tag, (*it)->pos().to_index( false ) );
      } else {
        map<string,object>::iterator it = ranges.find( tag );
        if( it == ranges.end() ) {
          ranges.insert( make_pair( tag, object() ) );
        }
      }
    }
    ltype = (*it)->type();
    lrow  = (*it)->pos().row();
    lcol  = (*it)->pos().start_col();
  }

  /* Render the context ranges */
  for( map<string,object>::iterator it=ranges.begin(); it!=ranges.end(); it++ ) {
    contexts.append( interp, (object)it->first );
    contexts.append( interp, it->second );
  }

  /* Indicate that the contexts have been rendered */
  _contexts_rendered = true;

  /* Return the result */
  result.append( interp, contexts );
  result.append( interp, filter_contexts( _tags_to_filter ) );

  return( result );

}

Tcl::object model::filter_contexts(
  const object & args
) {

  interpreter interp( args.get_interp(), false );
  int         tag_length = args.length( interp );
  object      result;

  if( _contexts_rendered && (tag_length > 0) ) {

    /* Perform the filter operation */
    for( int i=0; i<tag_length; i+=2 ) {
      string context    = args.at( interp, (i + 0) ).at( interp, 0 ).get<string>( interp );
      string tag        = args.at( interp, (i + 0) ).at( interp, 1 ).get<string>( interp );
      object ranges     = args.at( interp, (i + 1) );
      int    ranges_len = ranges.length( interp );
      object filtered;
      for( int j=0; j<ranges_len; j+= 2 ) {
        tindex ti( ranges.at( interp, j ) );
        if( _tree.is_in_context( _types.type( context ), ti ) ) {
          filtered.append( interp, ranges.at( interp, (j + 0) ) );
          filtered.append( interp, ranges.at( interp, (j + 1) ) );
        }
      }
      result.append( interp, (object)tag );
      result.append( interp, filtered );
    }

    /* Clear the tags to filter */
    _contexts_rendered = false;

    /* Clear the tags to filter */
    _tags_to_filter = "";

  } else {

    _tags_to_filter = args;

  }

  return( result );

}

bool model::is_escaped(
  const object & ti
) const {

  return( _serial.is_escaped( tindex( ti ), _types ) );

}

object model::is_index(
  const object & args
) const {

  interpreter interp( args.get_interp(), false );
  string      typ  = args.at( interp, 0 ).get<string>( interp );
  tindex      ti( args.at( interp, 1 ) );
  string      extra = args.at( interp, 2 ).get<string>( interp );

  if( typ.substr( 0, 2 ) == "in" ) {
    return( _tree.is_in_index( typ.substr( 2 ), (extra == "inner"), ti, _types ) );
  } else {
    return( (object)_serial.is_index( typ, ti, get_side( extra ), _types ) );
  }

}

object model::indent_line_start(
  const object & indent_index
) const {

  tindex ti( indent_index );
  int    row = ti.row();
  tnode* node;

  if( (node = _serial.find_node( tindex( ti ) )) ) {
    row = node->get_line_start( row );
  }

  return( (object)row );

}
