#!/bin/bash

grep -q "7.3.1611" /etc/redhat-release
if [[ $? -eq 0 ]]; then
    echo "操作系统检查 : Centos 7.3(1611) 检查成功!"
else
    echo "ERROR：操作系统版本错误，请重新安装Centos 7.3(1611)，否则系统无法正常部署!"
    exit 1
fi

curr_date=$(date)
if [[ $curr_date =~ "CST" ]]; then
    echo "操作系统时区 : CST 检查成功!"
else
    read -p "WARN：操作系统时区设置错误，按1重新设置，按其它键忽略，忽略会导致告警时间显示异常" sel

    if [[ $sel -eq  1 ]];then
	exit 1
    fi
fi

echo "环境检查完成,开始优化系统参数..."

grep -q "net.ipv4.tcp_syncookies" /etc/sysctl.conf
if [[ ! $? -eq 0 ]]; then
    echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf 
else
   echo "net.ipv4.tcp_syncookies 已经存在需要重新赋值......."
   sed -i "s/^net.ipv4.tcp_syncookies.*$/net.ipv4.tcp_syncookies = 1/g" /etc/sysctl.conf
fi

grep -q "net.ipv4.tcp_tw_reuse" /etc/sysctl.conf
if [[ ! $? -eq 0 ]]; then
    echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf 	
else
   echo "net.ipv4.tcp_tw_reuse 已经存在需要重新赋值......."
   sed -i "s/^net.ipv4.tcp_tw_reuse.*$/net.ipv4.tcp_tw_reuse = 1/g" /etc/sysctl.conf
fi

grep -q "net.ipv4.tcp_tw_recycle" /etc/sysctl.conf
if [[ ! $? -eq 0 ]]; then
    echo "net.ipv4.tcp_tw_recycle = 1" >> /etc/sysctl.conf 	
else
   echo "net.ipv4.tcp_tw_recycle 已经存在需要重新赋值......."
   sed -i "s/^net.ipv4.tcp_tw_recycle.*$/net.ipv4.tcp_tw_recycle = 1/g" /etc/sysctl.conf
fi

grep -q "net.ipv4.tcp_fin_timeout" /etc/sysctl.conf
if [[ ! $? -eq 0 ]]; then
    echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf 	
else
   echo "net.ipv4.tcp_fin_timeout 已经存在需要重新赋值......."
   sed -i "s/^net.ipv4.tcp_fin_timeout.*$/net.ipv4.tcp_fin_timeout = 30/g" /etc/sysctl.conf
fi

grep -q "net.ipv4.tcp_timestamps" /etc/sysctl.conf
if [[ ! $? -eq 0 ]]; then
    echo "net.ipv4.tcp_timestamps = 0" >> /etc/sysctl.conf 	
else
   echo "net.ipv4.tcp_timestamps 已经存在需要重新赋值......."
   sed -i "s/^net.ipv4.tcp_timestamps.*$/net.ipv4.tcp_timestamps = 0/g" /etc/sysctl.conf
fi

grep -q "net.ipv4.tcp_max_tw_buckets" /etc/sysctl.conf
if [[ ! $? -eq 0 ]]; then
    echo "net.ipv4.tcp_max_tw_buckets = 5000" >> /etc/sysctl.conf 	
else
   echo "net.ipv4.tcp_max_tw_buckets 已经存在需要重新赋值......."
   sed -i "s/^net.ipv4.tcp_max_tw_buckets.*$/net.ipv4.tcp_max_tw_buckets = 5000/g" /etc/sysctl.conf
fi

/sbin/sysctl -p


chmod +x ./*
./install_depends.sh


echo "开启NTP网络校时..."

yum install -y ntpdate

grep -q "ntpdate" /var/spool/cron/root
if [[ ! $? -eq 0 ]]; then
    echo "00 05 * * * /usr/sbin/ntpdate -u cn.pool.ntp.org && /usr/sbin/hwclock -w" >>/var/spool/cron/root 	
fi

echo "开启定时任务每天凌晨5点删除过期日志文件（7天）..."

grep -q "logs" /var/spool/cron/root
if [[ ! $? -eq 0 ]]; then
    echo "00 05 * * * find /data/logs -mtime +7 -name \"*.log*\" -exec rm -rf {} \;" >>/var/spool/cron/root	
fi

echo "开启定时任务每分钟检测一次tomcat存活状态，如果服务存在则自动拉起tomcat服务"
grep -q "monitorprocess" /var/spool/cron/root
if [[ ! $? -eq 0 ]]; then
    echo "*/1 * * * * /bin/sh /sensing/monitorprocess.sh;" >>/var/spool/cron/root	
fi

echo "关闭并禁用防火墙..."

systemctl stop firewalld
systemctl disable firewalld

echo 安装rar解压工具
chmod 755 rarlinux-x64-5.3.0.tar.gz
tar -zxvf rarlinux-x64-5.3.0.tar.gz
cd rar
chmod 755 *
make
echo 安装rar解压工具完毕