# elasticache-redis-latency

This repo contains terraform code that deploys a ElastiCache redis instance in one AZ and EC2 instances in every AZs in a region to run redis-benchmark from each instance to the ElastiCache redis instance. 

After deploying resources by running "terraform apply", run the following commands on each EC2 instance.

```
# Installing Redis 7 on AL2023
sudo yum install wget make pkg-config gcc
wget https://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
cd deps/
make hiredis jemalloc linenoise lua hdr_histogram
cd ..
make
sudo make install
$ redis-server -v
Redis server v=7.0.12 sha=00000000:0 malloc=jemalloc-5.2.1 bits=64 build=4d759d4e8eb73ffb
  
```

And run redis-benchmark as below. To increase throughput, use pipelining option (-P 5)
```
Running redis-benchmark
[ec2-user@ip-10-10-103-64 redis-stable]$ redis-benchmark -h demo-redis-cluster.wbpq8z.0001.apn2.cache.amazonaws.com -d 1000 -r 10000 -n 100000 -q -P 5 --threads 8
WARNING: Could not fetch server CONFIG
PING_INLINE: 132978.73 requests per second, p50=1.319 msec
PING_MBULK: 133155.80 requests per second, p50=1.319 msec
SET: 132978.73 requests per second, p50=1.383 msec
GET: 132978.73 requests per second, p50=1.343 msec
INCR: 132978.73 requests per second, p50=1.303 msec
LPUSH: 133155.80 requests per second, p50=1.391 msec
RPUSH: 132978.73 requests per second, p50=1.399 msec
LPOP: 132978.73 requests per second, p50=1.383 msec
RPOP: 133155.80 requests per second, p50=1.335 msec
SADD: 132978.73 requests per second, p50=1.303 msec
HSET: 132978.73 requests per second, p50=1.415 msec
SPOP: 133155.80 requests per second, p50=1.327 msec
ZADD: 132978.73 requests per second, p50=1.399 msec
ZPOPMIN: 132978.73 requests per second, p50=1.319 msec
LPUSH (needed to benchmark LRANGE): 133155.80 requests per second, p50=1.407 msec
LRANGE_100 (first 100 elements): 5182.96 requests per second, p50=3.319 msec
LRANGE_300 (first 300 elements): 1767.50 requests per second, p50=3.983 msec
LRANGE_500 (first 500 elements): 1051.68 requests per second, p50=4.519 msec
LRANGE_600 (first 600 elements): 41.68 requests per second, p50=5.535 msec
MSET (10 keys): 39840.64 requests per second, p50=2.879 msec

```

