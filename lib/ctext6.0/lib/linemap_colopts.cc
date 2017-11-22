/*!
 \file     linemap_colopts.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
*/

#include "linemap_colopts.h"

using namespace std;
using namespace Tcl;

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

