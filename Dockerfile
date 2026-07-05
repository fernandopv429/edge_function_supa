# Usa a imagem oficial do Edge Runtime do Supabase
# Nota: O Supabase não publica a tag "latest", portanto devemos especificar uma versão exata.
FROM supabase/edge-runtime:v1.74.2

# Define o diretório de trabalho onde as funções ficarão
WORKDIR /usr/services

# Variáveis de ambiente com valores padrão (serão sobrescritas pelo Coolify)
ENV PORT=8080
ENV WHATSAPP_VERIFY_TOKEN="nexus_verify_token_123"
# Variável para definir qual função iniciar (útil para rodar containers separados usando a mesma imagem base)
ENV FUNCTION_NAME="whatsapp-webhook"

# Copia as configurações do Deno (para cache de dependências)
COPY deno.json ./

# Copia todas as pastas de funções para dentro da imagem
COPY . .

# Expõe a porta que o Edge Runtime utiliza
EXPOSE 8080

# HEALTHCHECK para garantir que o container reinicie caso a função trave
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# Comando de inicialização solicitado
# Caso a imagem seja utilizada para múltiplas funções com um roteador dinâmico, o Edge Runtime
# vai procurar o index.ts na raiz de /usr/services
CMD ["start", "--main-service", "/usr/services"]
