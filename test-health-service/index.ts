import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
serve((req) => new Response("Forbidden", {status: 403}));
