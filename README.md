# Vagrant file options:

> NUM_WORKER_NODES=3
> 
> METRIC_NODE_ID=NUM_WORKER_NODES + 1
> 
> IP_NW="192.168.56."
> 
> IP_START=150

## Vagrant_for_centos8
Will do the following for you on your local machine:
- Create Aerospike Cluster including the Aerospike Metric Statck
- Disable swap
- Enable ports for inter vm connectivity
- To enable the hosts files to be updated automatically use the 
  - _start and 
  - _stop file for convenience. 
  
  Which will basically call 
   * vagrant plugin install vagrant-hostmanager ( once only )
   *vagrant hostmanager ( ona single machine )

- Set up the metrics server on http://192.168.56.[n]:3000 
  - where n is the last server created namesd obs*
