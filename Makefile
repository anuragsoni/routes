.PHONY: default build install uninstall clean test examples

default: build

build:
	dune build

build-bs:
	bsb -make-world

install:
	dune install

uninstall:
	dune uninstall

clean:
	dune clean

clean-bs:
	bsb -clean-world

test:
	dune runtest -f

examples:
	dune build @examples
