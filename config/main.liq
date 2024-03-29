#!/usr/bin/env liquidsoap


%include "utils.liq"


# CONFIGS
set("log.file", true)
set("log.stdout", true)
set("log.level", 3)
set("server.telnet", true)
set("server.telnet.port", 5000)
set("server.telnet.bind_addr", "0.0.0.0")
set("log.file.path", "/tmp/broadcast.log")
set("audio.converter.samplerate.libsamplerate.quality","best")
set("buffering.path","/tmp")
set("decoding.buffer_length",10.)


# INPUTS
clock = mksafe(
    audio_to_stereo(
        playlist.safe(
            reload=3600,
            "/playlists/singles/",
            mode="random",
            reload_mode="rounds"
        )
    )
)

jingles = mksafe(
    rewrite_metadata(
        [
            ("artist", "Salut c'est cool"),
            ("title","Jingle (radio Salut c'est cool)"),
            ("comment","http://www.salutcestcool.com/")
            ],
        audio_to_stereo(
            playlist.safe(
                reload=1800,
                "/playlists/jingles",
                mode="random",reload_mode="rounds"
                )
            )
        )
    )
#songs_reggae = mksafe(
#    audio_to_stereo(
#        rewrite_metadata(
#            [
#                ("title", "$(title) (reggae - radio Salut c'est cool)"),
#                ("comment", "http://www.salutcestcool.com")
#                ],
#            playlist.safe(
#                reload=600,
#                "/playlists/songs/reggae",
#                mode="randomize",reload_mode="rounds"
#                )
#            )
#        )
#    )
#songs_trance = mksafe(
#    audio_to_stereo(
#        rewrite_metadata(
#            [
#                ("title", "$(title) (reggae - radio Salut c'est cool)"),
#                ("comment", "http://www.salutcestcool.com")
#                ],
#            playlist.safe(
#                reload=600,
#                "/playlists/songs/reggae",
#                mode="randomize",reload_mode="rounds"
#                )
#            )
#        )
#    )
#songs_soiree = mksafe(
#    audio_to_stereo(
#        rewrite_metadata(
#            [
#                ("title", "$(title) (soiree - radio Salut c'est cool)"),
#                ("comment", "http://www.salutcestcool.com")
#                ],
#            playlist.safe(
#                reload=600,
#                "/playlists/songs/soiree",
#                mode="randomize",reload_mode="rounds"
#                )
#            )
#        )
#    )
songs_nuit = mksafe(
    audio_to_stereo(
        rewrite_metadata(
            [
                ("title", "$(title) (nuit - radio Salut c'est cool)"),
                ("comment", "http://www.salutcestcool.com")
                ],
            playlist.safe(
                reload=600,
                "/playlists/songs/nuit",
                mode="random",reload_mode="rounds"
                )
            )
        )
    )
#songs_matin = mksafe(
#    audio_to_stereo(
#        rewrite_metadata(
#            [
#                ("title", "$(title) (matin - radio Salut c'est cool)"),
#                ("comment", "http://www.salutcestcool.com")
#                ],
#            playlist.safe(
#                reload=600,
#                "/playlists/songs/matin",
#                mode="randomize",reload_mode="rounds"
#                )
#            )
#        )
#    )
songs_journee = mksafe(
    audio_to_stereo(
        rewrite_metadata(
            [
                ("title", "$(title) (journee - radio Salut c'est cool)"),
                ("comment", "http://www.salutcestcool.com")
                ],
            playlist.safe(
                reload=600,
                "/playlists/songs/journee",
                mode="random",reload_mode="rounds"
                )
            )
        )
    )
#songs_pluie = mksafe(
#    audio_to_stereo(
#        rewrite_metadata(
#            [
#                ("title", "$(title) (pluie - radio Salut c'est cool)"),
#                ("comment", "http://www.salutcestcool.com")
#                ],
#            playlist.safe(
#                reload=600,
#                "/playlists/songs/pluie",
#                mode="randomize",reload_mode="rounds"
#                )
#            )
#        )
#    )
live_scc = audio_to_stereo(
    rewrite_metadata(
        [
            ("title", "LIVE"),
            ("comment", "http://www.salutcestcool.com")
            ],
        stretch(
            ratio=interactive.float("test", 1.00005),
            input.harbor(
                "rscc.live",
                id="rscc.live",
                port=5002,
                password=my_getenv("LIVE_PASSWORD"),
                user="source",
                logfile="/tmp/harbor.log"
                )
            )
        )
    )
live_guest = audio_to_stereo(
    rewrite_metadata(
        [
            ("title", "LIVE"),
            ("comment", "http://www.salutcestcool.com")
            ],
        stretch(
            ratio=interactive.float("test2", 1.00005),
            input.harbor(
                "rscc.live",
                id="rscc.live",
                port=5001,
                password=my_getenv("LIVE_PASSWORD"),
                user="source",
                logfile="/tmp/harbor.log"
                )
            )
        )
    )
#live = strip_blank(live, length=10., threshold=-50.)


# MIXS
calendar_mix = switch(track_sensitive=true, [
#        ({ 10h-11h and 1w }, songs_pluie),

#        ({ 18h-23h and 4w }, songs_soiree ),
#        ({ 18h-23h and 5w }, songs_soiree ),
#        ({ 18h-23h and 6w }, songs_soiree ),

        ({ 23h-23h59m59s and 4w }, songs_nuit ),
        ({ 0h-6h and 5w }, songs_nuit ),
        ({ 23h-23h59m59s and 5w }, songs_nuit ),
        ({ 0h-6h and 6w }, songs_nuit ),
        ({ 23h-23h59m59s and 6w }, songs_nuit ),
        ({ 0h-6h and 7w }, songs_nuit ),

#        ({ 4h-6h }, songs_trance ),

#        ({ 6h-8h }, songs_matin ),

#        ({ 16h20-17h }, songs_reggae ),

        ({ true }, songs_journee)
])

#mix = random(weights=[1,1], [jingles, songs])
#mix = add([mix, amplify(5., override="replay_gain", live)])
#mix = fallback(track_sensitive=true, transitions=[custofade], [ mix ])
#mix = fallback(track_sensitive=false, [multi_live,mix])

def feedback(metadata)
   process.run("echo "^ string.quote(metadata["artist"] ^" - "^ metadata["title"]) ^" > /data/latest.txt")
   process.run("echo "^ string.quote(metadata["artist"] ^" - "^ metadata["title"]) ^" >> /data/history.txt")
end

# mix salut
# TODO: mix_salut = fallback(track_sensitive=true, calendar_mix, request.queue(id="request"))
#calendar_mix.on_metadata(calendar_mix, feedback)
mix_salut = fade(jingles, calendar_mix)
mix_salut = add([mix_salut, switch([({0m0s}, clock)])])
#mix_salut = store_metadata(size=20,id="history",mix_salut)
mix_salut.on_metadata(feedback)

# mix salut with live
mix_salut_with_live = fallback(track_sensitive=false, [live_scc, live_guest, mix_salut])

# mix journee
#mix_journee = songs_journee
#mix_journee = fade(jingles, songs_journee)
#mix_journee = add([mix_journee, switch([({0m0s}, clock)])])
#mix_journee = store_metadata(size=20,id="history_journee",mix_journee)
#mix_journee = on_metadata(feedback, mix_journee)

# mix nuit
#mix_nuit = songs_nuit
#mix_nuit = fade(jingles, songs_nuit)
#mix_nuit = add([mix_nuit, switch([({0m0s}, clock)])])
#mix_nuit = store_metadata(size=20,id="history_nuit",mix_nuit)
#mix_nuit = on_metadata(feedback, mix_nuit)

# OUTPUTS
output.icecast(
    password=my_getenv("HARBOR_PASSWORD"),
    host=my_getenv("BROADCAST_PORT_5001_TCP_ADDR"),
    port=int_of_string(my_getenv("BROADCAST_PORT_5001_TCP_PORT")),
    %wav,
    mount="rscc.main",
    mksafe(mix_salut_with_live)
    )
    
output.icecast(
    password=my_getenv("HARBOR_PASSWORD"),
    host=my_getenv("BROADCAST_PORT_5003_TCP_ADDR"),
    port=int_of_string(my_getenv("BROADCAST_PORT_5003_TCP_PORT")),
    %wav,
    mount="rscc.background",
    mksafe(mix_salut)
    )


#output.icecast(
#    password=my_getenv("HARBOR_PASSWORD"),
#    host=my_getenv("BROADCAST_PORT_5005_TCP_ADDR"),
#    port=int_of_string(my_getenv("BROADCAST_PORT_5005_TCP_PORT")),
#    %wav,
#    mount="rscc.journee",
#    mksafe(mix_journee)
#    )

#output.icecast(
#    password=my_getenv("HARBOR_PASSWORD"),
#    host=my_getenv("BROADCAST_PORT_5007_TCP_ADDR"),
#    port=int_of_string(my_getenv("BROADCAST_PORT_5007_TCP_PORT")),
#    %wav,
#    mount="rscc.nuit",
#    mksafe(mix_nuit)
#    )

title = '%Y/%m/%d, %H:%M:%S - $(if $(artist), "$(artist)", "") - $(if $(title),"$(title)", "")'
output.file(
    %vorbis,
     reopen_on_metadata=false,
     fallible=true,
     "/playlists/emissions/scc/" ^ title ^ ".ogg",
     live_scc
     )
output.file(
    %vorbis,
     reopen_on_metadata=false,
     fallible=true,
     "/playlists/emissions/guest/" ^ title ^ ".ogg",
     live_guest
     )
