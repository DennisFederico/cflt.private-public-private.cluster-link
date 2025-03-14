# Cluster Link with Public Jump Cluster

***IMPORTANT***
API Keys creation is driven by the `create_private_cluster_api_keys` variable, with `false` default value.
Run with `-var="create_private_cluster_api_keys=true"` if you are already on a network that can resolve the Clusters DNS when created and connectivity to reach them.

Options to run this locally include updating `/etc/hosts` file or openning a pipe connection to the NGINX proxy, perhaps using `proxychains4`

```shell
ssh -D 9050 -C -i ~/.ssh/[private.pem] ccproxyadmin@[proxy_ip]
```

---

This pattern applies to AZURE and GCP Cross-Region replication between two private cluster on different cloud regions.
See. [Private-Public-Private](https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/private-networking.html#private-public-private-pattern-with-cluster-link-chaining-and-a-jump-cluster)

This requires two Cluster Links, one from the Source private cluster to the Public "Jump" Cluster, and then a second Cluster Link, from the Public to the Destination private cluster.
Cluster linking is commonly hosted on the ***destination*** cluster of the data, but for the first leg of the replication flow, the public (destination) cluster cannot start a connection to the private (destination) cluster, thus the cluster link needs to be ***source*** initiated.

Assume a ACTIVE-PASSIVE DR scenario where data is replicated between two **private** cluster using a **public** cluster inbetween the replication flow. Let's define our clusters.

- PRIMARY: A **PRIVATE** cluster that holds the initial ***source*** of data
- JUMP: The intermediate cluster that both ends of the flow (private clusters) can connect to
- DR: The ***destination*** of the data another **PRIVATE** cluster in a different region from PRIMARY

Note in the following steps that the arrow (->) points the direction of the connection (the link), which is not necesarilly the same direction of the mirroring (replication).

## Setup PRIMARY->JUMP Cluster Link (Data from Private to Public)

See. [Private to Public Cluster Linking](https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/private-networking.html#private-to-public-cluster-linking)

This link follows the data flow, the link is hosted and established by the ***source*** of the data (**PRIMARY** cluster), but it is not the default approach as cluster don't push data for replication to other clusters, data is "consumed" by the replica, this this link requires another leg hosted on the **JUMP** cluster to indicate that the cluster link connection will be established by the PRIMARY cluster.

**NOTE**: This type of cluster link cannot be created on the Confluent Cloud Console. It must be created using the cluster REST APIs, the Confluent CLI, Terraform, or Confluent for Kubernetes.
Both parts of the cluster link need to be "working", deleting one (any) side stops data from being replicated

### Create a link leg on the data destination (JUMP) cluster (as usual)

This part of the link requires a specific configuration that needs to be passed as `key=value` to the Confluent CLI or using a config file (ie. `cl-primary-to-jump.jump.config`).

```conf
## THIS IS THE CONTENT OF primary-to-jump.jump.config CONFIGURATION FILE
link.mode=DESTINATION
connection.mode=INBOUND
```

No other ***connection*** configuration are required (ie. bootstrap, credentials, etc), as these will be added in the other half of the cluster link, at the data source cluster.
Other optional configuration options for this cluster link, such as consumer offset sync, ACL sync, and prefix can be added here

**NOTE**: `--source-cluster-id` was replaced with `--source-cluster` in version 3 of confluent CLI

```shell
confluent kafka link create primary-to-jump \
  --cluster [jump-cluster-id] \  
  --source-cluster [primary-cluster-id] \
  --config cl-primary-to-jump.jump.config
```

### Create a link leg on the data source cluster

This half of the link requires security credentials and permissions to both cluster, since we also need to specify the link mode, for convenience we are going to create a configuration file with the connection details (i.e. `cl-primary-to-jump.primary.config`)

```conf
## THIS IS THE CONTENT OF primary-to-jump.primary.config CONFIGURATION FILE
link.mode=SOURCE
connection.mode=OUTBOUND

bootstrap.servers=SASL_SSL://<JUMP_BOOTSTRAP_URL>:9092
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='<jump-api-key>' password='<jump-api-secret>';

local.bootstrap.servers=SASL_SSL://<PRIMARY_BOOTSTRAP_URL>:9092
local.security.protocol=SASL_SSL
local.sasl.mechanism=PLAIN
local.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='<primary-api-key>' password='<primary-api-secret>';
```

The bootstraps above could be passed on the command line, note that the `bootstrap.servers` is by convention the "destination" of a connection, thus we use the **JUMP** cluster coordinates. The `local` prefix indicates the source of the connection, in this case where the link is actually hosted, the **PRIMARY** cluster.

**NOTE**: Run this command from a host with access the the **PRIMARY** private cluster
**NOTE**: `--destination-cluster-id` was replaced with `--destination-cluster` in version 3 of confluent CLI

```shell
confluent kafka link create primary-to-jump \
  --cluster [primary-cluster-id] \
  --destination-cluster [jump-cluster-id] \
  --config cl-primary-to-jump.primary.config
```

### Verifying PRIMARY->JUMP Cluster Link (primary-to-jump data flow)

These are the typical commands that can be run to check the Cluster Link, note the `--cluster` to indicate for which *leg* are we querying

```shell
confluent kafka link list --cluster [jump-cluster-id]

       Name       | Source Cluster       | Destination Cluster | Remote Cluster       | State  | Error | Error Message  
------------------+----------------------+---------------------+----------------------+--------+-------+----------------
  primary-to-jump | [primary-cluster-id] |                     | [primary-cluster-id] | ACTIVE |       |                
```

```shell
confluent kafka link list --cluster [primary-cluster-id]

       Name       | Source Cluster      | Destination Cluster | Remote Cluster    | State  | Error | Error Message  
------------------+---------------------+---------------------+-------------------+--------+-------+----------------
  primary-to-jump |                     | [jump-cluster-id]   | [jump-cluster-id] | ACTIVE |       |              
```

***Note*** that each half references the other and there's only one Cluster link at the **JUMP** Cluster, from the above you can understand the direction of the connection and data flow (Source/Destination)

Additionally, for an overview of the mirroring status you would use `describe`, but note that only the *consuming* side, the ***DESTINATION*** (**JUMP**) cluster will hold the actual metric.

```shell
confluent kafka link describe --link primary-to-jump --cluster [primary-cluster-id]

+---------------------+-------------------+
| Name                | primary-to-jump   |
| Source Cluster      |                   |
| Destination Cluster | [jump-cluster-id] |
| Remote Cluster      | [jump-cluster-id] |
| State               | ACTIVE            |
+---------------------+-------------------+
```

```shell
confluent kafka link describe --link primary-to-jump --cluster [jump-cluster-id]

+-------------------------------+----------------------------------+
| Name                          | primary-to-jump                  |
| Source Cluster                | [primary-cluster-id]             |
| Destination Cluster           |                                  |
| Remote Cluster                | [primary-cluster-id]             |
| State                         | ACTIVE                           |
| Mirror Partition States Count | UNKNOWN: 0, IN_ERROR: 0,         |
|                               | ACTIVE: 0, PAUSED: 0, PENDING: 0 |
+-------------------------------+----------------------------------+
```

## Setup DR->JUMP Cluster Link (Data from Public to Private)

This is the "standard" cluster link, hosted at, and initiated by the ***destination*** cluster. What this mean is that the link will reside also on the private side, but at the destination side only.

**NOTE**: `--source-cluster-id` was replaced with `--source-cluster` in version 3 of confluent CLI

A single command is enough to create this link.

- Option 1: Without configuration file

```shell
confluent kafka link create jump-to-dr \
  --cluster [dr-cluster-id] \
  --source-cluster [jump-cluster-id] \
  --source-bootstrap-server  [jump-bootstrap-url] \
  --source-api-key [jump-api-key] \
  --source-api-secret [jump-api-secret]
```

- Option 2: Using a configuration file (`cl-jump-to-dr.dr.config`)

```conf
link.mode=DESTINATION
connection.mode=OUTBOUND
bootstrap.servers=SASL_SSL://<JUMP_BOOTSTRAP_URL>:9092
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='<jump-api-key>' password='jump-api-secret';
source.bootstrap.servers=SASL_SSL://<DR_BOOTSTRAP_URL>:9092
source.security.protocol=SASL_SSL
source.sasl.mechanism=PLAIN
source.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='<dr-api-key>' password='<dr-api-secret>';
```

Note from the above, that the configuration describes the LINK, the ***source*** is not the origin of the data, but from where the conection start, thus the `link.mode` is **DESTINATION** and the `connection.mode` is **OUTBOUND** (going from), both of these configuration are optional in these case, as those are the default values

```shell
confluent kafka link create jump-to-dr \
--cluster [dr_cluster_id] \
--source-cluster [jump_cluster_id] \
--config cl-jump-to-dr.dr.config
```

### Verifying DR->JUMP Cluster Link (jump-to-dr data flow)

Like the other flow we can check with `confluent kafka link list` on the **DR** Cluster, since that's the only place when the CL resides.

```shell
confluent kafka link list --cluster [dr-cluster-id]

     Name    | Source Cluster    | Destination Cluster | Remote Cluster    | State  | Error | Error Message  
-------------+-------------------+---------------------+-------------------+--------+-------+----------------
  jump-to-dr | [jump-cluster-id] |                     | [jump-cluster-id] | ACTIVE |       |  
```

## Create mirrors

These are created on the destination cluster of each link, on the **JUMP** cluster when mirroring from **PRIMARY** and on **DR** when mirroring from JUMP.
When using Confluent CLI we can only mirror individual topics

```shell
confluent kafka mirror create <topic-name> --link <link> --cluster <destination-cluster-id>
```

To mirror a set of topics automatically the cluster link configuration must include `auto.create.mirror.topics.enable` set to `true`, and `auto.create.mirror.topics.filters` to a value that includes the topic(s) to mirror automatically.

This filter includes all current and future topics

```json
{ "topicFilters": [ {"name": "*",  "patternType": "LITERAL",  "filterType": "INCLUDE"} ] }
```

This all the topics that start with `mirror_me` and excludes the ones that start when `no_mirror`

```json
{ 
    "topicFilters": [ 
        {"name": "mirror_me",  "patternType": "PREFIXED",  "filterType": "INCLUDE"},
        {"name": "no_mirror",  "patternType": "PREFIXED",  "filterType": "EXCLUDE"} 
    ] 
}
```

To add this to an exiting cluster link, use the `kafka link configure` command, assuming the following change in the `cl-primary-to-jump.jump.config` file

```conf
## ADDING AUTO MIRROR WITH FILTER TO cl-primary-to-jump.jump.config
link.mode=DESTINATION
connection.mode=INBOUND
auto.create.mirror.topics.enable=true
auto.create.mirror.topics.filters={ "topicFilters": [ {"name": "mirror_me",  "patternType": "PREFIXED",  "filterType": "INCLUDE"}, {"name": "no_mirror",  "patternType": "PREFIXED",  "filterType": "EXCLUDE"} ] }
```

The following will update the link `primary-to-jump` configuration

```shell
confluent kafka link configuration update primary-to-jump \
  --cluster [jump-cluster-id] \
  --config cl-primary-to-jump.jump.config
```

## Single topic mirror Test

***Note*** for the purpose of this guide, we already have API Keys and Secrets for each cluster stored for each cluster on the Confluent CLI enviroment, using the `api-key` command

```shell
confluent api-key store [primary-api-key] [primary-api-secret] --resource [primary-cluster-id]
confluent api-key store [jump-api-key] [jump-api-secret] --resource [jump-cluster-id]
confluent api-key store [dr-api-key] [dr-api-secret] --resource [dr-cluster-id]
```

That we can later refer for testing produce and consume from topics on each cluster `confluent api-key use [api-key to use in subsequent commands]`

```shell
## CREATE THE TOPIC
confluent kafka topic create my_test_topic --partitions 3 --cluster [primary-cluster-id]

##Create the mirror from PRIMARY
confluent kafka mirror create my_test_topic --link primary-to-jump --cluster [jump-cluster-id]

##Create the mirror from DR
confluent kafka mirror create my_test_topic --link jump-to-dr --cluster [dr-cluster-id]

## OPEN A NEW TERMINAL AND LEAVE A CONSUMER RUNNING ON DR
confluent api-key use [dr-api-key]
confluent kafka topic consume my_test_topic --cluster [dr-cluster-id]

## START A PRODUCER ON PRIMARY
confluent api-key use [primar-api-key]
confluent kafka topic produurce my_test_topic --cluster [primary-cluster-id]
```
