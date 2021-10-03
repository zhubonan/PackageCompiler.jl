const ESC = "\e"
const CSI = "\e["
const DEC_RST  = "l"
const DEC_SET  = "h"
const DEC_TCEM = "?25"

const TTY_HIDE_CURSOR = CSI * DEC_TCEM * DEC_RST
const TTY_SHOW_CURSOR = CSI * DEC_TCEM * DEC_SET
const TTY_CLEAR_LINE = CSI * "2K"

using Printf

const frames = [
    "⠋",
    "⠙",
    "⠹",
    "⠸",
    "⠼",
    "⠴",
    "⠦",
    "⠧",
    "⠇",
    "⠏",
]

Base.@kwdef struct Spinner{IO_t <: IO}
    frames::Vector{String} = frames
    interval::Float64 = 1/10 # [s]
    msg::String = ""
    stream::IO_t = stdout
    start = time()
end

function iterate_frame(s::Spinner, state::Int=1)
    frame = s.frames[state]
    state = state == length(s.frames) ? 1 : state + 1
    return frame, state
end

function spin(s::Spinner)
    frame, state = iterate_frame(s)
    print(s.stream, TTY_HIDE_CURSOR)
    t = Timer(0.0; interval=1/15) do timer
        print(s.stream, '\r')
        printstyled(s.stream, frame; color=Base.info_color())
        elapsed = time() - s.start
        (minutes, seconds) = fldmod(elapsed, 60)
        (hours, minutes) = fldmod(minutes, 60)
        if hours == 0
            printstyled(s.stream, @sprintf("[%02d:%02d]", minutes, seconds); color=Base.info_color())
        else
            printstyled(s.stream, @sprintf("[%02d:%02d:%02d]", hours, minutes, seconds); color=Base.info_color())
        end
        print(s.stream, " ", s.msg)
        frame, state = iterate_frame(s, state)
    end
    return t
end

function stop_spin(s::Spinner, t::Timer)
    close(t)
    print(s.stream, TTY_SHOW_CURSOR)
end

macro spin(msg, work)
    return quote
        s = Spinner(;msg=$(esc(msg)))
        t = spin(s)
        try
            return $(esc(work))
        finally
            stop_spin(s, t)
        end
    end
end

