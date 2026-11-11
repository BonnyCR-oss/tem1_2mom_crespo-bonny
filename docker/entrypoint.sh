#!/bin/bash

cleanup() {
  trap '' TERM INT
  echo "Stopping services; preserving HDFS namespace and blocks"
  if [ "${HADOOP_NODE:-}" = namenode ]; then
    hdfs --daemon stop secondarynamenode || true
    hdfs --daemon stop namenode || true
    yarn --daemon stop resourcemanager || true
    mapred --daemon stop historyserver || true
    "${SPARK_HOME}/sbin/stop-master.sh" || true
    "${SPARK_HOME}/sbin/stop-history-server.sh" || true
  else
    hdfs --daemon stop datanode || true
    yarn --daemon stop nodemanager || true
    "${SPARK_HOME}/sbin/stop-slave.sh" || true
  fi
  jobs -p | xargs -r kill 2>/dev/null || true
}
trap 'cleanup; exit 0' TERM INT


if [ -n "${HADOOP_DATANODE_UI_PORT}" ]; then
  echo "Replacing default datanode UI port 9864 with ${HADOOP_DATANODE_UI_PORT}"
  sed -i "$ i\<property><name>dfs.datanode.http.address</name><value>0.0.0.0:${HADOOP_DATANODE_UI_PORT}</value></property>" ${HADOOP_CONF_DIR}/hdfs-site.xml
fi
if [ "${HADOOP_NODE}" == "namenode" ]; then
  echo "Starting Hadoop name node..."
  if [ ! -f /dfs/name/current/VERSION ]; then
    echo "First initialization of persistent NameNode"
    hdfs namenode -format -nonInteractive || exit 1
  else
    echo "Preserving existing NameNode namespace"
  fi
  hdfs --daemon start namenode
  hdfs --daemon start secondarynamenode
  yarn --daemon start resourcemanager
  mapred --daemon start historyserver
fi
if [ "${HADOOP_NODE}" == "datanode" ]; then
  echo "Starting Hadoop data node..."
  hdfs --daemon start datanode
  yarn --daemon start nodemanager
fi

if [ -n "${HIVE_CONFIGURE}" ]; then
  # Wait until block reports have completed before Hive creates session folders.
  hdfs dfsadmin -safemode wait || exit 1
  echo "Configuring Hive..."
  if ! schematool -dbType postgres -info > /tmp/hive-schema-info.log 2>&1; then
    schematool -dbType postgres -initSchema || exit 1
  fi
  # Start metastore service.
  hive --service metastore &

  # JDBC Server.
  hiveserver2 &
fi

if [ -z "${SPARK_MASTER_ADDRESS}" ]; then
  echo "Starting Spark master node..."
  # Create directory for Spark logs
  SPARK_LOGS_HDFS_PATH=/log/spark
  if ! hadoop fs -test -d "${SPARK_LOGS_HDFS_PATH}"
  then
    hadoop fs -mkdir -p  ${SPARK_LOGS_HDFS_PATH}
    hadoop fs -chmod -R 755 ${SPARK_LOGS_HDFS_PATH}/*
  fi

  # Spark on YARN
  SPARK_JARS_HDFS_PATH=/spark-jars
  if ! hadoop fs -test -d "${SPARK_JARS_HDFS_PATH}"
  then
    hadoop dfs -copyFromLocal "${SPARK_HOME}/jars" "${SPARK_JARS_HDFS_PATH}"
  fi

  "${SPARK_HOME}/sbin/start-master.sh" -h master &
  "${SPARK_HOME}/sbin/start-history-server.sh" &
else
  echo "Starting Spark slave node..."
  "${SPARK_HOME}/sbin/start-slave.sh" "${SPARK_MASTER_ADDRESS}" &
fi

echo "All initializations finished!"

# Blocking call to view all logs. This is what won't let container exit right away.
/scripts/parallel_commands.sh "scripts/watchdir ${HADOOP_LOG_DIR}" "scripts/watchdir ${SPARK_LOG_DIR}" &
wait $!
cleanup

