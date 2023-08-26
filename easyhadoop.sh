#!/bin/bash

# Install Java
sudo apt install default-jdk default-jre -y

# Create Hadoop User and Configure Password-less SSH
sudo adduser hadoop
sudo usermod -aG sudo hadoop
sudo apt install openssh-server openssh-client -y
sudo su - hadoop <<EOF
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 640 ~/.ssh/authorized_keys
ssh localhost
EOF

# Install Apache Hadoop
sudo su - hadoop <<EOF
wget https://downloads.apache.org/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz
tar -xvzf hadoop-3.3.1.tar.gz
sudo mv hadoop-3.3.1 /usr/local/hadoop
sudo mkdir /usr/local/hadoop/logs
sudo chown -R hadoop:hadoop /usr/local/hadoop
EOF

# Configure Hadoop
sudo tee -a /home/hadoop/.bashrc > /dev/null <<EOF
export HADOOP_HOME=/usr/local/hadoop
export HADOOP_INSTALL=\$HADOOP_HOME
export HADOOP_MAPRED_HOME=\$HADOOP_HOME
export HADOOP_COMMON_HOME=\$HADOOP_HOME
export HADOOP_HDFS_HOME=\$HADOOP_HOME
export YARN_HOME=\$HADOOP_HOME
export HADOOP_COMMON_LIB_NATIVE_DIR=\$HADOOP_HOME/lib/native
export PATH=\$PATH:\$HADOOP_HOME/sbin:\$HADOOP_HOME/bin
export HADOOP_OPTS="-Djava.library.path=\$HADOOP_HOME/lib/native"
EOF

source /home/hadoop/.bashrc

# Configure Java Environment Variables
JAVA_PATH=$(which javac)
JAVA_HOME=$(readlink -f $JAVA_PATH | sed "s:/bin/javac::")
sudo sed -i "s|.*export JAVA_HOME=.*|export JAVA_HOME=$JAVA_HOME|" $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Download Javax activation file
sudo wget -P $HADOOP_HOME/lib/ https://jcenter.bintray.com/javax/activation/javax.activation-api/1.2.0/javax.activation-api-1.2.0.jar

# Configure Hadoop XML files
sudo tee $HADOOP_HOME/etc/hadoop/core-site.xml > /dev/null <<EOF
<configuration>
   <property>
      <name>fs.default.name</name>
      <value>hdfs://0.0.0.0:9000</value>
      <description>The default file system URI</description>
   </property>
</configuration>
EOF

sudo tee $HADOOP_HOME/etc/hadoop/hdfs-site.xml > /dev/null <<EOF
<configuration>
   <property>
      <name>dfs.replication</name>
      <value>1</value>
   </property>
   <property>
      <name>dfs.name.dir</name>
      <value>file:///home/hadoop/hdfs/namenode</value>
   </property>
   <property>
      <name>dfs.data.dir</name>
      <value>file:///home/hadoop/hdfs/datanode</value>
   </property>
</configuration>
EOF

sudo tee $HADOOP_HOME/etc/hadoop/mapred-site.xml > /dev/null <<EOF
<configuration>
   <property>
      <name>mapreduce.framework.name</name>
      <value>yarn</value>
   </property>
</configuration>
EOF

sudo tee $HADOOP_HOME/etc/hadoop/yarn-site.xml > /dev/null <<EOF
<configuration>
   <property>
      <name>yarn.nodemanager.aux-services</name>
      <value>mapreduce_shuffle</value>
   </property>
</configuration>
EOF

# Format the HDFS NameNode
sudo su - hadoop -c "$HADOOP_HOME/bin/hdfs namenode -format"

# Start the Apache Hadoop Cluster
sudo su - hadoop -c "$HADOOP_HOME/sbin/start-dfs.sh"
sudo su - hadoop -c "$HADOOP_HOME/sbin/start-yarn.sh"
