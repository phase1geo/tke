#ifndef __TYPE_DATA_H__
#define __TYPE_DATA_H__

/*!
 \file    type_data.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains class for handling model type information.
*/

#include <string>
#include <iostream>

class type_data {

  private:

    int         _type;
    std::string _tagname;

  public:

    /*! Default constructor */
    type_data(
      int type
    ) : _type( type ), _tagname( "" ) {}

    /*! Default constructor */
    type_data(
      int                 type,
      const std::string & tagname
    ) : _type( type ), _tagname( tagname ) {}

    /*! Copy constructor */
    type_data(
      const type_data & td
    ) : _type( td._type ), _tagname( td._tagname ) {}

    /*! Assignment operator */
    type_data & operator=( const type_data & td ) {
      _type    = td._type;
      _tagname = td._tagname;
      return( *this );
    }

    /*! Destructor */
    ~type_data() {}

    /*! Returns the string name of the type */
    int type() const { return( _type ); }

    /*! \return Returns the associated tagname */
    const std::string & tagname() const { return( _tagname ); }

    /*! Equality operator */
    bool operator==( const type_data & td ) const {
      return( _type == td._type );
    }

    /*! Inequality operator */
    bool operator!=( const type_data & td ) const {
      return( _type != td._type );
    }

    /*! Output operator */
    friend std::ostream & operator<<( std::ostream & os, const type_data* td );

};

inline std::ostream & operator<<( std::ostream & os, const type_data* td ) {

  if( td ) {
    os << std::hex << td->_type << "/" << td->_tagname;
  }

  return( os );

}

#endif

