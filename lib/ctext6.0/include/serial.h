#ifndef __SERIAL_H__
#define __SERIAL_H__

/*!
 \file    serial.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains class for storing serial marker information.
*/

#include <vector>
#include <string>
#include <iostream>

#include "cpptcl.h"
#include "tindex.h"
#include "sindex.h"
#include "serial.h"
#include "serial_item.h"

/*!
 Implementation of the serial list
*/
class serial : public std::vector<serial_item*> {

  private:

    bool _context_removed;  /*!< Indicates if a context character was removed since the last
                                 call to context_removed() */

    /*!
     Adjusts the serial list positions for the given ranges.
    */
    void adjust(
      const tindex & from,
      const tindex & to,
      const sindex & start,
      const sindex & end
    );

    /*!
     \return Returns the index of the next serial_item that matches the given type, starting
             at index 'start'.  If no matching item is found, a value of -1 is returned.
    */
    int nextindex(
      const sindex &   start,
      const type_data* type
    ) const;

    /*!
     \return Returns the index of the next serial_item that matches the given type, starting
             at index 'start' and stopping at index 'end'.  If no matching item is found, a
             value of -1 is returned.
    */
    int nextindex(
      const sindex &    start,
      const sindex &    end,
      const type_data* type
    ) const;

    /*!
     \return Returns the index of the previous serial_item that matches the given type,
             starting at index 'start'.  If no matching item is found, a value of -1 is
             returned.
    */
    int previndex(
      const sindex &   start,
      const type_data* type
    ) const;

    /*!
     \return Returns the index of the previous serial_item that matches the given type,
             starting at index 'start' and stopping at index 'end'.  If no matching item
             is found, a value of -1 is returned.
    */
    int previndex(
      const sindex &   start,
      const sindex &   end,
      const type_data* type
    ) const;

    /*!
     \return Returns true if the reindent mark at index should be treated as an unindent.
    */
    bool is_unindent_after_reindent (
      const tindex & ti
    ) const;

    /*!
     \return Returns true if the line containing the given text index should cause the
             following line to be indented.
    */
    bool line_contains_indentation(
      const tindex & ti
    ) const;

  public:

    /*! Default constructor */
    serial() : _context_removed( false ) {}

    /*! Destructor */
    ~serial();

    /*! Clears the contents for reuse */
    void clear();

    /*!< Adds the given item to the end of the list */
    void append( Tcl::object item );

    /*! Called when text is going to be inserted.  Adjusts the indices accordingly. */
    void insert( const std::vector<tindex> & ranges );

    /*! Called when text is going to be deleted.  Adjusts the indices accordingly. */
    void remove( const std::vector<tindex> & ranges );

    /*! Called when text is going to be replaced.  Adjusts the indices accordingly. */
    void replace( const std::vector<tindex> & ranges );

    /*! \return Returns the index of the text widget position in this list. */
    sindex get_index( const tindex & index ) const;

    /*! \return Returns the pointer to the node containing the given index */
    tnode* find_node( const tindex & index ) const;

    /*! \return Returns a stringified version of the serial list */
    std::string to_string() const;

    /*! \return Returns a human-readable version of the serial list */
    std::string show() const;

    /*! \return Returns true if the given index is immediately preceded by an escape */
    bool is_escaped( const tindex & ti ) const;

    /*! \return Returns true if the given index contains the given type */
    bool is_index(
      const std::string & type,
      const tindex      & ti
    ) const;

    /*! \return Returns all comment markers in the specified ranges */
    Tcl::object get_comment_markers(
      const Tcl::object & ranges
    ) const;

    /*! \return Returns true if a context character was recently removed */
    bool context_removed() {
      bool retval = _context_removed;
      _context_removed = false;
      return( retval );
    }

    /*! \return Returns the list of contextual items in the list as a new list */
    void get_context_items( serial & items ) const;

    /*! Updates the serial list with the given list. */
    bool update(
      const tindex & linestart,
      const tindex & lineend,
      serial       & elements
    );

};

#endif

