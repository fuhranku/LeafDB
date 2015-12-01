(* table.mli *)
open Typs

(* represents our table *)
type t

(* Takes a column, a table, returns the value associated with the column.
 * [postcondition] : returns Some value or None if no table exists w/ that name
 *)
val lookup    : column -> t -> value option

(* Takes two columns and returns the difference in their lengths*)
val get_diff  : t -> t -> int

(* Takes a list of columns, a table, and a condition and returns a
 * query given that the columns listed are in the table and the condition is
 * valid on the values of the columns
 *)
val select    : column list -> t -> where -> t

val selectAll : t -> where -> t

(* Takes a table, a list of columns, a list of values that
 * correspond respectively with the data types of the columns, and return a
 * table with the values appended to the columns
 *)
val insert    : t -> column list -> value list -> t

(* Takes a table, and a list which has a length equal to the number of
 * columns and which values correspond to the data types of the columns in order
 * of the columns, and returns a table with the values appended to the columns
 *)
(*val insertAll : t -> value list -> t*)

(* Takes a table, an updated list of (column * value) pairs, and a where
 * condition and returns an updated table for all records in which the condition
 * holds true
 *)
val update    : t -> (column * value) list -> where -> t

(* Takes a table, a list of (column * value) pairs, and returns a table
 * without the bindings in the list*)
val delete    : t -> where -> t

(* inner join
 * Takes two tables, and joins all rows from both tables where there is a
 * match between columns and joins them in a new table
 *)
val join      : t -> t -> on -> t

(* [precondition] : the two queries have the same number of columns
 * Takes two queries with the same number of columns and corresponding data
 * types. and appends one onto the other in a new query *)
val union     : t -> t -> t

val convert_matrix : t -> value list list

val strip_col : t -> column list -> column list
