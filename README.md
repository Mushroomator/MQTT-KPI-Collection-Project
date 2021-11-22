![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)

# MQTT KPI Collection Project
Simple application stack showcasing how data could be collected (from sensors), stored and monitored using Docker, MQTT, Grafana, PostgreSQL and some simple Java Containers.

## Table of Contents
- [MQTT KPI Collection Project](#mqtt-kpi-collection-project)
  - [Table of Contents](#table-of-contents)
  - [Getting Started](#getting-started)
  - [Stack services/ components](#stack-services-components)
    - [PostgreSQL](#postgresql)
    - [PgAdmin](#pgadmin)
    - [Database-Connector](#database-connector)
      - [Variables](#variables)
    - [Grafana](#grafana)
    - [Mosquitto MQTT message broker](#mosquitto-mqtt-message-broker)
    - [MQTT-Temp-Publisher](#mqtt-temp-publisher)
    - [MinIO](#minio)
    - [Outlier Detector](#outlier-detector)
    - [Outlier Detection Webapp](#outlier-detection-webapp)
    - [MQTT-Net](#mqtt-net)
  - [Associated repos](#associated-repos)
  - [License](#license)

## Getting Started
First of all you need to have two things installed:
- [Docker](https://docs.docker.com/get-docker/): container runtime to run paravirtualized workloads
- [docker-compose](https://docs.docker.com/compose/install/): allows to deploy a stack of containers

Second, you need to clone this repository:
```bash
git clone https://github.com/Mushroomator/kpi-collection.git
```

Now move into the cloned repository
```bash
cd kpi-collection
```
and deploy the stack on your local machine
```
docker-compose up
```

This will take a while on first startup as all of the containers need to be pulled (= downloaded) from the container registry first, before they can startup. The stack will get restarted on every startup of your host system. If you do not want that have a look at the [restart](https://docs.docker.com/compose/compose-file/compose-file-v3/#restart) command in the [docker-compose.yaml](docker-compose.yaml) for available options.

Stop may stop your stack by calling `docker-compose down`.

## Stack services/ components
The following is an explanation of all the components involved and configured in the [docker-compose file](docker-compose.yaml). You may skip this section and just read the compose file if your already familar with docker-compose.

### PostgreSQL
The [official PostgreSQL docker image](https://hub.docker.com/_/postgres) is used to store KPI values as well as images. The database server listens on default port `5432` for connections. Data is inserted by the [Database-Connector](#database-connector) using [JDBC](https://docs.oracle.com/javase/8/docs/technotes/guides/jdbc/) and read by [Grafana](#grafana).

The Postgres container creates the `kpis` database with the following tables on first startup:
| Table name | Description                                                                    |
| ---------- | ------------------------------------------------------------------------------ |
| kpi        | Stores all KPI values from clients (= devices) made at a certain point in time |
| images     | Stores all images made by clients (= devices) at a certain point in time       |
| units      | Table of all available units                                                   |

The following users will also be created on first startup:
| Username      | Password | Superuser | Additional information                                           |
| ------------- | -------- | --------- | ---------------------------------------------------------------- |
| admin         | pw       | Yes       | Database owner with all privileges                               |
| grafanareader | pw       | No        | Just `read` privileges on all tables in schema `kpis`            |
| dbcon         | pw       | No        | Just `insert` privileges on tables `kpis.kpis` and `kpis.images` |

To see the actual commands that are executed before the database server starts up have take a look at [PostgreSQL/sql-scripts/](PostgreSQL/sql-scripts/). Likewise the PosgreSQL configuration can be found [here](PostgreSQL/postgresql.conf).

> Hint: Port `5432` is also exposed on the host so you may also connect to the databse using your local `pgAdmin` or `psql` installation.

### PgAdmin
PgAdmin as a web client for [PostgreSQL](#postgresql) and can be used to manage, monitor, query a Posgres server in the browser. The web server exposes port `80` on the host machine as well as in the [MQTT-Net](#mqtt-net). 

The [PostgreSQL](#postgresql) server is already pre-configured on startup for connecting to the database server as `admin` user.


### Database-Connector
Java application that subscribes to the [Mosquitto MQTT message broker](#mosquitto-mqtt-message-broker) using the MQTT wildcard `#` and therefore gets all messages sent to all topics over this broker except `$SYS` messages. All messages of a certain topic must adhere to a certain pattern for the database connector to be able to put them into the correct table. The following table shows how different messages must be structured when posted to a certain topic:


| Topic                            | Purpose                                                      | Format                                                                                               | Validation                                                                             |
| -------------------------------- | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `/kpi/<kpi-name>/<client-ID>`    | Use this topic to store numeric KPI values into the database | Byte encoded JSON which must validate against JSON schema [kpi_msg_schema.json](kpi_msg_schema.json) | Yes. The sent JSON data will be checked against the [JSON Schema](kpi_msg_schema.json) |
| `/images/<kpi-name>/<client-ID>` | Use this topic to store images into the database             | TODO                                                                                                 | TODO                                                                                   |

> Hint: You may use [JSON Schema Tool](https://jsonschematool.ew.r.appspot.com/) or [JSON Schema Lint](https://jsonschemalint.com/) to validate your JSON against the JSON Schema.

#### Variables
| Name          | Description                                                                             | Example    |
| ------------- | --------------------------------------------------------------------------------------- | ---------- |
| `<kpi-name>`  | Name of the KPI                                                                         | engineTemp |
| `<client-ID>` | Unique ID according to the MQTTv5 standard. **MUST** be **exactly 10 characters** long! | temp-pub01 |

### Grafana
Grafana is used to monitor and visualize the KPIs stored in [PostgreSQL](#postgresql). The grafana container exposes its web GUI on port `3000`.

You can login to Grafana with the default credentials:
| Username | Password |
| -------- | -------- |
| admin    | admin    |

Grafana comes already preconfigured (= "provisioning" in Grafana terms) with the PostgreSQL database as a datasource as well as a dashboard to monitor temperatures. Take a look at [Grafana folder](Grafana/) to see the configuration files necessary to provision Grafana. 

### Mosquitto MQTT message broker
The official [Eclipse Mosquitto docker image](https://hub.docker.com/_/eclipse-mosquitto) is used as a MQTT message broker. As the message broker exposes port `1883` within the [MQTT Network](#mqtt-net) and on the host you may install [mosquitto_sub](https://mosquitto.org/man/mosquitto_sub-1.html) and subscribe e.g. to all sent MQTT messages using `mosquitto_sub -v -h localhost -p 1883 -t "#"`. This will subscribe to all messages sent to the message broker and print the message topic as well as the payload on screen.

### MQTT-Temp-Publisher
A simple Java application which generates mock temperature data and sends it to the [MQTT message broker](#mosquitto-mqtt-message-broker) every `x` seconds. This MQTT clients just serves as an simple example of a sensor which is measuring data.

> Further information can be found in the repository for the [MQTT-Temp-Publisher](https://github.com/Mushroomator/MQTT-Temp-Publisher). 

### MinIO
[MinIO](https://min.io/) is an S3 compliant object storage which is used here to store images made by the Raspberry Pi camera and images processed/ created by the AI models. Additionially it will serve those images via HTTP. The MinIO API is made available on port `9000` and the management GUI is served on port `9001`. 

You can login to the GUI (and private buckets) using the following credentials: 
| Username/ Access-Key | Password/ Secret-Key |
| -------------------- | -------------------- |
| admin                | alongerpw            |

On first startup of the container two buckets will be created:
| Bucket        | Policy   | Purpose                                                     |
| ------------- | -------- | ----------------------------------------------------------- |
| model-images  | download | Store the images from AI model downscaled and reconstructed |
| camera-images | download | Store images made by the RaspberryPi camera                 |

### Outlier Detector
Python program which processes a picture taken by the RaspberryPi camera, runs it through an AI model (= auto encoder) and the determines whether the image is an *outlier* (= different from the images the model has been trained with) or not. Once the model has calculated a result the input image as well as the reconstructed image are uploaded to [Min.io](#minio) and the URLs/ paths to those images as well as other information such as *quadratic error* and *timestamp* will be sent to the [Outlier Detection Webapp](#outlier-detection-webapp) so it can visualize the results.

### Outlier Detection Webapp
Webapp to show and monitor outliers detected by [Outlier-Detector](#outlier-detector). The backend runs a WebSocket server listening for results from the [Outlier-Detector](#outlier-detector) on port `5000`.

### MQTT-Net
Docker user-defined network which all of above services are connected to. This network is separate from you host network and allows i. a. to use domain names names instead of IP addresses making use of docker's service discovery.  

## Associated repos
Here are the links to all the associated repositories:
- [MQTT Temp Publisher](https://github.com/Mushroomator/MQTT-Temp-Publisher)
- [MQTT KPI Publisher](https://github.com/Mushroomator/MQTT-KPI-Publisher)
- [MQTT Database Connector](https://github.com/Mushroomator/MQTT-Database-Connector)
- [Outlier Detection Webapp](https://github.com/Mushroomator/Outlier-Detection-Webapp)
- [Outlier Detector](#) TODO

## License
Copyright 2021 Thomas Pilz

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

[https://www.apache.org/licenses/LICENSE-2.0](https://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.