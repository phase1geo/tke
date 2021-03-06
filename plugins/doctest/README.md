
# What is this?


This plugin allows the user to test TCL scripts à la Python doctest.

The main idea is that you have the test blocks directly in your TCL script. You run the test blocks and get the results of testing (OK or FAILED).

The test blocks include the test examples concerning the current script and are *quoted* with the following *doctest-begin* and *doctest-end* TCL comments:

  #% doctest
  #% (tested code)
  #> doctest

The commands of `... (tested code) ...` are marked with *#%* and are followed with their results that are marked with *#>*. For example:

  # these two lines are a command and its result
  #% somecommand
  #> "result of somecommand"

So, we place the commands and their results between *doctest quotes*. Let us see how to do it:

  #% doctest

  ############ here we have two commands and their waited results
  ############ (note how a command/result begins and ends)
  #% command1
  #> result of command1
  #% command2
  #> result of command2

  ############ command33 needs command31, command32 to be run before
  ############ (their results are ignored if not raising exceptions):
  #% command31
  #% command32
  #% command33
  #> result of command33

  ############ command4 returns a multiline result
  ############ (in particular, you should use this when the test raises
  ############ an exception so that you copy-paste it as the waited result)
  #% command4
  #> 1st line of result of command4
  #> 2nd line of result of command4
  #> 3rd line of result of command4

  # ... or this way:
  #% command41
  #> 1st line of result of command41 \
     2nd line of result of command41 \
     3rd line of result of command41

  # ... or this way:
  #% command42
  #> "  1st line of result of command42 with initial spaces" \
     "   2nd line of result of command42 with initial spaces" \
     "    3rd line of result of command42 with initial spaces"

  ############ command may be continued with "\" as its last character
  #% command-so-loooooong - begin \
  #% command-so-loooooong - cont. \
  #% command-so-loooooong - end
  #> result of command-so-loooooong

  # ... or this way:
  #% command-so-loooooong - begin \
     command-so-loooooong - cont. \
     command-so-loooooong - end
  #> result of command-so-loooooong

  #> doctest

You can have as many test blocks as you need. If there are no *doctest quotes*, all of the text is considered as a giant test block containing *#%* and *#>* lines to be tested.

**Note:** if there is a *quoted* doctest block, any outside #% and #> lines are ignored.

Also, you can selectively run any test block or even any part of it, if you select at least two lines. You have not to select all of the lines, it's enough to select any parts of them, e.g. from "- begin \" to "#> result of" in the example above.

The block is tested OK when all its test examples (*#%* through *#>*) result in OK. The whole doctest is considered OK when all its blocks result in OK.

Do not include into the test blocks the commands that cannot be run outside of their context (calls of external procedures etc.).

The most fit to *doctest* are the procedures with more or less complex and error-prone algorithms of pure computing. The typical though trivial example is *factorial*.

Note:
The plugin was tested under Linux (Debian) and Windows. All bug fixes and corrections for other platforms would be appreciated at aplsimple$mail.ru.


# Menu usage


The "Plugin/ Doctest TCL" operations mean:

  *Doctest Safe*         - perform tests in safe mode of TCL interp
  *Doctest Safe Verbose* - perform previous one with verbose comments
  *Doctest Full*         - perform tests in unsafe mode of TCL interp
  *Doctest Full Verbose* - perform previous one with verbose comments
  *Doctest Init*         - insert doctest template before current line

It would be convenient to assign the following shortkeys for "Plugin/ Doctest TCL" operations:

  *Alt-B*      - Doctest Safe
  *Alt-V*      - Doctest Safe Verbose
  *Ctrl-Alt-B* - Doctest Full
  *Ctrl-Alt-V* - Doctest Full Verbose
  *Ctrl-Alt-I* - Doctest Init


# Tips and traps


### 1.

PLEASE, NOTICE AGAIN: Do not include into the test blocks the commands that cannot be run or are unavailable (calls of external procedures etc.).

The test blocks should only contain the independently runnable TCL code plus the commented test examples. The test examples being stripped of *#%* are run one after another as the tailing code of their block.

### 2.

If the last *#% doctest* quote isn't paired with lower *#> doctest* quote, the test block continues to the end of text.

The middle unpaired *#% doctest* and the unpaired *#> doctest* are considered as errors making the test impossible.

### 3.

Results of commands are checked literally, though the starting and tailing spaces of *#%* and *#>* lines are ignored.

If a command's result should contain starting/tailing spaces, it should be quoted with double quotes. The following `someformat` command

  #% someformat 123
  #> "  123"

should return "  123" for the test to be OK.

The following two tests are identical and both return the empty string:

  #% set _ ""  ;# test #1
  #> ""
  #% set _ ""  ;# test #2
  #>

### 4.

The absence of resulting *#>* means that a result isn't important (e.g. for GUI tests) and no messages are displayed in non-verbose doctest. In such cases the "&" might be useful at the end of command, for returning to TKE:

  #% exec wish ./GUImodule.tcl arg1 arg2 &
  # ------ no result is waited here ------

NOTE: the successive *#%* commands form the suite with the result returned by the last command. See the example of command31-32-33 suite above.

### 5.

If there are *doctest quoted* test blocks, all the text outside of them is normally ignored by doctest. Nevertheless, you can test those outsiders after selecting them. You can try it just now on the upper `set _ ""` commands.

### 6.

A tested command can throw an exception which is considered as its result being normal under some conditions. See the example below.

### 7.

When you have a doctest to run an external application, e.g.

  #% doctest
  #% exec tclsh my-module1.tcl "this-data-file" arg11 arg12 arg13
  #> doctest

do not forget about the *#% doctest* and *#> doctest* lines. They are important in order to detach an external call from the rest of text. Otherwise you could get an error message (if you set *#> result* to see what's wrong with the call), like this:

  GOT:
  "can't read "::argv0": no such variable"

  WAITED:
  "result"

This one means that the rest of text (being evaluated as a Tcl snippet, not a module run in tclsh) can't get to the Tcl argument list.

### 8.

Run "Doctest Safe Verbose" on this README.md to see how the doctest works. Notice that:

1. The upper fictitious test block results in FAILED.
2. The lower factorial test block results in OK.
3. The out-of-blocks test examples are ignored.

This thing might be helpful, namely: the doctest's usage isn't restricted with a code. Any data file, that permits '#' or multi-line comments, may include the doctest strings for testing its contents, e.g. through something like:

  #% doctest
  #% exec tclsh my-module1.tcl "this-data-file" arg11 arg12 arg13
  #% exec tclsh my-module2.tcl "this-data-file" arg21 arg22 arg23
  ...
  #> doctest

...or

  #% doctest
  #% exec my-application1 "this-data-file" arg11 arg12 arg13
  #% exec my-application2 "this-data-file" arg21 arg22 arg23
  ...
  #> doctest

... so that, while editing this data file, you can periodically run the doctest on it to check if the data are OK.

*Note again:* If there is a *quoted* doctest block, any outside #% and #> lines are ignored. And vice versa, if there is no *quoted* doctest block, all of text is considered as a giant doctest block.

*As a result:* The *#% doctest* and *#> doctest* lines are important! You must detach the doctest blocks from the rest of text. Otherwise, all of the text would be evaluated as Tcl code, which won't highly likely be that you want.

You can define a whole set of testing application(s) in block(s) to run all of them at modifying the data.

### 9.

If a doctest body is large, it can be moved to a separate file to be sourced with a comment:

  #% doctest source testedfile.test

where *doctest source* may be of any case (Doctest Source, DOCTEST SOURCE etc.), *testedfile.test* contains the doctest body. Thus a code isn't cluttered with a doctest body.

See e.g. *obbit.tcl* and its sourced *tests/obbit_1.test* in https://github.com/aplsimple/pave.

### 10.

The *e_menu* plugin of TKE supports the `doctest` actions as well. It may be a good replacement of TKE doctest plugin in some specific cases.

The doctest menu items of *e_menu* are available via *Menu / Utils / Test1*.


# Example


  #% doctest
  ############## Calculate factorial of integer N (1 * 2 * 3 * ... * N)
  proc factorial {i} {
    if {$i<0} {
      throw {ARITH {factorial expects a positive integer}} \
      "expected positive integer but got \"$i\""
    }
    if {"$i" eq "0" || "$i" eq "1"} {return 1}
    return [expr {$i * [factorial [incr i -1]]}] ;# btw checks if i is integer
  }
  #% factorial 0
  #> 1
  #% factorial 1
  #> 1
  #% factorial 10
  #> 3628800
  #% factorial 50
  #> 30414093201713378043612608166064768844377641568960512000000000000
  #
  # (:=test for test:=)
  #% expr 1*2*3*4*5*6*7*8*9*10*11*12*13*14*15*16*17*18*19*20* \
  #%      21*22*23*24*25*26*27*28*29*30*31*32*33*34*35*36*37*38*39*40* \
  #%      41*42*43*44*45*46*47*48*49*50
  #> 30414093201713378043612608166064768844377641568960512000000000000
  #% expr [factorial 50] == \
  #%      1*2*3*4*5*6*7*8*9*10*11*12*13*14*15*16*17*18*19*20* \
  #%      21*22*23*24*25*26*27*28*29*30*31*32*33*34*35*36*37*38*39*40* \
  #%      41*42*43*44*45*46*47*48*49*50
  #> 1
  # (:=do not try factorial 1000, nevermore, the raven croaked:=)
  #
  #% factorial 1.1
  #> expected integer but got "1.1"
  #% factorial 0.1
  #> expected integer but got "0.1"
  #% factorial -1
  #> expected positive integer but got "-1"
  #% factorial -1.1
  #> expected positive integer but got "-1.1"
  #% factorial abc
  #> expected integer but got "abc"
  #% factorial
  #> wrong # args: should be "factorial i"
  #> doctest

