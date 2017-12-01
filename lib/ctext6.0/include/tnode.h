#ifndef __TNODE_H__
#define __TNODE_H__

/*!
 \file    tnode.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains functions for storing, updating and retrieving information
          for the marker modeller.
*/

#include <vector>
#include <string>
#include <iostream>

#include "cpptcl.h"
#include "type_data.h"
#include "position.h"
#include "serial_item.h"

class serial_item;

/*!
 Tree node.
*/
class tnode {

  private:

    tnode*              _parent;    /*!< Pointer to parent node */
    std::vector<tnode*> _children;  /*!< Pointer to children of this node */
    serial_item*        _left;      /*!< Index of serial item on the left side */
    serial_item*        _right;     /*!< Index of serial item on the right side */
    const type_data*    _type;      /*!< Item type */
    bool                _hidden;    /*!< Hidden indicator */

  public:

    /*! Default constructor */
    tnode( const type_data* type ) :
      _parent( 0 ), _left( 0 ), _right( 0 ), _type( type ), _hidden( false ) {}

    /*! Copy constructor */
    tnode( const tnode & node ) :
      _parent  ( 0 ),
      _left    ( node._left ),
      _right   ( node._right ),
      _type    ( node._type ),
      _hidden  ( node._hidden ) {}

    /*! Destructor */
    ~tnode() { clear(); }

    /*! Recursively destroys all nodes under this node including itself */
    void clear();

    /*! \return Returns true if the node does not contain a matching set */
    bool incomplete() const { return( (_type != 0) && ((_left == 0) || (_right == 0)) ); }

    /*! Sets the left pointer in the node to the given item */
    void left( serial_item* item ) { _left = item; }

    /*! \return Returns the pointer to the serial item on the left */
    const serial_item* left() const { return( _left ); }

    /*! Sets the right pointer in the node to the given item */
    void right( serial_item* item ) { _right = item; }

    /*! \return Returns the pointer to the serial item on the right */
    const serial_item* right() const { return( _right ); }

    /*! Adds the node to the end of the list of children */
    void add_child( tnode* child ) {
      _children.push_back( child );
      child->_parent = this;
    }

    /*! \return Returns a reference to the parent node */
    tnode* parent() { return( _parent ); }

    /*! \return Returns the children nodes of this node */
    std::vector<tnode*> & children() { return( _children ); }

    /*! \return Returns true if this node is the root node */
    bool isroot() const { return( _parent == 0 ); }

    /*! \return Returns the type of the node */
    const type_data* type() const { return( _type ); }

    /*! \return Returns the index of the node in the parent */
    int index() const;

    /*! \return Returns the depth of the node in the tree with the matching type */
    int depth() const;

    /*! \return Returns the depth of the node in the tree with the matching type */
    int depth( const type_data* type ) const;

    /*! \return Returns a string representation of this node and all children nodes */
    std::string to_string() const;

    /*! \return Recursively returns string version of the subtree */
    std::string tree_string() const;

    /*! Adds this node and all children nodes that are mismatched to the object list */
    void get_mismatched(
      Tcl::object & mismatched
    ) const;

    /*! \return Returns the position of the matching position */
    bool get_match_pos(
      const serial_item*   si,
      position           & pos
    ) const;

};

#endif

