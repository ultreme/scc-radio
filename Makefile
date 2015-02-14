-include config.mk

ADMIN_PASSWORD	?=	secure
HARBOR_PASSWORD	?=	secure
SOURCE_PASSWORD	?=	secure
RELAY_PASSWORD  ?=	secure
MYSQL_PASSWORD  ?=	secure
PIWIK_PASSWORD  ?=	secure
HOSTNAME	?=	$(shell hostname -f)
1AND1_FTP	?=	ftp://user:pass@host
ADMIN_IFRAME_URL ?=	http://$(shell ifconfig eth0 | grep inet\  | cut -d: -f2 | cut -d\  -f1):12348/admin.php?auth=$(ADMIN_PASSWORD)

ENV ?=			HARBOR_PASSWORD=$(HARBOR_PASSWORD) \
			LIVE_PASSWORD=$(HARBOR_PASSWORD) \
			ICECAST_SOURCE_PASSWORD=$(SOURCE_PASSWORD) \
			ICECAST_ADMIN_PASSWORD=$(ADMIN_PASSWORD) \
			ICECAST_PASSWORD=$(ADMIN_PASSWORD) \
			ICECAST_RELAY_PASSWORD=$(RELAY_PASSWORD) \
			MYSQL_ROOT_PASSWORD=$(MYSQL_PASSWORD) \
			PIWIK_MYSQL_PASSWORD=$(MYSQL_PASSWORD) \
			PIWIK_PASSWORD=$(PIWIK_PASSWORD) \
			HOSTNAME=$(HOSTNAME) \
			SITE_URL=https://$(HOSTNAME):12347 \
			ADMIN_IFRAME_URL=$(ADMIN_IFRAME_URL)

.PHONY: dev re_main re_broadcast re_icecast main broadcast icecast admin piwik piwikmysql dashing ftpd

dev:	chmod broadcast
	$(ENV) fig up --no-deps main


re_main: broadcast
	-$(ENV) fig kill main
	-$(ENV) fig rm --force main
	-$(ENV) fig up -d --no-deps main
	-$(ENV) fig logs main
	$(MAKE) admin


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


piwik:	piwikmysql
	-$(ENV) fig kill $@
	-$(ENV) fig rm --force $@
	$(ENV) fig up -d --no-deps $@
	$(ENV) fig logs $@


admin:
	-$(ENV) fig kill $@
	-$(ENV) fig rm --force $@
	$(ENV) fig up -d --no-deps $@
	#$(ENV) fig logs $@


piwikmysql:
	$(ENV) fig up -d --no-recreate $@


piwikmysql-client: piwikmysql
	docker run -it --rm --link radioscc_piwikmysql_1:mysql -e MYSQL_ROOT_PASSWORD=$(MYSQL_PASSWORD) mysql /bin/bash -c 'mysql -h$$MYSQL_PORT_3306_TCP_ADDR -p$$MYSQL_ENV_MYSQL_ROOT_PASSWORD piwik'


piwikcron:
	-$(ENV) fig kill $@
	$(ENV) fig up -d $@


kill:
	fig kill


clean:	kill
	fig --force rm


chmod:
	chmod -R 777 data playlists


sync-1and1:
	du -hs backup-1and1
	find backup-1and1 -type f | wc -l
	lftp -c "set ftp:list-options -a; open '$(1AND1_FTP)';lcd backup-1and1; mirror"
	du -hs backup-1and1
	find backup-1and1 -type f | wc -l


dashing:
	-$(ENV) fig kill $@
	-$(ENV) fig rm --force $@
	$(ENV) fig up -d --no-deps $@
	$(ENV) fig logs $@


ftpd:
	-$(ENV) fig kill $@
	-$(ENV) fig rm --force $@
	$(ENV) fig up -d --no-deps $@
	$(ENV) fig logs $@
