type 'a route
type 'a t

type 'a parse_result =
  { params : (string * string) list
  ; wildcard : string option
  ; data : 'a
  }

val route : string -> 'a -> 'a route
val one_of : 'a route list -> 'a t
val match' : 'a t -> target:string -> 'a parse_result option
