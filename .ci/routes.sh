#!/usr/bin/env bash
sudo add-apt-repository -y ppa:avsm/ppa
sudo apt-get update -y
sudo apt install -y opam
opam init
eval $(opam env)
opam pin add routes .
dune build
dune runtest
