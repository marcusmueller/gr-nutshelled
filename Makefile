all_targets = README.md structure.html structure.wiki structure.pdf structure.wiki.tmp
all: $(all_targets)

.PHONY : all

PANDOC = pandoc -f rst structure.rst

README.md: structure.rst
	$(PANDOC) -t markdown_github -o README.md -s 

structure.html: structure.rst
	$(PANDOC) -t html5 -o structure.html -s

structure.wiki.tmp: structure.rst
	$(PANDOC) -t textile -o structure.wiki.tmp

structure.wiki: structure.wiki.tmp
	sed 's/\* Category \(.*\)/{{collapse(\1)/' structure.wiki.tmp | sed 's/\*\* \.\.\./** ...\n}}\n\n/' > structure.wiki

structure.pdf: structure.rst
	$(PANDOC) -o structure.pdf

clean:
	rm $(all_targets)
