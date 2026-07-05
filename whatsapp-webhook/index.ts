import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const WHATSAPP_VERIFY_TOKEN =
Deno.env.get("WHATSAPP_VERIFY_TOKEN")
|| "nexus_verify_token_123";

serve(async (req) => {
  const url = new URL(req.url);
  const method = req.method;

  if (method === "GET") {

    const mode = url.searchParams.get("hub.mode");

    const token = url.searchParams.get("hub.verify_token");

    const challenge =
    url.searchParams.get("hub.challenge");

    if (
      mode === "subscribe" &&
      token === WHATSAPP_VERIFY_TOKEN
    ) {

      console.log("Webhook verificado!");

      return new Response(challenge,{
        status:200,
        headers:{
          "Content-Type":"text/plain"
        }
      });
    }

    return new Response("Forbidden",{status:403});
  }

  if(method==="POST"){

    try{

      const body=await req.json();

      console.log(JSON.stringify(body,null,2));

      // futuramente será enviado para o Supabase

      return new Response("OK",{status:200});

    }catch(e){

      console.error(e);

      return new Response("Bad Request",{status:400});

    }

  }

  return new Response(
    "Method not allowed",
    {status:405}
  );

});
