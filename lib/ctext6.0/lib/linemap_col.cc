/*!
 \file     linemap_col.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
*/

#include "linemap_col.h"

using namespace std;
using namespace Tcl;

linemap_col::linemap_col(
  const object & name,
  const object & opts
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
  const object & opts
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

