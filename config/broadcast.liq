#!/usr/bin/env liquidsoap


%include "utils.liq"


# CONFIGS
set("log.file", true)
set("log.stdout", true)
set("log.level", 2)
set("server.telnet", true)
set("server.telnet.port", 5000)
set("server.telnet.bind_addr", "0.0.0.0")
set("log.file.path", "/tmp/broadcast.log")
set("audio.converter.samplerate.libsamplerate.quality","best")
set("buffering.path","/tmp")
set("decoding.buffer_length",10.)


# FUNCTIONS
scc_out = output.icecast(
	description="La radio de les salut c'est cool",
	genre="Documentaires",
	url="http://www.salutcestcool.com/",
	host=my_getenv("ICECAST_PORT_8000_TCP_ADDR"),
    	port=int_of_string(my_getenv("ICECAST_PORT_8000_TCP_PORT")),
    	password=my_getenv("ICECAST_SOURCE_PASSWORD")
	)
#output_docker_env.icecast = scc_out(
#    host=my_getenv("ICECAST_PORT_8000_TCP_ADDR"),
#    port=int_of_string(my_getenv("ICECAST_PORT_8000_TCP_PORT")),
#    password=my_getenv("ICECAST_SOURCE_PASSWORD")
#)
#output_balrog.icecast = scc_out(host="212.83.158.125", port=8000, password=icecast_password)
#output_hobbit.icecast = scc_out(host="212.129.20.90", port=8000, password=icecast_password)
def outputs(encoder, ~mount, input)
    #output_balrog.icecast(encoder, mount=mount, input)
    #output_hobbit.icecast(encoder, mount=mount, input)
    #output_docker_env.icecast(encoder, mount=mount, input)
    scc_out(encoder, mount=mount, input)
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
input1 = mksafe(fallback(track_sensitive=false, [ harbor_input, default ]))

harbor_input2 = input.harbor("rscc.background", port=5003, password=my_getenv("HARBOR_PASSWORD"))
input2 = mksafe(fallback(track_sensitive=false, [ harbor_input2, default ]))

harbor_input3 = input.harbor("rscc.journee", port=5005, password=my_getenv("HARBOR_PASSWORD"))
input3 = mksafe(fallback(track_sensitive=false, [ harbor_input3, default ]))

harbor_input4 = input.harbor("rscc.nuit", port=5007, password=my_getenv("HARBOR_PASSWORD"))
input4 = mksafe(fallback(track_sensitive=false, [ harbor_input4, default ]))


# NORMALIZE
#input = audio_process(input)


# OUTPUTS
outputs(%mp3(bitrate=64), mount="/salut-radio-64.mp3", input1)
outputs(%mp3(bitrate=192), mount="/salut-radio-192.mp3", input1)
outputs(%fdkaac(bitrate=192), mount="/salut-radio-192.aac", input1)
outputs(%vorbis, mount="/salut-radio.ogg", input1)

outputs(%fdkaac(bitrate=192), mount="/bg-192.aac", input2)

outputs(%mp3(bitrate=192), mount="/journee-192.mp3", input3)

outputs(%mp3(bitrate=192), mount="/nuit-192.mp3", input4)


#outputs(%mp3(bitrate=128), mount="/salut-radio-128.mp3", input1)
#outputs(%mp3(bitrate=160), mount="/salut-radio-160.mp3", input1)
#outputs(%aac(bitrate=128), mount="/salut-radio-128.aac", input1)
#outputs(%aac(bitrate=160), mount="/salut-radio-160.aac", input1)
