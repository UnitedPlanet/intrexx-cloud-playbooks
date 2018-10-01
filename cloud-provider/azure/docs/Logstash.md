# Collect Intrexx Logs with Logstash and FileBeat

## Installation Logstash

### Install an Java JDK

```Bash
sudo apt-get install openjdk-8-jdk
```

### Install Logstash

Check instructions [here](https://www.elastic.co/guide/en/logstash/current/installing-logstash.html).

```Bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
```

```Bash
sudo apt-get install apt-transport-https
```

```Bash
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list
```

```Bash
sudo apt-get update && sudo apt-get install logstash
```

### create first-pipline.conf at /etc/logstash/conf.d/

```YML
input {
    beats {
        port => "5044"
    }
}

# The filter part of this file is commented out to indicate that it is
# optional.
filter {
  grok {
       match => { "message" => "%{LOGLEVEL:level}%{SPACE}%{TIMESTAMP_ISO8601:timestamp}(.|\r|\n)*"}
  }
  grok {
       match => {"source" => "%{PATH}%{WORD:filename}.log"}
  }
  date {
            match => ["timestamp" , "yyyy-MM-dd'T'HH:mm:ss,SSS"]
  }
}
output {
        file {
                path => "/var/log/logstash/logstash.log"
                codec => rubydebug
        }
        file {
                path => "/var/log/intrexx/%{host}/%{filename}.log"
                codec => line { format => "%{message}"}
        }
}
```

## Installation Filebeat

* You have to download filebeat from [here](https://www.elastic.co/de/downloads/beats/filebeat).
* unzip it
* modify the filebeat/filebeat.yml

### Configure Logfiles

```YML
 # Paths that should be crawled and fetched. Glob based paths.
  paths:
    - /var/log/intrexx/*.log
    - /var/log/intrexx/search/*.log
```

### Multiline Options

```YML
  ### Multiline options

  # Mutiline can be used for log messages spanning multiple lines. This is common
  # for Java Stack Traces or C-Line Continuation

  # The regexp Pattern that has to be matched. The example pattern matches all lines starting with [
  multiline.pattern: '^[[:space:]]+|^Caused by:'

  # Defines if the pattern set under pattern should be negated or not. Default is false.
  multiline.negate: false

  # Match can be set to "after" or "before". It is used to define if lines should be append to a pattern
  # that was (not) matched before or after or as long as a pattern is not matched based on negate.
  # Note: After is the equivalent to previous and before is the equivalent to to next in Logstash
  multiline.match: after

```

### Set Output to Logstash

```YML
#-------------------------- Elasticsearch output ------------------------------
#output.elasticsearch:
  # Array of hosts to connect to.
#  hosts: ["localhost:9200"]

  # Optional protocol and basic auth credentials.
  #protocol: "https"
  #username: "elastic"
  #password: "changeme"

#----------------------------- Logstash output --------------------------------
output.logstash:
  # Ip and port from Logstash
  hosts: ["10.0.0.4:5044"]

  # Optional SSL. By default is off.
  # List of root certificates for HTTPS server verifications
  #ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]

  # Certificate for SSL client authentication
  #ssl.certificate: "/etc/pki/client/cert.pem"

  # Client Certificate Key
  #ssl.key: "/etc/pki/client/cert.key"
```

* zip and copy it to the provisioning machine
* move it to cloud-playbooks/files/filebeat.zip
* execute:

```Bash
ansible-playbook -v -i hosts filebeat.yml
```

## Elastic Search config

If you want to use Elasticsearch you have to add these line into the `first-pipeline.conf` of logstash

```YML
...
output {
    ...
    elasticsearch{}
}
```

## Adding tags to the message

### Change the configuration of filebeat (filebeat.yml)

Enable the tags line

```YML
#================================ General =====================================

# The name of the shipper that publishes the network data. It can be used to group
# all the transactions sent by a single shipper in the web interface.
#name:

# The tags of the shipper are included in their own field with each
# transaction published.
tags: ["myMessageTag"]

# Optional fields that you can specify to add additional information to the
# output.
#fields:
#  env: staging
```