def custofade(previous, next)
  #source.skip(next)
  add([fade.initial(duration=2., type="exp", next), previous])
end


def fade(jingles,s)
  fade_in = 2.
  fade_out = 2.
  start_next = 2.
  j = random(
      id="jrand",
      weights=[1,1],
      [jingles, blank(id="bbb",duration=1.)])
  def fader(from,to)
    from = fade.out(duration=fade_out,from)
    to = fade.in(duration=fade_in,to)
    add(
        normalize=false,
        [
            to,
            sequence([ j, fallback([]) ]),
            from
            ]
        )
    end
  cross(duration=start_next,fader,s)
end


def my_getenv(key) =
  list.hd(get_process_lines("/bin/sh -c 'echo $#{key}'"))
end


def audio_process(s)
  gain = interactive.float("compress.gain",3.)
  ratio = 3. # interactive.float("compress.ratio",3.)
  threshold = interactive.float("compress.threshold",-15.)

  target = interactive.float("norm.target",-13.)
  k_up = interactive.float("norm.kup",0.005)
  k_down = interactive.float("norm.kdn",0.1)

  s = normalize(target=target,k_up=k_up,k_down=k_down,s)
  s = compress(gain=gain,ratio=ratio,threshold=threshold,s)
  s
end
