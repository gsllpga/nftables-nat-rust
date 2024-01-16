# 关闭firewalld
sudo service firewalld stop
sudo systemctl disable firewalld
# 关闭selinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config  
# 修改内存参数，开启端口转发
echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i '/^net.ipv4.ip_forward=0/'d /etc/sysctl.conf
sed -n '/^net.ipv4.ip_forward=1/'p /etc/sysctl.conf | grep -q "net.ipv4.ip_forward=1"
if [ $? -ne 0 ]; then
    echo -e "net.ipv4.ip_forward=1" >> /etc/sysctl.conf && sysctl -p
fi
# 确保nftables已安装
yum install -y nftables

# 必须是root用户
# sudo su
# 下载可执行文件
curl -sSLf http://cdn.arloor.com/tool/dnat -o /tmp/nat
# curl -sSLf https://github.com/arloor/nftables-nat-rust/releases/download/v1.0.0/dnat -o /tmp/nat
install /tmp/nat /usr/local/bin/nat

# 创建systemd服务
cat > /lib/systemd/system/nat.service <<EOF
[Unit]
Description=dnat-service
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/nat
EnvironmentFile=/opt/nat/env
ExecStart=/usr/local/bin/nat /etc/nat.conf
LimitNOFILE=100000
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

# 设置开机启动，并启动该服务
sudo systemctl daemon-reload
sudo systemctl enable nat
sudo systemctl enable nftables
sudo systemctl start nftables

mkdir /opt/nat
touch /opt/nat/env
# echo "nat_local_ip=10.10.10.10" > /opt/nat/env #自定义本机ip，用于多网卡的机器

# 生成配置文件，配置文件可按需求修改（请看下文）
cat > /etc/nat.conf <<EOF
SINGLE,49999,59999,baidu.com
RANGE,50000,50010,baidu.com
EOF

sudo systemctl restart nat