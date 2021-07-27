
signature LOC =
sig
    structure SourcePos :
    sig
        type t

        val filename : t -> string
        val line : t -> int
        val column : t -> int
        val offset : t -> int
        val toString : t -> string
    end

    structure Pos :
    sig
        type t

        val equals : t * t -> bool
        val compare : t * t -> order
        val hash : t -> word
    end

    structure File :
    sig
        type t

        val addLine : t * int -> unit
        val pos : t * int -> Pos.t
    end

    structure FileSet :
    sig
        type t

        val new : unit -> t
        val addFile : t * string * int -> File.t
        val sourcePos : t * Pos.t -> SourcePos.t
    end
end
