#ifndef __REQUEST_H__
#define __REQUEST_H__

/*!
 \file    request.h
 \author  Trevor Williams  (phase1geo@gmail.com)
 \date    11/8/2017
 \brief   Contains functions for storing, updating and retrieving information
          for the marker modeller.
*/

#include <iostream>

#include "cpptcl.h"
#include "model.h"

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
  REQUEST_ISINDEX,
  REQUEST_GETCOMMENTMARKERS,
  REQUEST_RENDERLINEMAP,
  REQUEST_SETMARKER,
  REQUEST_GETMARKERNAME,
  REQUEST_GETMARKERLINE,
  REQUEST_GUTTERCREATE,
  REQUEST_GUTTERDESTROY,
  REQUEST_GUTTERHIDE,
  REQUEST_GUTTERDELETE,
  REQUEST_GUTTERSET,
  REQUEST_GUTTERUNSET,
  REQUEST_GUTTERGET,
  REQUEST_GUTTERCGET,
  REQUEST_GUTTERCONFIGURE,
  REQUEST_GUTTERNAMES,
  REQUEST_UNDO,
  REQUEST_REDO,
  REQUEST_UNDOABLE,
  REQUEST_REDOABLE,
  REQUEST_UNDOSEPARATOR,
  REQUEST_UNDORESET,
  REQUEST_AUTOSEPARATE,
  REQUEST_CURSORHIST,
  REQUEST_FOLDADDTYPES,
  REQUEST_FOLDDELETE,
  REQUEST_FOLDDELETERANGE,
  REQUEST_FOLDOPEN,
  REQUEST_FOLDOPENRANGE,
  REQUEST_FOLDSHOWLINE,
  REQUEST_FOLDCLOSE,
  REQUEST_FOLDCLOSERANGE,
  REQUEST_FOLDFIND,
  REQUEST_INDENTLINESTART,
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

    /*! \return Returns the result of the last operation */
    bool result() const { return( _result ); }

    /*! \return Returns the tree update indicator value */
    bool tree() const { return( _tree ); }

};

#endif

