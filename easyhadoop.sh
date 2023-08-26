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

# Function to install Hadoop
install_hadoop() {
    cd ~
    wget https://downloads.apache.org/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz
    tar -xvzf hadoop-3.3.1.tar.gz
    sudo mv hadoop-3.3.1 /usr/local/hadoop
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

# Function to configure Hadoop files
configure_hadoop_files() {
    sudo nano $HADOOP_HOME/etc/hadoop/core-site.xml
    # Add the core-site.xml content as mentioned in your content

    sudo mkdir -p /home/hadoop/hdfs/{namenode,datanode}
    sudo chown -R hadoop:hadoop /home/hadoop/hdfs
    sudo nano $HADOOP_HOME/etc/hadoop/hdfs-site.xml
    # Add the hdfs-site.xml content as mentioned in your content

    sudo nano $HADOOP_HOME/etc/hadoop/mapred-site.xml
    # Add the mapred-site.xml content as mentioned in your content

    sudo nano $HADOOP_HOME/etc/hadoop/yarn-site.xml
    # Add the yarn-site.xml content as mentioned in your content

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
    sudo apt install figlet -y
    clear
    figlet -f mini Creator: Abishek Kafle 
    figlet EasyHadoop -c
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
