# AWS-response-time
Graph hourly timings on AWS AZ responses and create a web page
This is useful for finding which is the quickest AZ for you over time as well as finding service degradation

![Screenshot 2024-10-31 at 5 05 03 pm](https://github.com/user-attachments/assets/0cf24669-835c-4d04-ae85-83b602f852a5)

Requirements
  GNUplot

  on linux you can usually install this with 
  
        yum install gnuplot 
  
  or 
  
      dnf install gnuplot
    
  or if you are on Mac with either

      port install gnuplot

  or
      
      brew install gnuplot
      
Install

  Put this script where you like

  make it executable with

    chmod +x aws_response.sh

  create a subdir mkdir {path}/graphs

  edit the script to point to your webdirectory by setting WEBDIR="you web path" or set it to the install directory if you don't want a publically visible webpage.

  set a crontab to run it every hour

  1 * * * * {path}/aws_response.sh

  where {path} is the location that you've put aws_rsponse 


