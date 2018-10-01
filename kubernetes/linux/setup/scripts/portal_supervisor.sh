#!/bin/bash

# ------------------------------------------------------------------------------
# Copyright 2002-2016 United Planet GmbH, Freiburg, Germany
# All Rights Reserved.
# ------------------------------------------------------------------------------

/opt/intrexx/bin/linux/supervisor.sh &
exec /opt/intrexx/bin/linux/portal.sh /opt/intrexx/org/cloud
