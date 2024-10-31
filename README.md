# AWS-response-time
Graph hourly timings on AWS AZ responses and create a web page

Requirements
  GNUplot

  you can usually install this with yum install gnuplot or dnf install gnuplot

Install

  Put this script where you like

  chmod +x aws_response.sh

  set a crontab to run it every hour

  1 * * * * {path}/aws_response.sh

  where {path} is the location that you've put aws_rsponse 


