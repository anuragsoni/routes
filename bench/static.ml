(** Copyright (c) 2013 Julien Schmidt. All rights reserved. Redistribution and use in
    source and binary forms, with or without modification, are permitted provided that the
    following conditions are met: * Redistributions of source code must retain the above
    copyright notice, this list of conditions and the following disclaimer. *
    Redistributions in binary form must reproduce the above copyright notice, this list of
    conditions and the following disclaimer in the documentation and/or other materials
    provided with the distribution. * The names of the contributors may not be used to
    endorse or promote products derived from this software without specific prior written
    permission. THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
    IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
    NO EVENT SHALL JULIEN SCHMIDT BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. *)

open Bechamel

let urls =
  [ "/"
  ; "/cmd.html"
  ; "/code.html"
  ; "/contrib.html"
  ; "/contribute.html"
  ; "/debugging_with_gdb.html"
  ; "/docs.html"
  ; "/effective_go.html"
  ; "/files.log"
  ; "/gccgo_contribute.html"
  ; "/gccgo_install.html"
  ; "/go-logo-black.png"
  ; "/go-logo-blue.png"
  ; "/go-logo-white.png"
  ; "/go1.1.html"
  ; "/go1.2.html"
  ; "/go1.html"
  ; "/go1compat.html"
  ; "/go_faq.html"
  ; "/go_mem.html"
  ; "/go_spec.html"
  ; "/help.html"
  ; "/ie.css"
  ; "/install-source.html"
  ; "/install.html"
  ; "/logo-153x55.png"
  ; "/Makefile"
  ; "/root.html"
  ; "/share.png"
  ; "/sieve.gif"
  ; "/tos.html"
  ; "/articles/"
  ; "/articles/go_command.html"
  ; "/articles/index.html"
  ; "/articles/wiki/"
  ; "/articles/wiki/edit.html"
  ; "/articles/wiki/final-noclosure.go"
  ; "/articles/wiki/final-noerror.go"
  ; "/articles/wiki/final-parsetemplate.go"
  ; "/articles/wiki/final-template.go"
  ; "/articles/wiki/final.go"
  ; "/articles/wiki/get.go"
  ; "/articles/wiki/http-sample.go"
  ; "/articles/wiki/index.html"
  ; "/articles/wiki/Makefile"
  ; "/articles/wiki/notemplate.go"
  ; "/articles/wiki/part1-noerror.go"
  ; "/articles/wiki/part1.go"
  ; "/articles/wiki/part2.go"
  ; "/articles/wiki/part3-errorhandling.go"
  ; "/articles/wiki/part3.go"
  ; "/articles/wiki/test.bash"
  ; "/articles/wiki/test_edit.good"
  ; "/articles/wiki/test_Test.txt.good"
  ; "/articles/wiki/test_view.good"
  ; "/articles/wiki/view.html"
  ; "/codewalk/"
  ; "/codewalk/codewalk.css"
  ; "/codewalk/codewalk.js"
  ; "/codewalk/codewalk.xml"
  ; "/codewalk/functions.xml"
  ; "/codewalk/markov.go"
  ; "/codewalk/markov.xml"
  ; "/codewalk/pig.go"
  ; "/codewalk/popout.png"
  ; "/codewalk/run"
  ; "/codewalk/sharemem.xml"
  ; "/codewalk/urlpoll.go"
  ; "/devel/"
  ; "/devel/release.html"
  ; "/devel/weekly.html"
  ; "/gopher/"
  ; "/gopher/appenginegopher.jpg"
  ; "/gopher/appenginegophercolor.jpg"
  ; "/gopher/appenginelogo.gif"
  ; "/gopher/bumper.png"
  ; "/gopher/bumper192x108.png"
  ; "/gopher/bumper320x180.png"
  ; "/gopher/bumper480x270.png"
  ; "/gopher/bumper640x360.png"
  ; "/gopher/doc.png"
  ; "/gopher/frontpage.png"
  ; "/gopher/gopherbw.png"
  ; "/gopher/gophercolor.png"
  ; "/gopher/gophercolor16x16.png"
  ; "/gopher/help.png"
  ; "/gopher/pkg.png"
  ; "/gopher/project.png"
  ; "/gopher/ref.png"
  ; "/gopher/run.png"
  ; "/gopher/talks.png"
  ; "/gopher/pencil/"
  ; "/gopher/pencil/gopherhat.jpg"
  ; "/gopher/pencil/gopherhelmet.jpg"
  ; "/gopher/pencil/gophermega.jpg"
  ; "/gopher/pencil/gopherrunning.jpg"
  ; "/gopher/pencil/gopherswim.jpg"
  ; "/gopher/pencil/gopherswrench.jpg"
  ; "/play/"
  ; "/play/fib.go"
  ; "/play/hello.go"
  ; "/play/life.go"
  ; "/play/peano.go"
  ; "/play/pi.go"
  ; "/play/sieve.go"
  ; "/play/solitaire.go"
  ; "/play/tree.go"
  ; "/progs/"
  ; "/progs/cgo1.go"
  ; "/progs/cgo2.go"
  ; "/progs/cgo3.go"
  ; "/progs/cgo4.go"
  ; "/progs/defer.go"
  ; "/progs/defer.out"
  ; "/progs/defer2.go"
  ; "/progs/defer2.out"
  ; "/progs/eff_bytesize.go"
  ; "/progs/eff_bytesize.out"
  ; "/progs/eff_qr.go"
  ; "/progs/eff_sequence.go"
  ; "/progs/eff_sequence.out"
  ; "/progs/eff_unused1.go"
  ; "/progs/eff_unused2.go"
  ; "/progs/error.go"
  ; "/progs/error2.go"
  ; "/progs/error3.go"
  ; "/progs/error4.go"
  ; "/progs/go1.go"
  ; "/progs/gobs1.go"
  ; "/progs/gobs2.go"
  ; "/progs/image_draw.go"
  ; "/progs/image_package1.go"
  ; "/progs/image_package1.out"
  ; "/progs/image_package2.go"
  ; "/progs/image_package2.out"
  ; "/progs/image_package3.go"
  ; "/progs/image_package3.out"
  ; "/progs/image_package4.go"
  ; "/progs/image_package4.out"
  ; "/progs/image_package5.go"
  ; "/progs/image_package5.out"
  ; "/progs/image_package6.go"
  ; "/progs/image_package6.out"
  ; "/progs/interface.go"
  ; "/progs/interface2.go"
  ; "/progs/interface2.out"
  ; "/progs/json1.go"
  ; "/progs/json2.go"
  ; "/progs/json2.out"
  ; "/progs/json3.go"
  ; "/progs/json4.go"
  ; "/progs/json5.go"
  ; "/progs/run"
  ; "/progs/slices.go"
  ; "/progs/timeout1.go"
  ; "/progs/timeout2.go"
  ; "/progs/update.bash"
  ]
;;

let handler = ()

module Util = struct
  let split_path target =
    let split_target target =
      match target with
      | "" -> []
      | _ ->
        (match String.split_on_char '/' target with
        | "" :: xs -> xs
        | xs -> xs)
    in
    match String.index_opt target '?' with
    | None -> split_target target
    | Some 0 -> []
    | Some i -> split_target (String.sub target 0 i)
  ;;
end

open Routes

let mr r = r @--> handler

let router =
  one_of
    (List.map
       (fun u ->
         let split = Util.split_path u |> List.map (fun q -> s q) in
         let r =
           match split with
           | [] -> empty
           | [ x ] -> x /? nil
           | x :: xs ->
             let t = List.fold_left (fun acc y -> acc / y) x xs in
             t /? nil
         in
         mr r)
       urls)
;;

let bench_routes router targets =
  Staged.stage @@ fun () -> ignore (List.map (fun u -> match' ~target:u router) targets)
;;

let bench = Test.make ~name:"Static bench" @@ bench_routes router urls
