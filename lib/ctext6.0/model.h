#ifndef __MODEL_H__
#define __MODEL_H__

/*!
 \file    model.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains functions for storing, updating and retrieving information
          for the marker modeller.
*/

#include <vector>
#include <string>
#include <map>

#include "cpptcl/cpptcl.h"

/*! Text widget index */
typedef struct {
  int row;
  int col;
} tindex;

class types {

  private:

    std::map<std::string,int> _types;  /*!< Mapping of type string to integer values */
    std::map<int,std::string> _names;  /*!< Mapping of type integer to string values */
    std::string               _empty;

    /*! Default constructor */
    types() : _empty( "" ) {}

    /*! Assignment operator */
    types & operator=( const types & t ) {
      for( std::map<std::string,int>::const_iterator it=t._types.begin(); it!=t._types.end(); it++ ) {
        _types.insert( std::make_pair( (*it).first, (*it).second ) );
      }
      for( std::map<int,std::string>::const_iterator it=t._names.begin(); it!=t._names.end(); it++ ) {
        _names.insert( std::make_pair( (*it).first, (*it).second ) );
      }
    }

  public:

    /*! Destructor */
    ~types() {}
  
    /*! Calling point for the class */
    static types & staticObject() {
      static types t;
      return( t );
    }

    /*! Adds the given name/value pairing to the class */
    void add( std::string name, int value ) {
      _types.insert( std::make_pair( name, value ) );
    }

    /*! Retrieves the integer value of the given string name */
    int get( const std::string & name ) const {
      std::map<std::string,int>::const_iterator it = _types.find( name );
      if( it == _types.end() ) {
        return( -1 );
      }
      return( it->second );
    }

    /*! Retrieves the string name of the given integer type value */
    const std::string & get( int value ) const {
      std::map<int,std::string>::const_iterator it = _names.find( value );
      if( it == _names.end() ) {
        return( _empty );
      }
      return( it->second );
    }

    /*! \return Returns true if the given type is a comment or string type */
    bool comstr( int value ) const {

      return( (get( "bcomment" ) == value) ||
              (get( "lcomment" ) == value) ||
              (get( "double" )   == value) ||
              (get( "single" )   == value) ||
              (get( "btick" )    == value) ||
              (get( "tdouble" )  == value) ||
              (get( "tsingle" )  == value) ||
              (get( "tbtick" )   == value) );

    }

};

inline void add_type(
  std::string name,
  int         value
) {
  types::staticObject().add( name, value );
}

/*! Serial list index return value */
class sindex {

  private:

    int  _index;
    bool _matches;

  public:

    /*! Default constructor */
    sindex() : _index( -1 ), _matches( false ) {}

    /*! Default constructor */
    sindex( int index, bool matches ) : _index( index ), _matches( matches ) {}

    /*! Copy constructor */
    sindex( const sindex & si ) : _index( si._index ), _matches( si._index ) {}

    /*! Destructor */
    ~sindex() {}

    /*! \return Returns the stored index */
    int index() const { return( _index ); }

    /*! \return Returns the stored matches value */
    int matches() const { return( _matches ); }

    /*!
     Assignment operator.

     \return Returns a reference to this class
    */
    sindex & operator=( const sindex & si ) {
      _index   = si._index;
      _matches = si._matches;
      return( *this );
    }

    /*! \return Returns true if the two sindices are the same */
    bool operator==( const sindex & si ) {
      return( (_index == si._index) && (_matches == si._matches) );
    }

    /*! \return Returns true if the two sindices are the different */
    bool operator!=( const sindex & si ) {
      return( !(*this == si) );
    }

};

/*!
 Contains positional information for a parsed item
*/
class position {

  private:

    int _row;   /*!< Row containing the parsed item */
    int _scol;  /*!< Starting column containing the parsed item */
    int _ecol;  /*!< Ending column containing the parsed item */

  public:

    /*! Default constructor */
    position() : _row( 0 ), _scol( 0 ), _ecol( 0 ) {}

    /*! Constructor */
    position( int row, int scol, int ecol ) : _row( row ), _scol( scol ), _ecol( ecol ) {}

    /*! Constructor */
    position( Tcl::object item );

    /*! Copy constructor */
    position( const position & pos ) :
      _row( pos._row ),
      _scol( pos._scol ),
      _ecol( pos._ecol ) {}

    /*! Destructor */ 
    ~position() {}

    /*! Assignment operator */
    position & operator=( const position & pos ) {
      _row  = pos._row;
      _scol = pos._scol;
      _ecol = pos._ecol;
      return( *this );
    }

    /*! Adjust the item when it is the first in the range of items to adjust */
    void adjust_first(
      int from_col,
      int to_col,
      int col_diff
    );

    /*! Adjusts the information based on the adjustment value */
    void adjust(
      int from_row,
      int row_diff,
      int col_diff
    );

    /*! Increment the column by one */
    void incr_col() {
      _scol++;
      _ecol++;
    } 
    
    /*!
     \return Returns a value of -1 if the given row/col pair is less than the position, 0 if
             the row/col pair is within the position, or 1 if the row/col pair is greater than
             the position.
    */
    int compare(
      const tindex & index
    ) const {
      if( index.row == _row ) {
        return( (index.col < _scol) ? -1 : ((index.col > _ecol) ? 1 : 0) );
      }
      return( (index.row < _row) ? -1 : 1 );
    }

    /*! \return Returns a Tcl object containing a list of the text widget indices */
    void to_pair( Tcl::object & pair ) const;

    /*! \return Returns the position as a string */
    std::string to_string() const;

};

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
    int                 _type;      /*!< Item type */
    bool                _hidden;    /*!< Hidden indicator */
    bool                _comstr;    /*!< Set to true if the type is a comment/string indicator */

  public:

    /*! Default constructor */
    tnode( int type, bool comstr ) :
      _left( 0 ), _right( 0 ), _type( type ), _hidden( false ), _comstr( comstr ) {}

    /*! Copy constructor */
    tnode( const tnode & node ) :
      _left  ( node._left ),
      _right ( node._right ),
      _type  ( node._type ),
      _hidden( node._hidden ),
      _comstr( node._comstr ) {}

    /*! Destructor */
    ~tnode();

    /*! Recursively destroys all nodes under this node including itself */
    void destroy();

    /*! \return Returns true if the node does not contain a matching set */
    bool incomplete() const { return( (_type != -1) && ((_left == 0) || (_right == 0)) ); }

    /*! Sets the left pointer in the node to the given item */
    void left( serial_item* item ) { _left = item; }

    /*! Sets the right pointer in the node to the given item */
    void right( serial_item* item ) { _right = item; }

    /*! Adds the node to the end of the list of children */
    void add_child( tnode* child ) { _children.push_back( child ); }

    /*! \return Returns a reference to the parent node */
    tnode* parent() { return( _parent ); }

    /*! \return Returns the children nodes of this node */
    std::vector<tnode*> & children() { return( _children ); }

    /*! \return Returns the type of the node */
    int type() const { return( _type ); }

    /*! \return Returns the stored comstr value */
    bool comstr() const { return( _comstr ); }

    /*! Adds this node and all children nodes that are mismatched to the object list */
    void get_mismatched( Tcl::object & mismatched ) const;

};

/*!
 Serial item.
*/
class serial_item {

  private:

    int      _type;       /*!< Item type */
    int      _side;       /*!< Side that the item represents of a pair (0 = none, 1 = left, 2 = right, 3 = any) */
    position _pos;        /*!< Text widget position */
    bool     _iscontext;  /*!< Set to true if this item is a part of a context */
    tnode*   _node;       /*!< Pointer to the tree node associated with this item */
    int      _context;    /*!< Context that this item is only valid in */

  public:

    /*!
     Default constructor.
    */
    serial_item(
      int      type,
      int      side,
      position pos,
      bool     iscontext,
      int      context
    ) : _type( type ),
        _side( side ),
	_pos( pos ),
        _iscontext( iscontext ),
        _node( 0 ),
        _context( context ) {}

    /*! Constructor from a Tcl object */
    serial_item( Tcl::object item );

    /*! Destructor */
    ~serial_item() {}

    /*! Adjust the item when it is the first in the range of items to adjust */
    void adjust_first( int from_col, int to_col, int col_diff ) { _pos.adjust_first( from_col, to_col, col_diff ); }

    /*! Adjusts the positional information */
    void adjust( int from_row, int row_diff, int col_diff ) { _pos.adjust( from_row, row_diff, col_diff ); }

    /*! Sets the node pointer to the given node */
    void set_node( tnode* node ) { _node = node; }

    /*! \return Returns the stored side value */
    int side() const { return( _side ); }

    /*! \return Returns the stored type */
    int type() const { return( _type ); }

    /*! \return Returns the stored position information */
    position & pos() { return( _pos ); }

    /*! \return Returns a constant version of the stored position */
    const position & const_pos() const { return( _pos ); }

    /*! \return */
    void append_tindices( Tcl::object items );

};

/*!
 Implementation of the serial list
*/
class serial : public std::vector<serial_item*> {

  private:

    /*!
     Adjusts the serial list positions for the given ranges.
    */
    void adjust(
      const tindex & from,
      const tindex & to,
      const sindex & start,
      const sindex & end
    );

  public:

    /*! Default constructor */
    serial() {}

    /*! Destructor */
    ~serial();

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

    /*! Updates the serial list with the given list. */
    bool update(
      const tindex & linestart,
      const tindex & lineend,
      serial*        elements
    );

};

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
    tree() : _tree( new tnode( -1, false ) ) {}

    /*! Destructor */
    ~tree();

    /*! Updates the serial list */
    void update( serial & sl );

    /*! Searches the tree for mismatched nodes. */
    void get_mismatched( Tcl::object & mismatched ) const { _tree->get_mismatched( mismatched ); }

};

/*!
 Main modelling class that the Tcl core will interact with.
*/
class model {

  private:

    serial _serial;  /*!< Serial list structure */
    tree   _tree;    /*!< Tree structure */

  public:

    /*! Default constructor */
    model() {} // : _serial(), _tree() {}

    /*! Destructor */
    ~model() {}

    /*! Updates the model with the given tag information */
    bool update( Tcl::object linestart, Tcl::object lineend, serial* elements );   

    /*! \return Returns the list of mismatched indices */
    Tcl::object get_mismatched() const;
};

#endif
