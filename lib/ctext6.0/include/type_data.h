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

    std::string _name;
    std::string _tagname;
    bool        _comstr;
    bool        _matching;

    /*! Copy constructor */
    type_data(
      const type_data & td
    ) {}

    /*! Assignment operator */
    type_data & operator=( const type_data & td ) {
      return( *this );
    }

    void set_internals() {
      _comstr   = (_name.substr(0,9) == "bcomment:") ||
                  (_name.substr(0,9) == "lcomment:") ||
                  (_name == "double")   ||
                  (_name == "single")   ||
                  (_name == "btick")    ||
                  (_name == "tdouble")  ||
                  (_name == "tsingle")  ||
                  (_name == "tbtick");
      _matching = (_name == "curly")  ||
                  (_name == "square") ||
                  (_name == "paren")  ||
                  (_name == "angled") ||
                  (_name == "double") ||
                  (_name == "single") ||
                  (_name == "btick");
    }

  public:

    /*! Default constructor */
    type_data(
      const std::string & name
    ) : _name( name ), _tagname( "" ) {
      set_internals();
    }

    /*! Default constructor */
    type_data(
      const std::string & name,
      const std::string & tagname
    ) : _name( name ), _tagname( tagname ) {
      set_internals();
    }

    /*! Destructor */
    ~type_data() {}

    /*! Returns the string name of the type */
    const std::string & name() const { return( _name ); }

    /*! Equality operator */
    bool operator==( const type_data & td ) const {
      return( _name == td._name );
    }

    /*! Inequality operator */
    bool operator!=( const type_data & td ) const {
      return( !(*this == td) );
    }

    /*! \return Returns true if the type is a comment/string */
    bool comstr() const { return( _comstr ); }

    /*! \return Returns true if the type should be matched */
    bool matching() const { return( _matching ); }

    /*! \return Returns the associated tagname */
    const std::string & tagname() const { return( _tagname ); }

};

#endif

