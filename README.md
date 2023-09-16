# ETCD

ETCD es un componente esencial en la mayoría de las infraestructuras modernas, especialmente en entornos de contenedorización y orquestación como Kubernetes. En este post, exploraremos cómo funciona etcd, cómo configurar un clúster y cómo simular problemas comunes para fortalecer tu comprensión.

## ¿Qué es etcd?

etcd es un servicio de almacenamiento distribuido altamente confiable y consistente que se utiliza para mantener la configuración y los datos críticos para el funcionamiento de un clúster de máquinas. Desarrollado por CoreOS, ahora parte de Red Hat, etcd utiliza el algoritmo Raft para garantizar la tolerancia a fallos y la consistencia en el clúster.

# Funcionamiento de etcd

## Almacenamiento de Datos

etcd funciona como una base de datos clave-valor, donde los datos se almacenan en pares de clave-valor distribuidos. Puedes pensar en él como un gran diccionario distribuido en el que los valores están asociados a claves únicas.

## Tolerancia a Fallos

etcd se ejecuta en un clúster de máquinas y utiliza el algoritmo Raft para mantener la consistencia de datos incluso en situaciones de fallos. Raft asegura que un líder se elija para gestionar las operaciones de escritura, y las demás máquinas siguen este líder, replicando los datos de manera consistente.

## API HTTP
Una de las características notables de etcd es su interfaz HTTP/JSON. Esto significa que puedes interactuar con etcd utilizando solicitudes HTTP, lo que lo hace fácilmente accesible para aplicaciones y herramientas. Esto es particularmente útil para sistemas como Kubernetes, que utilizan etcd para mantener su estado.

# Creando un Clúster etcd con Docker Compose

Docker Compose es una herramienta que permite definir y ejecutar aplicaciones Docker multi-contenedor de manera sencilla. Utilizaremos Docker Compose para crear un clúster etcd con tres nodos. Asumiremos que ya tienes Docker y Docker Compose instalados en tu sistema.

## Configuración de Docker Compose
Primero, crea un archivo llamado docker-compose.yml en el directorio de tu elección. Aquí hay un ejemplo de cómo podría ser la configuración:

[docker-compose-etcd-cluster](./docker-compose.yaml)

Este archivo de configuración crea tres servicios etcd (ironman, thor, deadpool) utilizando la imagen oficial de etcd v3.5.0. Cada servicio se configura con una serie de parámetros importantes, incluyendo el nombre del nodo, las URL de comunicación entre pares y las URL de comunicación del cliente.

## Iniciar el Clúster etcd
Abre una terminal y navega al directorio donde tienes tu archivo docker-compose.yml. Luego, ejecuta el siguiente comando para iniciar el clúster etcd:

```bash
docker-compose up -d
```

OR

```bash
./runner.sh up_env
```


## Verificar el Clúster etcd
Para verificar si el clúster etcd está funcionando correctamente, puedes ejecutar el siguiente comando en una terminal:

```bash
# 1. docker-compose ps

# 2. docker exec -it client sh
# 3. etcdctl member list -w table

# OR

# 2. ./ctl.sh member list -w table
```

# Simulación de Problemas Comunes

La simulación de problemas comunes en un clúster etcd te permitirá comprender mejor cómo se comporta en situaciones adversas y cómo se recuperan de estos eventos. A continuación, se detallan algunas de estas simulaciones:

## Fallo del Nodo Líder

**Objetivo**: Simularemos un escenario en el que el nodo líder del clúster etcd falla y observaremos cómo se elige un nuevo líder.

1. Detén uno de los nodos líderes de tu clúster etcd utilizando el siguiente comando:
    ```bash
    docker-compose stop ${NODE_LEADER}
    ```

2. Monitorea los registros de los otros nodos para observar cómo uno de ellos es elegido como el nuevo líder.
    ```bash
    docker-compose logs -f
    ```

3. Utiliza comandos etcdctl desde otro nodo para confirmar quién es el nuevo líder y verificar que el clúster todavía es funcional.
    ```bash
    etcdctl endpoint status -w table
    ```

OR

```bash
./runner.sh failed_leader
```

## Reducción de Quórum

**Objetivo**: Simularemos un escenario en el que algunos nodos se desconectan temporalmente del clúster, lo que provoca una reducción de quórum y conflictos de liderazgo.

1. Detén uno o más nodos del clúster etcd de la siguiente manera:
    ```bash
    docker-compose stop ${NODE}
    ```

2. Observa cómo los nodos restantes intentan mantener la coherencia y resuelven los conflictos de liderazgo.
    ```bash
    docker-compose logs -f
    ```

3. Reinicia los nodos que se detuvieron previamente
    ```bash
    docker-compose start ${NODE}
    ```

4. Verifica cómo el clúster se recupera y vuelve a alcanzar un quórum
    ```bash
    docker-compose logs -f
    ```

## Escalabilidad

**Objetivo**: Agregaremos nuevos nodos al clúster etcd para comprender cómo se reequilibra la distribución de datos y el liderazgo.

1. Agrega un nuevo nodo al clúster etcd en el archivo docker-compose.yml. Copia y pega una de las definiciones de servicio existentes y cambia el nombre y los puertos para evitar conflictos.

2. Ejecuta el siguiente comando para recrear y reiniciar el clúster con el nuevo nodo:
    ```bash
    docker-compose up -d
    ```

3. Utiliza etcdctl desde cualquier nodo para verificar cómo se distribuyen los datos en el nuevo nodo y cómo el clúster equilibra la carga.
    ```bash
    etcdctl endpoint status -w table
    ```

## Pérdida de Datos

**Objetivo**: Simularemos la pérdida accidental de datos en un nodo etcd y utilizaremos las instantáneas automáticas de etcd para restaurar esos datos a partir de una copia de seguridad previa.

1. Realizar una instantánea de etcd ANTES de eliminar los datos: Antes de eliminar cualquier dato crítico, toma una instantánea de etcd. Ejecuta el siguiente comando en un nodo del clúster:
    ```bash
    # Esto crea una copia de seguridad de los datos tal como están en ese momento.
    docker exec -it ${NODE} etcdctl snapshot save /data/snapshot.db
    ```


2. Eliminar los datos del nodo: Una vez que hayas tomado la instantánea, procede a eliminar la clave o los datos específicos como lo deseabas, utilizando etcdctl desde el nodo seleccionado:
    ```bash
    docker exec -it ${NODE} etcdctl del ${KEY}
    ```

2. Confirmar la pérdida de datos: Ejecuta consultas etcdctl para confirmar que los datos se han eliminado correctamente. 

3. Restaurar los datos desde la instantánea: Si deseas recuperar los datos eliminados, puedes utilizar la instantánea que tomaste antes de la eliminación. Ejecuta el siguiente comando:
    ```bash
    # Esto restaurará los datos a partir de la instantánea que tomaste ANTES de la eliminación.
    docker exec -it ${NODE} etcdctl snapshot restore /data/snapshot.db --data-dir /data
    ```

4. Verificar la restauración: Utiliza etcdctl nuevamente para verificar que los datos se hayan restaurado correctamente a partir de la instantánea.

# Conclusión
etcd es una pieza crítica en la infraestructura moderna, y comprender su funcionamiento, la configuración de clústeres y la resolución de problemas es esencial para garantizar la estabilidad de tus sistemas. Mediante la simulación de problemas comunes, puedes adquirir experiencia práctica y mejorar tu habilidad para gestionar entornos con etcd.