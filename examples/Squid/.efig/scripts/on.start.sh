#!/bin/bash

# This script will run on start containers

echo "Create iptable rule"
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to 3129 -w
