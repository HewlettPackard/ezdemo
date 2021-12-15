FROM node:17 AS builder
WORKDIR /app
COPY package.json ./
RUN npm install 
COPY . ./
RUN npm run build

FROM --platform=amd64 python:3-slim
LABEL Name=ezdemo Version=0.0.2
ENV PATH /root/.local/bin:$PATH

RUN apt update -y && apt install -y curl unzip openssh-client jq vim git nodejs yarn 

WORKDIR /tmp
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
  && unzip awscliv2.zip && ./aws/install
RUN curl "https://releases.hashicorp.com/terraform/1.0.4/terraform_1.0.4_linux_amd64.zip" -o terraform.zip \
  && unzip terraform.zip && mv terraform /usr/bin
### For 5.4 we have ['1.19.15', '1.20.11', '1.21.5'] for K8s versions
RUN curl -LO "https://dl.k8s.io/release/v1.20.11/bin/linux/amd64/kubectl" && install -o root -g root \
  -m 0755 kubectl /usr/local/bin/kubectl
RUN curl -LO "https://dl.google.com/go/go1.13.linux-amd64.tar.gz" && tar -C /usr/local -xzf go1.13.linux-amd64.tar.gz
RUN git clone https://github.com/jsha/minica.git && cd minica/ && /usr/local/go/bin/go build &&\
  mv minica /usr/local/bin
## clean temp files
RUN rm -rf aws* terraform.zip kubectl minica /usr/local/aws-cli/v2/current/dist/awscli/examples

WORKDIR /app
COPY --from=builder /app/build /app/build
COPY server /app/server

WORKDIR /app/server
RUN pip install --no-cache-dir -r requirements.txt
RUN chmod +x *.sh */*.sh

EXPOSE 4000
CMD python3 ./main.py 
