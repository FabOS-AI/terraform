FROM ubuntu:22.04

ENV GITLAB_ACCESS_TOKEN=<your.access.token> \
    OS_AUTH_URL=http://keystone-api.fec-ipa-001.gecgo.net/v3 \
    OS_REGION_NAME=RegionOne \
    OS_INTERFACE=public \
    OS_IDENTITY_API_VERSION=3

RUN mkdir /project

RUN apt update && \
    apt install -y python3-dev python3-pip jq sshpass dnsutils git && \
    pip3 install --upgrade pip && \
    pip3 install ansible

RUN ansible-galaxy collection install git+https://github.com/ansible-collections/cloud.terraform.git,957b64b4c5421a56aa6e72d52f7a8e8137880450

# Install OpenStackClient
RUN pip3 install python-openstackclient

RUN mkdir -p /etc/bash_completion.d && \
    mkdir -p ~/.config/openstack && \
    openstack complete | tee /etc/bash_completion.d/osc.bash_completion > /dev/null

RUN echo "alias os='openstack'" >> ~/.bashrc

# Install Terraform
RUN apt update && apt install -y vim curl wget gpg lsb-release netcat
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
RUN apt update && apt -y install terraform

RUN echo "alias tfi='terraform init'" >> ~/.bashrc && \
    echo "alias tfp='terraform plan'" >> ~/.bashrc && \
    echo "alias tfa='terraform apply'" >> ~/.bashrc && \
    echo "alias tfaa='terraform apply -auto-approve'" >> ~/.bashrc && \
    echo "alias tfaav='terraform apply -auto-approve -var-file=\"params.tfvars\"'" >> ~/.bashrc && \
    echo "alias tfd='terraform destroy'" >> ~/.bashrc && \
    echo "alias tfda='terraform destroy -auto-approve'" >> ~/.bashrc && \
    echo "alias tfdav='terraform destroy -auto-approve -var-file=\"params.tfvars\"'" >> ~/.bashrc

RUN echo "credentials \"gitlab.cc-asp.fraunhofer.de\" {\n  token = \"${GITLAB_ACCESS_TOKEN}\"\n}" > ~/.terraformrc

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

COPY replace_gitlab_token.sh write_ansible_vault_file.sh /root/

WORKDIR /project

ENTRYPOINT /root/replace_gitlab_token.sh; /root/write_ansible_vault_file.sh; sleep infinity
