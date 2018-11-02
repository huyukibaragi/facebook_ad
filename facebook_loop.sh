#!/bin/sh

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

cd /root/facebook_ad

while :
do
  bundle exec ruby ./facebook_ad_crawler.rb
  sleep 1h
done
