#!/usr/bin/env liquidsoap


%include "utils.liq"


# CONFIGS
set("log.file", true)
set("log.stdout", true)
set("log.level", 5)
set("server.telnet", true)
set("server.telnet.port", 5000)
set("log.file.path", "/tmp/broadcast.log")
set("audio.converter.samplerate.libsamplerate.quality","best")
set("buffering.path","/tmp")
set("decoding.buffer_length",10.)


# FUNCTIONS
def custofade(previous, next)
  #source.skip(next)
  add([fade.initial(duration=2., type="exp", next), previous])
end


# INPUTS
clock = mksafe(audio_to_stereo(playlist.safe(reload=3600, "/playlists/singles/", mode="random")))
jingles = mksafe(
    rewrite_metadata(
        [
            ("artist", "Salut c'est cool"),
            ("title","Jingle (Salut c'est cool)"),
            ("comment","http://www.salutcestcool.com/")
            ],
        audio_to_stereo(
            playlist.safe(
                reload=1800,
                "/playlists/jingles",
                mode="random"
                )
            )
        )
    )
songs = mksafe(
    audio_to_stereo(
        rewrite_metadata(
            [
                ("title", "$(title) (radio Salut c'est cool)"),
                ("comment", "http://www.salutcestcool.com")
                ],
            playlist.safe(
                reload=600,
                "/playlists/songs",
                mode="random"
                )
            )
        )
    )
live = audio_to_stereo(
    rewrite_metadata(
        [
            ("title", "$(title) (LIVE - Salut c'est cool)"),
            ("comment", "http://www.salutcestcool.com")
            ],
        stretch(
            ratio=interactive.float("test", 1.005),
            input.harbor(
                "rscc.live",
                id="rscc.live",
                port=5001,
                password="LIVE_PASSWORD",
                user="source",
                logfile="/tmp/harbor.log"
                )
            )
        )
    )
#live = strip_blank(live, length=10., threshold=-50.)


# MIXS
input = random(weights=[1,1], [jingles, songs])
input = add([input, switch([({0m0s}, clock)])])
#input = add([input, amplify(5., override="replay_gain", live)])
#input = fallback(track_sensitive=true, transitions=[custofade], [ input ])
#multi_live = add([live, live2])
#input = fallback(track_sensitive=false, [multi_live,input])
input = fallback(track_sensitive=false, [live, input])


# OUTPUTS
input = mksafe(input)
output.icecast(
    host="HARBOR_HOST",
    port=HARBOR_PORT,
    password="HARBOR_PASSWORD",
    %mp3(bitrate=128),
    mount="rscc.main",
    input
    )

title = '%Y-%m-%d, %H:%M:%S - $(if $(artist), "$(artist)", "Artiste inconnu") - $(if $(title),"$(title)", "Emission inconnue")'
output.file(
    %vorbis,
     reopen_on_metadata=false,
     fallible=true,
     "/playlists/emissions/" ^ title ^ ".ogg",
     live
     )
