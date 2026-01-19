#Creo un bucket y le subo el archivo de la aplicacion web
S3=s3-green-blue

aws s3 mb s3://$S3

file=blue.zip

#Creo una versión de la aplicación y le aplico el archivo de la aplicación web
aws elasticbeanstalk create-application-version \
  --application-name green-blue-cli \
  --version-label v1.0.1 \
  --source-bundle S3Bucket="$S3",S3Key="$file"

#Implementar la nueva versión de la aplicación en el entorno
aws elasticbeanstalk update-environment \
    --environment-name green-blue-cli-env \
    --version-label v1.0.1