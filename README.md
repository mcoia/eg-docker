# MOBIUS Evergreen Docker example set

## Recommended Hardware

- I recommend at least 4 CPU's and 4GB of memory, but 8CPU, 8GB would be better :)

- You might find the 2017 presentation helpful [Evergreen conference 2017 presentation](http://slides.mobiusconsortium.org/blake/evergreengoogledocker/)

## First steps

- Make sure your host machine is not using the following ports
  - 32
  - 80
  - 443

- Clone this repo

  `git clone https://github.com/mcoia/eg-docker.git`


### Maybe customize vars.yml and Dockerfile

- Set your desired ubuntu version (xenial, bionic, focal)
  - Keep in mind that certain versions of Evergreen are only compatible with certain versions of ubuntu

- Set your desired Evergreen version
  - This installation is "best effort". install_evergreen.yml makes a best effort to install different versions of Evergreen that you choose. Mileage will vary because of the Node dependency stack as time goes on.

### Build the container

`cd generic-dockerhub && docker build --add-host public.localhost:127.0.1.2 --add-host public:127.0.1.2 --add-host private.localhost:127.0.1.3 --add-host private:127.0.1.3 .`

### Run the container

`docker run -it -p 80:80 -p 443:443 -p 32:22 -h app.brick.com 51d5369e7d89`

- NOTE: replace the image hash with yours

### _Optionally_ use docker-compose

`HOST=app.brick.com IMAGE=evergreen docker-compose up -d`

- NOTE: Default VARS are defined in .env and docker-compose.yml

### Look for the container finish line

- When the container is ready, you should see something that looks like

  `PLAY RECAP *******************************************************************************************************************************`

And it will be apparently hanging. You need to issue this command:

ctrl+pq

which will escape out of the console of the Docker container without killing the container

### Open a web browser

Attempt to connect to the server on your web browser:

http://127.0.0.1

Use your specific IP as needed.

### Certificates

This build will create a self-signed SSL certificate. Your browser will give you an error. As long as you connect to the server by IP address (not domain name), your browser will allow you to make an exception.

### SSH

This build creates a linux user in the Docker container. The user is "user" and the password is: "password"

This allows you to SSH into the Docker container to make changes if you'd like.

`ssh -p 32 user@localhost`

### Troubleshooting

If you find that this build won't finish. Then you need to break the process down. Do the following:

- Edit Dockerfile. Comment out these two lines:

  `#RUN cd /egconfigs && ansible-playbook install_evergreen.yml -v -e "hosts=127.0.0.1"`

  `#ENTRYPOINT cd /egconfigs && ansible-playbook evergreen_restart_services.yml -vvvv -e "hosts=127.0.0.1" && while true; do sleep 1; done`

- UNCOMMENT this line:

  `ENTRYPOINT while true; do sleep 1; done`


- Then perform the docker build again. This time, it should finish.
- Run the container
- ctrl+pq to escape out of the container
- Get to a shell in the container

  ``docker exec `docker ps --format "{{.ID}}"` /bin/bash``

- Manually execute the command:

  `cd /egconfigs && ansible-playbook install_evergreen.yml -v -e "hosts=127.0.0.1"`

- Watch and see where it errors out, and track down that command in the ansible script. Make tweaks and try again.


Everything in this repository is open and free to use under the GNU.


    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	
