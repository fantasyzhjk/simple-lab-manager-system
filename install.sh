#!/bin/bash
echo "安装环境"
sudo apt update -y
sudo apt upgrade -y
sudo apt install make libsqlite3-dev gcc ruby2.7 ruby2.7-dev libruby2.7 ruby2.7-doc openssl -y
echo "安装包"
bundle package
echo "安装完成, 你可以通过输入'bash run.sh'来启动"