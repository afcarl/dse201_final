sync; /etc/init.d/postgresql stop; echo 3 > /proc/sys/vm/drop_caches; /etc/init.d/postgresql start

echo 'Sleeping for 5s'
sleep 5
