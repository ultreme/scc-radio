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
