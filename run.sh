#!/bin/bash
echo "启动"
bundle exec puma -e production -p 9292
echo "已关闭"