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
  
  public:
    
    /*! Default constructor */
    undo_change() {}
    
    /*! Copy constructor */
    undo_change( const undo_change & uc ) {}
  
    ~undo_change() {};
    
    virtual int type() = 0;
    
};

/*!
 Insert change.
*/
class insert_change : public undo_change {
  
  private:
    
    tindex              _pos;      /*!< Insertion index */
    std::string         _str;      /*!< String that was inserted */
    std::vector<tindex> _cursors;  /*!< Cursors */
    
  public:
    
    /*! Default constructor */
    insert_change(
      const tindex      & pos,
      const std::string & str,
      const std::vector<tindex> & cursors
    ) : _pos( pos ),
        _str( str )
    {
      for( std::vector<tindex>::iterator it=cursors.begin(); it!=cursors.end(); it++ ) {
        _cursors.push_back( *it );
      }
    }
    
    /*! Copy constructor */
    insert_change(
      const insert_change & ic
    ) : _pos ( pos ),
        _str ( str ),
    {
      for( std::vector<tindex>::iterator it=cursors.begin(); it!=cursors.end(); it++ ) {
        _cursors.push_back( *it );
      }
    }
    
    /*! Destructor */
    ~insert_change() {}
    
    /*! Specifies the type */
    int type() const { return( UNDO_TYPE_INSERT ); }
  
};

/*!
 Deletion change.
*/
class delete_change : public undo_change {
  
  private:
    
    tindex                      _startpos;  /*!< Starting position */
    tindex                      _endpos;    /*!< Ending position */
    const std::vector<tindex> & _cursors;   /*!< Cursors */
    
  public:
    
    /*! Default constructor */
    delete_change(
      const tindex      & startpos,
      const tindex      & endpos,
      const std::vector<tindex> & cursors
    ) : _startpos ( startpos ),
        _endpos   ( endpos )
    {
      for( std::vector<tindex>::iterator it=cursors.begin(); it!=cursors.end(); it++ ) {
        _cursors.push_back( *it );
      }
    }

    /*! Copy constructor */
    delete_change(
      const delete_change & dc
    ) : _startpos( dc.startpos ),
        _endpos  ( dc.endpos )
    {
      for( std::vector<tindex>::iterator it=cursors.begin(); it!=cursors.end(); it++ ) {
        _cursors.push_back( *it );
      }
    }

    /*! Destructor */
    ~delete_change() {}
    
    /*! Specifies the type */
    int type() const { return( UNDO_TYPE_DELETE ); }
  
};

/*!
 A group of changes.
*/
class undo_group : public std::stack<undo_change*> {
  
  public:
    
    /*! Default constructor */
    undo_group() {}
    
    /*! Copy constructor */
    undo_group( const undo_group & ug ) {
      for( std::stack<undo_change*>::iterator it=ug.begin(); it!=ug.end(); it++ ) {
        if( ug.type() == UNDO_TYPE_INSERT ) {
          push( new insert_change( *it ) );
        } else {
          push( new delete_change( *it ) );
        }
      }
    }
    
    /*! Destructor */
    ~undo_group() {
      for( std::stack<undo_change*>::iterator it=begin(); it!=end(); it++ ) {
        delete *it;
      }
    }
    
};

/*!
 Represents an undo/redo buffer.
*/
class undo_buffer : public std::stack<undo_group*> {
  
  public:
    
    /*! Constructor */
    undo_buffer() {}
    
    /*! Destructor */
    ~undo_buffer() {
      for( std::stack<undo_group*>::iterator it=begin(); it!=end(); it++ ) {
        delete *it;
      }
    }
    
};

/*!
 Main class that manages the undo buffer.
*/
class undo_manager {
  
  private:
    
    undo_buffer _undo_buffer;  /*!< Undo buffer */
    undo_buffer _redo_buffer;  /*!< Redo buffer */
    undo_group* _group;        /*!< Uncommitted group */
    
  public:
    
    /*! Default constructor */
    undo_manager() : _group( 0 ) {}
    
    /*! Destructor */
    ~undo_manager() {
      if( _group ) {
        delete _group;
      }
    }
    
    /*! Add insertion change */
    void add_insert_change(
      Tcl::object startpos,
      Tcl::object str,
      Tcl::object cursors
    );
    
    /*! Delete insertion change */
    void add_delete_change(
      Tcl::object startpos,
      Tcl::object endpos,
      Tcl::object cursors
    );
    
    /*! Commits the current change to the undo buffer */
    void add_separator() {
      if( _group ) {
        _undo_buffer.push( _group );
        _group = 0;
      }
    }
    
    /*! Retrieves the last change */
    Tcl::object undo();
    
    /*! Undoes the last undo */
    Tcl::object redo();
    
    /*! Retrieves the cursor history in a list */
    Tcl::object cursor_history() const;
    
};

#endif

