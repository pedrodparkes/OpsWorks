# OpsWorks test task

Image builder organized on hosted Jenkins Instance:
http://jenkinsx.glash.io

Builder job:
pipeline-opsworkd

Pre-requirements:
- config aws creds for Jenkins user

- create ec2 instance

docker-machine -D create --driver amazonec2 --amazonec2-vpc-id vpc-7c89241a --amazonec2-region us-west-2 --amazonec2-instance-type t2.micro --amazonec2-zone "b" RlyImportantWorker

- deploy new container to RlyImportantWorker:

docker run -d --name RlyImportantWorker pedrodeparkes/nginx