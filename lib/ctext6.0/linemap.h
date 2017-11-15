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

class linemap_colopts;
class linemap_col;

/*!
 Tracks the state of all linemap gutter items for a single row.
*/
class linemap_row {

  private:

    int                           _row;     /*!< Specifies the row number associated with this instance */
    std::string                   _marker;  /*!< Specifies the name of the marker */
    std::vector<linemap_colopts*> _items;   /*!< Fully populated list of items for the given row */

  public:

    /*! Default constructor */
    linemap_row( int row ) : _row( row ), _marker( "" ) {}

    /*! Destructor */
    ~linemap_row();

    /*! Add a column at the given position */
    void add_column( int pos ) { _items.insert( (_items.begin() + pos), 0 ); }

    /*! Remove the given column from the gutter */
    void remove_column( int pos ) { _items.erase( _items.begin() + pos ); }

    /*! Returns the row number associated with this row */
    int row() const { return( _row ); }

    /*! Increments the row number by the given amount */
    void increment( int value ) { _row += value; }

    /*! Sets the marker with the given name */
    void marker( const std::string & name ) { _marker = name; }

    /*! Sets the given gutter item in the given column to the given value */
    void set_value( int col, linemap_colopts* value ) { _items[col] = value; }

    /*! \return Returns the name of the marker stored on this line (or the empty string if no marker exists) */
    const std::string & marker() const { return( _marker ); }

    /*! \return Returns the Tcl list required for rendering */
    Tcl::object render(
      Tcl::interpreter                 & interp,
      const std::vector<linemap_cols*> & cols
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
    linemap_colopts() _symbol( "" ), _color( "" ) {}

    /*! Destructor */
    ~linemap_colopts() {}

    /*! Sets the symbol to the given value */
    void symbol( const std::string & symbol ) { _symbol = symbol; }

    /*! \return Returns the stored symbol */
    const std::string & symbol() const { return( _symbol ); }

    /*! Sets the color to the given value */
    void color( const std::string & color ) { _color = color; }

    /*! \return Returns the stored color */
    const std::string & color() const { return( _color ); }

    /*!
     Adds the given binding to the binding list.  If command is set to
     the empty string, removes the given binding event.
    */
    void add_binding(
      const std::string & event,
      const std::string & command
    ) {
      std::map<std::string,std::string>::iterator it = _bindings.find( event );
      if( it == _bindings.end() ) {
        if( command != "" ) {
          _bindings.insert( std::make_pair( event, command ) );
        }
      } else {
        if( command == "" ) {
          _bindings.erase( it );
        } else {
          it->second = command;
        }
      }
    }

    /*! \return Returns the command associated with the given event binding */
    std::string get_binding( const std::string & event ) const {
      std::map<std::string,std::string>::const_iterator it = _bindings.find( event );
      if( it == _bindings.end() ) {
        return( "" );
      } else {
        return( it->second );
      }
    }

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
      const std::string & name
    ) : _name( name ), _hidden( false ) {}

    /*! Destructor */
    ~linemap_col();

    /*! Equality operator */
    bool operator==( const std::string & name ) const {
      return( _name == name );
    }

    /*! Set the hidden state of the given column */
    void hidden( bool value ) { _hidden = value; }

    /*! \return Returns the hidden state of the column */
    bool hidden() const { return( _hidden ); }

    /*! \return Returns the pointer to the colopts structure for the given value */
    linemap_colopts* get_value( const std::string & value );

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

    /*! Sets the given gutter item to the given value */
    void set_item(
      const std::string & name,
      int                 row,
      const std::string & value
    );

    /*! \return Returns the row number for the given marker name if it exists; otherwise,
                returns 0. */
    int marker_row( const std::string & name ) const;

    /*! \return Returns the total number of gutters in the linemap */
    int num_gutters() const { return( _cols.size() ); }

    /*! Renders the linemap for the given range */
    Tcl::object render(
      int first_row,
      int last_row
    ) const;

};

#endif

