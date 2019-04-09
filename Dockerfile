FROM amazonlinux:2017.03.1.20170812

COPY . .

#install aws-cli
RUN yum install -y wget unzip
RUN wget "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" && unzip awscli-bundle.zip && rm -rf awscli-bundle.zip
RUN ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
RUN rm -rf awscli-bundle

#Install some required packages
RUN yum update -y && yum install -y tar readline-devel xorg-x11-server-devel libX11-devel libXt-devel curl-devel gcc-c++ gcc-gfortran zlib-devel bzip2 bzip2-libs gzip zip openssl-devel libxml2-devel jq

#Install the regular version of R, needed for some dependencies during building
RUN wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y epel-release-latest-7.noarch.rpm
RUN yum install -y R

ENTRYPOINT ["./build_layers.sh"]