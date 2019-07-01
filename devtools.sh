#!/bin/bash

yum upgrade -y
yum install -y git
amazon-linux-extras install ansible2

git clone https://github.com/sysx23/graduate_work /usr/local/project
