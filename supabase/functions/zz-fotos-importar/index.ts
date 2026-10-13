Deno.serve(() => new Response(JSON.stringify({ ok: false, erro: "desligada" }), { status: 410, headers: { "Content-Type": "application/json" } }));
