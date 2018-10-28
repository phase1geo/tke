/*!
 \file     side.cc
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/22/2017
*/

#include <map>
#include <string>

#include "side.h"

using namespace std;

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

