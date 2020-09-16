#!/bin/bash

gost(){
    cd /root/proxy
    # read -p "Enter inport:" inPort
    # read -p "Enter transferPort:" transferPort

    url='https://raw.githubusercontent.com/crossfw/configTest/master/test/gost'
    # inPort='2082'
    # transferPort='31813'

    wget ${url}
    chmod +x gost

    nohup /root/proxy/gost -L relay+ws://:${inPort}/127.0.0.1:${transferPort} >/dev/null 2>&1 &
    # echo "nohup /root/proxy/gost -L relay+ws://:${inPort}/127.0.0.1:${transferPort} >/dev/null 2>&1 &" >> /etc/rc.local
    cat > /root/proxy/gost.sh <<EOF
#!/bin/bash
eval ps -ef | grep gost | grep -v grep| grep -v "gost.sh" | awk '{print \$2}' | xargs kill -9
nohup /root/proxy/gost -L relay+ws://:${inPort}/127.0.0.1:${transferPort} >/dev/null 2>&1 &
EOF
chmod +x /root/proxy/gost.sh
}

ssr(){
    cd /root/proxy
    domain="https:\/\/"$domain

    git clone -b manyuser https://github.com/lizhongnian/shadowsocks.git
    cd shadowsocks
    pip install idna ndg-httpsclient pyOpenSSL
    cp apiconfig.py userapiconfig.py
    cp config.json user-config.json

    sed -i "s/NODE_ID = 0/NODE_ID = ${id}/g" userapiconfig.py
    sed -i "s/WEBAPI_URL = 'https:\/\/zhaoj.in'/WEBAPI_URL = '${domain}'/g" userapiconfig.py
    sed -i "s/WEBAPI_TOKEN = 'glzjin'/WEBAPI_TOKEN = '${token}'/g" userapiconfig.py
    sed -i "s/SPEEDTEST = 6/SPEEDTEST = 0/g" userapiconfig.py
    chmod +x ./run.sh
    nohup python /root/proxy/shadowsocks/server.py >/dev/null 2>&1 &
    cat > /root/proxy/ssr.sh <<EOF
#!/bin/bash
eval ps -ef | grep "python /root/proxy/shadowsocks/server\\.py" | grep -v grep | awk '{print \$2}' | xargs kill -9
nohup python /root/proxy/shadowsocks/server.py >/dev/null 2>&1 &
EOF
chmod +x /root/proxy/gost.sh
}


init(){
    echo "########ssr config#######\n"
    read -p "Enter id:" id
    read -p "Enter domain(https://):" domain
    read -p "Enter token:" token
    echo "########gost config#######\n"
    read -p "Enter inport:" inPort
    read -p "Enter transferPort:" transferPort
    
    apt-get update
    apt-get install python-pip git cron wget -y
}

keepalive(){
    cat > /root/proxy/keepalive.sh <<EOF
#!/bin/bash

ssr=\$(ps -ef | grep "python /root/proxy/shadowsocks/server\\.py" | grep -v grep | wc -l)
if [ \$ssr -eq 0 ];then
    bash /root/proxy/ssr.sh
else
   echo "ssr ok"
fi


gost=\$(ps -ef | grep "gost" | grep -v grep | wc -l)
if [ \$gost -eq 0 ];then
    bash /root/proxy/gost.sh
else
   echo "gost ok"
fi
EOF
chmod +x /root/proxy/keepalive.sh
echo "SHELL=/bin/bash" > /var/spool/cron/crontabs/root
echo '*/1 * * * * /root/proxy/keepalive.sh'  >> /var/spool/cron/crontabs/root
chown root:crontab /var/spool/cron/crontabs/root
chmod 600 /var/spool/cron/crontabs/root
}

mkdir /root/proxy
init;
gost;
ssr;
keepalive;
