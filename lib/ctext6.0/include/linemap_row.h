#ifndef __LINEMAP_ROW_H__
#define __LINEMAP_ROW_H__

/*!
 \file     linemap_row.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
 \brief    Contains class for handling a linemap row
*/

#include <vector>
#include <map>
#include <iostream>

#include "cpptcl.h"
#include "linemap_colopts.h"
#include "linemap_col.h"

/*!
 Tracks the state of all linemap gutter items for a single row.
*/
class linemap_row {

  private:

    int                                 _row;     /*!< Specifies the row number associated with this instance */
    std::string                         _marker;  /*!< Specifies the name of the marker */
    std::vector<const linemap_colopts*> _items;   /*!< Fully populated list of items for the given row */

  public:

    /*! Default constructor */
    linemap_row( int row, int cols ) : _row( row ), _marker( "" ) {
      for( int i=0; i<cols; i++ ) {
        _items.push_back( 0 );
      }
    }

    /*! Destructor */
    ~linemap_row() {}

    /*! Add a column at the given position */
    void add_column() { _items.push_back( 0 ); }

    /*! Remove the given column from the gutter */
    void remove_column( int pos ) { _items.erase( _items.begin() + pos ); }

    /*! Returns the row number associated with this row */
    int row() const { return( _row ); }

    /*! Increments the row number by the given amount */
    void increment( int value ) {
      _row += value;
    }

    /*! Sets the marker with the given name */
    void set_marker( const std::string & name ) { _marker = name; }

    /*! Sets the given gutter item in the given column to the given value */
    void set_value( int col, const linemap_colopts* value ) { _items[col] = value; }
    
    /*! \return Returns the stored value */
    const linemap_colopts* get_value( int col ) const { return( _items[col] ); }
    
    /*! Clears the value if it matches the given value */
    void clear_value( int col, const linemap_colopts* value ) {
      if( _items[col] == value ) {
        _items[col] = 0;
      }
    }

    /*! \return Returns the name of the marker stored on this line (or the empty string if no marker exists) */
    const std::string & marker() const { return( _marker ); }

    /*! \return Returns the Tcl list required for rendering */
    Tcl::object render(
      Tcl::interpreter                & interp,
      const std::vector<linemap_col*> & cols
    ) const;

};

#endif

