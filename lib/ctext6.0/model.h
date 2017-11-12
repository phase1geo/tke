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
#include <queue>
#include <string>
#include <map>
#include <iostream>
#include <iomanip>
#include <thread>

#include "cpptcl/cpptcl.h"

/*! Text widget index */
typedef struct {
  int row;
  int col;
} tindex;

class types {

  private:

    class type_data {
      public:
        std::string name;
        bool        comstr;
        type_data( std::string n, bool cs ) : name( n ), comstr( cs ) {}
        type_data( const type_data & td ) : name( td.name ), comstr( td.comstr ) {}
        ~type_data() {}
    };

    std::map<std::string,int> _types;  /*!< Mapping of type string to integer values */
    std::map<int,type_data>   _data;   /*!< Mapping of type integer to string values and comstr info */
    std::string               _empty;  /*!< Used when we need to return a reference to the empty string */
    int                       _id;     /*!< Unique identifier */

    /*! Default constructor */
    types() : _empty( "" ), _id( 0 ) {}

    /*! Assignment operator */
    types & operator=( const types & t ) {
      for( std::map<std::string,int>::const_iterator it=t._types.begin(); it!=t._types.end(); it++ ) {
        _types.insert( std::make_pair( (*it).first, (*it).second ) );
      }
      for( std::map<int,type_data>::const_iterator it=t._data.begin(); it!=t._data.end(); it++ ) {
        _data.insert( std::make_pair( (*it).first, (*it).second ) );
      }
      return( *this );
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
    void add( std::string name, bool comstr ) {
      if( get( name ) == -1 ) {
        _types.insert( std::make_pair( name, _id ) );
        _data.insert(  std::make_pair( _id, type_data( name, comstr ) ) );
        _id++;
      }
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
      std::map<int,type_data>::const_iterator it = _data.find( value );
      if( it == _data.end() ) {
        return( _empty );
      }
      return( it->second.name );
    }

    /*! \return Returns true if the given type is a comment or string type */
    bool comstr( int value ) const {
      std::map<int,type_data>::const_iterator it = _data.find( value );
      if( it == _data.end() ) {
        return( false );
      }
      return( it->second.comstr );
    }

};

/*! Adds the specified type and value to the singleton class */
inline void add_type(
  std::string name,
  bool        comstr
) {
  types::staticObject().add( name, comstr );
}

/*! \return Returns the side value for the given name */
int get_side( std::string name );

/*! \return Returns the side name for the given value */
std::string get_side( int value );

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

    /*! \return Returns a string version of this instance */
    std::string to_string() const {
      std::ostringstream oss;
      oss << _index << "/" << _matches;
      return( oss.str() );
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
      int row_diff,
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

    /*! \return Returns the first column text index */
    std::string to_index() const;

    /*! \return Returns a Tcl object containing a list of the text widget indices */
    void to_pair( Tcl::object & pair ) const;

    /*! \return Returns the position as a string */
    std::string to_string() const;

    /*! \return Returns the stored row */
    int row() const { return( _row ); }

    /*! \return Returns the starting column */
    int start_col() const { return( _scol ); }

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
    ~tnode() { clear(); }

    /*! Recursively destroys all nodes under this node including itself */
    void clear();

    /*! \return Returns true if the node does not contain a matching set */
    bool incomplete() const { return( (_type != -1) && ((_left == 0) || (_right == 0)) ); }

    /*! Sets the left pointer in the node to the given item */
    void left( serial_item* item ) { _left = item; }

    /*! Sets the right pointer in the node to the given item */
    void right( serial_item* item ) { _right = item; }

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
    bool isroot() const { return( _type == -1 ); }

    /*! \return Returns the type of the node */
    int type() const { return( _type ); }

    /*! \return Returns the stored comstr value */
    bool comstr() const { return( _comstr ); }

    /*! \return Returns the index of the node in the parent */
    int index() const;

    /*! \return Returns the depth of the node in the tree */
    int depth(
      int type = -1  /*!< If set to a type value, returns the depth of the given type
                          (otherwise, tree depth is used). */
    ) const;

    /*! \return Returns a string representation of this node and all children nodes */
    std::string to_string() const;

    /*! \return Recursively returns string version of the subtree */
    std::string tree_string() const;

    /*! Adds this node and all children nodes that are mismatched to the object list */
    void get_mismatched( Tcl::object & mismatched ) const;

    /*! \return Returns the position of the matching position */
    bool get_match_pos(
      const serial_item*   si,
      position           & pos
    ) const;

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
    int type() const { return( _type ); }

    /*! \return Returns the stored context indicator */
    bool iscontext() const { return( _iscontext ); }

    /*! \return Returns the stored position information */
    position & pos() { return( _pos ); }

    /*! \return Returns a constant version of the stored position */
    const position & const_pos() const { return( _pos ); }

    /*! \return Returns a pointer to the associated node in the tree */
    tnode* node() const { return( _node ); }

    /*! \return Returns a human-readable version of this element */
    std::string to_string() const;

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

    /*! \return Returns the pointer to the node containing the given index */
    tnode* find_node( const tindex & index ) const;

    /*! \return Returns a stringified version of the serial list */
    std::string to_string() const;

    /*! \return Returns a human-readable version of the serial list */
    std::string show() const;

    /*! \return Returns true if the given index is immediately preceded by an escape */
    bool is_escaped( const tindex & ti ) const;

    /*! \return Returns the list of contextual items in the list as a new list */
    void get_context_items( serial & items ) const;

    /*! Updates the serial list with the given list. */
    bool update(
      const tindex & linestart,
      const tindex & lineend,
      serial       & elements
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

    /*! \return Returns a graphical view of the stored string */
    std::string tree_string() const { return( _tree->tree_string() ); }

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

    /*!
     Converts the given object to a vector of text indices.
    */
    void object_to_ranges(
      Tcl::object,
      std::vector<tindex> & vec
    );

  public:

    /*! Default constructor */
    model() {}

    /*! Destructor */
    ~model() {}

    /*! Called when text is going to be inserted.  Adjusts the indices accordingly. */
    void insert( Tcl::object ranges ) {
      std::vector<tindex> vec;
      object_to_ranges( ranges, vec );
      _serial.insert( vec );
    }

    /*! Called when text is going to be deleted.  Adjusts the indices accordingly. */
    void remove( Tcl::object ranges ) {
      std::vector<tindex> vec;
      object_to_ranges( ranges, vec );
      _serial.remove( vec );
    }

    /*! Called when text is going to be replaced.  Adjusts the indices accordingly. */
    void replace( Tcl::object ranges ) {
      std::vector<tindex> vec;
      object_to_ranges( ranges, vec );
      _serial.replace( vec );
    }

    /*! Updates the model with the given tag information */
    bool update(
      Tcl::object linestart,
      Tcl::object lineend,
      Tcl::object elements
    );

    /*! Update the tree with the contents of the serial list */
    void update_tree() { _tree.update( _serial ); }

    /*! \return Returns a human-readable representation of the stored serial list */
    std::string show_serial() const { return( _serial.show() ); }

    /*! \return Returns a graphical representation of the stored tree */
    std::string show_tree() const { return( _tree.tree_string() ); }

    /*! \return Returns the list of mismatched indices */
    Tcl::object get_mismatched() const;

    /*!
     \return Returns the character range of the matching char if found; otherwise,
             outputs the empty string.
    */
    Tcl::object get_match_char( Tcl::object ti );

    /*! \return Returns the depth of the given item in the tree */
    int get_depth( Tcl::object index, Tcl::object type );

    /*! \return Returns the list of context tags */
    std::string get_context_items(
      Tcl::object linestart,
      Tcl::object lineend,
      Tcl::object tags
    ) const;

    /*! \return Returns true if the given text index is immediately preceded by an escape */
    bool is_escaped( Tcl::object ti ) const;

};

enum {
  REQUEST_INSERT = 0,
  REQUEST_DELETE,
  REQUEST_REPLACE,
  REQUEST_UPDATE,
  REQUEST_SHOWSERIAL,
  REQUEST_SHOWTREE,
  REQUEST_MISMATCHED,
  REQUEST_MATCHINDEX,
  REQUEST_DEPTH,
  REQUEST_GETCONTEXTS,
  REQUEST_ISESCAPED,
  REQUEST_NUM
};

class request {

  private:

    void*       _inst;     /*!< Instance pointer */
    int         _command;  /*!< Command to execute */
    Tcl::object _args;     /*!< Arguments to pass to the command */
    bool        _block;    /*!< Specifies that this command requires the
                                model to be updated prior to its execution */

  public:

    /*! Default contructor */
    request(
      void*         inst,
      int           command,
      Tcl::object & args,
      bool          block
    ) : _inst   ( inst ),
        _command( command ),
        _args   ( args ),
        _block  ( block ) {}

    /*! Copy constructor */
    request( const request & req ) :
      _inst   ( req._inst ),
      _command( req._command ),
      _args   ( req._args ),
      _block  ( req._block ) {}

    /*! Destructor */
    ~request() {}

    /*! Executes the request */
    Tcl::object execute(
      bool & update_needed
    ) const;

    /*! \return Returns true if this command requires the model to be
                up-to-date before we are run */
    bool block() const { return( _block ); }

};

class mailbox {

  private:

    model                _model;          /*!< Model instance to use */
    std::queue<request*> _requests;       /*!< FIFO of requests */
    bool                 _thread_active;  /*!< Set to true when a thread is currently active */

  public:

    /*! Default constructor */
    mailbox() : _thread_active( false ) {}

    /*! Destructor */
    ~mailbox() {}

    /*! Adds a request to the mailbox */
    void request(
      int                 cmd,
      const Tcl::object & args,
      bool                block
    );

    /*! Execute items from the requests queue */
    void execute();

    void insert( Tcl::object ranges );
    void remove( Tcl::object ranges );
    void replace( Tcl::object ranges );
    bool update(
      Tcl::object linestart,
      Tcl::object lineend,
      Tcl::object elements
    );
    std::string show_serial() const;
    std::string show_tree() const;
    Tcl::object get_mismatched() const;
    Tcl::object get_match_char( Tcl::object ti );
    int get_depth( Tcl::object index, Tcl::object type );
    bool is_escaped( Tcl::object ti ) const;
    std::string get_context_items(
      Tcl::object linestart,
      Tcl::object lineend,
      Tcl::object tags
    ) const;

};

#endif
