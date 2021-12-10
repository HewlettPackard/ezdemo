FROM --platform=amd64 python:3-slim
LABEL Name=ezdemo Version=0.0.2
RUN apt update -y && apt install -y curl unzip openssh-client jq vim
# RUN python -m pip install --upgrade pip
ENV PATH /root/.local/bin:$PATH

WORKDIR /tmp
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install
RUN curl "https://releases.hashicorp.com/terraform/1.0.4/terraform_1.0.4_linux_amd64.zip" -o terraform.zip && unzip terraform.zip && mv terraform /usr/bin
### For 5.4 we have ['1.19.15', '1.20.11', '1.21.5'] for K8s versions
RUN curl -LO "https://dl.k8s.io/release/v1.20.11/bin/linux/amd64/kubectl" && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
## clean temp files
RUN rm -rf aws* terraform.zip kubectl

COPY . /app

WORKDIR /app/server
RUN pip install --no-cache-dir -r requirements.txt
RUN chmod +x *.sh */*.sh

EXPOSE 3000
EXPOSE 3001

CMD nohup python3 ./main.py & python3 -m http.server 3000 -d ../build
