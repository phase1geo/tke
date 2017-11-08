#ifndef __MODEL_H__
#define __MODEL_H__

/*!
 \file    model.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains functions for storing, updating and retrieving information
          for the marker modeller.
*/

#include <list>

/*! Text widget index */
typedef struct {
  int row;
  int col;
} tindex;

/*! Serial list index return value */
typedef struct {
  int  index;
  bool matches;
} sindex;

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
    position( int row, int scol, int ecol ) : _row( row ), _scol( scol ), _ecol( ecol ) {}

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

};

/*!
 Tree node.
*/
class tnode {

  private:

    serial_item* _left;    /*!< Index of serial item on the left side */
    serial_item* _right;   /*!< Index of serial item on the right side */
    int          _type;    /*!< Item type */
    bool         _hidden;  /*!< Hidden indicator */
    bool         _comstr;  /*!< Set to true if the type is a comment/string indicator */

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
    ~tnode() {}

    /*! Returns true if this node is incomplete */
    bool incomplete() const { return( (_left == 0) || (_right == 0) ); }

    /*! Sets the left pointer in the node to the given item */
    void left( serial_item* item ) { _left = item; }

    /*! Sets the right pointer in the node to the given item */
    void right( serial_item* item ) { _right = item; }

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
    int      _tag;        /*!< Highlighting tag */

  public:

    /*!
     Default constructor.
    */
    serial_item(
      int      type,
      int      side,
      position pos,
      bool     iscontext,
      int      context,
      int      tag
    ) : _type( type ),
        _side( side ),
        _iscontext( iscontext ),
        _node( 0 ),
        _context( context ),
        _tag( tag ) {}

    /*! Destructor */
    ~serial_item() {}

    /*! Adjust the item when it is the first in the range of items to adjust */
    void adjust_first( int from_col, int to_col, int col_diff ) { _pos.adjust_first( from_col, to_col, col_diff ); }

    /*! Adjusts the positional information */
    void adjust( int from_row, int row_diff, int col_diff ) { _pos.adjust( from_row, row_diff, col_diff ); }

    /*! \return Returns the stored type */
    int type() const { return( _type ); }

    /*! \return Returns the stored position information */
    position pos() const { return( _pos ); }

};

/*!
 Implementation of the serial list
*/
class serial {

  private:

    std::list<serial_item*> _list;  /*!< Serial list */

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
    serial();

    /*! Destructor */
    ~serial();

    /*! Called when text is going to be inserted.  Adjusts the indices accordingly. */
    void insert( const std::vector<tindex> & ranges );

    /*! Called when text is going to be deleted.  Adjusts the indices accordingly. */
    void delete( const std::vector<tindex> & ranges );

    /*! Called when text is going to be replaced.  Adjusts the indices accordingly. */
    void replace( const std::vector<tindex> & ranges );

    /*! Appends an item to the end of this list */
    void append( const serial_item & element ) { _list.push_back( new serial_item( element ) ); }

    /*! \return Returns the index of the text widget position in this list. */
    int get_index( const tindex & index ) const;

    /*! Updates the serial list with the given list. */
    void update( const tindex & linestart, const tindex & lineend, const std::list<serial_item*> & elements );

    /*! \return Returns the size of the list */
    int size() const { return( _list.size() ); }

    /*! \return Returns the serial item at the given index */
    serial_item & get_item( int index ) { return( *(_list[index]) ); }

};

/*!
 Node tree containing positional information for the given tree
*/
class tree {

  private:

    tnode* _tree;  /*!< Pointer to the tree structure */

  public:
 
    /*! Default constructor */
    tree() : _tree( new tnode() );

    /*! Destructor */
    ~tree();

    /*! Updates the serial list */
    void update( const serial & sl );

};

#endif
