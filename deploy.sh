#!/bin/bash
set -e

echo "============================================="
echo "  Полное развертывание кластера 1С"
echo "  Terraform + Ansible"
echo "============================================="

echo ""
echo "===== Создание облачной инфраструктуры ====="
cd ~/VKR_IaC_1C/terraform
terraform apply -auto-approve

echo ""
echo "===== Ожидание загрузки серверов (60 сек) ====="
sleep 60

echo ""
echo "===== Настройка серверов (Ansible) ====="
cd ~/VKR_IaC_1C/ansible
ansible-playbook -i inventory.ini site.yml

echo ""
echo "============================================="
echo "  Развертывание завершено!"
echo "============================================="
