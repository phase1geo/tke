#ifndef __UNDO_BUFFER_H__
#define __UNDO_BUFFER_H__

/*!
 \file     undo_buffer.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
 \brief    Contains class for handling an undo buffer.
*/

#include <vector>
#include <iostream>

#include "cpptcl.h"
#include "undo_group.h"

/*!
 Represents an undo/redo buffer.
*/
class undo_buffer : public std::vector<undo_group*> {

  public:

    /*! Constructor */
    undo_buffer() {}

    /*! Destructor */
    ~undo_buffer() {
      clear_buffer();
    }

    /*! Deallocates all memory associated with the buffer */
    void clear_buffer() {
      for( std::vector<undo_group*>::iterator it=begin(); it!=end(); it++ ) {
        delete *it;
      }
      clear();
    }

    /*! \return Returns the history of cursor positions from the buffer */
    Tcl::object cursor_history() const;

};

#endif

