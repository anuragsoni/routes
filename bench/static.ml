(**
Copyright (c) 2013 Julien Schmidt. All rights reserved.


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * The names of the contributors may not be used to endorse or promote
      products derived from this software without specific prior written
      permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL JULIEN SCHMIDT BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

let urls =
  [ `GET, "/"
  ; `GET, "/cmd.html"
  ; `GET, "/code.html"
  ; `GET, "/contrib.html"
  ; `GET, "/contribute.html"
  ; `GET, "/debugging_with_gdb.html"
  ; `GET, "/docs.html"
  ; `GET, "/effective_go.html"
  ; `GET, "/files.log"
  ; `GET, "/gccgo_contribute.html"
  ; `GET, "/gccgo_install.html"
  ; `GET, "/go-logo-black.png"
  ; `GET, "/go-logo-blue.png"
  ; `GET, "/go-logo-white.png"
  ; `GET, "/go1.1.html"
  ; `GET, "/go1.2.html"
  ; `GET, "/go1.html"
  ; `GET, "/go1compat.html"
  ; `GET, "/go_faq.html"
  ; `GET, "/go_mem.html"
  ; `GET, "/go_spec.html"
  ; `GET, "/help.html"
  ; `GET, "/ie.css"
  ; `GET, "/install-source.html"
  ; `GET, "/install.html"
  ; `GET, "/logo-153x55.png"
  ; `GET, "/Makefile"
  ; `GET, "/root.html"
  ; `GET, "/share.png"
  ; `GET, "/sieve.gif"
  ; `GET, "/tos.html"
  ; `GET, "/articles/"
  ; `GET, "/articles/go_command.html"
  ; `GET, "/articles/index.html"
  ; `GET, "/articles/wiki/"
  ; `GET, "/articles/wiki/edit.html"
  ; `GET, "/articles/wiki/final-noclosure.go"
  ; `GET, "/articles/wiki/final-noerror.go"
  ; `GET, "/articles/wiki/final-parsetemplate.go"
  ; `GET, "/articles/wiki/final-template.go"
  ; `GET, "/articles/wiki/final.go"
  ; `GET, "/articles/wiki/get.go"
  ; `GET, "/articles/wiki/http-sample.go"
  ; `GET, "/articles/wiki/index.html"
  ; `GET, "/articles/wiki/Makefile"
  ; `GET, "/articles/wiki/notemplate.go"
  ; `GET, "/articles/wiki/part1-noerror.go"
  ; `GET, "/articles/wiki/part1.go"
  ; `GET, "/articles/wiki/part2.go"
  ; `GET, "/articles/wiki/part3-errorhandling.go"
  ; `GET, "/articles/wiki/part3.go"
  ; `GET, "/articles/wiki/test.bash"
  ; `GET, "/articles/wiki/test_edit.good"
  ; `GET, "/articles/wiki/test_Test.txt.good"
  ; `GET, "/articles/wiki/test_view.good"
  ; `GET, "/articles/wiki/view.html"
  ; `GET, "/codewalk/"
  ; `GET, "/codewalk/codewalk.css"
  ; `GET, "/codewalk/codewalk.js"
  ; `GET, "/codewalk/codewalk.xml"
  ; `GET, "/codewalk/functions.xml"
  ; `GET, "/codewalk/markov.go"
  ; `GET, "/codewalk/markov.xml"
  ; `GET, "/codewalk/pig.go"
  ; `GET, "/codewalk/popout.png"
  ; `GET, "/codewalk/run"
  ; `GET, "/codewalk/sharemem.xml"
  ; `GET, "/codewalk/urlpoll.go"
  ; `GET, "/devel/"
  ; `GET, "/devel/release.html"
  ; `GET, "/devel/weekly.html"
  ; `GET, "/gopher/"
  ; `GET, "/gopher/appenginegopher.jpg"
  ; `GET, "/gopher/appenginegophercolor.jpg"
  ; `GET, "/gopher/appenginelogo.gif"
  ; `GET, "/gopher/bumper.png"
  ; `GET, "/gopher/bumper192x108.png"
  ; `GET, "/gopher/bumper320x180.png"
  ; `GET, "/gopher/bumper480x270.png"
  ; `GET, "/gopher/bumper640x360.png"
  ; `GET, "/gopher/doc.png"
  ; `GET, "/gopher/frontpage.png"
  ; `GET, "/gopher/gopherbw.png"
  ; `GET, "/gopher/gophercolor.png"
  ; `GET, "/gopher/gophercolor16x16.png"
  ; `GET, "/gopher/help.png"
  ; `GET, "/gopher/pkg.png"
  ; `GET, "/gopher/project.png"
  ; `GET, "/gopher/ref.png"
  ; `GET, "/gopher/run.png"
  ; `GET, "/gopher/talks.png"
  ; `GET, "/gopher/pencil/"
  ; `GET, "/gopher/pencil/gopherhat.jpg"
  ; `GET, "/gopher/pencil/gopherhelmet.jpg"
  ; `GET, "/gopher/pencil/gophermega.jpg"
  ; `GET, "/gopher/pencil/gopherrunning.jpg"
  ; `GET, "/gopher/pencil/gopherswim.jpg"
  ; `GET, "/gopher/pencil/gopherswrench.jpg"
  ; `GET, "/play/"
  ; `GET, "/play/fib.go"
  ; `GET, "/play/hello.go"
  ; `GET, "/play/life.go"
  ; `GET, "/play/peano.go"
  ; `GET, "/play/pi.go"
  ; `GET, "/play/sieve.go"
  ; `GET, "/play/solitaire.go"
  ; `GET, "/play/tree.go"
  ; `GET, "/progs/"
  ; `GET, "/progs/cgo1.go"
  ; `GET, "/progs/cgo2.go"
  ; `GET, "/progs/cgo3.go"
  ; `GET, "/progs/cgo4.go"
  ; `GET, "/progs/defer.go"
  ; `GET, "/progs/defer.out"
  ; `GET, "/progs/defer2.go"
  ; `GET, "/progs/defer2.out"
  ; `GET, "/progs/eff_bytesize.go"
  ; `GET, "/progs/eff_bytesize.out"
  ; `GET, "/progs/eff_qr.go"
  ; `GET, "/progs/eff_sequence.go"
  ; `GET, "/progs/eff_sequence.out"
  ; `GET, "/progs/eff_unused1.go"
  ; `GET, "/progs/eff_unused2.go"
  ; `GET, "/progs/error.go"
  ; `GET, "/progs/error2.go"
  ; `GET, "/progs/error3.go"
  ; `GET, "/progs/error4.go"
  ; `GET, "/progs/go1.go"
  ; `GET, "/progs/gobs1.go"
  ; `GET, "/progs/gobs2.go"
  ; `GET, "/progs/image_draw.go"
  ; `GET, "/progs/image_package1.go"
  ; `GET, "/progs/image_package1.out"
  ; `GET, "/progs/image_package2.go"
  ; `GET, "/progs/image_package2.out"
  ; `GET, "/progs/image_package3.go"
  ; `GET, "/progs/image_package3.out"
  ; `GET, "/progs/image_package4.go"
  ; `GET, "/progs/image_package4.out"
  ; `GET, "/progs/image_package5.go"
  ; `GET, "/progs/image_package5.out"
  ; `GET, "/progs/image_package6.go"
  ; `GET, "/progs/image_package6.out"
  ; `GET, "/progs/interface.go"
  ; `GET, "/progs/interface2.go"
  ; `GET, "/progs/interface2.out"
  ; `GET, "/progs/json1.go"
  ; `GET, "/progs/json2.go"
  ; `GET, "/progs/json2.out"
  ; `GET, "/progs/json3.go"
  ; `GET, "/progs/json4.go"
  ; `GET, "/progs/json5.go"
  ; `GET, "/progs/run"
  ; `GET, "/progs/slices.go"
  ; `GET, "/progs/timeout1.go"
  ; `GET, "/progs/timeout2.go"
  ; `GET, "/progs/update.bash"
  ]
;;

let handler = ()

open Routes
open Infix

let router =
  with_method
    (List.map
       (fun (m, u) ->
         let split = Routes_private.Util.split_path u in
         let p =
           match split with
           | [] -> empty
           | [ x ] -> s x
           | x :: xs -> List.fold_left (fun acc y -> acc *> s y) (s x) xs
         in
         m, handler <$ p)
       urls)
;;

let bench =
  let open Core_bench in
  Bench.Test.create ~name:"Static Bench" (fun () -> Util.bench_routes router urls)
;;
