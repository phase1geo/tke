#ifndef __TYPES_H__
#define __TYPES_H__

/*!
 \file    types.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains functions for storing, updating and retrieving information
          for the marker modeller.
*/

#include <vector>
#include <string>
#include <iostream>

#include "type_data.h"

/*!
 Singleton class containing type information.
*/
class types {

  private:

    std::vector<type_data*> _types;  /*!< Mapping of type string to integer values */

    /*! Default constructor */
    types() {}

    /*! Copy constructor */
    types( const types & t ) {}

    /*! Assignment operator */
    types & operator=( const types & t ) {
      return( *this );
    }

  public:

    /*! Destructor */
    ~types() {}

    /*! Calling point for the class */
    static types & staticObject() {
      static types t;
      return( t );
    }

    /*! Adds the given type to the types list */
    void add( const std::string & name ) {
      if( get( name ) == 0 ) {
        _types.push_back( new type_data( name ) );
      }
    }

    /*! Adds the given type to the types list */
    void add(
      const std::string & name,
      const std::string & tagname
    ) {
      if( get( name ) == 0 ) {
        _types.push_back( new type_data( name, tagname ) );
      }
    }

    /*! Retrieves the integer value of the given string name */
    const type_data* get( const std::string & name ) const {
      for( std::vector<type_data*>::const_iterator it=_types.begin(); it!=_types.end(); it++ ) {
        if( (*it)->name() == name ) {
          return( (*it) );
        }
      }
      return( 0 );
    }

};

/*! Adds the specified type and value to the singleton class */
inline void add_type(
  const std::string & name,
  const std::string & tagname = ""
) {
  types::staticObject().add( name, tagname );
}

/*! \return Returns the side value for the given name */
int get_side( std::string name );

/*! \return Returns the side name for the given value */
std::string get_side( int value );

#endif

