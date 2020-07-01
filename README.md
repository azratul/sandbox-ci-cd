# GITLAB & MICROK8S

Proyecto para levantar un sandbox de Continuous Integration & Continuous Delivery con microk8s, docker registry y gitlab.

Se recomienda un mínimo de 4 Cores de CPU y 16 GB de RAM.

- DNS:
> Levantar el Docker Registry

`cd portus && docker-compose up -d`

* Crear admin y usuario de gitlab


- Microk8s:
> Generar el CA Cert y Token que será solicitado en Gitlab

`/vagrant/gitlab.sh`


- Gitlab
> Ingresar por browser

* Crear root user
* Ir a: [Admin Area -> Settings -> Network](http://gitlab.magi-system.com/admin/application_settings/network)
* En "Outbound requests", clickear "Allow requests to the local network from web hooks and services" y "Save changes"
* Ir a: [Admin Area -> Kubernetes](http://gitlab.magi-system.com/admin/clusters)
* Ingresar la configuración de microk8s/.gitlab.conf
* Instalar "Helm"
* Instalar "Gitlab runner"
* Agregar las variables $DOCKER_LOGIN y $DOCKER_PASSWORD a los settings de CI/CD, con los datos ingresados al levantar el Docker Registry

Enjoy!
