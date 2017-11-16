#ifndef __UTILS_H__
#define __UTILS_H__

/*!
 \file     utils.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
 \brief    Utility types and functions.
*/

/*! Text widget index */
typedef struct {
  int row;
  int col;
} tindex;

/*! Converts a Tcl object into a tindex structure */
inline tindex object_to_tindex( const Tcl::object & obj ) {

  Tcl::interpreter i( obj.get_interp(), false );
  std::string      value  = obj.get<std::string>( i );
  int              period = value.find( "." );
  tindex           ti;

  /* If the period cannot be found, throw an error */
  if( period == std::string::npos ) {
    throw std::runtime_error( "Specified index is not in a.b format" );
  }

  /* Populate the tindex */
  ti.row = atoi( value.substr( 0, (period + 1) ).c_str() );
  ti.col = atoi( value.substr( (period + 1) ).c_str() );

  return( ti );

}

/*! \return Returns a string formatted version of the given index */
inline std::string tindex_to_string( const tindex & ti ) {

  std::ostringstream oss;

  oss << ti.row << "." << ti.col;

  return( oss.str() );

}

#endif

