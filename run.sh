#!/bin/bash

if [[ ! -e vars.sh ]]; then
    echo "vars.sh could not be found"
    exit -1
fi

. vars.sh

main() {
    TEST=$1

    make_checks
    
    if [[ -e $DIR/interview-tasks ]]; then
        echo "Cleanup repo..."
        rm -rf $DIR/interview-tasks
    fi

    echo "Clone repo..."
    git clone $REPO $DIR/interview-tasks
    echo "Cleanup answers..."
    rm -rf $DIR/interview-tasks/**/answers

    if [[ ! -z $TEST && ! -e $DIR/interview-tasks/$TEST ]]; then
        echo "Unknown test $TEST"
        exit -1
    fi

    if [ "$(docker ps -q -f name=^$CONTAINER$)" ]; then
        echo "Stopping old container..."
        docker stop $CONTAINER
    fi

    if [ "$(docker ps -q -a -f name=^$CONTAINER$)" ]; then
        echo "Remove old container..."
        docker rm $CONTAINER
    fi

    if [[ -e $DIR/project ]]; then 
        echo "Cleanup project dir for Code-server..."
        rm -rf $DIR/project
    fi

    mkdir $DIR/project
    if [[ -z $TEST ]]; then
        echo "Copy all tasks to project dir..."
        cp -r $DIR/interview-tasks/* $DIR/project/
    else
        echo "Copy tasks for $TEST to project dir..."
        cp -r $DIR/interview-tasks/$TEST $DIR/project/
    fi

    echo "Generate password..."
    PASS=`pwgen 16 1`

    if [[ ! -e $DIR/.config/code-server/config.yaml ]]; then
        echo "Create config for code-server..."
        mkdir -p $DIR/.config/code-server
        echo "bind-addr: 127.0.0.1:8080
auth: password
password: 123
cert: false" > $DIR/.config/code-server/config.yaml
    fi

    if [[ $PWD_LEVEL == app ]]; then
        echo "Write password to code-server's config..."
        sed -i "/^password:/c\password: $PASS" $DIR/.config/code-server/config.yaml
        sed -i "/^auth:/c\auth: password" $DIR/.config/code-server/config.yaml
    fi

    if [[ $PWD_LEVEL == basic || $PWD_LEVEL == none ]]; then
        echo "Disable app-level password in code-server's config..."
        sed -i "/^auth:/c\auth: none" $DIR/.config/code-server/config.yaml
    fi
    
    echo "Run docker container..."
    docker run -d -it --name $CONTAINER -p $BIND_IP:$BIND_PORT:8080 \
    -v "$DIR/.config:/home/coder/.config" \
    -v "$DIR/project:/home/coder/project" \
    -u "$(id -u):$(id -g)" \
    -e "DOCKER_USER=$USER" \
    $IMAGE /home/coder/project/$TEST

    sleep 1

    if [ ! "$(docker ps -q -f name=^$CONTAINER$)" ]; then
        docker logs $CONTAINER
        echo "======================================================"
        echo "Failed to run docker container, check logs please..."
        exit -1
    fi
    
    LOCAL_URL=$BIND_IP
    if [[ $BIND_IP == "0.0.0.0" ]]; then
        LOCAL_URL=127.0.0.1
    fi

    echo -n "Wait for server on http://$LOCAL_URL:$BIND_PORT ... "

    i=0
    while [[ ${STATUS_RECEIVED} != 200 ]]; do
        if [[ $i -ge 180 ]]; then
            echo "Failed to get code-server ready for $i seconds"
            exit -1
        fi
        if [[ $i -gt 0 ]]; then
            sleep 1
        fi
        STATUS_RECEIVED=$(curl -s -o /dev/null -L -w '%{http_code}' http://$LOCAL_URL:$BIND_PORT)
        echo -n "$i... "
        ((i+=1))
    done

    echo ""

    if [[ $PWD_LEVEL == basic ]]; then
        echo -n "$BASIC_USER:" > $DIR/.htpasswd
        openssl passwd -apr1 $PASS >> $DIR/.htpasswd
    fi

    PUBLIC_URL="$CODE_SERVER_SCHEME://"
    if [[ $PWD_LEVEL == basic ]]; then
        PUBLIC_URL="$PUBLIC_URL$BASIC_USER:$PASS@"
    fi
    PUBLIC_URL="$PUBLIC_URL$CODE_SERVER_DOMAIN"
    if [[ ($CODE_SERVER_SCHEME == http && $CODE_SERVER_PORT != 80) || ($CODE_SERVER_SCHEME == https && $CODE_SERVER_PORT != 443) ]]; then
        PUBLIC_URL="$PUBLIC_URL:$CODE_SERVER_PORT"
    fi

    SQL_FILES=`find $DIR -wholename "$DIR/project/**/init/*.sql" | sed -e "s|$DIR/||g"`

    if ! [[ -z $SQL_FILES ]]; then
        docker exec $CONTAINER sudo service postgresql start
        for file in $SQL_FILES; do
            docker exec $CONTAINER psql -U postgres -f "/home/coder/$file"
        done
    fi

    if [[ $PWD_LEVEL != 'none' ]]; then
        echo "============ SERVER PASSWORD =================="
        echo Password: $PASS
        echo $PUBLIC_URL/
        echo "==============================================="
    else
        echo "=================== SERVER ===================="
        echo $PUBLIC_URL/
        echo "==============================================="
    fi
}

make_checks() {
    if [[ $EUID == 0 ]]; then 
        echo "Please run as user"
        exit -1
    fi

    for cmdName in pwgen git openssl docker; do
        if [[ ! $(command -v $cmdName) ]]; then
            echo "$cmdName could not be found"
            exit -1
        fi
    done

    if [[ -z $BASIC_USER ]]; then
        BASIC_USER=coder
    fi

    if [[ -z $DIR ]]; then
        DIR=/opt/code-server
    fi

    if [[ ! -e $DIR ]]; then
        echo "$DIR doesn't exist"
        exit -1
    fi

    if [[ -z $REPO ]]; then
        echo "Empty repository URL"
        exit -1
    fi

    if [[ -z $IMAGE ]]; then
        IMAGE=code-server:local
    fi

    if [[ -z $CONTAINER ]]; then
        CONTAINER=code-server
    fi

    if [[ -z $BIND_PORT ]]; then
        BIND_PORT=8080
    fi

    if [[ -z $BIND_IP ]]; then
        BIND_IP=127.0.0.1
    fi

    if [[ -z $PWD_LEVEL ]]; then
        PWD_LEVEL=basic
    fi

    if [[ $PWD_LEVEL != 'basic' && $PWD_LEVEL != 'app' && $PWD_LEVEL != 'none' ]]; then
        echo 'Wrong PWD_LEVEL'
        exit -1
    fi

    if [[ -z $CODE_SERVER_SCHEME ]]; then
        CODE_SERVER_SCHEME=http
    fi

    if [[ $CODE_SERVER_SCHEME != http && $CODE_SERVER_SCHEME != https ]]; then
        echo "Wrong CODE_SERVER_SCHEME"
        exit -1
    fi

    if [[ -z $CODE_SERVER_DOMAIN ]]; then
        CODE_SERVER_DOMAIN=127.0.0.1
    fi

    if [[ -z $CODE_SERVER_PORT ]]; then
        if [[ $SERVER_CODE_SCHEME == http ]]; then
            CODE_SERVER_PORT=80
        fi
        if [[ $CODE_SERVER_SCHEME == https ]]; then
            CODE_SERVER_PORT=443
        fi
    fi
}

main "$@"; exit