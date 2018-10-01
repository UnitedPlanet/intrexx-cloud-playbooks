#!/bin/bash

# ------------------------------------------------------------------------------
# Copyright 2002-2016 United Planet GmbH, Freiburg, Germany
# All Rights Reserved.
# ------------------------------------------------------------------------------

export LC_CTYPE=en_US.UTF-8

# determine the installation directory and use it as the working directory
cd "${0/%supervisor.sh/}"
source ./uposarch
cd ../..

export INTREXX_HOME=$(pwd)

# collect used paths
CLASSPATH=$INTREXX_HOME/lib/update

CLASSPATH=$CLASSPATH$(s="$INTREXX_HOME/lib"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")
CLASSPATH=$CLASSPATH$(s="$INTREXX_HOME/lib/distributed"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")
CLASSPATH=$CLASSPATH$(s="$INTREXX_HOME/lib/custom"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")

[ -d "$INTREXX_HOME/derby/lib" ] && CLASSPATH=$CLASSPATH$(s="$INTREXX_HOME/derby/lib"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")

#[ -d "/usr/share/java" ] && CLASSPATH=$CLASSPATH$(s="/usr/share/java"; find "$s" -maxdepth 1 -name '*.jar' -printf ":$s/%f")

#set start environment
JRE_HOME="$INTREXX_HOME"/jre/linux/$OS_ARCH

# now start the java vm
	exec "$JRE_HOME/bin/java" -Xbootclasspath/p:"$INTREXX_HOME"/lib/xsltc-hndl-fix.jar \
						 -XX:+UseParNewGC \
						 -Xms32m \
						 -Xmx128m \
						 -Djava.security.auth.login.config=file:cfg/LucyAuth.cfg \
						 -Dlog4j.configurationFile=cfg/log4j2_supervisor.xml \
						 -XX:+HeapDumpOnOutOfMemoryError \
						 -Djava.library.path="$INTREXX_HOME"/bin/linux/$OS_ARCH \
						 -classpath "$CLASSPATH" \
						 de.uplanet.lucy.supervisor.SupervisorService




