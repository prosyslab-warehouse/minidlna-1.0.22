# $Id: Makefile,v 1.31 2011/04/21 08:50:44 jmaggard Exp $
# MiniDLNA project
# http://sourceforge.net/projects/minidlna/
# (c) 2008-2009 Justin Maggard
# for use with GNU Make
# To install use :
# $ DESTDIR=/dummyinstalldir make install
# or :
# $ INSTALLPREFIX=/usr/local make install
# or :
# $ make install
#
#CFLAGS = -Wall -O -D_GNU_SOURCE -g -DDEBUG
#CFLAGS = -Wall -g -Os -D_GNU_SOURCE
CFLAGS = -Wall -g -O3 -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 \
	 -I/usr/include/ffmpeg \
	 -I/usr/include/libavutil -I/usr/include/libavcodec -I/usr/include/libavformat \
	 -I/usr/include/ffmpeg/libavutil -I/usr/include/ffmpeg/libavcodec -I/usr/include/ffmpeg/libavformat
#STATIC_LINKING: CFLAGS += -DSTATIC
#STATIC_LINKING: LDFLAGS = -static
CC = gcc
RM = rm -f
INSTALL = install

INSTALLPREFIX ?= $(DESTDIR)/usr
SBININSTALLDIR = $(INSTALLPREFIX)/sbin
ETCINSTALLDIR = $(DESTDIR)/etc

BASEOBJS = minidlna.o upnphttp.o upnpdescgen.o upnpsoap.o \
           upnpreplyparse.o minixml.o \
           getifaddr.o daemonize.o upnpglobalvars.o \
           options.o minissdp.o uuid.o upnpevents.o \
           sql.o utils.o metadata.o scanner.o inotify.o \
           tivo_utils.o tivo_beacon.o tivo_commands.o \
           tagutils/textutils.o tagutils/misc.o tagutils/tagutils.o \
           playlist.o image_utils.o albumart.o log.o

ALLOBJS = $(BASEOBJS) $(LNXOBJS)

LIBS = -lpthread -lexif -ljpeg -lsqlite3 -lavformat -lavutil -lavcodec -lid3tag -lFLAC -logg -lvorbis
#STATIC_LINKING: LIBS = -lvorbis -logg -lm -lsqlite3 -lpthread -lexif -ljpeg -lFLAC -lm -lid3tag -lz -lavformat -lavutil -lavcodec -lm

TESTUPNPDESCGENOBJS = testupnpdescgen.o upnpdescgen.o

EXECUTABLES = minidlna testupnpdescgen

.PHONY:	all clean distclean install depend

all:	$(EXECUTABLES)

clean:
	$(RM) $(ALLOBJS)
	$(RM) $(EXECUTABLES)
	$(RM) testupnpdescgen.o

distclean: clean
	$(RM) config.h

install:	minidlna
	$(INSTALL) -d $(SBININSTALLDIR)
	$(INSTALL) minidlna $(SBININSTALLDIR)
	$(INSTALL) -d $(ETCINSTALLDIR)
	$(INSTALL) --mode=0644 minidlna.conf $(ETCINSTALLDIR)

minidlna:	$(BASEOBJS) $(LNXOBJS) $(LIBS)
	@echo Linking $@
	@$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(BASEOBJS) $(LNXOBJS) $(LIBS)


testupnpdescgen:	$(TESTUPNPDESCGENOBJS)
	@echo Linking $@
	@$(CC) $(CFLAGS) -o $@ $(TESTUPNPDESCGENOBJS)

config.h:	genconfig.sh
	./genconfig.sh

depend:	config.h
	makedepend -f$(MAKEFILE_LIST) -Y \
	$(ALLOBJS:.o=.c) $(TESTUPNPDESCGENOBJS:.o=.c) 2>/dev/null

# DO NOT DELETE

minidlna.o: config.h upnpglobalvars.h minidlnatypes.h
minidlna.o: upnphttp.h upnpdescgen.h minidlnapath.h getifaddr.h upnpsoap.h
minidlna.o: options.h minissdp.h daemonize.h upnpevents.h log.h
upnphttp.o: config.h upnphttp.h upnpdescgen.h minidlnapath.h upnpsoap.h
upnphttp.o: upnpevents.h image_utils.h sql.h log.h icons.c
upnpdescgen.o: config.h upnpdescgen.h minidlnapath.h upnpglobalvars.h
upnpdescgen.o: minidlnatypes.h upnpdescstrings.h log.h
upnpsoap.o: config.h upnpglobalvars.h minidlnatypes.h log.h utils.h sql.h
upnpsoap.o: upnphttp.h upnpsoap.h upnpreplyparse.h getifaddr.h log.h
upnpreplyparse.o: upnpreplyparse.h minixml.h log.h
minixml.o: minixml.h
getifaddr.o: getifaddr.h log.h
daemonize.o: daemonize.h config.h log.h
upnpglobalvars.o: config.h upnpglobalvars.h
upnpglobalvars.o: minidlnatypes.h
options.o: options.h config.h upnpglobalvars.h
options.o: minidlnatypes.h
minissdp.o: config.h upnpdescstrings.h minidlnapath.h upnphttp.h
minissdp.o: upnpglobalvars.h minidlnatypes.h minissdp.h log.h
upnpevents.o: config.h upnpevents.h minidlnapath.h upnpglobalvars.h
upnpevents.o: minidlnatypes.h upnpdescgen.h log.h uuid.h
uuid.o: uuid.h
testupnpdescgen.o: config.h upnpdescgen.h
upnpdescgen.o: config.h upnpdescgen.h minidlnapath.h upnpglobalvars.h
upnpdescgen.o: minidlnatypes.h upnpdescstrings.h
scanner.o: upnpglobalvars.h metadata.h utils.h sql.h scanner.h log.h playlist.h
metadata.o: upnpglobalvars.h metadata.h albumart.h utils.h sql.h log.h
albumart.o: upnpglobalvars.h albumart.h utils.h image_utils.h sql.h log.h
tagutils/misc.o: tagutils/misc.h
tagutils/textutils.o: tagutils/misc.h tagutils/textutils.h log.h
tagutils/tagutils.o: tagutils/tagutils-asf.c tagutils/tagutils-flc.c tagutils/tagutils-plist.c tagutils/tagutils-misc.c
tagutils/tagutils.o: tagutils/tagutils-aac.c tagutils/tagutils-asf.h tagutils/tagutils-flc.h tagutils/tagutils-mp3.c tagutils/tagutils-wav.c
tagutils/tagutils.o: tagutils/tagutils-ogg.c tagutils/tagutils-aac.h tagutils/tagutils.h tagutils/tagutils-mp3.h tagutils/tagutils-ogg.h log.h
playlist.o: playlist.h
inotify.o: inotify.h playlist.h
image_utils.o: image_utils.h
tivo_utils.o: config.h tivo_utils.h
tivo_beacon.o: config.h tivo_beacon.h tivo_utils.h
tivo_commands.o: config.h tivo_commands.h tivo_utils.h utils.h
utils.o: utils.h
sql.o: sql.h
log.o: log.h

.SUFFIXES: .c .o

.c.o:
	@echo Compiling $*.c
	@$(CC) $(CFLAGS) -o $@ -c $< && exit 0;\
		echo "The following command failed:" 1>&2;\
		echo "$(CC) $(CFLAGS) -o $@ -c $<";\
		$(CC) $(CFLAGS) -o $@ -c $< &>/dev/null
