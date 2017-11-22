#ifndef __SIDE_H__
#define __SIDE_H__

/*!
 \file     side.h
 \author   Trevor Williams (phase1geo@gmail.com)
 \date     11/22/2017
 \brief    Contains functions for getting/setting side information in the singleton class.
*/

#include <string>

/*! \return Returns the side value for the given name */
int get_side( std::string name );

/*! \return Returns the side name for the given value */
std::string get_side( int value );

#endif

