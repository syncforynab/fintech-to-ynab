FROM python:2.7.14-alpine

MAINTAINER Ross Dargan

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh gcc g++ python python-dev py-pip libxml2-dev libffi-dev libxslt-dev openssl-dev curl

COPY requirements.txt /usr/src/requirements.txt

COPY python/. /usr/src/

EXPOSE 5000

WORKDIR /usr/src

RUN pip install -r requirements.txt

ENTRYPOINT ["python"]

CMD ["/usr/src/main.py"]

HEALTHCHECK CMD curl --fail http://localhost:5000/ping || exit 1
