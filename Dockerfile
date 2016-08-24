# -*- conf -*-

FROM ubuntu:14.04
MAINTAINER Maciej Pasternacki <maciej@3ofcoins.net>

EXPOSE 80 443
VOLUME /var/opt/opscode

COPY install.sh /tmp/install.sh
# For development uncomment the next line and comment the wget in install.sh
# COPY chef-compliance_1.3.1-1_amd64.deb /tmp/chef-compliance_1.3.1-1_amd64.deb

RUN [ "/bin/sh", "/tmp/install.sh" ]

COPY init.rb /init.rb
COPY chef-compliance.rb /.chef/chef-compliance.rb

CMD [ "/opt/chef-compliance/embedded/bin/ruby", "/init.rb" ]
