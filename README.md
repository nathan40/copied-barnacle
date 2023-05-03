# copied-barnacle

The backup script is to be scheduled via cron or some other automated means. It is to be configured per machine so that based on the machine, it will create a hierarchy in the remote respository. Configuration is only the first couple lines for where files are to be backed up to and what volumes are to be excluded, if any.

The restore file is set up with a quasi GUI menu for how to restore. I left my servers in as examples of what to configure. The restore is meant to be a manual process run after the initial start of the docker container. It will not set up a container and settings, only restore the volume over one already present. 
