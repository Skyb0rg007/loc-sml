
signature LOC =
sig
    (* A SourcePos.t represents all parts of a location
     * This type should not be stored, and is instead retrieved via FileSet.sourcePos
     *)
    structure SourcePos :
    sig
        type t

        (* The name of the file *)
        val filename : t -> string
        (* The line number (starts at 1) *)
        val line : t -> int
        (* The column number (starts at 1) *)
        val column : t -> int
        (* The file offset (starts at 0). Can be equal to file size (represents EOF). *)
        val offset : t -> int
        (* Convert to a string, using "filename:line.column" format *)
        val toString : t -> string
    end

    (* A Pos.t represents a compressed source position. Store this within ASTs. *)
    structure Pos :
    sig
        type t

        val equals : t * t -> bool
        val compare : t * t -> order
        val hash : t -> word
    end

    (* Represents a single source file. Used to create Pos.t-s and register lines. *)
    structure File :
    sig
        type t

        (* [size file] is the size of the file in bytes *)
        val size : t -> int
        (* [addLine (file, offset)] registers the given offset as the first character on a given line.
         * So if offset 20 is a newline, [addLine (file, 21)] would register that fact.
         *)
        val addLine : t * int -> unit
        (* Create a compressed position from a file offset.
         * This represents the position at that offset in the given file.
         *)
        val pos : t * int -> Pos.t
    end

    (* A FileSet.t is a manager of all location-handling. *)
    structure FileSet :
    sig
        type t

        (* Create a new FileSet.t. *)
        val new : unit -> t
        (* [addFile (fileSet, fileName, fileSize)] adds a new file.
         * You must register line offsets using File.addLine.
         *)
        val addFile : t * string * int -> File.t
        (* Recover a full SourcePos.t from a compressed Pos.t
         * This call is O(log(n) + log(m)),
         * where n is the number of files and m is the number of lines in that file.
         *)
        val sourcePos : t * Pos.t -> SourcePos.t
    end
end
