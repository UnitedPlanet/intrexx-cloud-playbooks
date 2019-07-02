#!/bin/bash

# ------------------------------------------------------------------------------
# Copyright 2002-2016 United Planet GmbH, Freiburg, Germany
# All Rights Reserved.
# ------------------------------------------------------------------------------

export LC_CTYPE=en_US.UTF-8

if [ -z "$1" ]
	then
	echo `gettext "Usage:"$0" <Portal-Directory>"`
	exit 1
fi

if [ ! -d "$1" ]
	then
	echo " "$1" is not a directory"
	exit 1
fi

# determine the portal directory
pushd "$1" &> /dev/null
PORTAL_DIR=$(pwd)
popd &> /dev/null

# determine the installation directory and use it as the working directory
cd "${0/%portal.sh/}"
source ./uposarch
cd ../..

export INTREXX_HOME=$(pwd)

# collect used paths
CLASSPATH=$INTREXX_HOME/lib/update

CLASSPATH=$CLASSPATH$(s="$INTREXX_HOME/lib"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")
CLASSPATH=$CLASSPATH$(s="$INTREXX_HOME/lib/distributed"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")
CLASSPATH=$CLASSPATH$(s="$INTREXX_HOME/lib/custom"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")

[ -d "$INTREXX_HOME/derby/lib" ] && CLASSPATH=$CLASSPATH$(s="$INTREXX_HOME/derby/lib"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")

#set start environment
cd "$PORTAL_DIR"
JRE_HOME="$INTREXX_HOME"/java/packaged/linux/$OS_ARCH

# now start the java vm
exec "$JRE_HOME/bin/java" \
		-XX:NewSize=32m \
		-server \
		-Xms1024m \
		-Xmx2084m \
		-Dfile.encoding=UTF-8 \
		-Dgroovy.source.encoding=UTF-8 \
		-Djava.library.path="$INTREXX_HOME"/bin/linux/$OS_ARCH \
		-classpath "$CLASSPATH" \
		-Djava.security.auth.login.config=file:internal/cfg/LucyAuth.cfg \
		-Dlog4j.configurationFile=internal/cfg/log4j2.xml \
		-XX:+HeapDumpOnOutOfMemoryError \
		-Dde.uplanet.jdbc.dump=true \
		-Djavax.net.ssl.trustStore=internal/cfg/cacerts \
		-Djava.security.egd=file:/dev/urandom \
		-Djava.io.tmpdir=internal/tmp \
		-Dde.uplanet.lucy.logPath=/var/log/intrexx \
		-Djava.net.preferIPv4Stack=true \
		-DIGNITE_UPDATE_NOTIFIER=false \
		--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED \
		--add-exports=java.base/sun.nio.cs=ALL-UNNAMED \
		--add-exports=java.base/sun.nio.ch=ALL-UNNAMED \
		--add-exports=java.management/com.sun.jmx.mbeanserver=ALL-UNNAMED \
		--add-exports=jdk.internal.jvmstat/sun.jvmstat.monitor=ALL-UNNAMED \
		--add-exports=java.base/sun.reflect.generics.reflectiveObjects=ALL-UNNAMED \
		--illegal-access=permit \
		de.uplanet.lucy.server.portalserver.PortalService \
		--pid-file /var/run/intrexx/portal.pid
