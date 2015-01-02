############################################################
# Dockerfile to build My-application
# Based on Debian
############################################################

FROM debian

MAINTAINER Ludovic Bouguerra

############################################################
# System update
############################################################
RUN apt-get update
RUN apt-get -y upgrade

############################################################
# Installing apache 2 / lib Mysql / Python deps
############################################################
RUN apt-get install -y python-setuptools subversion git libmysqlclient-dev libxslt-dev libxml2-dev python-dev

RUN mkdir -p /home/my-application/

RUN easy_install pip

RUN pip install virtualenv

RUN mkdir -p /home/my-application/

RUN cd /home/my-application/ && virtualenv venv
RUN mkdir -p /home/my-application/

ADD docs /home/my-application/app/docs
ADD extra /home/my-application/app/extra
ADD requirements /home/my-application/app/requirements
ADD src /home/my-application/app/src

RUN cd /home/my-application/app/ && ls

# Recuperation des dépendances 
RUN /bin/bash -c 'source /home/my-application/venv/bin/activate && cd /home/my-application/app/requirements &&  pip install -r requirements-prod.txt' 

COPY extra/apache2/application.conf /etc/apache2/sites-available/application.conf

RUN a2ensite application.conf

RUN a2dissite default

RUN cp /home/my-application/app/src/conf/local_settings.py.sample /home/my-application/app/src/conf/local_settings.py

RUN /bin/bash -c 'source /home/my-application/venv/bin/activate && cd /home/my-application/app/src &&  python manage.py syncdb' 

RUN /bin/bash -c 'source /home/my-application/venv/bin/activate && cd /home/my-application/app/src &&  python manage.py collectstatic --noinput' 
 
RUN /etc/init.d/apache2 stop

EXPOSE 80

CMD /usr/sbin/apache2ctl -D FOREGROUND
