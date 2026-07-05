# Usa a imagem oficial do Edge Runtime do Supabase
# Nota: O Supabase não publica a tag "latest", portanto devemos especificar uma versão exata.
FROM supabase/edge-runtime:v1.74.2

# Instala curl para o HEALTHCHECK do Coolify
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Define o diretório de trabalho onde as funções ficarão
WORKDIR /usr/services

# Variáveis de ambiente com valores padrão (serão sobrescritas pelo Coolify)
ENV PORT=9999
ENV WHATSAPP_VERIFY_TOKEN="nexus_verify_token_123"
# Variável para definir qual função iniciar (útil para rodar containers separados usando a mesma imagem base)
ENV FUNCTION_NAME="whatsapp-webhook"

# Copia as configurações do Deno (para cache de dependências)
COPY deno.json ./

# Copia todas as pastas de funções para dentro da imagem
COPY . .

# Expõe a porta que o Edge Runtime utiliza (padrão 9999)
EXPOSE 9999

# HEALTHCHECK para garantir que o container reinicie caso a função trave
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:9999/ || exit 1

# Comando de inicialização solicitado
# Caso a imagem seja utilizada para múltiplas funções com um roteador dinâmico, o Edge Runtime
# vai procurar o index.ts na raiz de /usr/services
CMD ["start", "--main-service", "/usr/services"]
