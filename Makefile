ADMIN_PASSWORD	?=	secure
HARBOR_PASSWORD ?=	secure
SOURCE_PASSWORD ?=	secure

ENV ?=			HARBOR_PASSWORD=internal \
			LIVE_PASSWORD=$(HARBOR_PASSWORD) \
			SOURCE_PASSWORD=$(SOURCE_PASSWORD) \
			ADMIN_PASSWORD=$(ADMIN_PASSWORD) \
			PASSWORD=internal \
			RELAY_PASSWORD=internal


dev:	broadcast
	$(ENV) fig up -d --no-deps main
	fig logs main


broadcast:
	$(ENV) fig up -d --no-recreate broadcast


kill:
	fig $@
