#ifndef __RESPONSE_H__
#define __RESPONSE_H__

/*!
 \file     response.h
 \author   Trevor Williams  (phase1geo@gmail.com)
 \date     1/25/2018
 \brief    Contains information for a thread response for callbacks.
*/

#include <string>

#if defined(__MINGW32__) || defined(__MINGW64__)
#include <boost/thread/future.hpp>
#define GENERIC_FUTURE  boost::future
#define GENERIC_PROMISE boost::promise
#else
#include <future>
#define GENERIC_FUTURE  std::future
#define GENERIC_PROMISE std::promise
#endif

#include "cpptcl.h"

class response {

  private:

    std::string                 _callback;  /*!< Callback function name to call */
    GENERIC_FUTURE<Tcl::object> _data;      /*!< Returned data */

  public:

    /*! Default constructor */
    response(
      const std::string            & callback,
      GENERIC_PROMISE<Tcl::object> & data
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

