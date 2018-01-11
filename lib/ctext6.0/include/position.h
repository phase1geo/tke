#ifndef __POSITION_H__
#define __POSITION_H__

/*!
 \file    position.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains functions for storing, updating and retrieving information
          for the marker modeller.
*/

#include <string>
#include <iostream>

#include "cpptcl.h"
#include "tindex.h"

/*!
 Contains positional information for a parsed item
*/
class position {

  private:

    int _row;   /*!< Row containing the parsed item */
    int _scol;  /*!< Starting column containing the parsed item */
    int _ecol;  /*!< Ending column containing the parsed item */

  public:

    /*! Default constructor */
    position() : _row( 0 ), _scol( 0 ), _ecol( 0 ) {}

    /*! Constructor */
    position( int row, int scol, int ecol ) : _row( row ), _scol( scol ), _ecol( ecol ) {}

    /*! Constructor */
    position( const Tcl::object & item );

    /*! Copy constructor */
    position( const position & pos ) :
      _row( pos._row ),
      _scol( pos._scol ),
      _ecol( pos._ecol ) {}

    /*! Destructor */
    ~position() {}

    /*! Assignment operator */
    position & operator=( const position & pos ) {
      _row  = pos._row;
      _scol = pos._scol;
      _ecol = pos._ecol;
      return( *this );
    }

    /*! Equality operator */
    bool operator==( const position & pos ) const {
      return( (_row == pos._row) && (_scol == pos._scol) && (_ecol == pos._ecol) );
    }

    /*! Adjust the item when it is the first in the range of items to adjust */
    void adjust_first(
      int from_col,
      int to_col,
      int row_diff,
      int col_diff
    );

    /*! Adjusts the information based on the adjustment value */
    void adjust(
      int from_row,
      int row_diff,
      int col_diff
    );

    /*! Increment the column by one */
    void incr_col() {
      _scol++;
      _ecol++;
    }

    /*!
     \return Returns a value of -1 if the given row/col pair is less than the position, 0 if
             the row/col pair is within the position, or 1 if the row/col pair is greater than
             the position.
    */
    int compare(
      const tindex & index
    ) const {
      if( index.row() == _row ) {
        return( (index.col() < _scol) ? -1 : ((index.col() > _ecol) ? 1 : 0) );
      }
      return( (index.row() < _row) ? -1 : 1 );
    }

    /*!
     \return Returns true if the starting index matches the given text index.
    */
    bool matches_tindex(
      const tindex & ti
    ) const {
      return( (_row == ti.row()) && (_scol == ti.col()) );
    }

    /*! \return Returns the first column text index */
    std::string to_index(
      bool first_col = true
    ) const;

    /*! \return Returns the first or last position as a text index */
    tindex to_tindex(
      bool first_col = true
    ) const;

    /*! \return Returns a Tcl object containing a list of the text widget indices */
    void to_pair( Tcl::object & pair ) const;

    /*! \return Returns the position as a string */
    std::string to_string() const;

    /*! \return Returns the stored row */
    int row() const { return( _row ); }

    /*! \return Returns the starting column */
    int start_col() const { return( _scol ); }

};

#endif

