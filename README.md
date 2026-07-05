# 🚀 Supabase Edge Functions no Coolify (Self-Hosted)

Arquitetura profissional para hospedar Supabase Edge Functions utilizando apenas Docker e Coolify, com deploys automáticos via Git Push.

## 📁 Estrutura do Projeto

```text
supabase-functions/
│
├── Dockerfile             # Configuração otimizada da imagem Docker
├── deno.json              # Configurações e dependências do Deno
├── index.ts               # Entrypoint (Roteador de Inicialização Dinâmico)
├── README.md              # Documentação da arquitetura
├── .dockerignore          # Arquivos ignorados no build
├── .gitignore             # Arquivos ignorados no Git
│
├── whatsapp-webhook/      # Função: Webhook do WhatsApp
│     └── index.ts
│
├── ai-agent/              # (Futuro) Função: Agente de IA
├── send-email/            # (Futuro) Função: Envio de E-mails
└── stripe-webhook/        # (Futuro) Função: Webhooks do Stripe
```

## 🏗️ Como a Arquitetura Funciona

Esta arquitetura resolve o problema de rodar múltiplas funções de forma escalável em containers Docker sem depender do Supabase Cloud, mantendo os arquivos intactos.

Como o comando oficial exige `start --main-service /usr/services`, o Edge Runtime busca por um `index.ts` na raiz do diretório. Criamos este arquivo para atuar como um **Roteador de Inicialização Dinâmico**. Ele lê a variável de ambiente `FUNCTION_NAME` (padrão: `whatsapp-webhook`) e importa a pasta correta no momento da inicialização.

Isso permite que você utilize **exatamente o código original do Supabase** (com `serve()`) sem nenhuma alteração!

Para escalar para dezenas de funções, a estratégia recomendada no Coolify é **Multi-Container**:
- Uma única imagem Docker é gerada via Git Push.
- No Coolify, você cria múltiplos serviços (containers) apontando para o mesmo repositório e branch.
- Em cada container, você muda apenas a variável `FUNCTION_NAME`. 
- Ex: Container A com `FUNCTION_NAME=whatsapp-webhook`, Container B com `FUNCTION_NAME=ai-agent`. 
- Isso garante total isolamento, observabilidade e escalabilidade individual por função.

## 🚀 Como Publicar no Coolify

Todo o processo é automatizado. Sem SCP, sem volumes, sem cópias manuais.

1. No painel do Coolify, vá em **Create New Resource** > **Application** > **GitHub/GitLab/Git** (repositório público ou privado).
2. Selecione o repositório e a branch (ex: `main`) onde este código está hospedado.
3. Na seção **Build Pack**, escolha **Dockerfile**.
4. Em **Port**, defina `9999`.
5. Em **Environment Variables**, adicione as variáveis de ambiente necessárias:
   - `WHATSAPP_VERIFY_TOKEN=meu_token_secreto`
   - `FUNCTION_NAME=whatsapp-webhook` (se for outra função, altere o valor).
6. Salve e clique em **Deploy**.

A partir de agora, a mágica do GitOps está ativa! Qualquer **`git push`** na branch principal fará o Coolify:
1. Receber o webhook do GitHub/GitLab.
2. Fazer o Build de uma nova imagem Docker (usando o cache do Deno).
3. Substituir o container antigo (Zero-Downtime Deployment).

## 🐳 Como Atualizar o Supabase Edge Runtime

O repositório do Supabase não utiliza a tag `latest` em suas imagens Docker para evitar quebras em produção. Por conta disso, fixamos uma versão específica (ex: `v1.74.2`) no `Dockerfile`.

Para atualizar a versão do Edge Runtime no futuro:
1. Verifique as novas versões disponíveis no [repositório oficial do Supabase Edge Runtime no GitHub](https://github.com/supabase/edge-runtime/releases).
2. Atualize a primeira linha do seu `Dockerfile`:
   `FROM supabase/edge-runtime:vX.Y.Z`
3. Faça o commit e o push das alterações. O Coolify realizará um novo build com a versão mais recente.

## ➕ Como Adicionar Novas Funções

Pensando no futuro (ex: `send-email`, `ai-agent`):

1. Crie uma nova pasta na raiz: `mkdir send-email`
2. Crie o arquivo `index.ts` dentro dela com o seu código Deno (importando o `serve(...)`).
3. Faça o commit e push: `git add . && git commit -m "feat: nova funcao send email" && git push`
4. No Coolify, duplique a aplicação atual ou adicione um novo recurso apontando para o mesmo repositório e altere a variável de ambiente para `FUNCTION_NAME=send-email`.

## 🔄 Como Atualizar uma Função

1. Edite o código (ex: `whatsapp-webhook/index.ts`) localmente.
2. Realize o commit e o push para o Git.
3. O Coolify iniciará o build automaticamente e substituirá o container em produção sem interrupção de tráfego.

## 🏷️ Como Criar Novas Versões (Release Management)

Recomenda-se utilizar **Semantic Versioning (SemVer)** e estratégias de Branching:

1. **Tags do Git:** Ao finalizar uma versão estável, crie uma tag (ex: `git tag v1.2.0`). Você pode configurar o Coolify para fazer deploy apenas quando tags específicas forem lançadas (opção baseada em Tags).
2. **Ambientes (Staging / Prod):** Utilize a branch `main` para produção e uma branch `develop` (ou `staging`) para testes. No Coolify, crie uma aplicação de "Staging" que escuta a branch `develop`.

## 🛡️ Sugestões de Arquitetura e Produção

* **Observabilidade e Logs:** O `console.log` nativo do Deno é capturado pelo daemon do Docker. No Coolify, os logs estarão visíveis instantaneamente na aba de logs da aplicação. Para produção em larga escala, considere enviar logs estruturados (JSON) para o Datadog, Axiom ou Better Stack diretamente de dentro da sua função, interceptando as requisições, ou configurando o driver de log do Docker do host.
* **Rollback:** Se uma nova versão falhar (o HEALTHCHECK no Dockerfile garante que o tráfego só será roteado se a porta 9999 responder com sucesso), o Rollback no Coolify é feito acessando o painel de deploys (aba Deployments) e clicando em "Redeploy" na versão anterior com sucesso. Como alternativa via código, basta fazer um `git revert` do commit defeituoso e dar push.
* **Organização dos Diretórios:** Conforme suas funções crescem, crie uma pasta `/shared` na raiz (ex: `/shared/supabase-client.ts`, `/shared/cors.ts`). O Deno permite importar funções locais facilmente (`import { corsHeaders } from "../shared/cors.ts"`).
* **Segurança:** 
  * Nunca versione o arquivo `.env` no Git. Configure os secrets sempre via painel do Coolify.
  * O Edge Runtime do Supabase roda sobre o Deno, o que já garante um sandbox seguro (security by default).
  * Valide a origem e os cabeçalhos de todas as requisições expostas publicamente.
* **CI/CD Avançado:** O próprio Coolify atua como pipeline contínuo. Caso necessite de testes, integre o GitHub Actions para rodar testes locais (com `deno test`) e, em caso de sucesso, dispare um deploy webhook para o Coolify via API (se preferir ter controle fino sobre o momento do deploy em vez do push direto).
