# SANDBOX WITH GITLAB

Lo único que necesitas tener instalado en tu equipo es Vagrant, que puedes descargar e instalar de [aquí](https://www.vagrantup.com/downloads).


## ARCH USERS

`pacman -S vagrant`

`vagrant plugin install vagrant-libvirt`


## Up & Running

1. Obtener el proyecto del repositorio

    `git clone https://github.com/azratul/sandbox-ci-cd`

2. Ingresar a la carpeta donde se ubica el proyecto

    `cd sandbox-ci-cd/gitlab`

3. Iniciar la VM. La primera vez que lo ejecutes en tu equipo la máquina será aprovisionada automáticamente con todos los paquetes necesario, por lo cual puede tardar varios minutos

    `vagrant up`

4. Entrar a la web

    `http://gitlab.magi-system.com`

5. That's all! Now u'r ready to go


## Optional

1. Configurar el clúster de Microk8s.
- Ir a: [Admin Area -> Settings -> Network](http://gitlab.magi-system.com/admin/application_settings/network)
- En "Outbound requests", clickear "Allow requests to the local network from web hooks and services" y "Save changes"
- Ir a: [Admin Area -> Kubernetes](http://gitlab.magi-system.com/admin/clusters)
