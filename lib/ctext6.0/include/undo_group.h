#ifndef __UNDO_GROUP_H__
#define __UNDO_GROUP_H__

/*!
 \file     undo_group.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
 \brief    Contains class for handling a group of changes.
*/

#include <vector>
#include <iostream>

#include "cpptcl.h"
#include "undo_change.h"
#include "serial.h"
#include "linemap.h"

/*!
 A group of changes.
*/
class undo_group : public std::vector<undo_change*> {

  public:

    /*! Default constructor */
    undo_group() {}

    /*! Copy constructor */
    undo_group( const undo_group & ug ) {
      for( std::vector<undo_change*>::const_iterator it=ug.begin(); it!=ug.end(); it++ ) {
        push_back( new undo_change( **it ) );
      }
    }

    /*! Destructor */
    ~undo_group() { clear_group(); }

    /*! Clear all of the memory associated with this group */
    void clear_group() {
      for( std::vector<undo_change*>::iterator it=begin(); it!=end(); it++ ) {
        delete *it;
      }
      clear();
    }

    /*! Renders the commands required for the undo/redo operation for the group */
    Tcl::object render(
      serial  & ser,
      linemap & lmap
    );

    /*! Returns the first cursor position of this change group */
    const tindex & first_cursor() const {
      return( front()->cursor() );
    }

    /*! Returns the last cursor position of this change group */
    const tindex & last_cursor() const {
      return( back()->cursor() );
    }

    /*! Generates a list of all stored cursor positions in the group */
    void cursor_history( Tcl::object & result ) const;

};

#endif

