#ifndef __SINDEX_H__
#define __SINDEX_H__

/*!
 \file    sindex.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Class for storing and handling an index into the serial list.
*/

/*! Serial list index return value */
class sindex {

  private:

    int  _index;
    bool _matches;

  public:

    /*! Default constructor */
    sindex() : _index( -1 ), _matches( false ) {}

    /*! Default constructor */
    sindex( int index, bool matches ) : _index( index ), _matches( matches ) {}

    /*! Copy constructor */
    sindex( const sindex & si ) : _index( si._index ), _matches( si._index ) {}

    /*! Destructor */
    ~sindex() {}

    /*! \return Returns the stored index */
    int index() const { return( _index ); }

    /*! \return Returns the stored matches value */
    int matches() const { return( _matches ); }

    /*!
     Assignment operator.

     \return Returns a reference to this class
    */
    sindex & operator=( const sindex & si ) {
      _index   = si._index;
      _matches = si._matches;
      return( *this );
    }

    /*! \return Returns a string version of this instance */
    std::string to_string() const {
      std::ostringstream oss;
      oss << _index << "/" << _matches;
      return( oss.str() );
    }

    /*! \return Returns true if the two sindices are the same */
    bool operator==( const sindex & si ) {
      return( (_index == si._index) && (_matches == si._matches) );
    }

    /*! \return Returns true if the two sindices are the different */
    bool operator!=( const sindex & si ) {
      return( !(*this == si) );
    }

};

#endif

