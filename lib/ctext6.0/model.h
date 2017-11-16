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
#include <stack>
#include <map>
#include <iostream>
#include <iomanip>
#include <thread>

#include "cpptcl/cpptcl.h"
#include "utils.h"
#include "linemap.h"

class type_data {

  private:

    std::string _name;
    std::string _tagname;
    bool        _comstr;
    bool        _matching;

    /*! Copy constructor */
    type_data(
      const type_data & td
    ) {}

    /*! Assignment operator */
    type_data & operator=( const type_data & td ) {
      return( *this );
    }

    void set_internals() {
      _comstr   = (_name.substr(0,9) == "bcomment:") ||
                  (_name.substr(0,9) == "lcomment:") ||
                  (_name == "double")   ||
                  (_name == "single")   ||
                  (_name == "btick")    ||
                  (_name == "tdouble")  ||
                  (_name == "tsingle")  ||
                  (_name == "tbtick");
      _matching = (_name == "curly")  ||
                  (_name == "square") ||
                  (_name == "paren")  ||
                  (_name == "angled") ||
                  (_name == "double") ||
                  (_name == "single") ||
                  (_name == "btick");
    }

  public:

    /*! Default constructor */
    type_data(
      const std::string & name
    ) : _name( name ), _tagname( "" ) {
      set_internals();
    }

    /*! Default constructor */
    type_data(
      const std::string & name,
      const std::string & tagname
    ) : _name( name ), _tagname( tagname ) {
      set_internals();
    }

    /*! Destructor */
    ~type_data() {}

    /*! Returns the string name of the type */
    const std::string & name() const { return( _name ); }

    /*! Equality operator */
    bool operator==( const type_data & td ) const {
      return( _name == td._name );
    }

    /*! Inequality operator */
    bool operator!=( const type_data & td ) const {
      return( !(*this == td) );
    }

    /*! \return Returns true if the type is a comment/string */
    bool comstr() const { return( _comstr ); }

    /*! \return Returns true if the type should be matched */
    bool matching() const { return( _matching ); }

    /*! \return Returns the associated tagname */
    const std::string & tagname() const { return( _tagname ); }

};

class types {

  private:

    std::vector<type_data*> _types;  /*!< Mapping of type string to integer values */

    /*! Default constructor */
    types() {}

    /*! Copy constructor */
    types( const types & t ) {}

    /*! Assignment operator */
    types & operator=( const types & t ) {
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

    /*! Adds the given type to the types list */
    void add( const std::string & name ) {
      if( get( name ) == 0 ) {
        _types.push_back( new type_data( name ) );
      }
    }

    /*! Adds the given type to the types list */
    void add(
      const std::string & name,
      const std::string & tagname
    ) {
      if( get( name ) == 0 ) {
        _types.push_back( new type_data( name, tagname ) );
      }
    }

    /*! Retrieves the integer value of the given string name */
    const type_data* get( const std::string & name ) const {
      for( std::vector<type_data*>::const_iterator it=_types.begin(); it!=_types.end(); it++ ) {
        if( (*it)->name() == name ) {
          return( (*it) );
        }
      }
      return( 0 );
    }

};

/*! Adds the specified type and value to the singleton class */
inline void add_type(
  const std::string & name,
  const std::string & tagname = ""
) {
  types::staticObject().add( name, tagname );
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
    std::string to_index(
      bool first_col = true
    ) const;

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
    const type_data*    _type;      /*!< Item type */
    bool                _hidden;    /*!< Hidden indicator */

  public:

    /*! Default constructor */
    tnode( const type_data* type ) :
      _left( 0 ), _right( 0 ), _type( type ), _hidden( false ) {}

    /*! Copy constructor */
    tnode( const tnode & node ) :
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
    serial_item( Tcl::object item );

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
    tree() : _tree( new tnode( 0 ) ) {}

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

    serial      _serial;  /*!< Serial list structure */
    tree        _tree;    /*!< Tree structure */
    linemap     _linemap; /*!< Line map structure */
    std::string _win;     /*!< Name of this model */

    /*!
     Converts the given object to a vector of text indices.
    */
    void object_to_ranges(
      Tcl::object,
      std::vector<tindex> & vec
    );

    /*!
     Adds the given tag index to the list.
    */
    void add_tag_index(
      Tcl::interpreter                  & i,
      std::map<std::string,Tcl::object> & ranges,
      const std::string                 & tag,
      const std::string                 & index
    );

  public:

    /*! Default constructor */
    model( const std::string & win ) : _win( win ) {}

    /*! Destructor */
    ~model() {}

    /*! Called when text is going to be inserted.  Adjusts the indices accordingly. */
    void insert( Tcl::object ranges ) {
      std::vector<tindex> vec;
      object_to_ranges( ranges, vec );
      _serial.insert( vec );
      _linemap.insert( vec );
    }

    /*! Called when text is going to be deleted.  Adjusts the indices accordingly. */
    void remove( Tcl::object ranges ) {
      std::vector<tindex> vec;
      object_to_ranges( ranges, vec );
      _serial.remove( vec );
      _linemap.remove( vec );
    }

    /*! Called when text is going to be replaced.  Adjusts the indices accordingly. */
    void replace( Tcl::object ranges ) {
      std::vector<tindex> vec;
      object_to_ranges( ranges, vec );
      _serial.replace( vec );
      _linemap.replace( vec );
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

    /*!
     Handles rendering all of the contexts in the given list as well
     as what is stored in the model.
    */
    Tcl::object render_contexts(
      Tcl::object linestart,
      Tcl::object lineend,
      Tcl::object tags
    );

    /*! \return Returns true if the given text index is immediately preceded by an escape */
    bool is_escaped( Tcl::object ti ) const;

    /*!
     Handles rendering the currently viewable linemap.
    */
    Tcl::object render_linemap(
      Tcl::object first_row,
      Tcl::object last_row
    ) const {
      return( _linemap.render( first_row, last_row ) );
    }

    /*! Adds a marker to the linemap with the given name for the given line */
    void set_marker(
      Tcl::object row,
      Tcl::object name
    ) {
      _linemap.set_marker( row, name );
    }

    /*! Creates a new gutter column in the linemap gutter */
    void gutter_create(
      Tcl::object name,
      Tcl::object values
    ) {
      _linemap.create( name, values );
    }

    /*! Sets rows for a given gutter column to the specified values */
    void gutter_set(
      Tcl::object name,
      Tcl::object values
    ) {
      _linemap.set( name, values );
    }

    /*! \return Returns a Tcl list of all stored gutter names */
    Tcl::object gutter_names() const {
      return( _linemap.names() );
    }

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
  REQUEST_RENDERCONTEXTS,
  REQUEST_ISESCAPED,
  REQUEST_RENDERLINEMAP,
  REQUEST_SETMARKER,
  REQUEST_GUTTERCREATE,
  REQUEST_GUTTERSET,
  REQUEST_GUTTERNAMES,
  REQUEST_NUM
};

class request {

  private:

    int         _command;  /*!< Command to execute */
    Tcl::object _args;     /*!< Arguments to pass to the command */
    bool        _result;   /*!< Specifies that this command requires a result to be returned */
    bool        _tree;     /*!< Specifies that this command requires the tree be up-to-date prior to processing */

  public:

    /*! Default contructor */
    request(
      int                 command,
      const Tcl::object & args,
      bool                result,
      bool                tree
    ) : _command( command ),
        _args   ( args ),
        _result ( result ),
        _tree   ( tree ) {}

    /*! Copy constructor */
    request( const request & req ) :
      _command( req._command ),
      _args   ( req._args ),
      _result ( req._result ),
      _tree   ( req._tree ) {}

    /*! Destructor */
    ~request() {}

    /*! Executes the request */
    Tcl::object execute(
      model & inst,
      bool  & update_needed
    ) const;

    bool result() const { return( _result ); }
    bool tree() const { return( _tree ); }

};

class mailbox {

  private:

    model                _model;          /*!< Model instance to use */
    std::queue<request*> _requests;       /*!< FIFO of requests */
    std::thread          _th;             /*!< Active thread */
    Tcl::object          _result;         /*!< Stores the last returned result */
    bool                 _update_needed;  /*!< Set to true when a tree update is eventually needed */
    bool                 _thread_active;  /*!< Set to true while the thread is checking queue status */

    /*! Adds the specified request to the mailbox queue */
    void add_request(
      int                 command,
      const Tcl::object & args,
      bool                result,
      bool                tree
    );

  public:

    /*! Default constructor */
    mailbox(
      const std::string & win
    ) : _model( win ), _update_needed( false ), _thread_active( false ) {}

    /*! Destructor */
    ~mailbox();

    /*! Execute items from the requests queue */
    void execute();

    /*! \return Returns the last calculated result */
    Tcl::object & result() {
      if( _th.joinable() ) { _th.join(); }
      return( _result );
    }

    void insert( Tcl::object ranges );
    void remove( Tcl::object ranges );
    void replace( Tcl::object ranges );
    void update(
      Tcl::object linestart,
      Tcl::object lineend,
      Tcl::object elements
    );
    Tcl::object show_serial();
    Tcl::object show_tree();
    Tcl::object get_mismatched();
    Tcl::object get_match_char( Tcl::object ti );
    Tcl::object get_depth( Tcl::object index, Tcl::object type );
    Tcl::object is_escaped( Tcl::object ti );
    Tcl::object render_contexts(
      Tcl::object linestart,
      Tcl::object lineend,
      Tcl::object tags
    );
    Tcl::object render_linemap(
      Tcl::object first_row,
      Tcl::object last_row
    );
    void set_marker(
      Tcl::object row,
      Tcl::object name
    );
    void gutter_create(
      Tcl::object name,
      Tcl::object values
    );
    void gutter_set(
      Tcl::object name,
      Tcl::object values
    );
    Tcl::object gutter_names();

};

#endif
