#ifndef __UNDO_H__
#define __UNDO_H__

/*!
 \file     undo.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/17/2017
 \brief    Contains classes for handling the undo buffer.
*/

#include <vector>

#include "cpptcl/cpptcl.h"
#include "utils.h"

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
    void render( Tcl::object & result ) const;

    /*! \return Returns the stored cursor position */
    const tindex & cursor() const { return( _cursor ); }
    
};

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
    Tcl::object render();
    
    /*! Generates a list of all stored cursor positions in the group */
    void cursor_history( Tcl::object & result ) const;

};

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

/*!
 Main class that manages the undo buffer.
*/
class undo_manager {
  
  private:
    
    undo_buffer _undo_buffer;  /*!< Undo buffer */
    undo_buffer _redo_buffer;  /*!< Redo buffer */
    undo_group* _uncommitted;  /*!< Uncommitted group */
    
    /*! Add insertion change */
    void add_change(
      int type,
      Tcl::object startpos,
      Tcl::object endpos,
      Tcl::object str,
      Tcl::object cursor,
      Tcl::object mcursor
    );
    
  public:
    
    /*! Default constructor */
    undo_manager() : _uncommitted( 0 ) {}
    
    /*! Destructor */
    ~undo_manager() {
      if( _uncommitted ) {
        delete _uncommitted;
      }
    }

    /*! Adds an insertion entry into the buffer */
    void add_insertion(
      Tcl::object startpos,
      Tcl::object endpos,
      Tcl::object str,
      Tcl::object cursor,
      Tcl::object mcursor
    ) {
      add_change( UNDO_TYPE_INSERT, startpos, endpos, str, cursor, mcursor );
    }
    
    /*! Adds an insertion entry into the buffer */
    void add_deletion(
      Tcl::object startpos,
      Tcl::object endpos,
      Tcl::object str,
      Tcl::object cursor,
      Tcl::object mcursor
    ) {
      add_change( UNDO_TYPE_DELETE, startpos, endpos, str, cursor, mcursor );
    }
    
    /*! Commits the current change to the undo buffer */
    void add_separator();
    
    /*! Retrieves the last change */
    Tcl::object undo();
    
    /*! Undoes the last undo */
    Tcl::object redo();
    
    /*! Retrieves the cursor history in a list */
    Tcl::object cursor_history() const {
      return( _undo_buffer.cursor_history() );
    }

    /*! \return Returns true if the undo buffer is empty */
    Tcl::object undo_empty() const {
      return( (Tcl::object)((_uncommitted == 0) && _undo_buffer.empty()) );
    }

    /*! \return Returns true if the redo buffer is empty */
    Tcl::object redo_empty() const {
      return( (Tcl::object)_redo_buffer.empty() );
    }
    
};

#endif

