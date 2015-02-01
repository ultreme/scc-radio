#!/usr/bin/env liquidsoap


%include "utils.liq"


# CONFIGS
set("log.file", true)
set("log.stdout", true)
set("log.level", 4)
set("server.telnet", true)
set("server.telnet.port", 5000)
set("log.file.path", "/tmp/broadcast.log")
set("audio.converter.samplerate.libsamplerate.quality","best")
set("buffering.path","/tmp")
set("decoding.buffer_length",10.)
icecast_password=my_getenv("ICECAST_PASSWORD")


# FUNCTIONS
scc_out = output.icecast(description="La radio de les salut c'set cool", genre="Documentaires", url="http://www.salutcestcool.com/")
output_balrog.icecast = scc_out(host="212.83.158.125", port=8000, password=icecast_password)
output_hobbit.icecast = scc_out(host="212.129.20.90", port=8000, password=icecast_password)
def outputs(encoder, ~mount, input)
    output_balrog.icecast(encoder, mount=mount, input)
    output_hobbit.icecast(encoder, mount=mount, input)
end


# MIXS
default = mksafe(
    rewrite_metadata(
        [
            ("artist", "Salut c'est cool"),
            ("title", "Maintenance en cours"),
            ("comment", "http://www.salutcestcool.com/")
            ],
        audio_to_stereo(
            playlist.safe(
                reload=60,
                "/playlists/failures/",
                mode="random"
                )
            )
        )
    )

harbor_input = input.harbor("rscc.main", port=5001, password=my_getenv("HARBOR_PASSWORD"))
input = mksafe(fallback(track_sensitive=false, [ harbor_input, default ]))


# NORMALIZE
input = audio_process(input)


# OUTPUTS
outputs(%mp3(bitrate=64), mount="/salut-radio-64.mp3", input)
outputs(%mp3(bitrate=128), mount="/salut-radio-128.mp3", input)
outputs(%mp3(bitrate=256), mount="/salut-radio-256.mp3", input)
outputs(%vorbis, mount="/salut-radio.ogg", input)
