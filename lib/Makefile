.PHONY: commit snippets snip_parser.tcl

commit:
	tclsh8.5 commit.tcl
	hg commit

snippets: snip_lexer.tcl snip_parser.tcl

snip_lexer.tcl: snip_lexer.fcl
	tclsh8.5 ../scripts/fickle.tcl -P snip_ snip_lexer.fcl

snip_parser.tcl:
	tclsh8.5 ../scripts/taccle.tcl -d -p snip_ snip_parser.tac
