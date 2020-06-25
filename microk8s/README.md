# SANDBOX WITH MICROK8S, OPENFAAS & DOCKER

Lo único que necesitas tener instalado en tu equipo es Vagrant, que puedes descargar e instalar de [aquí](https://www.vagrantup.com/downloads).


## ARCH USERS

`pacman -S vagrant`

`vagrant plugin install vagrant-libvirt`


## Up & Running

1. Obtener el proyecto del repositorio

    `git clone https://github.com/azratul/sandbox-ci-cd`

2. Ingresar a la carpeta donde se ubica el proyecto

    `cd sandbox-ci-cd/microk8s`

3. Iniciar la VM. La primera vez que lo ejecutes en tu equipo la máquina será aprovisionada automáticamente con todos los paquetes necesario, por lo cual puede tardar varios minutos

    `vagrant up`

4. Entrar a la máquina creada

    `vagrant ssh`

5. Esperar aproximadamente 90s para que todos los servicios del k8s arranquen y ejecutar el siguiente comando

    `kubectl get all --all-namespaces`

6. That's all! Now u'r ready to go


## Optional

1. Luego del aprovisionamiento de la máquina la primera vez que la corres, encontrarás 2 archivos en la raíz del proyecto: .tokens y .kube-config. El primer archivo contiene la contraseña para acceder desde tu host a openfaas y el archivo .kube-config contiene la configuración para acceder al clúster de k8s desde tu host.

2. Si quieres integrar tu microk8s con Gitlab para el CI/CD, hay un script en microk8s/gitlab.sh que se encarga de obtener todo lo que necesitas para poder configurarlo fácilmente. Desde dentro de la VM ejecutar:

	`/vagrant/gitlab.sh && cat .gitlab.conf`

3. Para agregar tu DNS server a tu resolv, debes ejecutar el siguiente comando como root:

	`printf "search TU.DNS\nnameserver IP.DE.TU.DNS\n" > /etc/resolv.conf`

4. Si algo no va bien con el DNS Server, consulta documentación [aquí](https://www.linuxtechi.com/install-configure-bind-9-dns-server-ubuntu-debian/)

	Para agregar un nuevo DNS(en este caso será de Gitlab), modifica los siguientes archivos:

	- /etc/bind/forward.<YOUR>.<DNS> agrega gitlab IN A <YOUR.GIT.LAB.IP>
	- /etc/bind/reverse.<YOUR>.<DNS> <255>.<255> IN   PTR  gitlab.<YOUR>.<DNS>.

	Ejemplo:
	/etc/bind/forward.domain.com: gitlab IN A 192.168.121.75
	/etc/bind/reverse.domain.com: 121.75 IN PTR gitlab.domain.com