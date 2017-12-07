#ifndef __TINDEX_H__
#define __TINDEX_H__

/*!
 \file     tindex.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
 \brief    Utility types and functions.
*/

#include <string>
#include <iostream>

#include "cpptcl.h"

class tindex {

  private:

    int _row;  /*!< Index row */
    int _col;  /*!< Index column */

  public:

    /*! Default constructor */
    tindex() : _row( 1 ), _col( 0 ) {}

    /*! Constructor */
    tindex( int row, int col ) : _row( row ), _col( col ) {}

    /*! Constructor */
    tindex( const Tcl::object & obj );

    /*! Copy constructor */
    tindex( const tindex & ti ) : _row( ti._row ), _col( ti._col ) {}

    /*! Destructor */
    ~tindex() {}

    /*! Outputs a string version of the index */
    std::string to_string() const {
      std::ostringstream oss;
      oss << _row << "." << _col;
      return( oss.str() );
    }

    /*! Assignment operator */
    tindex & operator=( const tindex & ti ) {
      _row = ti._row;
      _col = ti._col;
      return( *this );
    }

    /*! \return Returns the row associated with this index */
    int row() const { return( _row ); }

    /*! \return Returns the column associated with this index */
    int col() const { return( _col ); }

    /*! Adjusts the row by the given amount */
    void inc_row( int value ) {
      if( (_row += value) < 1 ) {
        _row = 1;
      }
    }

    /*! Equality operator */
    bool operator==( const tindex & ti ) {
      return( (_row == ti._row) && (_col == ti._col) );
    }

    /*! Inequality operator */
    bool operator!=( const tindex & ti ) {
      return( (_row != ti._row) || (_col != ti._col) );
    }

    /*! Less than operator */
    bool operator<( const tindex & ti ) {
      return( (_row < ti._row) || ((_row == ti._row) && (_col < ti._col)) );
    }

    /*! Less than or equal to operator */
    bool operator<=( const tindex & ti ) {
      return( (*this == ti) || (*this < ti) );
    }

    /*! Greater than operator */
    bool operator>( const tindex & ti ) {
      return( (_row > ti._row) || ((_row == ti._row) && (_col > ti._col)) );
    }

    /*! Greater than or equal to operator */
    bool operator>=( const tindex & ti ) {
      return( (*this == ti) || (*this > ti) );
    }

};

#endif

