vagrant up

vagrant ssh-config master
ssh -i path/to/private/key -p 2222 -L 12000:localhost:12000 vagrant@127.0.0.1

 ssh -i /home/sulav/Desktop/vagrantCluster/.vagrant/machines/master/virtualbox/private_key -p 2222 -L 12000:localhost:12000 vagrant@127.0.0.1

Step1:
All cluster must be assigned unique podCIDR ranges, in addition to allowing inter-cluster communication (L3).

Step2:
We need to add the context of one cluster into another cluster.(In one of the cluster)

Step3:
By defaut cilium sets cluster id to 0 and cluster name to default

so we need to change the cluster id and name for both cluster

```bash
cilium config set cluster-id 1
cilium config set cluster-name cluster1

cilium config set cluster-id 2
cilium config set cluster-name cluster2
```

```bash
cilium clustermesh enable
```

```bash
cilium clustermesh connect --context context1@clustername1 --destination-context context2@clustername2

```
