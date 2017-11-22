#ifndef __TREE_H__
#define __TREE_H__

/*!
 \file    tree.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains tree structure containing brackets.
*/

#include <string>
#include <iostream>

#include "cpptcl.h"
#include "tindex.h"
#include "tnode.h"
#include "serial_item.h"
#include "serial.h"

class tnode;

/*!
 Node tree containing positional information for the given tree
*/
class tree {

  private:

    tnode* _tree;  /*!< Pointer to the tree structure */

    /*!
     Inserts an item into the tree.
    */
    void insert_item(
      tnode*      & current,
      tindex      & lescape,
      serial_item & item
    );

    /*!
     Inserts the given serial item to the left root element.
    */
    void insert_root_left(
      tnode*      & current,
      tindex      & lescape,
      serial_item & item
    );

    /*!
     Inserts the given serial item to the right root element.
    */
    void insert_root_right(
      tnode*      & current,
      tindex      & lescape,
      serial_item & item
    );

    /*!
     Inserts the given serial item to the left or right root element.
    */
    void insert_root_any(
      tnode*      & current,
      tindex      & lescape,
      serial_item & item
    );

    /*!
     Inserts the given serial item to the left node element.
    */
    void insert_left(
      tnode*      & current,
      tindex      & lescape,
      serial_item & item
    );

    /*!
     Inserts the given serial item to the right node element.
    */
    void insert_right(
      tnode*      & current,
      tindex      & lescape,
      serial_item & item
    );

    /*!
     Inserts the given serial item to the left or right node element.
    */
    void insert_any(
      tnode*      & current,
      tindex      & lescape,
      serial_item & item
    );

    /*!
     Handle the case of a serial element that should not be inserted into
     the table.
    */
    void insert_none(
      tnode*      & current,
      tindex      & lescape,
      serial_item & item
    );

    /*!
     Adds a child node to the end of the children list for the given node.
    */
    void add_child_node(
      tnode*      & current,
      bool          left,
      serial_item & item
    );

  public:

    /*! Default constructor */
    tree() : _tree( new tnode( 0 ) ) {}

    /*! Destructor */
    ~tree();

    /*! Updates the serial list */
    void update( serial & sl );

    /*! \return Returns a graphical view of the stored string */
    std::string tree_string() const { return( _tree->tree_string() ); }

    /*! Searches the tree for mismatched nodes. */
    void get_mismatched(
      Tcl::object & mismatched
    ) const {
      _tree->get_mismatched( mismatched );
    }

};

#endif

