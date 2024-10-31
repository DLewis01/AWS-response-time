# AWS-response-time
Graph hourly timings on AWS AZ responses and create a web page
This is useful for finding which is the quickest AZ for you over time as well as finding service degradation

Requirements
  GNUplot

  you can usually install this with yum install gnuplot or dnf install gnuplot

Install

  Put this script where you like

  make it executable with

  chmod +x aws_response.sh

  create a subdir mkdir {path}/graphs

  set a crontab to run it every hour

  1 * * * * {path}/aws_response.sh

  where {path} is the location that you've put aws_rsponse 


