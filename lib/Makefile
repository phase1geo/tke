FICKLE = ../scripts/fickle.tcl
TACCLE = ../scripts/taccle.tcl

ifeq ($(OS),Windows_NT)
TCLSH = tclsh86
else
TCLSH = tclsh8.6
endif

NAGELFAR_FILES = version.tcl \
                 share.tcl \
                 startup.tcl \
                 utils.tcl \
                 preferences.tcl \
                 edit.tcl \
                 gui.tcl \
                 sidebar.tcl \
                 menus.tcl \
                 launcher.tcl \
                 plugins.tcl \
                 interpreter.tcl \
                 snip_parser.tcl \
                 format_parser.tcl \
                 snippets.tcl \
                 bindings.tcl \
                 bgproc.tcl \
                 multicursor.tcl \
                 cliphist.tcl \
                 vim.tcl \
                 syntax.tcl \
                 api.tcl \
                 markers.tcl \
                 tkedat.tcl \
                 themer.tcl \
                 theme.tcl \
                 themes.tcl \
                 favorites.tcl \
                 logger.tcl \
                 diff.tcl \
                 sessions.tcl \
                 search.tcl \
                 scroller.tcl \
                 templates.tcl \
                 folding.tcl \
                 fontchooser.tcl \
                 emmet.tcl \
                 pref_ui.tcl \
                 remote.tcl \
                 socksend.tcl \
                 ftp_wrapper.tcl \
                 files.tcl

.PHONY: commit snippets emmet snip_parser.tcl format_parser.tcl static

commit:
	$(TCLSH) commit.tcl
	cd ..; git add .
	git commit

snippets: snip_lexer.tcl snip_parser.tcl format_lexer.tcl format_parser.tcl

emmet: emmet_lexer.tcl emmet_parser.tcl

snip_lexer.tcl: snip_lexer.fcl
	$(TCLSH) $(FICKLE) -P snip_ snip_lexer.fcl

snip_parser.tcl:
	$(TCLSH) $(TACCLE) -d -v -p snip_ snip_parser.tac

format_lexer.tcl: format_lexer.fcl
	$(TCLSH) $(FICKLE) -P format_ format_lexer.fcl

format_parser.tcl:
	$(TCLSH) $(TACCLE) -d -p format_ format_parser.tac

emmet_lexer.tcl: emmet_lexer.fcl
	$(TCLSH) $(FICKLE) -P emmet_ emmet_lexer.fcl

emmet_parser.tcl: emmet_parser.tac
	$(TCLSH) $(TACCLE) -d -p emmet_ emmet_parser.tac

static:
	nagelfar -gui $(NAGELFAR_FILES) &
