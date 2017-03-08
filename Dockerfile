FROM python:2.7.13

MAINTAINER Ross Dargan

COPY requirements.txt /usr/src/requirements.txt

COPY python/main.py /usr/src/main.py

COPY python/settings.py /usr/src/settings.py

EXPOSE 5000

WORKDIR /usr/src

RUN pip install -r requirements.txt

CMD ["python", "/usr/src/main.py", "-p 80"]

