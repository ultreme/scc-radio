ADMIN_PASSWORD	?=	secure
HARBOR_PASSWORD	?=	secure
SOURCE_PASSWORD	?=	secure

ENV ?=			HARBOR_PASSWORD=internal \
			LIVE_PASSWORD=$(HARBOR_PASSWORD) \
			SOURCE_PASSWORD=$(SOURCE_PASSWORD) \
			ADMIN_PASSWORD=$(ADMIN_PASSWORD) \
			PASSWORD=internal \
			RELAY_PASSWORD=internal


dev:	chmod broadcast
	$(ENV) fig up --no-deps main


broadcast:
	$(ENV) fig up -d --no-recreate broadcast


kill:
	fig $@


chmod:
	chmod -R 777 data playlists
