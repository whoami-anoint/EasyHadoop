#!/bin/bash

# Function to install Java
install_java() {
    sudo apt update
    sudo apt install default-jdk default-jre -y
}

# Function to create Hadoop user and configure SSH
configure_hadoop_user() {
    sudo adduser hadoop
    sudo usermod -aG sudo hadoop
    sudo su - hadoop
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -P ""
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    chmod 640 ~/.ssh/authorized_keys
    exit
}

# Function to install OpenSSH
install_openssh() {
    sudo apt install openssh-server openssh-client -y
}

# Function to download and install Hadoop
install_hadoop() {
    HADOOP_DOWNLOAD_URL="https://archive.apache.org/dist/hadoop/common/hadoop-3.1.0/hadoop-3.1.0.tar.gz"

    cd ~
    wget "$HADOOP_DOWNLOAD_URL" -O hadoop-3.1.0.tar.gz
    tar -xzvf hadoop-3.1.0.tar.gz
    sudo mv hadoop-3.1.0 /usr/local/hadoop
    sudo mkdir /usr/local/hadoop/logs
    sudo chown -R hadoop:hadoop /usr/local/hadoop

    echo 'export HADOOP_HOME=/usr/local/hadoop
    export HADOOP_INSTALL=$HADOOP_HOME
    export HADOOP_MAPRED_HOME=$HADOOP_HOME
    export HADOOP_COMMON_HOME=$HADOOP_HOME
    export HADOOP_HDFS_HOME=$HADOOP_HOME
    export YARN_HOME=$HADOOP_HOME
    export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
    export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
    export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"' >> ~/.bashrc
    source ~/.bashrc

    JAVA_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
    echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
    echo 'export HADOOP_CLASSPATH+=" $HADOOP_HOME/lib/*.jar"' >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
    cd /usr/local/hadoop/lib
    sudo wget https://jcenter.bintray.com/javax/activation/javax.activation-api/1.2.0/javax.activation-api-1.2.0.jar
}

# Function to configure core-site.xml
configure_core_site() {
    echo "<?xml version=\"1.0\"?>
    <?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
    <configuration>
        <property>
            <name>fs.defaultFS</name>
            <value>hdfs://$1:9000</value>
        </property>
    </configuration>" | sudo tee $HADOOP_HOME/etc/hadoop/core-site.xml
}

# Function to configure hdfs-site.xml
configure_hdfs_site() {
    echo "<?xml version=\"1.0\"?>
    <?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
    <configuration>
        <property>
            <name>dfs.replication</name>
            <value>1</value>
        </property>
        <property>
            <name>dfs.namenode.name.dir</name>
            <value>file:///home/hadoop/hadoop/hadoopdata/hdfs/namenode</value>
        </property>
        <property>
            <name>dfs.datanode.data.dir</name>
            <value>file:///home/hadoop/hadoop/hadoopdata/hdfs/datanode</value>
        </property>
    </configuration>" | sudo tee $HADOOP_HOME/etc/hadoop/hdfs-site.xml
}

# Function to configure yarn-site.xml
configure_yarn_site() {
    echo "<?xml version=\"1.0\"?>
    <?xml-stylesheet type=\"text/xsl\" href=\"configuration.xsl\"?>
    <configuration>
        <property>
            <name>yarn.nodemanager.aux-services</name>
            <value>mapreduce_shuffle</value>
        </property>
        <property>
            <name>yarn.nodemanager.auxservices.mapreduce.shuffle.class</name>
            <value>org.apache.hadoop.mapred.ShuffleHandler</value>
        </property>
        <property>
            <name>yarn.resourcemanager.hostname</name>
            <value>$1</value>
        </property>
    </configuration>" | sudo tee $HADOOP_HOME/etc/hadoop/yarn-site.xml
}

# Function to configure Hadoop files
configure_hadoop_files() {
    read -p "Enter Public DNS/IP or 'localhost' for Hadoop configuration: " input_dns

    # Configure core-site.xml
    configure_core_site "$input_dns"

    # Create HDFS data directories
    sudo mkdir -p /home/hadoop/hadoop/hadoopdata/hdfs/{namenode,datanode}
    sudo chown -R hadoop:hadoop /home/hadoop/hadoop/hadoopdata/hdfs

    # Configure hdfs-site.xml
    configure_hdfs_site

    # Configure yarn-site.xml
    configure_yarn_site "$input_dns"

    hdfs namenode -format
}

# Function to start Hadoop services
start_hadoop_services() {
    start-dfs.sh
    start-yarn.sh
}

# Function to verify running components
verify_components() {
    jps
}

# Main menu
while true; do
    clear
    figlet -f big "EasyHadoop"
    echo "Creator: Abishek Kafle"
    echo "Apache Hadoop Installation and Configuration Menu"
    echo "1. Install Java"
    echo "2. Configure Hadoop User and SSH"
    echo "3. Install OpenSSH"
    echo "4. Install Hadoop"
    echo "5. Configure Hadoop Files"
    echo "6. Start Hadoop Services"
    echo "7. Verify Running Components"
    echo "8. Exit"

    read -p "Enter your choice: " choice

    case $choice in
        1) install_java ;;
        2) configure_hadoop_user ;;
        3) install_openssh ;;
        4) install_hadoop ;;
        5) configure_hadoop_files ;;
        6) start_hadoop_services ;;
        7) verify_components ;;
        8) exit ;;
        *) echo "Invalid choice. Please enter a valid option." ;;
    esac

    read -p "Press Enter to continue..."
done
