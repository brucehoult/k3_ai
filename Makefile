install: aix
	mkdir -p ~/bin && cp ai aix ~/bin && chmod +x ~/bin/ai

aix: aix.S
	gcc -nostartfiles -static aix.S -o aix

clean:
	rm -f aix \#* *~
