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
#mix = random(weights=[1,1], [jingles, songs])
mix = fade(jingles,songs)
mix = add([mix, switch([({0m0s}, clock)])])
#mix = add([mix, amplify(5., override="replay_gain", live)])
#mix = fallback(track_sensitive=true, transitions=[custofade], [ mix ])
#mix = fallback(track_sensitive=false, [multi_live,mix])
mix = fallback(track_sensitive=false, [live, mix])
mix = store_metadata(size=20,id="history",mix)
def feedback(metadata)
   system("echo "^ quote(metadata["artist"] ^" - "^ metadata["title"]) ^" > /data/latest.txt")
   system("echo "^ quote(metadata["artist"] ^" - "^ metadata["title"]) ^" >> /data/history.txt")
end
mix = on_metadata(feedback, mix)


# OUTPUTS
mix = mksafe(mix)
output.icecast(
    host="HARBOR_HOST",
    port=HARBOR_PORT,
    password="HARBOR_PASSWORD",
    %mp3(bitrate=128),
    mount="rscc.main",
    mix
    )

title = '%Y-%m-%d, %H:%M:%S - $(if $(artist), "$(artist)", "Artiste inconnu") - $(if $(title),"$(title)", "Emission inconnue")'
output.file(
    %vorbis,
     reopen_on_metadata=false,
     fallible=true,
     "/playlists/emissions/" ^ title ^ ".ogg",
     live
     )
