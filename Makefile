# Makefile for AutoRescan plugin for Squeezebox Server 7.7 (and later)
# Copyright © Stuart Hickinbottom 2007-2014
# Copyright © James Marsh 2020

# This file is part of AutoRescan.
#
# AutoRescan is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# AutoRescan is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with AutoRescan; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

VERSION=1.4.2
PERLSOURCE=Plugin.pm Settings.pm Monitor_Linux.pm Monitor_Windows.pm
HTMLSOURCE=HTML/EN/plugins/AutoRescan/settings/basic.html
SOURCE=$(PERLSOURCE) $(HTMLSOURCE) README strings.txt install.xml LICENSE
RELEASEDIR=releases
STAGEDIR=stage
PLUGINDIR=AutoRescan
COMMIT=`git log -1 --pretty=format:%H`
DISTFILE=AutoRescan-$(VERSION).zip
DISTFILEDIR=$(RELEASEDIR)/$(DISTFILE)
SVNDISTFILE=AutoRescan.zip
LATESTLINK=$(RELEASEDIR)/AutoRescan-latest.zip

.SILENT:

all: release

FORCE:

make-stage:
	echo "Creating stage files (v$(VERSION)/$(COMMIT))..."
	-rm -rf $(STAGEDIR)/* >/dev/null 2>&1
	for FILE in $(SOURCE); do \
		mkdir -p "$(STAGEDIR)/$(PLUGINDIR)/`dirname $$FILE`"; \
		sed "s/@@VERSION@@/$(VERSION)/;s/@@COMMIT@@/$(COMMIT)/" <"$$FILE" >"$(STAGEDIR)/$(PLUGINDIR)/$$FILE"; \
	done

# Regenerate tags.
tags: $(PERLSOURCE)
	echo Tagging...
	exuberant-ctags $^

# Run the plugin through the Perl beautifier.
pretty:
	for FILE in $(PERLSOURCE); do \
		perltidy -b -ce -et=4 $$FILE && rm $$FILE.bak; \
	done

# Build a distribution package for this Plugin.
release: make-stage
	git diff --quiet --exit-code || ( git status && echo "Commit files first" && exit 1 )
	echo Building distfile: $(DISTFILE)
	-rm "$(DISTFILEDIR)" >/dev/null 2>&1
	(cd "$(STAGEDIR)" && zip -r "../$(DISTFILEDIR)" "$(PLUGINDIR)")
	-rm "$(LATESTLINK)" >/dev/null 2>&1
	ln -s "$(DISTFILE)" "$(LATESTLINK)"
	{ \
		set -e ;\
		SHASUM=$$(shasum "$(LATESTLINK)" | cut -f1 -d' ') ;\
		sed "s/@@VERSION@@/$(VERSION)/;s/@@SHASUM@@/$${SHASUM}/;s/@@DISTFILE@@/$(DISTFILE)/" < repo.xml.in >repo.xml ;\
	}
	git add  "$(DISTFILEDIR)" repo.xml "$(LATESTLINK)"
	git status
	@echo '"make tag" to finalise release'

tag:
	git commit -m "Release $(VERSION)"
	git tag "$(VERSION)"
