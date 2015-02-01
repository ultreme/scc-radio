#!/usr/bin/env liquidsoap

set("log.file", true)
set("log.stdout", true)
set("log.level", 5)
set("server.telnet", true)
set("server.telnet.port", 5000)
set("log.file.path", "/tmp/broadcast.log")
set("audio.converter.samplerate.libsamplerate.quality","best")
set("buffering.path","/tmp")
set("decoding.buffer_length",10.)

clock = mksafe(audio_to_stereo(playlist(reload=60, "/playlists/singles/", mode="random")))
jingles = mksafe(audio_to_stereo(playlist(reload=60, "/playlists/jingles", mode="random")))
songs = mksafe(audio_to_stereo(playlist(reload=60, "/playlists/songs", mode="random")))

live = audio_to_stereo(input.harbor("rscc.live", id="rscc.live", port=5001, password="LIVE_PASSWORD", user="source", logfile="/tmp/harbor.log"))
#live2 = audio_to_stereo(input.harbor("rscc2.live", id="rscc2.live", port=5001, password="LIVE_PASSWORD", user="source"))
#live = strip_blank(live, length=10., threshold=-50.)

def custofade(previous, next)
  #source.skip(next)
  add([fade.initial(duration=2., type="exp", next), previous])
end

input = random(weights=[1,1], [jingles, songs])
input = add([input, switch([({0m0s}, clock)])])
#input = add([input, amplify(5., override="replay_gain", live)])

#input = live

#input = fallback(track_sensitive=true,
#                 transitions=[custofade],
#                 [ input ])
#multi_live = add([live, live2])
#input = fallback(track_sensitive=false, [multi_live,input])
input = fallback(track_sensitive=false, [live,input])
input = mksafe(input)

output.icecast(host="HARBOR_HOST",
               port=HARBOR_PORT,
               password="HARBOR_PASSWORD",
               %mp3(bitrate=128),
               mount="rscc.main",
               input)


title = '$(if $(title),"$(title)", "Emission inconnue")$(if $(artist), " par $(artist)") - %m-%d-%Y, %H:%M:%S'
output.file(%vorbis, reopen_on_metadata=true,
            fallible=true,
            "/playlists/emissions/" ^ title ^ ".ogg",
            live)