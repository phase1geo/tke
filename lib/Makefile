FICKLE = ../scripts/fickle.tcl
TACCLE = ../scripts/taccle.tcl

.PHONY: commit snippets emmet snip_parser.tcl format_parser.tcl

commit:
	tclsh8.5 commit.tcl
	hg commit

snippets: snip_lexer.tcl snip_parser.tcl format_lexer.tcl format_parser.tcl

emmet: emmet_lexer.tcl emmet_parser.tcl

snip_lexer.tcl: snip_lexer.fcl
	tclsh8.5 $(FICKLE) -P snip_ snip_lexer.fcl

snip_parser.tcl:
	tclsh8.5 $(TACCLE) -d -p snip_ snip_parser.tac

format_lexer.tcl: format_lexer.fcl
	tclsh8.5 $(FICKLE) -P format_ format_lexer.fcl

format_parser.tcl:
	tclsh8.5 $(TACCLE) -d -p format_ format_parser.tac

emmet_lexer.tcl: emmet_lexer.fcl
	tclsh8.5 $(FICKLE) -P emmet_ emmet_lexer.fcl

emmet_parser.tcl: emmet_parser.tac
	tclsh8.5 $(TACCLE) -d -p emmet_ emmet_parser.tac

