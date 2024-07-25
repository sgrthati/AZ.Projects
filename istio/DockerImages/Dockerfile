#Docker build
# docker build -t helloworld:v1 .
# Use the official Python image from the Docker Hub
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

# Install Flask
RUN pip install flask

# Copy the Flask app code into the container
COPY app.py .

# Expose the port the app runs on
EXPOSE 5000

# Define environment variable
ENV INSTANCE_NAME="DockerInstance"

# Command to run the application
CMD ["python", "app.py"]