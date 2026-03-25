#!/bash/bash

# setup-vps.sh - Script de configuração automática para servidor Ubuntu

echo "Iniciando a configuração do servidor para o Saas-1.0..."

# 1. Atualizar o sistema
sudo apt update && sudo apt upgrade -y

# 2. Instalar dependências essenciais
sudo apt install -y curl git nginx build-essential

# 3. Instalar NVM e Node.js LTS
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts
    nvm use --lts
fi

# 4. Instalar PM2 globalmente
npm install -g pm2

# 5. Criar diretório da aplicação e ajustar permissões
sudo mkdir -p /var/www/saas-1.0
sudo chown $USER:$USER /var/www/saas-1.0

# 6. Exibir instruções finais
echo "---------------------------------------------------------"
echo "Sua VPS está quase pronta!"
echo "Agora você deve clonar seu repositório em /var/www/saas-1.0"
echo "E configurar o seu arquivo .env com as chaves reais."
echo "---------------------------------------------------------"
