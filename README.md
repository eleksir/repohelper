## repohelper package repo server helper

### What it is?

Helper tool for repository. Main idea is to receive rpms, store them in target
directory and re-generate repo metadata. But it can be used with any other repos
too.

### What status of this thing?

Private use ready :)

I'm not sure if it is applicable for public use without proper authorisation
setup on fronend server (nginx in my case), but if it set properly, then maybe.

Anyway it was not designed for highloads, but for corporate CI use in internal
repositories.

### What do i need to start?

"Development Tools" or similar group of packages, perl-App-cpanm,
perl-local-lib.

And bootstrap app itself

```sh
bash bootstrap.sh
```

### What else you need?

nginx or something like that to serve rpms and proxy requests to this webapp.
And some app server - i use uwsgi, but nginx unit or starman or dancer or any
other psgi-capable server is okay.

### Any configs?

Yup, nginx:

```
location /upload {
	proxy_pass http://127.0.0.1:4080;
	proxy_buffering off;
	client_max_body_size 300M;
	allow 127.0.0.0/8;
	allow 192.168.0.0/20;
	allow 10.0.3.0/24;
	deny all;
}

location /my {
	root /var/www;
	autoindex on;
}
```

App itself data/config.json

```json
{
    "dir" : {
        "my/6/" : {
            "hook" : "/usr/bin/createrepo_c",
            "path" : "/var/www/html/my/6"
        },
        "my/7/" : {
            "hook" : "/usr/bin/createrepo_c",
            "path" : "/var/www/html/my/7"
        }
    }
}
```

uwsgi config - repohelper.yaml

```yaml
uwsgi:
  http11-socket: 127.0.0.1:4080
  socket-protocol: http11
  so-keepalive: 0
  listen: 16
  logformat: [ %(pid) %(ltime) ] %(var.REMOTE_ADDR) %(var.REQUEST_METHOD) %(var.REQUEST_URI) => generated %(rsize) bytes in %(msecs) msecs (%(var.SERVER_PROTOCOL) %(status))
  processes: 1
  thunder-lock: true
  need-app: true
  log-reopen: yes
  reload-mercy: 5
  buffer-size: 32768
  die-on-term: true
```

and uwsgi can be executed as runit service with following script

```sh
#!/bin/sh

exec 2>&1

LOGDIR=/var/log/uwsgi
PIDDIR=/var/run/uwsgi
APPDIR=/var/www/repohelper

mkdir -p $LOGDIR
mkdir -p $PIDDIR
chown nginx:nginx $LOGDIR
chown nginx:nginx $PIDDIR

cd $APPDIR

exec sudo -u nginx /usr/bin/uwsgi \
 --plugins         psgi \
 --pidfile         $PIDDIR/repohelper.pid \
 --yaml            /etc/uwsgi/repohelper.yaml \
 --logto           $LOGDIR/repohelper.log \
 --psgi            $APPDIR/repohelper.psgi \
 --perl-local-lib  $APPDIR/vendor_perl/lib/perl5
```

### What platform it was tested on?

CentOS 7, Slackware 14.2. On RPM package repositories.

### How to upload file via this helper?

```sh
curl --upload-file ./binutils-2.31.1-25.el7.x86_64.rpm  http://127.0.0.1/upload/my/7/
```
