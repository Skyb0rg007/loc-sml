
structure Loc : LOC =
struct
    structure DynArray =
    struct
        datatype 'a t = T of {
            array: 'a option array ref,
            length: int ref
        }

        fun empty () = T { array = ref (Array.array (0, NONE)), length = ref 0 }

        fun singleton x = T { array = ref (Array.array (1, SOME x)), length = ref 1 }

        fun sub (T { array, length }, index) =
            case Array.sub (!array, index) of
                 SOME x => x
               | NONE => raise Subscript

        fun push (T { array, length }, elem) =
            (Array.update (!array, !length, SOME elem); length := !length + 1)
            handle Subscript =>
                let val new_size = Int.max (!length * 2, 10)
                    val new_arr = Array.array (new_size, NONE)
                in  Array.copy { src = !array, dst = new_arr, di = 0 };
                    array := new_arr;
                    Array.update (!array, !length, SOME elem);
                    length := !length + 1
                end

        fun length (T { length, ... }) = !length

        fun search (T { array, length }, f) =
            let val array = !array
                fun go (i, j) =
                    if i >= j then i else
                    let val h = Int.quot (i + j, 2)
                    in  if f (valOf (Array.sub (array, h)))
                        then go (i, h)
                        else go (h + 1, j)
                    end
            in  go (0, !length)
            end
    end

    structure SourcePos =
    struct
        datatype t = T of {
            filename: string,
            offset: int,
            line: int,
            column: int
        }

        fun filename (T {filename, ...}) = filename

        fun offset (T {offset, ...}) = offset

        fun line (T {line, ...}) = line

        fun column (T {column, ...}) = column

        fun toString (T {filename, line, column, ...}) =
            filename ^ ":" ^ Int.toString line ^ "." ^ Int.toString column
    end

    structure Pos =
    struct
        type t = int

        val hash = Word.fromInt
        val compare = Int.compare
        val equals: t * t -> bool = op =
    end

    structure File =
    struct
        datatype t = T of {
            name: string,
            base: int,
            size: int,
            lines: int DynArray.t
        }

        fun size (T {size, ...}) = size

        fun pos (T {base, size, ...}, offset) =
            if offset > size
            then raise Fail (String.concat
                ["Invalid file offset ", Int.toString offset,
                 " (should be <= ", Int.toString size, ")"])
            else base + offset

        fun addLine (T {lines, size, ...}, offset) =
            let val len = DynArray.length lines
            in  if (len = 0 orelse DynArray.sub (lines, len - 1) < offset) andalso offset < size
                    then DynArray.push (lines, offset)
                    else ()
            end

        fun sourcePos (T {name, lines, base, size}, p) =
            if p < base orelse p > base + size
            then raise Fail (String.concat
                ["Invalid Pos.t value ", Int.toString p,
                 " (should be in [", Int.toString base,
                 ", " ^ Int.toString (base + size), "])"])
            else
            let val offset = p - base
                val i = DynArray.search (lines, fn x => x > offset) - 1
            in  SourcePos.T {
                    filename = name,
                    line = i + 1,
                    column = offset - DynArray.sub (lines, i) + 1,
                    offset = offset
                }
            end
    end

    structure FileSet =
    struct
        datatype t = T of {
            base: int ref,
            files: File.t DynArray.t,
            last: File.t option ref
        }

        fun new () = T {
                base = ref 1,
                files = DynArray.empty (),
                last = ref NONE
            }

        fun addFile (T {base, files, last}, name, size) =
            let val () = if size < 0
                    then raise Fail ("Invalid size " ^ Int.toString size ^ " (should be >= 0)")
                    else ()
                val f = File.T {
                    name = name,
                    base = !base,
                    size = size,
                    lines = DynArray.singleton 0
                }
            in  base := !base + size + 1;
                DynArray.push (files, f);
                last := SOME f;
                f
            end

        fun file (T {files, last, ...}, p) =
            let fun searchFiles () =
                    let val i = DynArray.search (files, fn (File.T {base, ...}) => base > p) - 1
                        val f as File.T {base, size, ...} = DynArray.sub (files, i)
                    in  if p > base + size
                            then raise Fail "Invalid position"
                            else ();
                        last := SOME f;
                        f
                    end
            in  case !last of
                     NONE => searchFiles ()
                   | SOME (f as File.T {base, size, ...}) =>
                       if base <= p andalso p <= base + size
                           then f
                           else searchFiles ()
            end

        fun sourcePos (fs, p) = File.sourcePos (file (fs, p), p)
    end
end
