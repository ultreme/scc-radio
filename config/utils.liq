def custofade(previous, next)
  #source.skip(next)
  add([fade.initial(duration=2., type="exp", next), previous])
end

  def source_tag(s,tag) =
    def f(_)
      [("source_tag",(tag:string))]
    end
    map_metadata(id=tag,insert_missing=true,f,s)
  end

  def transition(a,b)
    # If old or new source is not music, no fade
    if a.metadata["source_tag"] != "music" or a.metadata["source_tag"] != "music" then
      sequence([a.source, b.source])
    else
      # Else, apply the standard smart transition
      cross.smart(a, b)
    end
  end


def fade(jingles,music)
  music = source_tag(music, "music")
  jingles = source_tag(jingles, "jingles")

  radio = rotate(weights = [1,3],[jingles,music])

  cross(duration=3.,transition, radio)
end


def my_getenv(key) =
  list.hd(get_process_lines("/bin/sh -c 'echo $#{key}'"))
end


#def audio_process(s)
#  gain = interactive.float("compress.gain",3.)
#  ratio = 3. # interactive.float("compress.ratio",3.)
#  threshold = interactive.float("compress.threshold",-15.)
#
#  target = interactive.float("norm.target",-13.)
#  k_up = interactive.float("norm.kup",0.005)
#  k_down = interactive.float("norm.kdn",0.1)
#
#  s = normalize(target=target,k_up=k_up,k_down=k_down,s)
#  s = compress(gain=gain,ratio=ratio,threshold=threshold,s)
#  s
#end
