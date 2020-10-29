FROM alpine:3.12
MAINTAINER dynax60 <dynax60@gmail.com>

ARG KANNEL_CONF="/etc/kannel"
ARG KANNEL_REVISION="r5302"
ARG KANNEL_REPOSITORY="https://svn.kannel.org/gateway/trunk"

ENV KANNEL_CONF="${KANNEL_CONF:-/etc/kannel}"

WORKDIR /
COPY *.patch /
COPY conf/* ${KANNEL_CONF}/

RUN set -ex \
    && apk update \
    && apk --update --no-cache add bash hiredis libldap libpcre32 libpq libsasl libxml2 \
    	mariadb-connector-c pcre sqlite-libs \
	&& apk --update --no-cache add --virtual .build-deps autoconf automake \
		build-base byacc flex gettext gettext-dev gettext-libs hiredis-dev \
		libtool libxml2-dev mariadb-dev openssl-dev pcre-dev postgresql-dev sqlite-dev subversion \
	&& echo "#include <unistd.h>" > /usr/include/sys/unistd.h \
	&& echo "#include <poll.h>" > /usr/include/sys/poll.h \
	&& echo "#include <termios.h>" > /usr/include/sys/termios.h \
	&& svn --non-interactive --trust-server-cert co -r${KANNEL_REVISION} ${KANNEL_REPOSITORY} \
	&& cd /trunk \
	&& (for i in /*.patch; do patch -p0 < $i; done || true) \
	&& ./bootstrap.sh \
	&& ./configure --prefix=/usr --sysconfdir=${KANNEL_CONF} --enable-debug \
		--enable-assertions --with-defaults=speed --disable-localtime \
		--enable-start-stop-daemon --disable-wap --with-redis \
		--with-redis-dir=/usr/include/hiredis --enable-ssl --enable-pcre --with-mysql \
		--with-sqlite3 --with-pgsql \
	&& make \
	&& make install \
	&& cd addons/opensmppbox \
	&& ./bootstrap \
	&& ./configure --prefix=/usr --with-kannel-dir=/usr && make && make install \
	&& cd ../sqlbox \
	&& ./bootstrap \
	&&./configure --prefix=/usr --with-kannel-dir=/usr && make && make install \
	&& apk del .build-deps \
	&& rm -rf /trunk /*.patch \
    && mkdir -p /var/log/kannel /var/spool/kannel \
	&& /usr/sbin/bearerbox --version
