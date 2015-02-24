#!/usr/bin/env liquidsoap


%include "utils.liq"


# CONFIGS
set("log.file", true)
set("log.stdout", true)
set("log.level", 5)
set("server.telnet", true)
set("server.telnet.port", 5000)
set("server.telnet.bind_addr", "0.0.0.0")
set("log.file.path", "/tmp/broadcast.log")
set("audio.converter.samplerate.libsamplerate.quality","best")
set("buffering.path","/tmp")
set("decoding.buffer_length",10.)


# FUNCTIONS
scc_out = output.icecast(description="La radio de les salut c'est cool", genre="Documentaires", url="http://www.salutcestcool.com/")
output_docker_env.icecast = scc_out(
    host=my_getenv("ICECAST_PORT_8000_TCP_ADDR"),
    port=int_of_string(my_getenv("ICECAST_PORT_8000_TCP_PORT")),
    password=my_getenv("ICECAST_SOURCE_PASSWORD")
)
#output_balrog.icecast = scc_out(host="212.83.158.125", port=8000, password=icecast_password)
#output_hobbit.icecast = scc_out(host="212.129.20.90", port=8000, password=icecast_password)
def outputs(encoder, ~mount, input)
    #output_balrog.icecast(encoder, mount=mount, input)
    #output_hobbit.icecast(encoder, mount=mount, input)
    output_docker_env.icecast(encoder, mount=mount, input)
end



# INPUTS
clock = mksafe(audio_to_stereo(playlist.safe(reload=3600, "/playlists/singles/", mode="randomize",reload_mode="rounds")))
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
                mode="randomize",reload_mode="rounds"
                )
            )
        )
    )
songs_reggae = mksafe(
    audio_to_stereo(
        rewrite_metadata(
            [
                ("title", "$(title) (reggae - radio Salut c'est cool)"),
                ("comment", "http://www.salutcestcool.com")
                ],
            playlist.safe(
                reload=600,
                "/playlists/songs/reggae",
                mode="randomize",reload_mode="rounds"
                )
            )
        )
    )
songs_trance = mksafe(
    audio_to_stereo(
        rewrite_metadata(
            [
                ("title", "$(title) (reggae - radio Salut c'est cool)"),
                ("comment", "http://www.salutcestcool.com")
                ],
            playlist.safe(
                reload=600,
                "/playlists/songs/reggae",
                mode="randomize",reload_mode="rounds"
                )
            )
        )
    )
songs_soiree = mksafe(
    audio_to_stereo(
        rewrite_metadata(
            [
                ("title", "$(title) (soiree - radio Salut c'est cool)"),
                ("comment", "http://www.salutcestcool.com")
                ],
            playlist.safe(
                reload=600,
                "/playlists/songs/soiree",
                mode="randomize",reload_mode="rounds"
                )
            )
        )
    )
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
                mode="randomize",reload_mode="rounds"
                )
            )
        )
    )
songs_matin = mksafe(
    audio_to_stereo(
        rewrite_metadata(
            [
                ("title", "$(title) (matin - radio Salut c'est cool)"),
                ("comment", "http://www.salutcestcool.com")
                ],
            playlist.safe(
                reload=600,
                "/playlists/songs/matin",
                mode="randomize",reload_mode="rounds"
                )
            )
        )
    )
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
                mode="randomize",reload_mode="rounds"
                )
            )
        )
    )
songs_pluie = mksafe(
    audio_to_stereo(
        rewrite_metadata(
            [
                ("title", "$(title) (pluie - radio Salut c'est cool)"),
                ("comment", "http://www.salutcestcool.com")
                ],
            playlist.safe(
                reload=600,
                "/playlists/songs/pluie",
                mode="randomize",reload_mode="rounds"
                )
            )
        )
    )
live_scc = audio_to_stereo(
    rewrite_metadata(
        [
            ("title", "$(title) (LIVE de SCC - radio Salut c'est cool)"),
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
            ("title", "$(title) (LIVE de copains - radio Salut c'est cool)"),
            ("comment", "http://www.salutcestcool.com")
            ],
        stretch(
            ratio=interactive.float("test", 1.00005),
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
        ({ 10h-11h and 1w }, songs_pluie),

        ({ 18h-23h and 4w }, songs_soiree ),
        ({ 18h-23h and 5w }, songs_soiree ),
        ({ 18h-23h and 6w }, songs_soiree ),

        ({ 23h-23h59m59s and 4w }, songs_nuit ),
        ({ 0h-6h and 5w }, songs_nuit ),
        ({ 23h-23h59m59s and 5w }, songs_nuit ),
        ({ 0h-6h and 6w }, songs_nuit ),
        ({ 23h-23h59m59s and 6w }, songs_nuit ),
        ({ 0h-6h and 7w }, songs_nuit ),

        ({ 4h-6h }, songs_trance ),

        ({ 6h-8h }, songs_matin ),

        ({ 16h20-17h }, songs_reggae ),

        ({ true }, songs_journee)
])

#mix = random(weights=[1,1], [jingles, songs])
mix = fade(jingles, calendar_mix)
mix = add([mix, switch([({0m0s}, clock)])])
#mix = add([mix, amplify(5., override="replay_gain", live)])
#mix = fallback(track_sensitive=true, transitions=[custofade], [ mix ])
#mix = fallback(track_sensitive=false, [multi_live,mix])
mix = fallback(track_sensitive=false, [live_scc, live_guest, mix])
mix = store_metadata(size=20,id="history",mix)
def feedback(metadata)
   system("echo "^ quote(metadata["artist"] ^" - "^ metadata["title"]) ^" > /data/latest.txt")
   system("echo "^ quote(metadata["artist"] ^" - "^ metadata["title"]) ^" >> /data/history.txt")
end
mix = on_metadata(feedback, mix)


# OUTPUTS
mix = mksafe(mix)

outputs(%mp3(bitrate=160), mount="/salut-testing-160.mp3", mix)
outputs(%aac(bitrate=160), mount="/salut-testing-160.aac", mix)

title = '%Y-%m-%d, %H:%M:%S - $(if $(artist), "$(artist)", "Artiste inconnu") - $(if $(title),"$(title)", "Emission inconnue")'
output.file(
    %vorbis,
     reopen_on_metadata=false,
     fallible=true,
     "/playlists/emissions/testing/" ^ title ^ ".ogg",
     live_scc
     )
output.file(
    %vorbis,
     reopen_on_metadata=false,
     fallible=true,
     "/playlists/emissions/testing/" ^ title ^ ".ogg",
     live_guest
     )
