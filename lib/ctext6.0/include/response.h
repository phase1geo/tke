#ifndef __RESPONSE_H__
#define __RESPONSE_H__

/*!
 \file     response.h
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     1/25/2018
 \brief    Contains information for a thread response for callbacks.
*/

#include <string>
#include <future>

#include "cpptcl.h"

class response {

  private:

    std::string              _callback;  /*!< Callback function name to call */
    std::future<Tcl::object> _data;      /*!< Returned data */

  public:

    /*! Default constructor */
    response(
      const std::string         & callback,
      std::promise<Tcl::object> & data
    ) : _callback ( callback ),
        _data     ( data.get_future() ) {}

    /*! Destructor */
    ~response() {}
    
    /*! Returns the callback */
    const std::string & callback() const { return( _callback ); }

    /*! \return Waits for and returns the response data */
    Tcl::object get() {
      Tcl::object      retval;
      Tcl::interpreter interp( retval.get_interp(), false );
      retval.append( interp, (Tcl::object)_callback );
      retval.append( interp, _data.get() );
      return( retval );
    }

};

#endif

