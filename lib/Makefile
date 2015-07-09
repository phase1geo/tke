FICKLE = ../scripts/fickle.tcl
TACCLE = ../scripts/taccle.tcl

.PHONY: commit snippets snip_parser.tcl format_parser.tcl

commit:
	tclsh8.5 commit.tcl
	hg commit

snippets: snip_lexer.tcl snip_parser.tcl format_lexer.tcl format_parser.tcl

snip_lexer.tcl: snip_lexer.fcl
	tclsh8.5 $(FICKLE) -P snip_ snip_lexer.fcl

snip_parser.tcl:
	tclsh8.5 $(TACCLE) -d -p snip_ snip_parser.tac

format_lexer.tcl: format_lexer.fcl
	tclsh8.5 $(FICKLE) -P format_ format_lexer.fcl

format_parser.tcl:
	tclsh8.5 $(TACCLE) -d -p format_ format_parser.tac
