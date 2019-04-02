.PHONY: default build install uninstall clean

default: build

build:
	dune build

install:
	dune install

uninstall:
	dune uninstall

clean:
	dune clean
