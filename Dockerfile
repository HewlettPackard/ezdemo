FROM node AS builder
WORKDIR /app
COPY package.json ./
RUN npm install 
COPY . ./
RUN npm run build

FROM python:3-slim
LABEL Name=ezdemo Version=0.0.2
ENV PATH /root/.local/bin:$PATH

RUN apt update -y && apt install -y curl unzip openssh-client jq vim git nodejs yarn azure-cli \
  libcurl4-openssl-dev libssl-dev libxml2-dev gcc terraform sshpass
WORKDIR /tmp
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip && ./aws/install
RUN curl "https://releases.hashicorp.com/terraform/1.2.0/terraform_1.2.0_linux_amd64.zip" -o terraform.zip \
  && unzip terraform.zip && mv terraform /usr/bin

### For 5.4 we have ['1.19.15', '1.20.11', '1.21.5'] for K8s versions
RUN curl -LO "https://dl.k8s.io/release/v1.20.11/bin/linux/amd64/kubectl" && install -o root -g root \
  -m 0755 kubectl /usr/local/bin/kubectl
RUN curl -LO "https://go.dev/dl/go1.18.linux-amd64.tar.gz" && tar -C /usr/local -xzf go1.18.linux-amd64.tar.gz
RUN git clone https://github.com/jsha/minica.git && cd minica/ && /usr/local/go/bin/go build &&\
  mv minica /usr/local/bin
## clean temp files

RUN curl -C - -o terratag_0.1.37_linux_amd64.tar.gz -L https://github.com/env0/terratag/releases/download/v0.1.37/terratag_0.1.37_linux_amd64.tar.gz && tar -xzf terratag_0.1.37_linux_amd64.tar.gz terratag \
  && mv terratag /usr/local/bin

RUN rm -rf aws* terraform.zip go1.* terratag* kubectl minica /usr/local/go /usr/local/aws-cli/v2/current/dist/awscli/examples

WORKDIR /app
COPY --from=builder /app/build /app/build
COPY server /app/server

# Initialize providers
WORKDIR /app/server/aws
RUN terraform init -upgrade
WORKDIR /app/server/azure
RUN terraform init -upgrade

WORKDIR /app/server
RUN chmod +x *.sh */*.sh
RUN pip install --no-cache-dir -r requirements.txt
EXPOSE 3000
EXPOSE 4000
EXPOSE 8443
EXPOSE 9443
EXPOSE 8780
EXPOSE 5601
CMD python3 ./main.py 
