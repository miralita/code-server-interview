FROM codercom/code-server:latest

RUN curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash - && \
    sudo apt-get install -y gcc g++ make iputils-ping httpie nodejs && \
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    sudo apt-get install -y yarn && \
    sudo apt-get upgrade -y && \
    sudo npm install --location=global typescript

RUN curl -L -O https://go.dev/dl/go1.18.3.linux-amd64.tar.gz && \
    sudo tar -C /usr/local -xzf go1.18.3.linux-amd64.tar.gz && \
    echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.profile && \
    rm go1.18.3.linux-amd64.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin && \
    go install -v golang.org/x/tools/gopls@latest && \
    go install -v github.com/go-delve/delve/cmd/dlv@latest && \
    code-server --install-extension golang.go

RUN sudo apt install -y unzip zip openjdk-11-jre-headless && \
    curl -L "https://get.sdkman.io" | bash && \
    bash -c "source /home/coder/.sdkman/bin/sdkman-init.sh && sdk install kotlin" && \
    code-server --install-extension fwcd.kotlin && \
    code-server --install-extension vscjava.vscode-java-pack && \
    code-server --install-extension formulahendry.code-runner
