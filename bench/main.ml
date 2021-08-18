(* Benchmark setup taken from
   https://github.com/mirage/bechamel/blob/3e1887305badf5dcc1ecb06beb5b023f55b4193c/examples/list.ml

   License:

   The MIT License (MIT)

   Copyright (c) 2018 Romain Calascibetta <romain.calascibetta@gmail.com>

   Permission is hereby granted, free of charge, to any person obtaining a copy of this
   software and associated documentation files (the "Software"), to deal in the Software
   without restriction, including without limitation the rights to use, copy, modify,
   merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to the following
   conditions:

   The above copyright notice and this permission notice shall be included in all copies
   or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
   PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
   CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
   THE USE OR OTHER DEALINGS IN THE SOFTWARE. *)

open Bechamel
open Toolkit

let benches = Test.make_grouped ~name:"Routes bench" [ Static.bench; Parse.bench ]

let benchmark () =
  let ols = Analyze.ols ~bootstrap:0 ~r_square:true ~predictors:Measure.[| run |] in
  let instances = Instance.[ minor_allocated; major_allocated; monotonic_clock ] in
  let cfg = Benchmark.cfg ~limit:2000 ~quota:(Time.second 0.5) ~kde:(Some 1000) () in
  let raw_results = Benchmark.all cfg instances benches in
  let results =
    List.map (fun instance -> Analyze.all ols instance raw_results) instances
  in
  let results = Analyze.merge ols instances results in
  results, raw_results
;;

open Notty_unix

let img (window, results) =
  Bechamel_notty.Multiple.image_of_ols_results ~rect:window ~predictor:Measure.run results
;;

let () = match Sys.argv with
  | [| _; "json" |] ->
    let results = benchmark () in
    let results =
      let open Bechamel_js in
      emit ~dst:(Channel stdout) (fun _ -> Ok ()) ~compare:String.compare ~x_label:Measure.run
        ~y_label:(Measure.label Instance.monotonic_clock) results in
      Rresult.R.failwith_error_msg results
  | _ ->
    List.iter
      (fun v -> Bechamel_notty.Unit.add v (Measure.unit v))
      Instance.[ minor_allocated; major_allocated; monotonic_clock ];
    let window =
      match winsize Unix.stdout with
      | Some (w, h) -> { Bechamel_notty.w; h }
      | None -> { Bechamel_notty.w = 80; h = 1 }
    in
    let results, _ = benchmark () in
    img (window, results) |> eol |> output_image
;;
