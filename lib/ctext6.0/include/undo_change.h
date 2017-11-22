#ifndef __UNDO_CHANGE_H__
#define __UNDO_CHANGE_H__

/*!
 \file     undo_change.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
 \brief    Contains class for handling a single undo change.
*/

#include <vector>
#include <iostream>

#include "cpptcl.h"
#include "tindex.h"
#include "serial.h"
#include "linemap.h"

/*!
 Undo types.
*/
enum {
  UNDO_TYPE_INSERT,
  UNDO_TYPE_DELETE,
  UNDO_TYPE_NUM
};

/*!
 Interface class for undo changes.
*/
class undo_change {

  private:

    int         _type;      /*!< Specifies the change type */
    tindex      _startpos;  /*!< Starting position */
    tindex      _endpos;    /*!< Ending position */
    std::string _str;       /*!< String that was inserted/deleted */
    tindex      _cursor;    /*!< Cursor */
    bool        _mcursor;   /*!< Set to true if we are part of a multicursor group */

  public:

    /*! Default constructor */
    undo_change(
      int                 type,
      tindex              startpos,
      tindex              endpos,
      const std::string & str,
      tindex              cursor,
      bool                mcursor
    ) : _type     ( type ),
        _startpos ( startpos ),
        _endpos   ( endpos ),
        _str      ( str ),
        _cursor   ( cursor ),
        _mcursor  ( mcursor ) {}

    /*! Copy constructor */
    undo_change(
      const undo_change & uc
    ) : _type     ( uc._type ),
        _startpos ( uc._startpos ),
        _endpos   ( uc._endpos ),
        _str      ( uc._str ),
        _cursor   ( uc._cursor ),
        _mcursor  ( uc._mcursor ) {}

    /*! Destructor */
    ~undo_change() {}

    /* Switch the type */
    void invert_type() {
      _type = (_type == UNDO_TYPE_INSERT) ? UNDO_TYPE_DELETE : UNDO_TYPE_INSERT;
    }

    /*! Renders the Tcl list used to perform the associated operation */
    void render(
      Tcl::object & result,
      serial      & ser,
      linemap     & lmap
    ) const;

    /*! \return Returns the stored cursor position */
    const tindex & cursor() const { return( _cursor ); }

    /*!
     \return Returns true if the merge was successful; otherwise,
             returns false.
    */
    bool merge( const undo_change & uc );

};

#endif

