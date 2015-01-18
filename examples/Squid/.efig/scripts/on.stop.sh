#!/bin/bash

# This script will run on stop containers

echo "Remove iptable rule"
iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to 3129 -w
