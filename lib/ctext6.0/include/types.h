#ifndef __TYPES_H__
#define __TYPES_H__

/*!
 \file    types.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains functions for storing, updating and retrieving information
          for the marker modeller.
*/

#include <map>
#include <string>
#include <iostream>

#include "type_data.h"

/*!
 Singleton class containing type information.
*/
class types {

  private:

    std::map<std::string,type_data*> _types;  /*!< Mapping of type string to integer values */
    int                              _matching;
    int                              _comstr;
    int                              _indent;
    int                              _reindent;
    int                              _reindentStart;

    /*! Copy constructor */
    types( const types & t ) {}

    /*! Assignment operator */
    types & operator=( const types & t ) {
      return( *this );
    }

    void set_matching(
      const std::string & name,
      int bitpos
    ) {
      _matching |= ((name == "curly")  ||
                    (name == "square") ||
                    (name == "paren")  ||
                    (name == "angled") ||
                    (name == "double") ||
                    (name == "single") ||
                    (name == "btick")) ? (1 << bitpos) : 0;
    }

    void set_comstr(
      const std::string & name,
      int bitpos
    ) {
      _comstr |= ((name.substr(0,9) == "bcomment:") ||
                  (name.substr(0,9) == "lcomment:") ||
                  (name == "double")   ||
                  (name == "single")   ||
                  (name == "btick")    ||
                  (name == "tdouble")  ||
                  (name == "tsingle")  ||
                  (name == "tbtick")) ? (1 << bitpos) : 0;
    }

  public:

    /*! Default constructor */
    types() {}

    /*! Destructor */
    ~types() {
      clear();
    }

    /*! Clears the class for reuse */
    void clear() {
      for( std::map<std::string,type_data*>::iterator it=_types.begin(); it!=_types.end(); it++ ) {
        delete it->second;
      }
      _types.clear();
    }

    /*! Adds the given type to the types list */
    void add(
      const std::string & name,
      const std::string & tagname,
      int                 matching,
      int                 comstr,
      int                 indent,
      int                 reindent,
      int                 reindentStart
    ) {
      if( get( name ) == -1 ) {
        int bitpos = _types.size();
        _types.insert( make_pair( name, new type_data( (1 << bitpos), tagname ) ) );
        _matching      |= (matching      << bitpos);
        _comstr        |= (comstr        << bitpos);
        _indent        |= (indent        << bitpos);
        _reindent      |= (reindent      << bitpos);
        _reindentStart |= (reindentStart << bitpos);
      }
    }

    /*! Retrieves the integer value of the given string name */
    int get( const std::string & name ) const {
      std::map<std::string,type_data*>::const_iterator it = _types.find( name );
      if( it == _types.end() ) {
        return( -1 );
      }
      return( it->second->type() );
    }

    /*! \return Returns true if the given type is one that should be matched */
    bool is_matching( int type ) const { return( (type & _matching) != 0 ); }

    /*! \return Returns true if the given type is a comment or string */
    bool is_comstr( int type ) const { return( (type & _comstr) != 0 ); }

    /*! \return Returns true if the given type is an indent or unindent type */
    bool is_indent( int type ) const { return( (type & _indent) != 0 ); }

    /*! \return Returns true if the given type is a reindent type */
    bool is_reindent( int type ) const { return( (type & _reindent) != 0 ); }

    /*! \return Returns true if the given type is a reindentStart type */
    bool is_reindentStart( int type ) const { return( (type & _reindentStart) != 0 ); }

};

/*! \return Returns the side value for the given name */
int get_side( std::string name );

/*! \return Returns the side name for the given value */
std::string get_side( int value );

#endif

