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

#include "cpptcl.h"
#include "tindex.h"
#include "linemap_row.h"
#include "linemap_col.h"

/*!
 Tracks the state of the linemap.
*/
class linemap {

  private:

    std::vector<linemap_row*> _rows;
    std::vector<linemap_col*> _cols;
    std::map<std::string,int> _fold_increment;

    /*! \return Returns the row index that is at or after the given row number */
    int get_row_index( int row ) const;

    /*! \return Returns the index of the column */
    int get_col_index( const std::string & name ) const;

  public:

    /*! Default constructor */
    linemap();

    /*! Destructor */
    ~linemap();

    /*! Sets the marker indicator associated with the given line to the given value */
    void set_marker(
      const Tcl::object & row,
      const Tcl::object & value
    );

    /*! \return Returns the marker name stored at the given row */
    Tcl::object get_marker_name(
      const Tcl::object & row
    ) const;

    /*! \return Returns the line number containing the marker with the given name */
    Tcl::object get_marker_line(
      const Tcl::object & name
    ) const;

    /*! \return Returns the row number for the given marker name if it exists; otherwise,
                returns 0. */
    int marker_row( const std::string & name ) const;

    /*! Called when text is inserted into the buffer */
    void insert(
      const std::vector<tindex> & ranges
    );

    /*! Called when text is deleted from the buffer */
    Tcl::object remove(
      const std::vector<tindex> & ranges
    );

    /*! Called when text is replaced in the buffer */
    Tcl::object replace(
      const std::vector<tindex> & ranges
    );

    /*! Creates a new gutter, inserting it at the end of the list */
    void create(
      const Tcl::object & name,
      const Tcl::object & values
    );

    /*! Destroys a gutter */
    void destroy(
      const Tcl::object & name
    );

    /*!
     If value is not the empty string, sets the hidden state to the given value.

     \return Returns the current hidden state of the given gutter if value is
             set to the empty string; otherwise, returns false.
    */
    bool hide(
      const Tcl::object & name,
      const Tcl::object & value
    );

    /*! Deletes the symbols from the gutter */
    void delete_symbols(
      const Tcl::object & name,
      const Tcl::object & syms
    );

    /*! Sets one or more lines for the given gutter column */
    void set(
      const Tcl::object & name,
      const Tcl::object & values
    );

    /*! Sets the line number to the given name */
    void set(
      const std::string & name,
      const std::string & value,
      int                 row
    );

    /*! Unsets the identified gutter for a single entry or a range */
    void unset(
      const Tcl::object & name,
      const Tcl::object & first,
      const Tcl::object & last
    );

    /*! Clears all elements in the given gutter */
    void clear(
      const std::string & name
    );

    /*! \return Returns the gutter symbol location information */
    Tcl::object get(
      const Tcl::object & name,
      const Tcl::object & value,
      const Tcl::object & valueisint
    ) const;

    /*! \return Returns the value stored at the given line number */
    std::string get(
      const std::string & name,
      int                 row
    );

    /*! \return Returns the current value for the given symbol's option */
    Tcl::object cget(
      const Tcl::object & name,
      const Tcl::object & symbol,
      const Tcl::object & option
    ) const;

    /*!
     Allows the user to set one or more symbol options or returns the
     current values in a Tcl list
    */
    Tcl::object configure(
      const Tcl::object & name,
      const Tcl::object & symbol,
      const Tcl::object & opts
    );

    /*! \return Returns the gutter names */
    Tcl::object names() const;

    /*! Renders the linemap for the given range */
    Tcl::object render(
      const Tcl::object & first_row,
      const Tcl::object & last_row
    ) const;

    Tcl::object fold_delete(
      const Tcl::object & line
    );

    Tcl::object fold_delete_range(
      const Tcl::object & startline,
      const Tcl::object & endline
    );

    /*!
     Opens the given fold for the specified depth.

     \return Returns a Tcl list containing indices that need to be un-elided.
    */
    Tcl::object fold_open(
      const Tcl::object & startline,
      const Tcl::object & depth_obj
    );

    Tcl::object fold_open_range(
      const Tcl::object & startline,
      const Tcl::object & endline
    );

    Tcl::object fold_show_line(
      const Tcl::object & line
    );

    /*!
     Closes the given fold for the specified depth.

     \return Returns a Tcl list containing indices that need to be elided.
    */
    Tcl::object fold_close(
      const Tcl::object & startline,
      const Tcl::object & depth_obj
    );

    Tcl::object fold_close_range(
      const Tcl::object & startline,
      const Tcl::object & endline
    );

    Tcl::object fold_find(
      const Tcl::object & startline,
      const Tcl::object & dir,
      const Tcl::object & num
    );

    /*! \return Returns the fold information for a given range */
    Tcl::object get_fold_info(
      Tcl::object startline,
      Tcl::object depth_obj
    ) const;

};

#endif

