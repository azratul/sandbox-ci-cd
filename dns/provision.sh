#!/bin/sh

export GITLAB=121.11
export KUBERNETES=121.12
export IP=$(ip a | grep ens6 | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b/" | sed 's/\///g')
export DNS=magi-system.com
export DEBIAN_FRONTEND=noninteractive
export FINAL_USER=vagrant
export EMAIL=raspberry.camara.ip@gmail.com
export HOME=/home/vagrant

# CORE PACKAGES INSTALLATION(AND VPN, JUST IN CASE)
echo "***********************************************"
echo "*          INSTALLING CORE PACKAGES           *"
echo "***********************************************"
apt -y install git ufw curl apt-transport-https ca-certificates certbot docker docker-compose vim bind9 bind9utils bind9-doc resolvconf
curl -sSL https://get.docker.com/ | sh
curl -L "https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ufw allow 53
ufw allow 80
ufw allow 443
ufw allow 3000
ufw allow 5000

# MODIFYING PRINCIPAL USER'S PERMISSIONS
usermod -aG docker $FINAL_USER
systemctl restart docker

# BASICS BIND9 SETTINGS. YOU'LL HAVE TO CHANGED IT ACCORDING TO YOUR NEEDS
echo "***********************************************"
echo "*            INSTALLING DNS SERVER            *"
echo "***********************************************"
sed 's/OPTIONS.*bind/& -4/g' /etc/default/bind9
cp /etc/bind/db.local /etc/bind/forward.${DNS}
cp /etc/bind/db.127 /etc/bind/reverse.${DNS}
cp /vagrant/named.conf.local /etc/bind/named.conf.local
cp /vagrant/named.conf.options /etc/bind/named.conf.options
sed -i "s/localhost/dns.${DNS}/g" /etc/bind/forward.${DNS}
sed -i 's/@\tIN\tA/; &/g' /etc/bind/forward.magi-system.com
sed -i "s/localhost/${DNS}/g" /etc/bind/reverse.${DNS}
sed -i "s/\tIN\tNS\t/&dns./g" /etc/bind/reverse.${DNS}
sed -i 's/1\.0\.0\tIN/; &/g' /etc/bind/reverse.magi-system.com
OCTET1=$(echo ${IP%%.*})
OCTET2=$(echo ${IP}|cut -d "." -f 2)
OCTET3=$(echo ${IP}|cut -d "." -f 3)
OCTET4=$(echo ${IP##*.})
GITLAB1=$(echo ${GITLAB%%.*})
GITLAB2=$(echo ${GITLAB##*.})
KUBERNETES1=$(echo ${KUBERNETES%%.*})
KUBERNETES2=$(echo ${KUBERNETES##*.})
printf "dns\tIN\tA\t${IP}\n" >> /etc/bind/forward.${DNS}
printf "docker\tIN\tA\t${IP}\n" >> /etc/bind/forward.${DNS}
printf "gitlab\tIN\tA\t${OCTET1}.${OCTET2}.${GITLAB1}.${GITLAB2}\n" >> /etc/bind/forward.${DNS}
printf "kubernetes\tIN\tA\t${OCTET1}.${OCTET2}.${KUBERNETES1}.${KUBERNETES2}\n" >> /etc/bind/forward.${DNS}
printf "dns\tIN\tA\t${IP}\n" >> /etc/bind/reverse.${DNS}
printf "${OCTET4}.${OCTET3}\tIN\tPTR\tdns.${DNS}.\n" >> /etc/bind/reverse.${DNS}
printf "${GITLAB2}.${GITLAB1}\tIN\tPTR\tgitlab.${DNS}.\n" >> /etc/bind/reverse.${DNS}
printf "${KUBERNETES2}.${KUBERNETES1}\tIN\tPTR\tkubernetes.${DNS}.\n" >> /etc/bind/reverse.${DNS}
printf "${OCTET4}.${OCTET3}\tIN\tPTR\tdocker.${DNS}.\n" >> /etc/bind/reverse.${DNS}
printf "search ${DNS}\nnameserver ${IP}\n" >> /etc/resolvconf/resolv.conf.d/head

echo "***********************************************"
echo "*              REGISTRY & PORTUS              *"
echo "***********************************************"
# Install Portus
git clone https://github.com/SUSE/Portus.git /tmp/portus
mv /tmp/portus/examples/compose ${HOME}/portus
cp /vagrant/extfile.cnf ${HOME}/portus
cd ${HOME}/portus
sed -i "s/172.17.0.1/docker.${DNS}/g" .env
sed -i "s/172.17.0.1/docker.${DNS}/g" nginx/nginx.conf
rm docker-compose.*

openssl genrsa -out secrets/rootca.key 2048
dd if=/dev/urandom of=~/.rnd bs=256 count=1
openssl req -x509 -new -nodes -key secrets/rootca.key -subj "/C=US/ST=CA/O=Acme, Inc."-sha256 -days 1024 -out secrets/rootca.crt
openssl genrsa -out secrets/portus.key 2048
openssl req -new -key secrets/portus.key -out secrets/portus.csr -subj "/C=US/ST=CA/O=Acme, Inc./CN=docker.${DNS}"
openssl x509 -req -in secrets/portus.csr -CA secrets/rootca.crt -extfile extfile.cnf -CAkey secrets/rootca.key -CAcreateserial -out secrets/portus.crt -days 500 -sha256

# We're getting all the config files into the right place
cat << 'EOF' > docker-compose.yml
version: "2"

services:
  portus:
    image: opensuse/portus:head
    environment:
      - PORTUS_MACHINE_FQDN_VALUE=${MACHINE_FQDN}
      - PORTUS_SECURITY_CLAIR_SERVER=http://clair:6060

      # DB. The password for the database should definitely not be here. You are
      # probably better off with Docker Swarm secrets.
      - PORTUS_DB_HOST=db
      - PORTUS_DB_DATABASE=PORTUS_production
      - PORTUS_DB_PASSWORD=${DATABASE_PASSWORD}
      - PORTUS_DB_POOL=5

      # Secrets. It can possibly be handled better with Swarm's secrets.
      - PORTUS_SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - PORTUS_KEY_PATH=/certificates/portus.key
      - PORTUS_PASSWORD=${PORTUS_PASSWORD}

      # SSL
      - PORTUS_PUMA_TLS_KEY=/certificates/portus.key
      - PORTUS_PUMA_TLS_CERT=/certificates/portus.crt
      # - PORTUS_CHECK_SSL_USAGE_ENABLED=false

      # NGinx is serving the assets instead of Puma. If you want to change this,
      # uncomment this line.
      - RAILS_SERVE_STATIC_FILES=true

      # Other Config
      #- PORTUS_SIGNUP_ENABLED=false
      - PORTUS_ANONYMOUS_BROWSING_ENABLED=false
      - PORTUS_DELETE_ENABLED=true
    ports:
      - 3000:3000
    links:
      - db
    volumes:
      - ./secrets:/certificates:ro
      #- ./static:/srv/Portus/public

  background:
    image: opensuse/portus:head
    depends_on:
      - portus
      - db
    environment:
      # Theoretically not needed, but cconfig's been buggy on this...
      - CCONFIG_PREFIX=portus
      - PORTUS_MACHINE_FQDN_VALUE=${MACHINE_FQDN}
      - PORTUS_SECURITY_CLAIR_SERVER=http://clair:6060

      # DB. The password for the database should definitely not be here. You are
      # probably better off with Docker Swarm secrets.
      - PORTUS_DB_HOST=db
      - PORTUS_DB_DATABASE=PORTUS_production
      - PORTUS_DB_PASSWORD=${DATABASE_PASSWORD}
      - PORTUS_DB_POOL=5

      # Secrets. It can possibly be handled better with Swarm's secrets.
      - PORTUS_SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - PORTUS_KEY_PATH=/certificates/portus.key
      - PORTUS_PASSWORD=${PORTUS_PASSWORD}

      - PORTUS_BACKGROUND=true
      - PORTUS_SYNC_ENABLED=true
      - PORTUS_SYNC_STRATEGY=update-delete
    links:
      - db
    volumes:
      #- ./secrets:/certificates:ro
      - /etc/letsencrypt/live/dr.mrpowerscripts.com:/certificates

  db:
    image: library/mariadb:10.0.23
    command: mysqld --character-set-server=utf8 --collation-server=utf8_unicode_ci --init-connect='SET NAMES UTF8;' --innodb-flush-log-at-trx-commit=0
    environment:
      - MYSQL_DATABASE=PORTUS_production

      # Again, the password shouldn't be handled like this.
      - MYSQL_ROOT_PASSWORD=${DATABASE_PASSWORD}
    volumes:
      - ./mariadb:/var/lib/mysql

  registry:
    image: library/registry:2.6
    command: ["/bin/sh", "/etc/docker/registry/init"]
    environment:
      # Authentication
      REGISTRY_AUTH_TOKEN_REALM: https://${MACHINE_FQDN}/v2/token
      REGISTRY_AUTH_TOKEN_SERVICE: ${MACHINE_FQDN}:5000
      REGISTRY_AUTH_TOKEN_ISSUER: ${MACHINE_FQDN}
      REGISTRY_AUTH_TOKEN_ROOTCERTBUNDLE: /secrets/portus.crt

      # SSL
      REGISTRY_HTTP_TLS_CERTIFICATE: /secrets/portus.crt
      REGISTRY_HTTP_TLS_KEY: /secrets/portus.key

      # portus endpoint
      REGISTRY_NOTIFICATIONS_ENDPOINTS: >
        - name: portus
          url: https://${MACHINE_FQDN}/v2/webhooks/events
          timeout: 2000ms
          threshold: 5
          backoff: 1s
    volumes:
      - ./secrets:/usr/local/share/ca-certificates:ro
      - ./registry/data:/var/lib/registry
      - ./secrets:/secrets:ro
      - ./registry/config.yml:/etc/docker/registry/config.yml:ro
      - ./registry/init:/etc/docker/registry/init:ro
    ports:
      - 5000:5000
      - 5001:5001 # required to access debug service
    links:
      - portus:portus

  postgres:
    image: library/postgres:10-alpine
    environment:
      POSTGRES_PASSWORD: portus

  clair:
    image: quay.io/coreos/clair
    restart: unless-stopped
    depends_on:
      - postgres
    links:
      - postgres
      - portus
    ports:
      - "6060-6061:6060-6061"
    volumes:
      - /tmp:/tmp
      - ./clair/clair.yml:/clair.yml
    command: [-config, /clair.yml]


  nginx:
    image: library/nginx:alpine
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./secrets:/secrets:ro
      - static:/srv/Portus/public:ro
    ports:
      - 80:80
      - 443:443
    links:
      - registry:registry
      - portus:portus

volumes:
  static:
EOF