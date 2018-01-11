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

/*!
 Singleton class containing type information.
*/
class types {

  private:

    std::map<std::string,int> _types;
    std::map<int,std::string> _tags;
    std::string               _empty;
    int                       _bracket;
    int                       _string;
    int                       _comment;
    int                       _indent;
    int                       _reindent;
    int                       _reindentStart;

    /*! Copy constructor */
    types( const types & t ) {}

    /*! Assignment operator */
    types & operator=( const types & t ) {
      return( *this );
    }

    void set_internals(
      const std::string & name,
      int bitpos
    ) {
      _bracket       |= ((name == "curly")   ||
                         (name == "square")  ||
                         (name == "paren")   ||
                         (name == "angled")) ? (1 << bitpos) : 0;
      _string        |= ((name == "double")   ||
                         (name == "single")   ||
                         (name == "btick")    ||
                         (name == "tdouble")  ||
                         (name == "tsingle")  ||
                         (name == "tbtick")) ? (1 << bitpos) : 0;
      _comment       |= (name.substr(0, 8) == "comment:")       ? (1 << bitpos) : 0;
      _indent        |= (name.substr(0, 7) == "indent:")        ? (1 << bitpos) : 0;
      _reindent      |= (name.substr(0, 9) == "reindent:")      ? (1 << bitpos) : 0;
      _reindentStart |= (name.substr(0,14) == "reindentStart:") ? (1 << bitpos) : 0;
    }

  public:

    /*! Default constructor */
    types()
    : _empty         ( "" ),
      _bracket       ( 0 ),
      _string        ( 0 ),
      _comment       ( 0 ),
      _indent        ( 0 ),
      _reindent      ( 0 ),
      _reindentStart ( 0 ) {}

    /*! Destructor */
    ~types() {
      clear();
    }

    /*! Clears the class for reuse */
    void clear() {
      _types.clear();
      _tags.clear();
      _bracket       = 0;
      _string        = 0;
      _comment       = 0;
      _indent        = 0;
      _reindent      = 0;
      _reindentStart = 0;
    }

    /*! Adds the given type to the types list */
    void add(
      const std::string & name,
      const std::string & tagname
    ) {
      if( type( name ) == -1 ) {
        int bitpos = _types.size();
        _types.insert( make_pair( name, (1 << bitpos) ) );
        _tags.insert( make_pair( (1 << bitpos), tagname ) );
        set_internals( name, bitpos );
      }
    }

    /*! Retrieves the integer value of the given string name */
    int type( const std::string & name ) const {
      std::map<std::string,int>::const_iterator it = _types.find( name );
      if( it == _types.end() ) {
        return( -1 );
      }
      return( it->second );
    }

    /*! \return Returns the tag associated with the given type */
    const std::string & tag( int type ) const {
      std::map<int,std::string>::const_iterator it = _tags.find( type );
      if( it == _tags.end() ) {
        return( _empty );
      }
      return( it->second );
    }

    /*! \return Returns true if the given type is one that should be matched */
    bool is_matching( int type ) const { return( (type & (_bracket | _string)) != 0 ); }

    /*! \return Returns true if the given type is a comment or string */
    bool is_comstr( int type ) const { return( (type & (_comment | _string)) != 0 ); }

    /*! \return Returns true if the given type is a comment */
    bool is_comment( int type ) const { return( (type & _comment) != 0 ); }

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

