FROM amazonlinux:2
USER 0
RUN yum -y update \
    # systemd is not a hard requirement for Amazon ECS Anywhere, but the installation script currently only supports systemd to run.
    # Amazon ECS Anywhere can be used without systemd, if you set up your nodes and register them into your ECS cluster **without** the installation script.
    && yum -y install systemd \
    && yum clean all

RUN cd /lib/systemd/system/sysinit.target.wants/; \
    for i in *; do [ $i = systemd-tmpfiles-setup.service ] || rm -f $i; done

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/*

RUN amazon-linux-extras install epel docker && \
    systemctl enable docker

CMD ["/usr/sbin/init"]


FROM nuxeo:2021.34.6

USER 0 
COPY saml2-authentication-2021.33.9.zip .
COPY nuxeo-web-ui-3.0.19.zip .
COPY nuxeo-retention-2021.2.1.zip .
COPY amazon-s3-online-storage-2021.33.9.zip .
RUN mkdir mongo-utils
COPY mongodb-linux-x86_64-amazon-3.6.23/ mongo-utils/

RUN yum -y install ImageMagick ufraw poppler-utils libwpd-tools ghostscript which net-tools telnet curl iputils
RUN yum -y install http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
RUN yum -y install ffmpeg perl-Image-ExifTool

RUN rm docker-entrypoint.sh

COPY docker-entrypoint.sh .
RUN ["chmod", "+x", "docker-entrypoint.sh"]
COPY nuxeo.conf .

## Copy and add the required packages

RUN mkdir /opt/nuxeo/addons
RUN mv nuxeo.conf /etc/nuxeo
RUN mv saml2-authentication-2021.33.9.zip nuxeo-web-ui-3.0.19.zip nuxeo-retention-2021.2.1.zip amazon-s3-online-storage-2021.33.9.zip /opt/nuxeo/addons/
RUN nuxeoctl mp-install /opt/nuxeo/addons/nuxeo-web-ui-3.0.19.zip 
RUN nuxeoctl mp-install --relax=true --accept=true /opt/nuxeo/addons/amazon-s3-online-storage-2021.33.9.zip
RUN nuxeoctl mp-install --relax=true --accept=true /opt/nuxeo/addons/saml2-authentication-2021.33.9.zip
RUN nuxeoctl mp-install --relax=true --accept=true /opt/nuxeo/addons/nuxeo-retention-2021.2.1.zip

##Install packages
RUN mkdir libre_office
COPY libreoffice_7.5.0.3.zip libre_office/
RUN unzip libre_office/libreoffice_7.5.0.3.zip -d /libre_office
RUN yum -y localinstall /libre_office/*.rpm --skip-broken 
RUN rm -rf /libre_office

USER 0 
