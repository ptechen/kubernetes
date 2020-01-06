#!/bin/bash

systemctl stop firewalld

systemctl disable firewalld

yum install epel-release -y

yum install wget net-tools telnet tree nmap sysstat lrzsz dos2unix bind-utils -y

# vi /etc/named.conf
#listen-on port 53 { 10.4.7.11; };
#allow-query     { any; };
#forwarders      { 10.4.7.254; };
#dnssec-enable no;
#dnssec-validation no;

named-checkconf

echo '
zone "host.com" IN {
        type  master;
        file  "host.com.zone";
        allow-update { 10.4.7.11; };
};

zone "od.com" IN {
        type  master;
        file  "od.com.zone";
        allow-update { 10.4.7.11; };
};' >> /etc/named.rfc1912.zones


echo '$ORIGIN host.com.
$TTL 600	; 10 minutes
@       IN SOA	dns.host.com. dnsadmin.host.com. (
				2019111001 ; serial
				10800      ; refresh (3 hours)
				900        ; retry (15 minutes)
				604800     ; expire (1 week)
				86400      ; minimum (1 day)
				)
			NS   dns.host.com.
$TTL 60	; 1 minute
dns                A    10.4.7.11
HDSS7-11           A    10.4.7.11
HDSS7-12           A    10.4.7.12
HDSS7-21           A    10.4.7.21
HDSS7-22           A    10.4.7.22
HDSS7-200          A    10.4.7.200
' > /var/named/host.com.zone

echo '$ORIGIN od.com.
$TTL 600	; 10 minutes
@   		IN SOA	dns.od.com. dnsadmin.od.com. (
				2019111001 ; serial
				10800      ; refresh (3 hours)
				900        ; retry (15 minutes)
				604800     ; expire (1 week)
				86400      ; minimum (1 day)
				)
				NS   dns.od.com.
$TTL 60	; 1 minute
dns                A    10.4.7.11
harbor             A    10.4.7.200
k8s-yaml           A    10.4.7.200
' > /var/named/od.com.zone

# systemctl start named
# systemctl enable named
# netstat -luntp|grep 53
# dig -t A hdss7-21.host.com @10.4.7.11 +short
