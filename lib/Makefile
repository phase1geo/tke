.PHONY: commit

commit:
	tclsh8.5 commit.tcl
	hg commit

snippets: snippets-lex snippets-yacc

snippets-lex: sniplex.fcl
	tclsh8.5 ../scripts/fickle.tcl sniplex.fcl

snippets-yacc: snipyacc.tac
	tclsh8.5 ../scripts/taccle.tcl snipyacc.tac
