open Sys
open Maps
open Str

(*filesystem.ml*)

let get_files_paths folder =
  let dir = "/path/to/dir" in
  let children = Sys.readdir dir in
    Array.iter print_endline children;;

let read_db folder = failwith "not implemented"

let parse_item (s:string) =
  let sep = Str.search_forward (regexp_string "*") s 0 in
    (int_of_string (Bytes.sub s 0 sep),
    (Bytes.sub s (sep + 1) (Bytes.length s - sep - 1)))

let make_map typ =
  match typ with
  | "VInt" -> Maps.create (VInt 0)
  | "VString" -> Maps.create (VString "")
  | "VBool" -> Maps.create (VBool false)
  | "VFloat" -> Maps.create (VFloat 0.0)
  | _ -> failwith "Error: Not a valid SQL type"

let rec parse_all_items row acc =
  match row with
  | [] -> acc
  | h::t -> parse_all_items t (acc @ [(parse_item h)])

let rec insert_items (typ:string) map row =
  match typ, map, row with
  | "VInt", m, (id, v)::t ->
      insert_items typ (Maps.insert (VInt (int_of_string v)) id m) t
  | "VString", m, (id, v)::t ->
      insert_items typ (Maps.insert (VString v) id m) t
  | "VBool", m, (id, v)::t ->
      insert_items typ (Maps.insert (VBool (bool_of_string v)) id m) t
  | "VFloat", m, (id, v)::t ->
      insert_items typ (Maps.insert (VFloat (float_of_string v)) id m) t
  | _ , _, [] -> map
  | _, _, _ -> failwith "Error: Type and Map should be specified"


let rec read_tbl_helper (matrix:bytes list list) acc =
  match matrix with
  | [] -> acc
  | (typ::name::t)::t'-> read_tbl_helper t' (acc @ [(name, insert_items typ (make_map typ) (parse_all_items t []))])
  | _::t' -> failwith "Error: Row should have more than 2 items"

let read_tbl file = failwith "unimplemented"

let add_db db = failwith "not implemented"

let write_tbl tbl = failwith "not implemented"

let delete_db file = failwith "not implemented"
