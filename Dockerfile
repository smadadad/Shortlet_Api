# using python 3.9 in a slim version as it is lightweight
FROM python:3.9-slim

# sets the working directory inside the container ro '/app'
WORKDIR /app

# copies all the files in the current working directory into the container
COPY . /app/

# tells Flask which file to run by setting an env variable
ENV FLASK_APP=main.py

# installs flasks inside the container
RUN pip install Flask gunicorn
# RUN apt-get update && apt-get install -y python3 python3-pip


# Exposes port 8080 to allow external access to the application 
EXPOSE 8080



# tells docker to run the application when the conatainer starts
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8080", "main:app"]