"""
A simple Flask web application for AWS deployment demonstration.

This application provides a basic landing page that can be used to verify
successful deployment to EC2 instances via AWS CodeDeploy.
"""

from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    """
    Home route handler that serves the main landing page of the web application.

    This function is a Flask route handler that responds to HTTP GET requests 
    to the root URL ("/"). It returns a simple HTML response containing a 
    greeting message and version information.

    Returns:
        str: An HTML string containing a heading with a greeting message 
             and a paragraph showing the current version number. The message 
             indicates the application is running on EC2 and was deployed 
             using AWS CodeDeploy.

    Note:
        This is typically used as a health check endpoint or simple landing 
        page to verify that the web application is running correctly after 
        deployment.
    """
    return "<h1>Hello from EC2 via CodeDeploy!</h1><p>Version 1</p>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
