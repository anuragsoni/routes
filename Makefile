.PHONY: default build install uninstall clean test examples

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

examples:
	dune build @examples
