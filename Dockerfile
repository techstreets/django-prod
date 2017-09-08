FROM python:3.6.2
MAINTAINER bradojevic@gmail.com

RUN apt-get update && apt-get install -y \
    gcc gettext mysql-client libmysqlclient-dev \
    postgresql-client libpq-dev sqlite3 \
    --no-install-recommends && rm -rf /var/lib/apt/lists/*

# we need to install pip2 but right after it revert pip to point to pip3
RUN curl -fsSL https://bootstrap.pypa.io/get-pip.py | python2.7 -
# make pip point to pip3 by default
RUN cp $(which pip3) $(which pip)

ENV DJANGO_VERSION 1.10.4
RUN pip install mysqlclient psycopg2 django=="$DJANGO_VERSION"

ENV NGINX_VERSION 1.6.2-5+deb8u5
ENV GUNICORN_VERSION 19.7.1
ENV SUPERVISOR_VERSION 3.3.3
ENV APP_ROOT /opt/app

# Define working directory.
RUN mkdir -p ${APP_ROOT}
# install common tools
RUN apt-get update && apt-get install -y net-tools curl wget vim git
RUN pip install --upgrade pip
RUN curl -fsSL https://bootstrap.pypa.io/get-pip.py | python2.7 -
# install nginx
RUN apt-get update && apt-get install -y nginx=${NGINX_VERSION}
RUN rm /etc/nginx/sites-enabled/default
RUN ln -s /opt/app/nginx/django_config /etc/nginx/sites-enabled/default
# install gunicorn
RUN pip install gunicorn==${GUNICORN_VERSION}
# install supervisor
RUN pip2.7 install supervisor==${SUPERVISOR_VERSION}
RUN echo_supervisord_conf > /etc/supervisord.conf
RUN mkdir -p /etc/supervisord.d
RUN echo '\
[include]\n\
files = /etc/supervisord.d/*.conf'\
>> /etc/supervisord.conf
RUN ln -s /opt/app/supervisor/supervisor.conf /etc/supervisord.d/supervisor.conf

WORKDIR ${APP_ROOT}
VOLUME ['${APP_ROOT}']

EXPOSE 80 443 8080 8000

CMD ["/usr/local/bin/supervisord"]
