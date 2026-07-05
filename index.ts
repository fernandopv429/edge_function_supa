/**
 * Roteador de Inicialização Dinâmico para o Edge Runtime
 * 
 * Como o comando de inicialização é `start --main-service /usr/services`, o Deno 
 * automaticamente procura este arquivo `index.ts` na raiz do diretório.
 * 
 * Para manter a compatibilidade com o código original das funções (onde cada uma 
 * chama `serve()` independentemente), nós redirecionamos a execução dinamicamente 
 * baseada em uma variável de ambiente (FUNCTION_NAME).
 * 
 * Assim, você pode utilizar a mesma imagem Docker no Coolify e rodar dezenas de 
 * containers independentes alterando apenas a variável FUNCTION_NAME de cada serviço.
 */

const functionName = Deno.env.get("FUNCTION_NAME") || "whatsapp-webhook";

console.log(`🚀 Iniciando a Supabase Edge Function: ${functionName}`);

try {
  // Importa dinamicamente a função desejada.
  // Como o código do usuário já chama serve(), isso iniciará o servidor na porta 8080.
  await import(`./${functionName}/index.ts`);
} catch (error) {
  console.error(`❌ Erro ao iniciar a função '${functionName}':`);
  console.error(error);
  console.error(`Certifique-se de que a pasta /${functionName} e o arquivo index.ts existem.`);
}
