#Creo la aplicación de elastic beanstalk
aws elasticbeanstalk create-application --application-name green-blue-cli

#Creo un bucket y le subo el archivo de la aplicacion web
S3=s3-green-blue

aws s3 mb s3://$S3

file=index.zip

#Creo una versión de la aplicación y le aplico el archivo de la aplicación web
aws elasticbeanstalk create-application-version \
  --application-name green-blue-cli \
  --version-label v1.0.0 \
  --source-bundle S3Bucket="$S3",S3Key="$file"

#Creo un entorno beanstalk
aws elasticbeanstalk create-environment \
    --application-name green-blue-cli \
    --environment-name green-blue-cli-env \
    --solution-stack-name "64bit Amazon Linux 2023 v4.7.8 running PHP 8.4" \
    --option-settings "Namespace=aws:autoscaling:launchconfiguration,OptionName=IamInstanceProfile,Value=LabInstanceProfile" \
    --version-label v1.0.0
    