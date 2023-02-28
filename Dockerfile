FROM codercom/code-server:4.10.0-debian

# common packages
RUN sudo apt-get update && sudo apt-get upgrade -y && \
    sudo apt-get install -y gcc g++ make iputils-ping httpie unzip zip wget jq mc && \
    sudo apt-get install -y python-is-python3 ruby postgresql sqlite3 && \
    echo '============== node.js and typescript ==============' && \
    curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash - && \
    sudo apt-get install -y nodejs && \
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    sudo apt-get install -y yarn && \
    sudo npm install --location=global typescript && \
    sudo npm install --location=global ts-node && \
    echo '====================== Go =========================' && \
    curl -L -O https://go.dev/dl/go1.20.1.linux-amd64.tar.gz && \
    sudo tar -C /usr/local -xzf go1.20.1.linux-amd64.tar.gz && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.profile && \
    rm go1.20.1.linux-amd64.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    go install -v golang.org/x/tools/gopls@latest && \
    go install -v github.com/go-delve/delve/cmd/dlv@latest && \
    go install -v honnef.co/go/tools/cmd/staticcheck@latest && \
    echo '================== java and kotlin ================' && \
    sudo apt-get install -y  openjdk-17-jdk && \
    curl -L "https://get.sdkman.io" | bash && \
    bash -c "source /home/coder/.sdkman/bin/sdkman-init.sh && sdk install kotlin 1.7.21" && \
    sudo apt autoremove -y && sudo apt clean && \
    echo '=============== code-server extensions ============' && \
    code-server --install-extension golang.go && \
    code-server --install-extension fwcd.kotlin && \
    code-server --install-extension vscjava.vscode-java-pack && \
    code-server --install-extension formulahendry.code-runner && \
    code-server --install-extension ms-python.python && \
    code-server --install-extension rebornix.ruby && \
    code-server --install-extension mtxr.sqltools && \
    code-server --install-extension mtxr.sqltools-driver-sqlite && \
    code-server --install-extension mtxr.sqltools-driver-pg && \
    code-server --install-extension mtxr.sqltools-driver-mysql && \
    echo '==================== postgres =====================' && \
    sudo sed -i -E 's/(peer|md5)$/trust/g' /etc/postgresql/13/main/pg_hba.conf && \
    echo '=================== dependensies ==================' && \
    wget https://github.com/fwcd/kotlin-language-server/releases/download/1.3.1/server.zip && \
    unzip server.zip -d ~/.local/ && \
    wget https://github.com/fwcd/kotlin-debug-adapter/releases/download/0.4.3/adapter.zip && \
    unzip adapter.zip -d ~/.local/ && \
    rm *.zip && \
    echo '{}' | jq '. += {"kotlin.languageServer.path": "'$HOME'/.local/server/bin/kotlin-language-server"}' | jq '. += {"kotlin.debugAdapter.path": "'$HOME'/.local/adapter/bin/kotlin-debug-adapter"}' | jq '. += {"kotlin.languageServer.enabled": true}' | jq '. += {"kotlin.debugAdapter.enabled": true}' | jq '. += {"sqltools.connections": [{"previewLimit": 50,     "server": "localhost", "port": 5432, "driver": "PostgreSQL", "name": "postgres-local", "database": "postgres", "username": "postgres", "password": ""}]}' > ~/.local/share/code-server/User/settings.json && \
    mkdir -p "$HOME/.local/share/code-server/User/globalStorage/fwcd.kotlin" && \
    echo '{"initialized":true}' > "$HOME/.local/share/code-server/User/globalStorage/fwcd.kotlin/config.json" && \
    echo '[]' | jq '. += [{"key": "ctrl+enter", "command": "sqltools.executeCurrentQuery"}]' > ~/.local/share/code-server/User/keybindings.json
