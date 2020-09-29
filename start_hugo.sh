#!/bin/bash
docker run -it --rm -v $(pwd):/opt/app/src -w /opt/app/src -p 8081:8080 acend/hugo:0.70.0 hugo server -p 8080 --bind 0.0.0.0