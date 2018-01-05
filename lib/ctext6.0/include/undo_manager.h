#ifndef __UNDO_MANAGER_H__
#define __UNDO_MANAGER_H__

/*!
 \file     undo_manager.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
 \brief    Contains main class for handling the undo facility.
*/

#include <vector>
#include <iostream>

#include "cpptcl.h"
#include "tindex.h"
#include "serial.h"
#include "linemap.h"
#include "undo_change.h"
#include "undo_group.h"
#include "undo_buffer.h"

/*!
 Main class that manages the undo buffer.
*/
class undo_manager {

  private:

    undo_buffer _undo_buffer;    /*!< Undo buffer */
    undo_buffer _redo_buffer;    /*!< Redo buffer */
    undo_group* _uncommitted;    /*!< Uncommitted group */
    bool        _auto_separate;  /*!< Configuration option */

    /*! Add insertion change */
    void add_change(
      const undo_change & change,
      bool                stop_separate
    );

  public:

    /*! Default constructor */
    undo_manager() : _uncommitted( 0 ), _auto_separate( true ) {}

    /*! Destructor */
    ~undo_manager() {
      if( _uncommitted ) {
        delete _uncommitted;
      }
    }

    /*! Sets the auto_separate value */
    void auto_separate(
      const Tcl::object & value
    ) {
      Tcl::interpreter i( value.get_interp(), false );
      _auto_separate = value.get<bool>( i );
    }

    /*! \return Returns the current auto-separate option */
    Tcl::object auto_separate() const {
      return( (Tcl::object)_auto_separate );
    }

    /*! Adds an insertion entry into the buffer */
    void add_insertion(
      const std::vector<tindex> & ranges,
      const Tcl::object & str,
      const Tcl::object & cursor
    );

    /*! Adds an insertion entry into the buffer */
    void add_insertion_list(
      const std::vector<tindex> & ranges,
      const Tcl::object & strs,
      const Tcl::object & cursor
    );

    /*! Adds an insertion entry into the buffer */
    void add_deletion(
      const std::vector<tindex> & ranges,
      const Tcl::object & strs,
      const Tcl::object & cursor
    );

    /*! Adds the equivalent of a replacement entry into the buffer */
    void add_replacement(
      const std::vector<tindex> & ranges,
      const Tcl::object & dstrs,
      const Tcl::object & istrs,
      const Tcl::object & cursor
    );

    /*! Commits the current change to the undo buffer */
    void add_separator();

    /*! Retrieves the last change */
    Tcl::object undo(
      serial  & ser,
      linemap & lmap
    );

    /*! Undoes the last undo */
    Tcl::object redo(
      serial  & ser,
      linemap & lmap
    );

    /*! Retrieves the cursor history in a list */
    Tcl::object cursor_history() const {
      return( _undo_buffer.cursor_history() );
    }

    /*! \return Returns true if the undo buffer is empty */
    Tcl::object undoable() const {
      return( (Tcl::object)((_uncommitted != 0) || !_undo_buffer.empty()) );
    }

    /*! \return Returns true if the redo buffer is empty */
    Tcl::object redoable() const {
      return( (Tcl::object)(!_redo_buffer.empty()) );
    }

    /*! Resets the undo/redo buffer */
    void reset();

};

#endif

