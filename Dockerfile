FROM ubuntu:18.04

RUN apt-get -y update &&  apt-get -y upgrade
RUN  apt-get install -y vim


