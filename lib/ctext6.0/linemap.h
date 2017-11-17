#ifndef __LINEMAP_H__
#define __LINEMAP_H__

/*!
 \file     linemap.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/15/2017
 \brief    Contains classes for handling the text widget linemap items.
*/

#include <vector>
#include <map>
#include <iostream>

#include "cpptcl/cpptcl.h"
#include "utils.h"

class linemap_colopts;
class linemap_col;

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

    /*! \return Returns the name of the marker stored on this line (or the empty string if no marker exists) */
    const std::string & marker() const { return( _marker ); }

    /*! \return Returns the Tcl list required for rendering */
    Tcl::object render(
      Tcl::interpreter                & interp,
      const std::vector<linemap_col*> & cols
    ) const;

};

/*!
 Stores the gutter column options.
*/
class linemap_colopts {

  private:

    std::string                       _symbol;
    std::string                       _color;
    std::map<std::string,std::string> _bindings;

  public:

    /*! Default constructor */
    linemap_colopts() : _symbol( "" ), _color( "" ) {}

    /*! Constructor */
    linemap_colopts( Tcl::object opts );

    /*! Destructor */
    ~linemap_colopts() {}

    /*! Configures the structure with the given options */
    void configure( Tcl::object opts );

    /*! \return Returns a Tcl list containing all of the option value pairs */
    Tcl::object configure() const;

    /*! \return Returns the stored value for the given option name */
    Tcl::object cget( const std::string & opt ) const;

    /*! \return Returns a rendered version of this instance */
    Tcl::object render( Tcl::interpreter & interp ) const;

};

/*!
 Stores information for a single gutter column.
*/
class linemap_col {

  private:

    std::string                            _name;    /*!< Name of gutter */
    bool                                   _hidden;  /*!< Set to true if the gutter column should be hidden from view */
    std::map<std::string,linemap_colopts*> _opts;    /*!< Named symbol options */

  public:

    /*! Default constructor */
    linemap_col(
      Tcl::object name,
      Tcl::object opts
    );

    /*! Destructor */
    ~linemap_col();

    /*! \return Returns the name of the column */
    const std::string & name() const { return( _name ); }

    /*! Set the hidden state of the given column */
    void hidden( bool value ) { _hidden = value; }

    /*! \return Returns the hidden state of the column */
    bool hidden() const { return( _hidden ); }

    /*! \return Returns the pointer to the colopts structure for the given value */
    const linemap_colopts* get_value( const std::string & value ) const;

    /*! \return Returns the value of the option for the given symbol */
    Tcl::object cget(
      const std::string & sym,
      const std::string & opt
    ) const;

    /*! Sets the symbol option to the given value */
    Tcl::object configure(
      const std::string & sym,
      Tcl::object         opts
    );

};

/*!
 Tracks the state of the linemap.
*/
class linemap {

  private:

    std::vector<linemap_row*> _rows;
    std::vector<linemap_col*> _cols;

    /*! \return Returns the row index that is at or after the given row number */
    int get_row_index( int row ) const;

    /*! \return Returns the index of the column */
    int get_col_index( const std::string & name ) const;

  public:

    /*! Default constructor */
    linemap() {}

    /*! Destructor */
    ~linemap();

    /*! Sets the marker indicator associated with the given line to the given value */
    void set_marker(
      Tcl::object row,
      Tcl::object value
    );

    /*! \return Returns the marker name stored at the given row */
    Tcl::object get_marker( Tcl::object row ) const;

    /*! \return Returns the row number for the given marker name if it exists; otherwise,
                returns 0. */
    int marker_row( const std::string & name ) const;

    /*! Called when text is inserted into the buffer */
    void insert(
      const std::vector<tindex> & ranges
    );

    /*! Called when text is deleted from the buffer */
    void remove(
      const std::vector<tindex> & ranges
    );

    /*! Called when text is replaced in the buffer */
    void replace(
      const std::vector<tindex> & ranges
    );

    /*! Creates a new gutter, inserting it at the end of the list */
    void create(
      Tcl::object name,
      Tcl::object values
    );

    /*! Destroys a gutter */
    void destroy(
      Tcl::object name
    );

    /*!
     If value is not the empty string, sets the hidden state to the given value.

     \return Returns the current hidden state of the given gutter if value is
             set to the empty string; otherwise, returns false.
    */
    bool hide(
      Tcl::object name,
      Tcl::object value
    );

    /*! Sets one or more lines for the given gutter column */
    void set(
      Tcl::object name,
      Tcl::object values
    );

    /*! Unsets the identified gutter for a single entry or a range */
    void unset(
      Tcl::object name,
      Tcl::object first,
      Tcl::object last
    );

    /*! \return Returns the current value for the given symbol's option */
    Tcl::object cget(
      Tcl::object name,
      Tcl::object symbol,
      Tcl::object option
    ) const;

    /*!
     Allows the user to set one or more symbol options or returns the
     current values in a Tcl list
    */
    Tcl::object configure(
      Tcl::object name,
      Tcl::object symbol,
      Tcl::object opts
    );

    /*! \return Returns the gutter names */
    Tcl::object names() const;

    /*! Renders the linemap for the given range */
    Tcl::object render(
      Tcl::object first_row,
      Tcl::object last_row
    ) const;

};

#endif

