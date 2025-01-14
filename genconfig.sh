#! /bin/sh
# $Id$
# MiniDLNA project
# http://sourceforge.net/projects/minidlna/
#
# MiniDLNA media server
# Copyright (C) 2008-2009  Justin Maggard
#
# This file is part of MiniDLNA.
#
# MiniDLNA is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# MiniDLNA is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MiniDLNA. If not, see <http://www.gnu.org/licenses/>.

RM="rm -f"
CONFIGFILE="config.h"
CONFIGMACRO="__CONFIG_H__"

# Database path
DB_PATH="/tmp/minidlna"
# Log path
LOG_PATH="${DB_PATH}"

# detecting the OS name and version
OS_NAME=`uname -s`
OS_VERSION=`uname -r`
TIVO="/*#define TIVO_SUPPORT*/"
NETGEAR="/*#define NETGEAR*/"
READYNAS="/*#define READYNAS*/"
PNPX="#define PNPX 0"

${RM} ${CONFIGFILE}

# Detect if there are missing headers
# NOTE: This check only works with a normal distro
[ ! -e "/usr/include/sqlite3.h" ] && MISSING="libsqlite3 $MISSING"
[ ! -e "/usr/include/jpeglib.h" ] && MISSING="libjpeg $MISSING"
[ ! -e "/usr/include/libexif/exif-loader.h" ] && MISSING="libexif $MISSING"
[ ! -e "/usr/include/id3tag.h" ] && MISSING="libid3tag $MISSING"
[ ! -e "/usr/include/ogg/ogg.h" ] && MISSING="libogg $MISSING"
[ ! -e "/usr/include/vorbis/codec.h" ] && MISSING="libvorbis $MISSING"
[ ! -e "/usr/include/FLAC/metadata.h" ] && MISSING="libflac $MISSING"
[ ! -e "/usr/include/ffmpeg/avutil.h" -a \
  ! -e "/usr/include/libavutil/avutil.h" -a \
  ! -e "/usr/include/ffmpeg/libavutil/avutil.h" ] && MISSING="libavutil $MISSING"
[ ! -e "/usr/include/ffmpeg/avformat.h" -a \
  ! -e "/usr/include/libavformat/avformat.h" -a \
  ! -e "/usr/include/ffmpeg/libavformat/avformat.h" ] && MISSING="libavformat $MISSING"
[ ! -e "/usr/include/ffmpeg/avcodec.h" -a \
  ! -e "/usr/include/libavcodec/avcodec.h" -a \
  ! -e "/usr/include/ffmpeg/libavcodec/avcodec.h" ] && MISSING="libavcodec $MISSING"
if [ -n "$MISSING" ]; then
	echo -e "\nERROR!  Cannot continue."
	echo -e "The following required libraries are either missing, or are missing development headers:\n"
	echo -e "$MISSING\n"
	exit 1
fi

echo "/* MiniDLNA Project" >> ${CONFIGFILE}
echo " * http://sourceforge.net/projects/minidlna/" >> ${CONFIGFILE}
echo " * (c) 2008-2009 Justin Maggard" >> ${CONFIGFILE}
echo " * generated by $0 on `date` */" >> ${CONFIGFILE}
echo "#ifndef $CONFIGMACRO" >> ${CONFIGFILE}
echo "#define $CONFIGMACRO" >> ${CONFIGFILE}
echo "" >> ${CONFIGFILE}

# OS Specific stuff
case $OS_NAME in
	OpenBSD)
		MAJORVER=`echo $OS_VERSION | cut -d. -f1`
		MINORVER=`echo $OS_VERSION | cut -d. -f2`
		#echo "OpenBSD majorversion=$MAJORVER minorversion=$MINORVER"
		# rtableid was introduced in OpenBSD 4.0
		if [ $MAJORVER -ge 4 ]; then
			echo "#define PFRULE_HAS_RTABLEID" >> ${CONFIGFILE}
		fi
		# from the 3.8 version, packets and bytes counters are double : in/out
		if [ \( $MAJORVER -ge 4 \) -o \( $MAJORVER -eq 3 -a $MINORVER -ge 8 \) ]; then
			echo "#define PFRULE_INOUT_COUNTS" >> ${CONFIGFILE}
		fi
		OS_URL=http://www.openbsd.org/
		;;
	FreeBSD)
		VER=`grep '#define __FreeBSD_version' /usr/include/sys/param.h | awk '{print $3}'`
		if [ $VER -ge 700049 ]; then
			echo "#define PFRULE_INOUT_COUNTS" >> ${CONFIGFILE}
		fi
		OS_URL=http://www.freebsd.org/
		;;
	pfSense)
		# we need to detect if PFRULE_INOUT_COUNTS macro is needed
		OS_URL=http://www.pfsense.com/
		;;
	NetBSD)
		OS_URL=http://www.netbsd.org/
		;;
	SunOS)
		echo "#define USE_IPF 1" >> ${CONFIGFILE}
		echo "#define LOG_PERROR 0" >> ${CONFIGFILE}
		echo "#define SOLARIS_KSTATS 1" >> ${CONFIGFILE}
		echo "typedef uint64_t u_int64_t;" >> ${CONFIGFILE}
		echo "typedef uint32_t u_int32_t;" >> ${CONFIGFILE}
		echo "typedef uint16_t u_int16_t;" >> ${CONFIGFILE}
		echo "typedef uint8_t u_int8_t;" >> ${CONFIGFILE}
		OS_URL=http://www.sun.com/solaris/
		;;
	Linux)
		OS_URL=http://www.kernel.org/
		KERNVERA=`echo $OS_VERSION | awk -F. '{print $1}'`
		KERNVERB=`echo $OS_VERSION | awk -F. '{print $2}'`
		KERNVERC=`echo $OS_VERSION | awk -F. '{print $3}'`
		KERNVERD=`echo $OS_VERSION | awk -F. '{print $4}'`
		#echo "$KERNVERA.$KERNVERB.$KERNVERC.$KERNVERD"
		# NETGEAR ReadyNAS special case
		if [ -f /etc/raidiator_version ]; then
			OS_NAME=$(awk -F'!!|=' '{ print $1 }' /etc/raidiator_version)
			OS_VERSION=$(awk -F'!!|[=,.]' '{ print $3"."$4 }' /etc/raidiator_version)
			OS_URL="http://www.readynas.com/"
			LOG_PATH="/var/log"
			DB_PATH="/var/cache/minidlna"
			TIVO="#define TIVO_SUPPORT"
			NETGEAR="#define NETGEAR"
			READYNAS="#define READYNAS"
			PNPX="#define PNPX 5"
		# Debian GNU/Linux special case
		elif [ -f /etc/debian_version ]; then
			OS_NAME=Debian
			OS_VERSION=`cat /etc/debian_version`
			OS_URL=http://www.debian.org/
			LOG_PATH="/var/log"
			# use lsb_release (Linux Standard Base) when available
			LSB_RELEASE=`which lsb_release 2>/dev/null`
			if [ 0 -eq $? ]; then
				OS_NAME=`${LSB_RELEASE} -i -s`
				OS_VERSION=`${LSB_RELEASE} -r -s`
			fi
		else
			# use lsb_release (Linux Standard Base) when available
			LSB_RELEASE=`which lsb_release 2>/dev/null`
			if [ 0 -eq $? ]; then
				OS_NAME=`${LSB_RELEASE} -i -s`
				OS_VERSION=`${LSB_RELEASE} -r -s`
			fi
		fi
		;;
	*)
		echo "Unknown OS : $OS_NAME"
		exit 1
		;;
esac

echo "#define OS_NAME			\"$OS_NAME\"" >> ${CONFIGFILE}
echo "#define OS_VERSION		\"$OS_NAME/$OS_VERSION\"" >> ${CONFIGFILE}
echo "#define OS_URL			\"${OS_URL}\"" >> ${CONFIGFILE}
echo "" >> ${CONFIGFILE}

echo "/* full path of the file database */" >> ${CONFIGFILE}
echo "#define DEFAULT_DB_PATH		\"${DB_PATH}\"" >> ${CONFIGFILE}
echo "" >> ${CONFIGFILE}

echo "/* full path of the log directory */" >> ${CONFIGFILE}
echo "#define DEFAULT_LOG_PATH	\"${LOG_PATH}\"" >> ${CONFIGFILE}
echo "" >> ${CONFIGFILE}

echo "/* Comment the following line to use home made daemonize() func instead" >> ${CONFIGFILE}
echo " * of BSD daemon() */" >> ${CONFIGFILE}
echo "#define USE_DAEMON" >> ${CONFIGFILE}
echo "" >> ${CONFIGFILE}

echo "/* Enable if the system inotify.h exists.  Otherwise our own inotify.h will be used. */" >> ${CONFIGFILE}
if [ -f /usr/include/sys/inotify.h ]; then
echo "#define HAVE_INOTIFY_H" >> ${CONFIGFILE}
else
echo "/*#define HAVE_INOTIFY_H*/" >> ${CONFIGFILE}
fi
echo "" >> ${CONFIGFILE}

echo "/* Enable if the system iconv.h exists.  ID3 tag reading in various character sets will not work properly otherwise. */" >> ${CONFIGFILE}
if [ -f /usr/include/iconv.h ]; then
echo "#define HAVE_ICONV_H" >> ${CONFIGFILE}
else
echo -e "\nWARNING!!  Iconv support not found.  ID3 tag reading may not work."
echo "/*#define HAVE_ICONV_H*/" >> ${CONFIGFILE}
fi
echo "" >> ${CONFIGFILE}

echo "/* Enable if the system libintl.h exists for NLS support. */" >> ${CONFIGFILE}
if [ -f /usr/include/libintl.h ]; then
echo "#define ENABLE_NLS" >> ${CONFIGFILE}
else
echo "/*#define ENABLE_NLS*/" >> ${CONFIGFILE}
fi
echo "" >> ${CONFIGFILE}

echo "/* Enable NETGEAR-specific tweaks. */" >> ${CONFIGFILE}
echo "${NETGEAR}" >> ${CONFIGFILE}
echo "/* Enable ReadyNAS-specific tweaks. */" >> ${CONFIGFILE}
echo "${READYNAS}" >> ${CONFIGFILE}
echo "/* Compile in TiVo support. */" >> ${CONFIGFILE}
echo "${TIVO}" >> ${CONFIGFILE}
echo "/* Enable PnPX support. */" >> ${CONFIGFILE}
echo "${PNPX}" >> ${CONFIGFILE}
echo "" >> ${CONFIGFILE}

echo "#endif" >> ${CONFIGFILE}

exit 0
