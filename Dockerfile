FROM python:3.8-slim-buster
LABEL Name=ezdemo Version=0.0.1
RUN apt update -y && apt install -y curl unzip openssh-client jq
RUN python3 -m pip install --upgrade pip
ENV PATH /root/.local/bin:$PATH

WORKDIR /tmp
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip && ./aws/install
RUN curl "https://releases.hashicorp.com/terraform/1.0.4/terraform_1.0.4_linux_amd64.zip" -o terraform.zip && unzip terraform.zip && mv terraform /usr/bin

COPY . /app

WORKDIR /app/server
RUN pip3 install -r requirements.txt
RUN chmod +x *.sh */*.sh

WORKDIR /app/build
EXPOSE 3000
EXPOSE 3001
CMD nohup python3 ../server/main.py & python3 -m http.server 3000
