FROM python:2.7.13

MAINTAINER Ross Dargan

COPY requirements.txt /usr/src/requirements.txt

COPY python/. /usr/src/

EXPOSE 5000

WORKDIR /usr/src

RUN pip install -r requirements.txt

ENTRYPOINT ["python"]

CMD ["/usr/src/main.py"]

HEALTHCHECK CMD curl --fail http://localhost:5000/ || exit 1
