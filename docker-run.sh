#!/usr/bin/env bash

## run at the background with web service exposed at 4000
docker run -d -p 4000:4000 -p 8443:8443 erdincka/ezdemo:latest 

exit 0
