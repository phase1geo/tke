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
#include <string>

#if defined(__MINGW32__) || defined(__MINGW64__)
//#include <boost/thread.hpp>
#include <boost/thread/future.hpp>
#define GENERIC_PROMISE boost::promise
#else
#include <future>
#define GENERIC_PROMISE std::promise
#endif

#include "cpptcl.h"
#include "model.h"

enum {
  REQUEST_TYPE_UPDATE = 0,
  REQUEST_TYPE_CALLBACK,
  REQUEST_TYPE_RETURN,
  REQUEST_TYPE_NUM
};

enum {
  REQUEST_ADDTYPE = 0,
  REQUEST_INSERT,
  REQUEST_INSERTLIST,
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
  REQUEST_RANGE,
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
  REQUEST_FOLDDELETE,
  REQUEST_FOLDDELETERANGE,
  REQUEST_FOLDOPEN,
  REQUEST_FOLDOPENRANGE,
  REQUEST_FOLDSHOWLINE,
  REQUEST_FOLDCLOSE,
  REQUEST_FOLDCLOSERANGE,
  REQUEST_FOLDFIND,
  REQUEST_FOLDINDENTUPDATE,
  REQUEST_FOLDSYNTAXUPDATE,
  REQUEST_FIRSTCHAR,
  REQUEST_INDENTLINESTART,
  REQUEST_INDENTPREVIOUS,
  REQUEST_INDENTBACKSPACE,
  REQUEST_INDENTNEWLINE,
  REQUEST_INDENTCHECKUNINDENT,
  REQUEST_INDENTFORMAT,
  REQUEST_NUM
};

class request {

  private:

    int                          _command;   /*!< Command to execute */
    Tcl::object                  _args;      /*!< Arguments to pass to the command */
    int                          _type;      /*!< Specifies the request type */
    bool                         _tree;      /*!< Specifies that this command requires the tree be
                                                  up-to-date prior to processing */
    std::string                  _callback;  /*!< Callback command to run once request has completed */
    GENERIC_PROMISE<Tcl::object> _rsp_data;  /*!< Returned data used when calling callback functions */

  public:

    /*! Default contructor */
    request(
      int                 command,
      const Tcl::object & args,
      int                 type,
      bool                tree
    ) : _command ( command ),
        _args    ( args ),
        _type    ( type ),
        _tree    ( tree ) {}

    /*! Constructor */
    request(
      int                 command,
      const Tcl::object & args,
      const std::string & callback,
      bool                tree
    ) : _command  ( command ),
        _args     ( args ),
        _type     ( REQUEST_TYPE_CALLBACK ),
        _tree     ( tree ),
        _callback ( callback ) {}
   

    /*! Copy constructor */
    request( const request & req ) :
      _command  ( req._command ),
      _args     ( req._args ),
      _type     ( req._type ),
      _tree     ( req._tree ),
      _callback ( req._callback ) {}

    /*! Destructor */
    ~request() {}

    /*! Executes the request */
    Tcl::object execute(
      model & inst,
      bool  & update_needed
    ) const;

    /*! \return Returns the type of the last operation */
    int type() const { return( _type ); }

    /*! \return Returns the tree update indicator value */
    bool tree() const { return( _tree ); }

    /*! \return Returns the stored callback routine */
    const std::string & callback() { return( _callback ); }

    /*! \return Returns the data to be used in a callback function */
    GENERIC_PROMISE<Tcl::object> & rsp_data() { return( _rsp_data ); }

};

#endif

