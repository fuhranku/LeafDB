(*maps.ml*)
open Typs
open Str
open Assertions

module Maps = struct

let pair_compare (a,a') (b,b') = if a' = b' then Pervasives.compare a b
                                 else Pervasives.compare a' b'

module Int: Map.OrderedType with type t = (int*int) = struct
  type t = (int*int)
  let compare = pair_compare
end

module String: Map.OrderedType with type t = (int*string) = struct
  type t = (int*string)
  let compare = pair_compare
end

module Bool: Map.OrderedType with type t = (int*bool) = struct
  type t = (int*bool)
  let compare = pair_compare
end

module Float: Map.OrderedType with type t = (int*float) = struct
  type t = (int*float)
  let compare = pair_compare
end


module IntMap    = Map.Make (Int)
module StringMap = Map.Make (String)
module BoolMap   = Map.Make (Bool)
module FloatMap  = Map.Make (Float)


type t =
  | Smap of int StringMap.t
  | Bmap of int BoolMap.t
  | Imap of int IntMap.t
  | Fmap of int FloatMap.t

(*precondition: r is a unique key *in* the map
  postcondition: returns the value associated with the row key r*)
let lookup r m = match m with
  |Fmap map ->
    VFloat(snd (fst (FloatMap.choose(FloatMap.filter(fun (row,v) value -> row = r) map))))
  |Smap map ->
    VString(snd (fst (StringMap.choose(StringMap.filter (fun (row,v) value -> row = r) map))))
  |Imap map ->
    VInt(snd (fst (IntMap.choose(IntMap.filter (fun (row,v) value -> row = r) map))))
  |Bmap map ->
    VBool(snd (fst (BoolMap.choose(BoolMap.filter(fun (row,v) value -> row = r) map))))
(*precondition:
  postcondition: *)
let joiner (vu:value) (m:t) : int  = match vu,m with
  |VFloat v, Fmap map ->
    fst (fst (FloatMap.choose(FloatMap.filter(fun (row,v') value -> v = v') map)))
  |VString v,Smap map ->
    fst (fst (StringMap.choose(StringMap.filter (fun (row,v') value -> v = v') map)))
  |VInt v, Imap map ->
    fst (fst (IntMap.choose(IntMap.filter (fun (row,v') value -> v = v') map)))
  |VBool v, Bmap map ->
    fst (fst (BoolMap.choose(BoolMap.filter(fun (row,v') value -> v = v') map)))
  |_ -> failwith "error"


let has_value (vu:value) (map:t) : bool =
  match vu,map with
  |VInt v, Imap m ->
    not (IntMap.is_empty (IntMap.filter(fun (row,v') value -> v = v') m))
  |VString v, Smap m ->
    not (StringMap.is_empty (StringMap.filter(fun (row,v') value -> v = v') m))
  |VBool v, Bmap m ->
    not (BoolMap.is_empty (BoolMap.filter(fun (row,v') value -> v = v') m))
  |VFloat v, Fmap m ->
    not (FloatMap.is_empty (FloatMap.filter(fun (row,v') value -> v = v') m))
  | _ -> failwith "error"


let is_member r map = match map with
  |Imap m ->
    not (IntMap.is_empty(IntMap.filter(fun (row,v) value -> row = r) m))
  |Smap m ->
    not (StringMap.is_empty(StringMap.filter(fun (row,v) value -> row = r) m))
  |Bmap m ->
    not (BoolMap.is_empty(BoolMap.filter(fun (row,v) value -> row = r) m))
  |Fmap m ->
    not (FloatMap.is_empty(FloatMap.filter(fun (row,v) value -> row = r) m))

let get_rows map = match map with
  |Imap m -> IntMap.fold (fun (r,v) a b -> a::b) m []
  |Smap m -> StringMap.fold (fun (r,v) a b -> a::b) m []
  |Bmap m -> BoolMap.fold (fun (r,v) a b -> a::b) m []
  |Fmap m -> FloatMap.fold (fun (r,v) a b -> a::b) m []

let empty map =
  match map with
  | Smap _ -> Smap (StringMap.empty)
  | Bmap _ -> Bmap (BoolMap.empty)
  | Imap _ -> Imap (IntMap.empty)
  | Fmap _ -> Fmap (FloatMap.empty)

(* [create v] creates an empty map based on the value v
 * precondition  : none
 * postcondition : create v ~ empty (create v) *)
let create (v : value) =
  match v with
  | VInt _ -> Imap (IntMap.empty)
  | VString _ -> Smap (StringMap.empty)
  | VFloat _ -> Fmap (FloatMap.empty)
  | VBool _ -> Bmap (BoolMap.empty)
  | _ -> failwith "Error"

let like_compare comp key condition =
  match condition with
  | LikeBegin -> string_match (regexp (key^".*")) comp 0
  | LikeEnd -> string_match (regexp (".*"^key)) comp 0
  | LikeSubstring -> string_match (regexp (".*"^key^".*")) comp 0
  | NotLikeBegin -> not (string_match (regexp (key^".*")) comp 0)
  | NotLikeEnd -> not (string_match (regexp (".*"^key)) comp 0)
  | NotLikeSubstring -> not (string_match (regexp (".*"^key^".*")) comp 0)
  | _ -> false

let size (map: t) : int = match map with
  | Smap m -> StringMap.cardinal m
  | Bmap m -> BoolMap.cardinal m
  | Imap m -> IntMap.cardinal m
  | Fmap m -> FloatMap.cardinal m

let rec get_longest (map_list:t list) (lsize:int) (lmap:t) : t =
  match map_list with
  | [] -> lmap
  | (Smap s)::t ->
     if (StringMap.cardinal s) > lsize then
       get_longest t (StringMap.cardinal s) (Smap s)
     else get_longest t lsize lmap
  | (Bmap b)::t ->
     if (BoolMap.cardinal b) > lsize then
       get_longest t (BoolMap.cardinal b) (Bmap b)
     else get_longest t lsize lmap
  | (Imap i)::t ->
     if (IntMap.cardinal i) > lsize then
       get_longest t (IntMap.cardinal i) (Imap i)
     else get_longest t lsize lmap
  | (Fmap f)::t ->
     if (FloatMap.cardinal f) > lsize then
       get_longest t (FloatMap.cardinal f) (Fmap f)
     else get_longest t lsize lmap

let does_satisfy condition comp (c,key) =
  let var = Pervasives.compare key comp in
  match condition with
  | Gt -> var > 0
  | Lt -> var < 0
  | Eq -> var = 0
  | GtEq -> var > 0 || var = 0
  | LtEq -> var < 0 || var = 0
  | NotEq -> var <> 0
  | _ -> failwith "error"

let does_satisfy' condition comp (c,key) =
  let var = Pervasives.compare key comp in
  match condition with
  | Gt -> var > 0
  | Lt -> var < 0
  | Eq -> var = 0
  | GtEq -> var > 0 || var = 0
  | LtEq -> var < 0 || var = 0
  | NotEq -> var <> 0
  | _ -> like_compare key comp condition


let select map condition comp =
  match comp,map with
  | VInt i,Imap m ->
     Imap(IntMap.filter (fun key value -> does_satisfy condition i key) m)
  | VString s,Smap m  ->
     Smap(StringMap.filter (fun key value -> does_satisfy' condition s key) m)
  | VBool b,Bmap m ->
     Bmap(BoolMap.filter (fun key value -> does_satisfy condition b key) m)
  | VFloat f,Fmap m ->
     Fmap(FloatMap.filter (fun key value -> does_satisfy condition f key) m)
  | _ -> failwith "Error"

let insert value row  m = match value, m with
  | VInt i, Imap map -> Imap(IntMap.add (row,i) row map)
  | VString s, Smap map -> Smap(StringMap.add (row,s) row map)
  | VBool b, Bmap map -> Bmap(BoolMap.add (row,b) row map)
  | VFloat f, Fmap map -> Fmap(FloatMap.add (row,f) row map)
  | _ -> failwith "Error"

let update (map:t)(newv:value) =
  match map,newv with
  | Imap m, VInt i' ->
     Imap(IntMap.fold(fun (c,k) a map -> IntMap.add (c,i')(c)(IntMap.remove (c,k) map)) m m)
  | Smap m, VString s'->
     Smap(StringMap.fold(fun (c,k) a map -> StringMap.add (c,s')(c)(StringMap.remove (c,k) map)) m m)
  | Bmap m, VBool b' ->
     Bmap(BoolMap.fold(fun (c,k) a map -> BoolMap.add (c,b')(c)(BoolMap.remove (c,k) map)) m m)
  | Fmap m, VFloat f' ->
     Fmap(FloatMap.fold(fun (c,k) a map -> FloatMap.add (c,f')(c)(FloatMap.remove (c,k) map)) m m)
  | _ -> failwith "Does not follow schema"

let replace (newm:t) (oldm:t) =
  match newm with
  |Imap m -> IntMap.fold(fun (c,k) a map -> update map (VInt k)) m oldm
  |Smap m -> StringMap.fold(fun (c,k) a map -> update map (VString k)) m oldm
  |Bmap m -> BoolMap.fold(fun (c,k) a map -> update map (VBool k)) m oldm
  |Fmap m -> FloatMap.fold(fun (c,k) a map -> update map (VFloat k)) m oldm

let join (m1:t) (m2:t) : (int*int) list =
  match m1,m2 with
  |Imap m,Imap m' ->
    (IntMap.fold(fun (r,v) a acc -> if (has_value (VInt v) m2) then (joiner (VInt v) m2,r)::acc else acc) m [])
  |Smap m,Smap m' ->
    (StringMap.fold(fun (r,v) a acc -> if (has_value (VString v) m2) then (joiner (VString v) m2,r)::acc else acc) m [])
  |Bmap m,Bmap m' ->
    (BoolMap.fold(fun (r,v) a acc -> if (has_value (VBool v) m2) then (joiner (VBool v) m2,r)::acc else acc) m [])
  |Fmap m,Fmap m' ->
    (FloatMap.fold(fun (r,v) a acc -> if (has_value (VFloat v) m2) then (joiner (VFloat v) m2,r)::acc else acc) m [])
  | _ -> failwith "error"

let delete map op v = match v,map with
  | VInt i,Imap m ->
     (Imap(IntMap.filter (fun key value -> (not)(does_satisfy op i key)) m))
  | VString s,Smap m  ->
     (Smap(StringMap.filter (fun key value -> (not)(does_satisfy' op s key)) m))
  | VBool b,Bmap m ->
     (Bmap(BoolMap.filter (fun key value -> (not)(does_satisfy op b key)) m))
  | VFloat f,Fmap m ->
     (Fmap(FloatMap.filter (fun key value -> (not)(does_satisfy op f key)) m))
  | _ -> failwith "Error"



end

(*TESTS*)
open Maps
let imap = create (VInt 0)


TEST "test_size and create" = (size imap = 0)
TEST "test_empty" = (size (empty imap) = 0)

let rec insert_tester (i:int) m =
  if i = 0 then m
  else insert (VInt i) i (insert_tester (i-1) m)

let make_string (i:int) : string =
  (string_of_int i) ^ " words & letters ! " ^ (string_of_int i)

let rec insert_tester_string (i:int) m =
  if i = 0 then m
  else insert (VString(make_string i)) i (insert_tester_string (i-1) m)

let imap_hundred = insert_tester 100 imap
(*represents the map containing (1,1) to (100,100)*)
TEST "test_insert" = (size imap_hundred = 100)
(* Getting all values greater than 50*)
TEST "test_select_int" = (size (select imap_hundred Gt (VInt 50)) = 50)


let smap = create (VString "")
let smap_hundred = insert_tester_string 100 smap
TEST "test_select_string" = (size (select smap_hundred LikeSubstring (VString "word")) = 100 )
TEST "test_select_string" = (size (select smap_hundred LikeBegin (VString "1")) = 12 )
TEST "test_select_string" = (size (select smap_hundred LikeEnd (VString "0")) = 10)


(*TEST "JOIN" =*)

