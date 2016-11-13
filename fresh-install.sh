#!/bin/bash
# Installs Neo4j on Amazon Linux.  Default installation directory is /opt/neo4j

NEO4J_INSTALL_DIR="/opt/neo4j"
NEO4J="http://neo4j.com/artifact.php?name=neo4j-community-3.0.7-unix.tar.gz"

########################################################################################################

downloadNeo4j(){
    installPath=$1
    url=$2
    wget -O "$installPath"/neo4j-community-3.0.7-unix.tar.gz "$url" &> /dev/null
    if [[ "$?" != 0 ]]; then
        echo "Neo4j failed to download from: $url"
        echo
        echo "Installation Failed! Reason: failed to download Neo4j"
        echo
        exit
    else
        echo "Neo4j was downloaded and saved to $installPath"
        echo "Extracting Neo4j tarball..."
        tar  --strip-components=1 -xzf "$installPath"/neo4j-community-3.0.7-unix.tar.gz -C "$installPath"
        echo "Cleaning up and removing Neo4j tarball..."
        rm -f "$installPath"/neo4j-community-3.0.7-unix.tar.gz
    fi
}

installNeo4j(){
    installPath=$1
    url=$2
    if [ -d "$1" ]; then
        echo "Warning: The directory $1 already exists."
        read -p "Destroy existing directory and continue with a fresh install [y/n]? " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$1"
            echo "Removed all content from existing installation directory"
            mkdir -p "$1"
            echo "Created new directory: $1"
            downloadNeo4j "$1" "$2"
        else
            echo "Installation script will now stop..."
            echo
            echo "Installation Failed! Reason: script canceled by user"
            echo
            exit
        fi
    else
        mkdir -p "$1"
        echo "Created new directory: $1"
        downloadNeo4j "$1" "$2"
    fi
}

checkJava(){
    yum update -y
    JAVA_VER=$(java -version 2>&1 | sed 's/.*version "\(.*\)\.\(.*\)\..*"/\1\2/; 1q')
    echo "Checking Java version for 1.8..."
    if [ "$JAVA_VER" -ge 18 ]; then
        echo "Found Java 1.8 or higher."
    else
        echo "Java 1.8 was not found..."
        yum remove java-1.7.0-openjdk -y
        yum install java-1.8.0 -y
        echo "Installed version Java 1.8"
        echo
        echo "Adding file entries..."
        echo "root soft nofile 40000" >> /etc/security/limits.conf
        echo "root hard nofile 40000" >> /etc/security/limits.conf
        echo 
    fi
}

setupNeo4j(){
  echo "NEO4J_ULIMIT_NOFILE=60000" >> /etc/default/neo4j
  sed -i 's/#dbms.connector.http.address=0.0.0.0:7474/dbms.connector.http.address=0.0.0.0:7474/g' "$1"/conf/neo4j.conf
  sed -i 's/# dbms.connector.bolt.address=0.0.0.0:7687/dbms.connector.bolt.address=0.0.0.0:7687/g' "$1"/conf/neo4j.conf
  sed -i 's/#dbms.logs.http.enabled=true/dbms.logs.http.enabled=true/g' "$1"/conf/neo4j.conf
}

startNeo4j(){
    sh $1/bin/neo4j start
}

setupAuthUser(){
    sleep 10
    curl -H "Content-Type: application/json" -X POST -d "{\"password\":\"${1}\"}" -u neo4j:neo4j http://localhost:7474/user/neo4j/password
    echo "Changed default Neo4j password"
}
echo -n "Enter a new password for default neo4j user and press [ENTER]: "
read password
checkJava
installNeo4j "$NEO4J_INSTALL_DIR" "$NEO4J"
setupNeo4j "$NEO4J_INSTALL_DIR"
startNeo4j "$NEO4J_INSTALL_DIR"
setupAuthUser "$password"
