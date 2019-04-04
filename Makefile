.PHONY: default build install uninstall clean test

default: build

build:
	dune build

install:
	dune install

uninstall:
	dune uninstall

clean:
	dune clean

test:
	dune runtest -f
