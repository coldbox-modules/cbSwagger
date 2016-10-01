#!/bin/bash
cd $TRAVIS_BUILD_DIR/build &&\ 
box forgebox enable &&\
box forgebox login username=$FORGEBOX_USERNAME password=$FORGEBOX_PASSWORD &&\
box forgebox publish;