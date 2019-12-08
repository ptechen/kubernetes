#!/bin/bash
yum install supervisor -y
systemctl start supervisord
systemctl enable supervisord
supervisorctl update
