-include config.mk

ADMIN_PASSWORD	?=	secure
HARBOR_PASSWORD	?=	secure
SOURCE_PASSWORD	?=	secure
RELAY_PASSWORD  ?=	secure

ENV ?=			HARBOR_PASSWORD=$(HARBOR_PASSWORD) \
			LIVE_PASSWORD=$(HARBOR_PASSWORD) \
			ICECAST_SOURCE_PASSWORD=$(SOURCE_PASSWORD) \
			ICECAST_ADMIN_PASSWORD=$(ADMIN_PASSWORD) \
			ICECAST_PASSWORD=$(ADMIN_PASSWORD) \
			ICECAST_RELAY_PASSWORD=$(RELAY_PASSWORD)


dev:	chmod broadcast
	$(ENV) fig up --no-deps main


re_main: broadcast
	-$(ENV) fig kill main
	-$(ENV) fig rm --force main
	-$(ENV) fig up -d --no-deps main
	-$(ENV) fig logs main


re_broadcast: icecast
	-$(ENV) fig kill broadcast
	-$(ENV) fig rm --force broadcast
	-$(ENV) fig up -d --no-deps broadcast
	-$(ENV) fig logs broadcast


re_icecast:
	-$(ENV) fig kill icecast
	-$(ENV) fig rm --force icecast
	-$(ENV) fig up -d --no-deps icecast
	-$(ENV) fig logs icecast


main:	broadcast
	$(ENV) fig up -d --no-deps --no-recreate $@

broadcast: icecast
	$(ENV) fig up -d --no-deps --no-recreate $@

icecast:
	$(ENV) fig up -d --no-deps --no-recreate $@


kill:
	fig kill


clean:	kill
	fig --force rm


chmod:
	chmod -R 777 data playlists
