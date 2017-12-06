#ifndef __SERIAL_ITEM_H__
#define __SERIAL_ITEM_H__

/*!
 \file    serial_item.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains class to handle a single serial item.
*/

#include <string>
#include <iostream>

#include "cpptcl.h"
#include "tindex.h"
#include "position.h"
#include "type_data.h"
#include "tnode.h"

class tnode;

/*!
 Serial item.
*/
class serial_item {

  private:

    const type_data* _type;       /*!< Item type */
    int              _side;       /*!< Side that the item represents of a pair (0 = none, 1 = left, 2 = right, 3 = any) */
    position         _pos;        /*!< Text widget position */
    bool             _iscontext;  /*!< Set to true if this item is a part of a context */
    tnode*           _node;       /*!< Pointer to the tree node associated with this item */
    const type_data* _context;    /*!< Context that this item is only valid in */

  public:

    /*!
     Default constructor.
    */
    serial_item(
      const type_data* type,
      int              side,
      position         pos,
      bool             iscontext,
      const type_data* context
    ) : _type( type ),
        _side( side ),
        _pos( pos ),
        _iscontext( iscontext ),
        _node( 0 ),
        _context( context ) {}

    /*! Constructor from a Tcl object */
    serial_item( const Tcl::object & item );

    /*! Copy constructor */
    serial_item( const serial_item & si );

    /*! Destructor */
    ~serial_item() {}

    /*! Adjust the item when it is the first in the range of items to adjust */
    void adjust_first( int from_col, int to_col, int row_diff, int col_diff ) {
      _pos.adjust_first( from_col, to_col, row_diff, col_diff );
    }

    /*! Adjusts the positional information */
    void adjust( int from_row, int row_diff, int col_diff ) { _pos.adjust( from_row, row_diff, col_diff ); }

    /*! Sets the node pointer to the given node */
    void set_node( tnode* node ) { _node = node; }

    /*! \return Returns the stored side value */
    int side() const { return( _side ); }

    /*! \return Returns the stored type */
    const type_data* type() const { return( _type ); }

    /*! \return Returns the stored context indicator */
    bool iscontext() const { return( _iscontext ); }

    /*! \return Returns the context that this item is valid within */
    const type_data* context() const { return( _context ); }

    /*! \return Returns the stored position information */
    position & pos() { return( _pos ); }

    /*! \return Returns a constant version of the stored position */
    const position & const_pos() const { return( _pos ); }

    /*! \return Returns a pointer to the associated node in the tree */
    tnode* node() const { return( _node ); }

    /*! \return Returns a constant pointer to the stored node */
    const tnode* const_node() const { return( _node ); }

    /*! \return Returns a human-readable version of this element */
    std::string to_string() const;

};

#endif

