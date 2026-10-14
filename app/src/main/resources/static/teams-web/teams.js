/* ---------- TEAM'S (pacote único) ---------- */
var TMX_BASE=(function(){try{return String(document.currentScript&&document.currentScript.src||'').replace(/[^\/]*$/,'');}catch(e){return '';}})();
const TMX_CSS=":host{--laranja:#FE4901;--laranjaAc:#FF9200;--laranjaTx:#D43D00;--laranjaSv:#FFF1EA;--laranjaCl:#FFD0B5;\n  --ink:#111114;--ink2:#1C1C1F;--grafite:#3F3F46;--apoio:#52525B;--apagado:#6B6B72;--nevoa:#A1A1AA;\n  --pagina:#FFFFFF;--superf:#FAFAFA;--superf2:#F4F4F5;--borda:#E4E4E7;--bordaF:#D4D4D8;\n  --verde:#1B7A44;--verdeSv:#DCF0E4;--vermelho:#C0392B;--vermelhoSv:#F8DAD6;--ambar:#B25E09;--ambarSv:#F6E2C8;--azul:#3A5A8C;--azulSv:#E5EAF2;--roxo:#6D4AA0;--roxoSv:#F0EAF8;\n  --grad:linear-gradient(135deg,var(--laranja),var(--laranjaAc));\n  --disp:'Space Grotesk',sans-serif;--corpo:'Geist',system-ui,-apple-system,Segoe UI,sans-serif;\n  --sm:0 1px 2px rgba(17,17,20,.06);--md:0 8px 24px rgba(17,17,20,.08);--r:14px;}\n*{box-sizing:border-box}\nbutton{font-family:inherit;cursor:pointer;color:inherit}\n:focus-visible{outline:2px solid var(--laranjaTx);outline-offset:2px}\n.av{border-radius:10px;display:grid;place-items:center;font-weight:700;color:#fff;background:var(--grad);flex:none}\n.miniB{border:1px solid var(--bordaF);background:var(--pagina);border-radius:8px;padding:5px 10px;font-size:11px;font-weight:600}\n.tela{padding:20px 24px;overflow-y:auto;flex:1}\n.tela h1{font-family:var(--disp);font-size:23px;margin:0 0 3px}\ntable{width:100%;border-collapse:collapse;font-size:12.5px}\n.tbwrap{overflow-x:auto;border:1px solid var(--borda);border-radius:var(--r);background:var(--pagina)}\nth,td{text-align:left;padding:9px 12px;border-bottom:1px solid var(--superf2);white-space:nowrap}\nth{background:var(--superf);font-size:10px;letter-spacing:.05em;text-transform:uppercase;color:var(--apagado)}\n.pill{font-size:10px;font-weight:700;padding:2px 8px;border-radius:999px}\n.pill.ok{background:var(--verdeSv);color:var(--verde)}\n.pill.pend{background:var(--ambarSv);color:var(--ambar)}\n.pill.falta{background:var(--vermelhoSv);color:var(--vermelho)}\n.waweb{display:grid;grid-template-columns:340px minmax(0,1fr);flex:1;min-height:0}\n.walist{border-right:1px solid var(--borda);display:flex;flex-direction:column;min-height:0;background:var(--pagina)}\n.bt-assumir{background:var(--grad);color:#fff;border:0;border-radius:9px;padding:7px 13px;font-size:12px;font-weight:700}\n.walist .srch{padding:10px;border-bottom:1px solid var(--borda);flex:none}\n.walist .srch input{width:100%;background:var(--superf2);border:1px solid var(--borda);border-radius:999px;padding:8px 13px;font-size:12px;outline:0;font-family:inherit}\n.walist .rl{overflow-y:auto;flex:1;min-height:0}\n.waconv{display:flex;gap:11px;padding:11px 13px;border-bottom:1px solid var(--superf2);cursor:pointer;align-items:center}\n.waconv:hover{background:var(--superf)}\n.waconv .av{width:42px;height:42px;font-size:13px}\n.waconv .nm{font-weight:600;font-size:13px;display:flex;justify-content:space-between;gap:6px;align-items:center}\n.wachat{display:flex;flex-direction:column;min-height:0;background:var(--tmxFundoConversa)}\n.wa-head{background:#0B3D2E;color:#fff;display:flex;align-items:center;gap:9px;padding:9px 12px;flex:none}\n.wa-head .avc{width:30px;height:30px;border-radius:999px;background:rgba(255,255,255,.2);display:grid;place-items:center;font-size:10.5px;font-weight:700;flex:none}\n.wa-head .nm{flex:1;min-width:0}\n.wa-head .nm b{font-size:13px;display:block;line-height:1.15;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.wa-head .nm span{font-size:10.5px;opacity:.82}\n.wa-msgs{flex:1;overflow-y:auto;padding:14px 12px;display:flex;flex-direction:column;gap:2px;background:var(--tmxFundoConversa);background-image:radial-gradient(rgba(17,17,20,.03) 1px,transparent 0);background-size:15px 15px}\n.wa-b{max-width:84%;padding:9px 11px;border-radius:13px;font-size:12.5px;line-height:1.5;white-space:pre-line;box-shadow:var(--sm)}\n.wa-b.ag{align-self:flex-end;background:#1c1c1e;color:#fff;border-bottom-right-radius:4px}\n.wa-b.cl{align-self:flex-start;background:#fff;border:1px solid var(--borda);color:var(--ink);border-bottom-left-radius:4px}\n.wa-t{font-size:10px;color:var(--apagado);margin:2px 3px 9px}\n.wa-t.ag{align-self:flex-end}\n.wa-t.cl{align-self:flex-start}\n.wa-doc{display:flex;gap:6px;align-items:center;background:rgba(255,255,255,.14);border-radius:7px;padding:5px 7px;margin-bottom:4px;font-size:10.5px}\n.wa-b.cl .wa-doc{background:var(--superf2)}\n.wa-doc .fi{background:var(--vermelhoSv);color:var(--vermelho);font-weight:700;font-size:8.5px;padding:3px 5px;border-radius:4px}\n.wa-comp{display:flex;align-items:center;gap:9px;padding:11px 12px;border-top:1px solid var(--borda);background:#fff;flex:none}\n.wa-comp .pl{width:38px;height:38px;border-radius:999px;border:1px solid var(--bordaF);background:#fff;display:grid;place-items:center;color:var(--apoio);flex:none;cursor:pointer;font-size:20px}\n.wa-comp .pl svg{width:17px;height:17px;fill:none;stroke:currentColor;stroke-width:2;stroke-linecap:round;stroke-linejoin:round}\n.wa-comp input{flex:1;border:1px solid var(--bordaF);border-radius:999px;padding:11px 15px;font-size:12.5px;font-family:inherit;outline:0;background:var(--superf2)}\n.wa-comp .snd{width:40px;height:40px;border-radius:999px;background:var(--grad);color:#fff;border:0;display:grid;place-items:center;font-size:15px;flex:none;cursor:pointer}\n.tm-rl .tm-sec button{font-size:11px;font-weight:700}\n.tm-tools{display:flex;gap:6px;padding:8px 12px 0;background:#fff;border-top:1px solid var(--borda);overflow-x:auto;flex:none;scrollbar-width:thin}\n.tm-tools button{flex:none;border:1px solid var(--borda);background:#fff;border-radius:999px;padding:5px 11px;font-size:11.5px;font-weight:600;color:var(--grafite);cursor:pointer;font-family:inherit;white-space:nowrap}\n.tm-tools button:hover{border-color:var(--laranja);color:var(--laranjaTx);background:var(--laranjaSv)}\n.tm-tools+.wa-comp{border-top:0}\n.tm-cli{display:flex;gap:10px;align-items:center;border:1px solid var(--borda);background:#fff;color:var(--ink);border-radius:10px;padding:8px 10px;margin-top:5px;cursor:pointer;min-width:220px}\n.tm-cli:hover{border-color:var(--laranja)}\n.tm-cli-ic{width:32px;height:32px;border-radius:8px;background:var(--laranjaSv);color:var(--laranjaTx);display:grid;place-items:center;flex:none}\n.tm-cli b{display:block;font-size:12.5px}\n.tm-cli span{font-size:11px;color:var(--apagado)}\n.tm-sis{background:var(--superf2)!important;color:var(--apoio)!important;font-weight:600}\n.tm-aviso.urgente{border-left:4px solid var(--vermelho)}\n.tm-aviso.visto{border-left:4px solid var(--ambar)}\n.tm-avtag{display:inline-block;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.05em;border-radius:999px;padding:2px 8px;margin-bottom:5px}\n.tm-avtag.u{background:var(--vermelhoSv);color:var(--vermelho)}\n.tm-avtag.v{background:var(--ambarSv);color:var(--ambar)}\n.tm-lig{position:fixed;inset:0;background:rgba(10,10,12,.55);display:grid;place-items:center;z-index:95}\n.tm-ligbox{width:min(760px,94vw);background:#121214;color:#fff;border-radius:18px;padding:18px;display:flex;flex-direction:column;gap:14px;box-shadow:var(--md)}\n.tm-ligbox.tm-toc{width:min(380px,92vw);align-items:center;text-align:center;padding:28px 22px;gap:8px}\n.tm-toc b{font-size:17px;margin-top:8px}\n.tm-toc>span{font-size:12.5px;color:#b9b9be}\n.tm-ligtop{display:flex;justify-content:space-between;align-items:center}\n.tm-ligtop b{font-size:14px}\n.tm-ligtop span{font-size:12px;color:#b9b9be;font-variant-numeric:tabular-nums}\n.tm-ligpal{position:relative;display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:10px;min-height:300px}\n.tm-tile{position:relative;background:#1d1d20;border-radius:12px;overflow:hidden;display:grid;place-items:center;min-height:240px}\n.tm-tile video{width:100%;height:100%;object-fit:cover;position:absolute;inset:0}\n.tm-tile span{position:absolute;left:10px;bottom:8px;font-size:12px;font-weight:600;background:rgba(0,0,0,.45);padding:2px 8px;border-radius:999px}\n.tm-tile.vazio{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:10px}\n.tm-tile.vazio span{position:static;background:none}\n.tm-eu-v{position:absolute;right:10px;bottom:10px;width:150px;height:110px;object-fit:cover;border-radius:10px;border:2px solid #fff;background:#000}\n.tm-ligctl{display:flex;gap:10px;justify-content:center;flex-wrap:wrap;margin-top:6px}\n.tm-lb{border:0;border-radius:999px;padding:10px 18px;font-size:13px;font-weight:700;background:#2e2e31;color:#fff;cursor:pointer;display:flex;gap:7px;align-items:center;font-family:inherit}\n.tm-lb.on{background:#fff;color:#121214}\n.tm-lb.ok{background:#1f9d55}\n.tm-lb.no{background:#d93025}\n.tm-perfil{display:flex;align-items:center;gap:12px;padding:14px 14px 12px;background:linear-gradient(135deg,#fff 30%,var(--laranjaSv) 160%);border-bottom:1px solid var(--borda);flex:none}\n.tm-av{width:44px;height:44px;border-radius:999px;display:grid;place-items:center;color:#fff;font-weight:700;font-size:13px;position:relative;flex:none}\n.tm-av img{width:100%;height:100%;object-fit:cover;border-radius:inherit}\n.tm-av svg{width:20px;height:20px}\n.tm-av.g{width:48px;height:48px;font-size:15px;box-shadow:0 0 0 3px #fff,0 0 0 4px var(--laranjaCl)}\n.tm-perfc{flex:1;min-width:0;display:flex;flex-direction:column;gap:1px}\n.tm-perfc b{font-family:var(--disp);font-size:14.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.tm-perfc>span{font-size:11px;color:var(--apagado);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.tm-stsel{display:inline-flex;align-items:center;gap:6px;align-self:flex-start;margin-top:5px;background:#fff;border:1px solid var(--borda);border-radius:999px;padding:2px 4px 2px 9px;box-shadow:var(--sm)}\n.tm-stsel i{width:8px;height:8px;border-radius:999px;flex:none}\n.tm-stsel select{border:0;background:transparent;font-size:11px;font-weight:600;font-family:inherit;outline:0;cursor:pointer;padding:2px 0}\n.tm-novo{width:40px;height:40px;flex:none;border-radius:999px;border:0;background:var(--grad);color:#fff;font-size:21px;font-weight:700;box-shadow:var(--md);cursor:pointer}\n.tm-abas2{display:grid;grid-template-columns:repeat(4,1fr);border-bottom:1px solid var(--borda);flex:none;background:#fff}\n.tm-abas2 button{border:0;border-right:1px solid var(--borda);background:#fff;color:var(--apoio);font-size:11.5px;font-weight:700;padding:13px 2px;font-family:inherit;display:flex;align-items:center;justify-content:center;gap:5px;cursor:pointer;min-width:0}\n.tm-abas2 button:last-child{border-right:0}\n.tm-abas2 button:hover{background:var(--superf)}\n.tm-abas2 button.on{background:var(--ink);color:#fff}\n.tm-abas2 i,.tm-subs i{font-style:normal;background:var(--laranja);color:#fff;border-radius:999px;font-size:9.5px;padding:1px 6px;font-weight:700}\n.tm-subs{display:flex;padding:0 8px;border-bottom:1px solid var(--borda);flex:none;background:#fff}\n.tm-subs button{flex:1;border:0;background:transparent;padding:11px 4px 9px;font-size:12px;font-weight:600;color:var(--apagado);border-bottom:2px solid transparent;font-family:inherit;display:flex;gap:5px;align-items:center;justify-content:center;cursor:pointer;white-space:nowrap}\n.tm-subs button:hover{color:var(--ink)}\n.tm-subs button.on{color:var(--ink);border-bottom-color:var(--laranja)}\n.tm-busca2{padding:10px 12px;flex:none;background:#fff}\n.tm-busca2 input{width:100%;border:1px solid var(--borda);background:var(--superf2) url(\"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 24 24' fill='none' stroke='%2396A0AC' stroke-width='2.4' stroke-linecap='round'%3E%3Ccircle cx='11' cy='11' r='7'/%3E%3Cpath d='M20 20l-3.5-3.5'/%3E%3C/svg%3E\") no-repeat 12px center;border-radius:10px;padding:9px 12px 9px 34px;font-size:12.5px;font-family:inherit;outline:0}\n.tm-busca2 input:focus{border-color:var(--laranja);background-color:#fff}\n.tm-rl{flex:1;overflow-y:auto;background:#fff}\n.tm-it{display:flex;gap:11px;align-items:center;padding:10px 14px;cursor:pointer;position:relative;border-bottom:1px solid var(--superf2)}\n.tm-it:hover{background:var(--superf)}\n.tm-it.on{background:var(--laranjaSv)}\n.tm-it.on::before{content:\"\";position:absolute;left:0;top:8px;bottom:8px;width:3px;border-radius:0 3px 3px 0;background:var(--laranja)}\n.tm-itc{flex:1;min-width:0}\n.tm-l1{display:flex;justify-content:space-between;gap:8px;align-items:baseline}\n.tm-l1 b{font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.tm-l1 span{font-size:10.5px;color:var(--apagado);flex:none}\n.tm-l2{display:flex;gap:8px;align-items:center;margin-top:2px}\n.tm-l2 span{flex:1;font-size:11.5px;color:var(--apagado);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.tm-l2 i{font-style:normal;background:var(--laranja);color:#fff;border-radius:999px;font-size:10px;font-weight:700;min-width:19px;height:19px;padding:0 6px;display:grid;place-items:center;flex:none}\n.tm-it.nl .tm-l1 b{font-weight:800}\n.tm-it.nl .tm-l1 span{color:var(--laranjaTx);font-weight:700}\n.tm-it.nl .tm-l2 span{color:var(--ink)}\n.tm-lado{padding:14px;display:flex;flex-direction:column;gap:10px;overflow-y:auto;flex:1;background:var(--fundo)}\n.tm-res{display:flex;gap:12px;align-items:center;background:#fff;border:1px solid var(--borda);border-radius:12px;padding:14px;box-shadow:var(--sm)}\n.tm-resic{font-size:22px}\n.tm-res b{font-family:var(--disp);font-size:22px;display:block;line-height:1.1}\n.tm-res span{font-size:11.5px;color:var(--apoio)}\n.tm-res em{display:block;font-style:normal;font-size:11px;color:var(--vermelho);font-weight:700;margin-top:2px}\n.tm-sec button{font-size:11px}\n.tm-bol{position:fixed;right:24px;bottom:24px;touch-action:none;user-select:none;width:56px;height:56px;border-radius:999px;border:0;padding:0;background:#fff;display:grid;place-items:center;box-shadow:var(--md);z-index:65;cursor:pointer;transition:bottom .2s}\n.tm-bol.alto{bottom:92px}\n.tm-bol.pulsa{animation:tmPulsa .5s ease-in-out 2}\n@keyframes tmPulsa{0%,100%{transform:scale(1)}50%{transform:scale(1.22)}}\n.tm-bol img{width:40px;height:40px;pointer-events:none;-webkit-user-drag:none}\n.tm-srchmais{display:flex;gap:8px;align-items:center}\n.tm-srchmais input{flex:1}\n.tm-mais{width:34px;height:34px;flex:none;border-radius:999px;border:0;background:var(--grad);color:#fff;font-size:18px;font-weight:700;display:grid;place-items:center;cursor:pointer}\n.tm-novacab{display:flex;align-items:center;gap:10px;padding:10px 12px;border-bottom:1px solid var(--borda);flex:none;background:var(--pagina)}\n.tm-novacab button{border:0;background:transparent;font-size:20px;color:var(--apoio);padding:0 4px}\n.tm-novacab b{font-size:13.5px}\n.tm-filtros{display:flex;gap:8px;padding:0 10px 10px;border-bottom:1px solid var(--borda);flex:none;background:var(--pagina)}\n.tm-filtros select{flex:1;min-width:0;border:1px solid var(--borda);border-radius:999px;padding:6px 10px;font-size:11.5px;font-family:inherit;background:var(--superf2);outline:0}\n.tm-bolb{position:absolute;top:-3px;right:-3px;min-width:20px;height:20px;padding:0 5px;border-radius:999px;background:var(--vermelho);color:#fff;font-size:10.5px;font-weight:700;display:grid;place-items:center;border:2px solid #fff}\n.tm-flut{position:fixed;right:24px;bottom:92px;width:430px;height:500px;max-height:calc(100vh - 180px);background:var(--tmxFundoConversa);border-radius:16px;box-shadow:var(--md);display:flex;flex-direction:column;overflow:hidden;z-index:66;opacity:0;transform:translateY(24px);transition:opacity .16s,transform .18s}\n.tm-flut{transition:opacity .16s,transform .18s,top .2s,right .2s}\n.tm-flut.on{opacity:1;transform:none}\n.tm-flut.sai{opacity:0;transform:translateY(24px)}\n.tm-flut .rl{background:var(--pagina)}\n.tm-flut .wa-head,.wa-head.tm-head{background:var(--tmxCabecalho)}\n.tm-abrir{border:1px solid rgba(255,255,255,.55);background:rgba(255,255,255,.14);color:#fff;border-radius:999px;padding:5px 11px;font-size:11px;font-weight:700;white-space:nowrap;cursor:pointer;font-family:inherit}\n.tm-abrir:hover{background:rgba(255,255,255,.26)}\n.tm-flut .srch{padding:10px;border-bottom:1px solid var(--borda);flex:none;background:var(--pagina)}\n.tm-flut .srch input{width:100%;background:var(--superf2);border:1px solid var(--borda);border-radius:999px;padding:8px 13px;font-size:12px;outline:0;font-family:inherit}\n.tm-flut .wa-head .wa-hbtn{font-size:15px}\n.tm-pres{position:absolute;right:-2px;bottom:-2px;width:11px;height:11px;border-radius:999px;border:2px solid #fff}\n.tm-sec{display:flex;align-items:center;justify-content:space-between;padding:12px 14px 5px;font-size:10px;font-weight:700;letter-spacing:.06em;text-transform:uppercase;color:var(--apagado)}\n.tm-sec button{border:0;background:transparent;color:var(--laranjaTx);font-size:15px;font-weight:700;padding:0 2px}\n.tm-men{background:var(--laranjaSv);color:var(--laranjaTx);border-radius:4px;padding:0 3px;font-weight:700}\n.wa-b.ag .tm-men{background:rgba(255,255,255,.18);color:#ffd3b8}\n.tm-ped{display:flex;flex-direction:column;gap:2px;border:1px solid var(--laranjaCl);background:var(--laranjaSv);color:var(--ink);border-radius:9px;padding:8px 10px;font-size:12px}\n.tm-ped b{color:var(--laranjaTx)}\n.tm-pag{flex:1;overflow-y:auto;padding:18px 20px;background:var(--fundo)}\n.tm-pagcab{display:flex;align-items:center;gap:12px;margin-bottom:14px;flex-wrap:wrap}\n.tm-pagcab>b{font-family:var(--disp);font-size:16px}\n.wa-hbtn{border:0;background:transparent;color:#fff;width:32px;height:32px;border-radius:999px;display:grid;place-items:center;flex:none}\n.wa-hbtn:hover{background:rgba(255,255,255,.14)}\n.wa-linha{display:flex;flex-direction:column;max-width:84%}\n.wa-linha.ag{align-self:flex-end;align-items:flex-end}\n.wa-linha.cl{align-self:flex-start;align-items:flex-start}\n.wa-linha .wa-b{max-width:100%;position:relative;padding-right:24px}\n.wa-bseta{position:absolute;top:3px;right:3px;border:0;background:transparent;color:inherit;opacity:0;width:20px;height:20px;padding:0;display:grid;place-items:center;border-radius:6px}\n.wa-b:hover .wa-bseta{opacity:.7}\n.wa-autor{font-size:11px;font-weight:700;color:var(--laranjaTx);margin-bottom:2px}\n.wa-cit{border-left:3px solid var(--laranja);background:rgba(127,127,127,.12);border-radius:6px;padding:4px 8px;margin-bottom:5px;font-size:11px;display:flex;flex-direction:column}\n.wa-cit b{font-size:10.5px;color:var(--laranjaTx)}\n.wa-b.ag .wa-cit b{color:#ffb38a}\n.wa-cit span{white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:260px;opacity:.85}\n.wa-img{display:block;max-width:260px;max-height:260px;border-radius:8px;margin-bottom:3px;cursor:pointer}\n.wa-resp{display:flex;align-items:center;gap:8px;padding:8px 12px 0;background:#fff;border-top:1px solid var(--borda);flex:none}\n.wa-resp .q{flex:1;min-width:0;border-left:3px solid var(--laranja);background:var(--superf2);border-radius:6px;padding:5px 9px;display:flex;flex-direction:column;font-size:11.5px}\n.wa-resp .q b{color:var(--laranjaTx);font-size:11px}\n.wa-resp .q span{white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.wa-resp button{border:0;background:transparent;color:var(--apagado);font-size:14px}\n.wa-rec{color:var(--vermelho);font-weight:700;font-size:12.5px}\n.wa-menu{position:fixed;z-index:80;background:#fff;border:1px solid var(--borda);border-radius:10px;box-shadow:var(--md);padding:5px;display:flex;flex-direction:column;min-width:190px}\n.wa-menu button{border:0;background:transparent;text-align:left;padding:8px 11px;font-size:12.5px;border-radius:7px;color:var(--ink);font-family:inherit}\n.wa-menu button:hover{background:var(--superf)}\n.wa-menu button.perigo{color:var(--vermelho)}\n.toasts{position:fixed;left:50%;bottom:20px;transform:translateX(-50%);display:flex;flex-direction:column;gap:8px;z-index:85}\n.toast{background:var(--ink);color:#fff;padding:9px 15px;border-radius:999px;font-size:12.5px;box-shadow:var(--md)}\n.modal{position:fixed;inset:0;background:rgba(17,17,20,.45);display:grid;place-items:center;z-index:75;padding:16px}\n.mcx{background:var(--pagina);border-radius:16px;width:min(460px,96vw);max-height:88vh;overflow:hidden;display:flex;flex-direction:column;box-shadow:var(--md)}\n.mcab{display:flex;align-items:center;gap:8px;padding:14px 16px;border-bottom:1px solid var(--borda)}\n.mcab b{flex:1;font-family:var(--disp)}\n.mcab .x{width:28px;height:28px;border-radius:8px;background:var(--superf2);border:0}\n.mbody{padding:14px 16px;overflow-y:auto}\n.apubtn{border:1px solid var(--bordaF);background:var(--pagina);color:var(--grafite);border-radius:9px;padding:7px 13px;font-size:12px;font-weight:700;display:flex;gap:6px;align-items:center}\n.apubtn:hover{border-color:var(--laranja);color:var(--laranjaTx)}\n.mbody .fl{display:block;font-size:10px;letter-spacing:.05em;text-transform:uppercase;color:var(--apagado);font-weight:700;margin:10px 0 5px}\n.mbody .fl:first-child{margin-top:0}\n.mbody .fi{width:100%;border:1px solid var(--borda);border-radius:9px;padding:9px 11px;font-size:12.5px;font-family:inherit;outline:0}\n.mbody .fi:focus{border-color:var(--laranja)}\n.cg-card{background:var(--pagina);border:1px solid var(--borda);border-radius:var(--r);box-shadow:var(--sm);padding:16px;min-width:0}\n.ap-fils{display:flex;gap:6px;flex-wrap:wrap}\n.ap-fil{font-size:11px;font-weight:600;border:1px solid var(--borda);border-radius:999px;padding:4px 10px;color:var(--apoio);background:var(--pagina)}\n.ap-fil.on{background:var(--ink);color:#fff;border-color:var(--ink)}\n.ap-dia{align-self:center;font-size:10.5px;background:#fff;color:var(--apoio);border-radius:7px;padding:3px 10px;margin:4px 0 8px;box-shadow:var(--sm)}\n:host{all:initial;font-family:var(--corpo);font-size:13px;line-height:1.5;color:var(--ink);--tmxFundoConversa:#efe7de;--tmxCabecalho:var(--grad)}\n:host(.tmx-mod){display:flex;flex-direction:column;flex:1;min-width:0;min-height:0;height:100%;background:var(--superf2)}\n:host(.dir) .waweb{grid-template-columns:minmax(0,1fr) 340px}\n:host(.dir) .walist{order:2;border-right:0;border-left:1px solid var(--borda)}\n:host(.cpt) .waweb{grid-template-columns:290px minmax(0,1fr)}\n:host(.cpt.dir) .waweb{grid-template-columns:minmax(0,1fr) 290px}\n:host(.cpt) .tm-it{padding-top:6px;padding-bottom:6px}\n\n.tm-lado3{flex:1;min-height:0;display:flex;flex-direction:column;overflow-y:auto;background:#fff}\n.tm-lado3 .tm-sec{display:flex;align-items:center;justify-content:space-between;gap:8px}\n.tm-lado3 .tm-sec button{border:1px solid var(--borda);background:#fff;border-radius:999px;padding:2px 9px;font-size:11px;font-weight:700;color:var(--laranjaTx);cursor:pointer;font-family:inherit;text-transform:none;letter-spacing:0}\n.tm-lado3 .tm-sec button:hover{border-color:var(--laranja);background:var(--laranjaSv)}\n.tm-deps{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:5px;padding:2px 12px 10px;flex:none}\n.tm-dep{display:flex;align-items:center;gap:8px;min-width:0;border:1px solid var(--borda);background:#fff;border-radius:10px;padding:4px 8px;cursor:pointer;font-family:inherit;text-align:left;position:relative}\n.tm-dep:hover{border-color:var(--bordaF);background:var(--superf)}\n.tm-dep.on{border-color:var(--laranja);background:var(--laranjaSv)}\n.tm-dep.nl b{color:var(--ink)}\n.tm-depic{width:30px;height:30px;border-radius:8px;display:grid;place-items:center;color:#fff;flex:none}\n.tm-depic svg{width:14px;height:14px}\n.tm-depc{display:flex;flex-direction:column;min-width:0;flex:1}\n.tm-depc b{font-size:12px;font-weight:700;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:var(--grafite)}\n.tm-depc em{font-style:normal;font-size:10px;color:var(--apagado)}\n.tm-dep i{font-style:normal;background:var(--laranja);color:#fff;border-radius:999px;font-size:9.5px;padding:1px 6px;font-weight:700;flex:none}\n.tm-lado3 .tm-busca2{padding:0 12px 8px}\n.tm-cx{flex:none;max-height:326px;overflow-y:auto;border-top:1px solid var(--superf2);border-bottom:1px solid var(--borda);scrollbar-width:thin;scrollbar-color:var(--bordaF) transparent}\n.tm-cx::-webkit-scrollbar{width:8px}\n.tm-cx::-webkit-scrollbar-thumb{background:var(--bordaF);border-radius:8px}\n.tm-feed{flex:1;min-height:160px;overflow-y:auto;padding:2px 12px 12px;display:flex;flex-direction:column;gap:7px;scrollbar-width:thin;scrollbar-color:var(--bordaF) transparent}\n.tm-fi{display:flex;gap:10px;align-items:flex-start;border:1px solid var(--borda);border-left-width:4px;border-radius:10px;padding:8px 10px;cursor:pointer;background:#fff;position:relative}\n.tm-fi:hover{box-shadow:var(--sm)}\n.tm-fi.aviso{border-left-color:var(--ambar);background:linear-gradient(90deg,var(--ambarSv),#fff 60%)}\n.tm-fi.pedido{border-left-color:var(--roxo);background:linear-gradient(90deg,var(--roxoSv),#fff 60%)}\n.tm-fi.reuniao{border-left-color:var(--verde);background:linear-gradient(90deg,var(--verdeSv),#fff 60%)}\n.tm-fi.on{outline:2px solid var(--laranja);outline-offset:-1px}\n.tm-fi.novo b::after{content:'';display:inline-block;width:7px;height:7px;border-radius:999px;background:var(--laranja);margin-left:6px;vertical-align:middle}\n.tm-fiic{font-size:16px;line-height:1;margin-top:2px;flex:none}\n.tm-fic{flex:1;min-width:0;display:flex;flex-direction:column;gap:1px}\n.tm-fil1{display:flex;justify-content:space-between;gap:8px}\n.tm-fil1 em{font-style:normal;font-size:9.5px;font-weight:800;text-transform:uppercase;letter-spacing:.06em}\n.tm-fi.aviso .tm-fil1 em{color:var(--ambar)}\n.tm-fi.pedido .tm-fil1 em{color:var(--roxo)}\n.tm-fi.reuniao .tm-fil1 em{color:var(--verde)}\n.tm-fil1 span{font-size:10px;color:var(--apagado);flex:none}\n.tm-fic b{font-size:12.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.tm-fic>span{font-size:11px;color:var(--apoio);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.tm-olho{border:0;background:transparent;color:var(--apagado);cursor:pointer;padding:2px 3px;border-radius:6px;display:inline-grid;place-items:center;vertical-align:middle;flex:none}\n.tm-olho:hover{color:var(--laranjaTx);background:var(--laranjaSv)}\n.wa-t .tm-olho{padding:0 2px;margin-left:3px}\n.wa-t .tm-olho svg{width:13px;height:13px}\n.tm-foco{outline:2px solid var(--laranja);outline-offset:2px}\n.tm-depwrap{flex:1;min-height:0;display:flex}\n.tm-depchat{flex:1;min-width:0;min-height:0;display:flex;flex-direction:column}\n.tm-membros{width:310px;flex:none;border-left:1px solid var(--borda);background:#fff;overflow-y:auto}\n.tm-mcab{padding:14px 14px 10px;border-bottom:1px solid var(--borda);display:flex;flex-direction:column;gap:2px;position:sticky;top:0;background:#fff;z-index:1}\n.tm-mcab b{font-family:var(--disp);font-size:14px}\n.tm-mcab span{font-size:11px;color:var(--apagado)}\n.tm-mb{display:flex;align-items:center;gap:10px;padding:9px 12px;border-bottom:1px solid var(--superf2)}\n.tm-mbc{flex:1;min-width:0;display:flex;flex-direction:column}\n.tm-mbc b{font-size:12.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.tm-mbc span{font-size:10.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}\n.tm-mbb{display:flex;gap:2px;flex:none}\n.tm-mbb button{width:26px;height:26px;border:1px solid var(--borda);background:#fff;border-radius:8px;display:grid;place-items:center;color:var(--apoio);cursor:pointer;padding:0}\n.tm-mbb button:hover{border-color:var(--laranja);color:var(--laranjaTx);background:var(--laranjaSv)}\n.tm-mbb svg{width:14px;height:14px;stroke:currentColor;fill:none}\n.wa-comp textarea{flex:1;border:1px solid var(--bordaF);border-radius:20px;padding:10px 15px;font-size:12.5px;font-family:inherit;outline:0;background:var(--superf2);resize:none;line-height:1.4;max-height:130px;min-height:40px;overflow-y:auto}\n.tm-depic{overflow:hidden}\n.tm-depic img{width:100%;height:100%;object-fit:cover}\n.wa-msgs[data-fundo] .wa-t{color:#fff;font-weight:600;text-shadow:0 1px 2px rgba(0,0,0,.45)}\n.wa-msgs[data-fundo] .wa-t .tm-olho{color:#fff}\n.tm-band{background:#fff;border-top:1px solid var(--borda);padding:8px 12px 0;flex:none}\n.tm-bcab{display:flex;align-items:center;justify-content:space-between;gap:8px;margin-bottom:6px}\n.tm-bcab b{font-size:11.5px;color:var(--apoio)}\n.tm-bcab button{border:0;background:transparent;color:var(--vermelho);font-size:11.5px;font-weight:700;cursor:pointer;font-family:inherit}\n.tm-blista{display:flex;gap:8px;overflow-x:auto;padding-bottom:4px;scrollbar-width:thin}\n.tm-bi{display:flex;align-items:center;gap:8px;border:1px solid var(--borda);border-radius:10px;padding:6px 6px 6px 8px;background:var(--superf);flex:none;max-width:260px}\n.tm-bi img{width:34px;height:34px;object-fit:cover;border-radius:6px;flex:none}\n.tm-bic{width:34px;height:34px;border-radius:6px;background:var(--vermelhoSv);color:var(--vermelho);font-size:9px;font-weight:800;display:grid;place-items:center;flex:none}\n.tm-bin{display:flex;flex-direction:column;min-width:0}\n.tm-bin b{font-size:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:170px}\n.tm-bin span{font-size:10.5px;color:var(--apagado)}\n.tm-bi button{border:0;background:transparent;color:var(--apagado);cursor:pointer;font-size:12px;padding:2px 4px}";
let tmxCfg={},tmxTema={},tmxEu={id:null,nome:''},tmxModHost=null,tmxCamHost=null,tmxBolAlta=false,tmxModalEl=null,tmxFolha=null,tmxLibsP=null;
const TMX_VARS={cor:'--laranja',corClara:'--laranjaAc',corTexto:'--laranjaTx',corSuave:'--laranjaSv',corBorda:'--laranjaCl',gradiente:'--grad',fonte:'--corpo',fonteTitulo:'--disp',texto:'--ink',textoApoio:'--apoio',textoApagado:'--apagado',fundo:'--pagina',fundoSuave:'--superf',fundoSuave2:'--superf2',borda:'--borda',fundoConversa:'--tmxFundoConversa',cabecalho:'--tmxCabecalho',raio:'--r'};
function tmxChave(){return (tmxCfg.chave||'teams')+'-bolinha-y';}
function tmxFolhaEstilo(){if(!tmxFolha){tmxFolha=new CSSStyleSheet();tmxFolha.replaceSync(TMX_CSS);}return tmxFolha;}
function tmxAplicarTema(h){const l=tmxCfg.layout||{};h.classList.toggle('dir',l.lista==='direita');h.classList.toggle('cpt',!!l.compacto);
 Object.keys(TMX_VARS).forEach(k=>{if(tmxTema[k])h.style.setProperty(TMX_VARS[k],tmxTema[k]);});Object.keys(tmxTema.vars||{}).forEach(k=>h.style.setProperty(k,tmxTema.vars[k]));}
function tmxHost(cls){const h=document.createElement('div');h.className=cls;const r=h.attachShadow({mode:'open'});r.adoptedStyleSheets=[tmxFolhaEstilo()];tmxAplicarTema(h);tmxLigarArquivos(r);return h;}
function tmxTemArquivos(e){return !!(e.dataTransfer&&[...(e.dataTransfer.types||[])].includes('Files'));}
function tmxCanalDoEvento(e){const p=e.composedPath?e.composedPath():[];if(p.some(x=>x&&x.id==='tmxFlut'))return tmxFlutAberto&&tmxFlutCanal?tmxFlutCanal:null;if(p.some(x=>x&&x.id==='tmxCentro'))return tmxAba==='conversas'?tmxSel:null;return null;}
const tmxPendentes={};
function tmxMandarArquivos(fs,canal){if(!canal||!fs.length)return;const l=tmxPendentes[canal]||(tmxPendentes[canal]=[]);
 fs.forEach((f,k)=>{if(f.size>100*1048576){tmxToast((f.name||'Arquivo')+' passa de 100 MB.');return;}const nome=f.name&&f.name!=='image.png'?f.name:'imagem-'+new Date().toISOString().slice(0,19).replace(/[-:T]/g,'')+(k?'-'+k:'')+'.'+((f.type||'').split('/')[1]||'png');
  l.push({f,nome,tipo:/^image\//.test(f.type)?'imagem':'documento',url:/^image\//.test(f.type)?URL.createObjectURL(f):''});});
 tmxBandejaAtualizar(canal);const i=tmxEl(canal===tmxFlutCanal&&tmxFlutAberto?'tmfin':'tmin');if(i)i.focus();}
function tmxTam(b){return b>=1048576?(b/1048576).toFixed(1).replace('.',',')+' MB':Math.max(1,Math.round(b/1024))+' KB';}
function tmxBandejaHtml(canal){const l=tmxPendentes[canal]||[];if(!l.length)return '';
 return `<div class="tm-band"><div class="tm-bcab"><b>${l.length} ${l.length===1?'arquivo':'arquivos'} para enviar</b><button onclick="tmxLimparPend('${canal}')">Cancelar</button></div><div class="tm-blista">${l.map((p,k)=>`<div class="tm-bi">${p.url?`<img src="${tmxEsc(p.url)}" alt="">`:`<span class="tm-bic">${tmxEsc((p.nome.split('.').pop()||'ARQ').slice(0,4).toUpperCase())}</span>`}<div class="tm-bin"><b title="${tmxEsc(p.nome)}">${tmxEsc(p.nome)}</b><span>${tmxTam(p.f.size)}</span></div><button title="Tirar" onclick="tmxTirarPend('${canal}',${k})">✕</button></div>`).join('')}</div></div>`;}
function tmxBandejaAtualizar(canal){['tmxBand','tmfBand'].forEach(id=>{const b=tmxEl(id);if(b&&b.dataset.canal===canal)b.innerHTML=tmxBandejaHtml(canal);});}
function tmxTirarPend(canal,k){const l=tmxPendentes[canal]||[];const p=l.splice(k,1)[0];if(p&&p.url)URL.revokeObjectURL(p.url);tmxBandejaAtualizar(canal);}
function tmxLimparPend(canal){(tmxPendentes[canal]||[]).forEach(p=>{if(p.url)URL.revokeObjectURL(p.url);});delete tmxPendentes[canal];tmxBandejaAtualizar(canal);}
async function tmxEnviarPendentes(canal){const l=tmxPendentes[canal]||[];if(!l.length)return;delete tmxPendentes[canal];tmxBandejaAtualizar(canal);
 for(const p of l){await tmxEnviarArquivo(p.f,p.nome,p.tipo,canal);if(p.url)URL.revokeObjectURL(p.url);}}
function tmxPularLinha(e){const a=e.composedPath?e.composedPath()[0]:e.target;if(e.key!=='Enter'||!e.ctrlKey||!e.shiftKey||!a||a.tagName!=='TEXTAREA')return;e.preventDefault();e.stopPropagation();const i=a.selectionStart,f2=a.selectionEnd;a.value=a.value.slice(0,i)+'\n'+a.value.slice(f2);a.selectionStart=a.selectionEnd=i+1;a.dispatchEvent(new Event('input',{bubbles:true}));}
function tmxLigarArquivos(r){
 r.addEventListener('keydown',tmxPularLinha,true);
 r.addEventListener('dragover',e=>{if(!tmxTemArquivos(e)||!tmxCanalDoEvento(e))return;e.preventDefault();e.dataTransfer.dropEffect='copy';});
 r.addEventListener('drop',e=>{if(!tmxTemArquivos(e))return;const canal=tmxCanalDoEvento(e);if(!canal)return;e.preventDefault();e.stopPropagation();tmxMandarArquivos([...e.dataTransfer.files],canal);});
 r.addEventListener('paste',e=>{const t=e.composedPath()[0];if(!t||(t.id!=='tmin'&&t.id!=='tmfin'))return;const dt=e.clipboardData;const fs=[...((dt&&dt.files)||[])];if(!fs.length||(dt.getData('text/plain')||'').trim())return;e.preventDefault();tmxMandarArquivos(fs,t.id==='tmfin'?tmxFlutCanal:tmxSel);});}
function tmxCamada(){if(!tmxCamHost){tmxCamHost=tmxHost('tmx-camada');tmxCamHost.style.cssText+=';position:fixed;top:0;left:0;width:0;height:0;z-index:'+(tmxCfg.camada||70);}if(!tmxCamHost.isConnected)document.body.appendChild(tmxCamHost);return tmxCamHost.shadowRoot;}
function tmxModRaiz(){return tmxModHost.shadowRoot;}
function tmxRaizes(){return [tmxModHost,tmxCamHost].filter(h=>h&&h.isConnected).map(h=>h.shadowRoot);}
function tmxEl(id){for(const r of tmxRaizes()){const e=r.getElementById(id);if(e)return e;}return null;}
function tmxQS(sel){return tmxRaizes().flatMap(r=>[...r.querySelectorAll(sel)]);}
function tmxQ1(sel){return tmxQS(sel)[0]||null;}
function tmxAtivo(){for(const r of tmxRaizes())if(r.activeElement)return r.activeElement;return null;}
function tmxNoModulo(){return !!(tmxModHost&&tmxModHost.isConnected);}
function tmxScript(src){return new Promise(ok=>{const s=document.createElement('script');s.src=src;s.onload=()=>ok(true);s.onerror=()=>{s.remove();ok(false);};document.head.appendChild(s);});}
function tmxLibs(){if(!tmxLibsP)tmxLibsP=(async()=>{if(!(window.supabase&&window.supabase.createClient))await tmxScript(TMX_BASE+'vendor/supabase.js');if(!window.LivekitClient)tmxScript(TMX_BASE+'vendor/livekit-client.umd.js');})();return tmxLibsP;}
function tmxToast(t){if(tmxCfg.toast){tmxCfg.toast(t);return;}const r=tmxCamada();let w=r.getElementById('tmxToasts');if(!w){w=document.createElement('div');w.id='tmxToasts';w.className='toasts';r.appendChild(w);}const d=document.createElement('div');d.className='toast';d.textContent=t;w.appendChild(d);setTimeout(()=>d.remove(),2600);}
function tmxFecharMenus(){tmxQS('.wa-menu').forEach(m=>m.remove());}
function tmxMenu(ev,itens,esquerda){
 ev.stopPropagation();tmxFecharMenus();
 const m=document.createElement('div');m.className='wa-menu';
 itens.filter(Boolean).forEach(([t,fn,perigo])=>{const b=document.createElement('button');b.textContent=t;if(perigo)b.className='perigo';b.onclick=e=>{e.stopPropagation();tmxFecharMenus();fn();};m.appendChild(b);});
 tmxCamada().appendChild(m);
 let r=ev.currentTarget?ev.currentTarget.getBoundingClientRect():null;if(!r||!r.width)r={left:ev.clientX,right:ev.clientX,top:ev.clientY,bottom:ev.clientY};
 let x=esquerda?r.left:r.right-m.offsetWidth,y=r.bottom+4;if(x+m.offsetWidth>window.innerWidth-8)x=window.innerWidth-m.offsetWidth-8;
 if(x<8)x=8;if(y+m.offsetHeight>window.innerHeight-8)y=r.top-m.offsetHeight-4;
 m.style.left=x+'px';m.style.top=y+'px';
 setTimeout(()=>document.addEventListener('click',tmxFecharMenus,{once:true}),0);
}
function tmxFecharModal(){if(tmxModalEl){tmxModalEl.remove();tmxModalEl=null;}}
function tmxModal(titulo,corpo,largura){
 tmxFecharModal();tmxModalEl=document.createElement('div');tmxModalEl.className='modal';
 tmxModalEl.innerHTML=`<div class="mcx" style="width:min(${largura||460}px,96vw)"><div class="mcab"><b>${tmxEsc(titulo)}</b><button class="x" onclick="tmxFecharModal()">✕</button></div><div class="mbody" id="tmxmb">${corpo}</div></div>`;
 tmxCamada().appendChild(tmxModalEl);
}
function tmxConfirmar(texto,botao,fn){
 tmxFecharModal();tmxModalEl=document.createElement('div');tmxModalEl.className='modal';
 tmxModalEl.innerHTML=`<div class="mcx"><div class="mcab"><b>${tmxEsc(botao)}</b><button class="x" onclick="tmxFecharModal()">✕</button></div><div class="mbody"><div style="font-size:12.5px;line-height:1.5">${tmxEsc(texto)}</div><div style="display:flex;justify-content:flex-end;gap:8px;margin-top:14px"><button class="apubtn" onclick="tmxFecharModal()">Cancelar</button><button class="bt-assumir" id="tmxcf">${tmxEsc(botao)}</button></div></div></div>`;
 tmxCamada().appendChild(tmxModalEl);tmxEl('tmxcf').onclick=()=>{tmxFecharModal();fn();};
}

const TMX_ICO_SETA='<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9l6 6 6-6"/></svg>';
const TMX_ICO_MAIS='<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><circle cx="12" cy="5" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="12" cy="19" r="1"/></svg>';
const TMX_ICO_GRUPO='<svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM23 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8"/></svg>';
const TMX_ICO_CLIPE='<svg viewBox="0 0 24 24"><path d="M21.4 11.1l-9.2 9.2a6 6 0 0 1-8.5-8.5l9.2-9.2a4 4 0 0 1 5.7 5.7l-9.2 9.2a2 2 0 0 1-2.8-2.8l8.5-8.5"/></svg>';
const TMX_MIC='<svg viewBox="0 0 24 24"><path d="M12 2a3 3 0 0 0-3 3v6a3 3 0 0 0 6 0V5a3 3 0 0 0-3-3zM5 10v1a7 7 0 0 0 14 0v-1M12 18v4"/></svg>';
function tmxOgg(b){
 let p=0,cab=null;const pac=[];
 const vint=(marca)=>{const f=b[p];let n=1,m=0x80;while(n<=8&&!(f&m)){m>>=1;n++;}if(n>8)throw new Error('ebml');let v=marca?f:(f&(m-1));let todos=(f&(m-1))===m-1;for(let i=1;i<n;i++){v=v*256+b[p+i];if(b[p+i]!==255)todos=false;}p+=n;return {v,n,todos};};
 const MESTRES=new Set([0x18538067,0x1F43B675,0x1654AE6B,0xAE,0xA0]);
 while(p<b.length-2){const id=vint(true).v;const tam=vint(false);const ini=p;
  if(MESTRES.has(id))continue;
  const fim=tam.todos?b.length:Math.min(b.length,ini+tam.v);
  if(id===0x63A2)cab=b.slice(ini,fim);
  else if(id===0xA3||id===0xA1){p=ini;vint(false);p+=3;pac.push(b.slice(p,fim));}
  p=fim;}
 if(!cab||!pac.length)throw new Error('sem audio');
 const CRC=new Uint32Array(256);for(let i=0;i<256;i++){let r=i<<24;for(let j=0;j<8;j++)r=r&0x80000000?((r<<1)^0x04c11db7)>>>0:(r<<1)>>>0;CRC[i]=r>>>0;}
 const serial=(Math.random()*0xffffffff)>>>0;let seq=0;const paginas=[];
 const pagina=(dado,gran,tipo)=>{const seg=[];let r=dado.length;while(r>=255){seg.push(255);r-=255;}seg.push(r);
  const h=new Uint8Array(27+seg.length+dado.length);const dv=new DataView(h.buffer);
  h.set([0x4f,0x67,0x67,0x53,0,tipo]);dv.setUint32(6,gran%4294967296,true);dv.setUint32(10,Math.floor(gran/4294967296),true);
  dv.setUint32(14,serial,true);dv.setUint32(18,seq++,true);h[26]=seg.length;h.set(seg,27);h.set(dado,27+seg.length);
  let crc=0;for(let i=0;i<h.length;i++)crc=((crc<<8)^CRC[((crc>>>24)^h[i])&0xff])>>>0;dv.setUint32(22,crc,true);paginas.push(h);};
 const amostras=x=>{const toc=x[0],cfg=toc>>3;const ms=cfg<12?[10,20,40,60][cfg%4]:cfg<16?[10,20][cfg%2]:[2.5,5,10,20][cfg%4];const c=toc&3;const nf=c===0?1:c<3?2:(x[1]&0x3f);return Math.round(nf*ms*48);};
 pagina(cab,0,2);
 const tags=new TextEncoder().encode('OpusTags');const vend=new TextEncoder().encode('fiscal');const t=new Uint8Array(8+4+vend.length+4);t.set(tags);new DataView(t.buffer).setUint32(8,vend.length,true);t.set(vend,12);pagina(t,0,0);
 let g=0;pac.forEach((x,i)=>{g+=amostras(x);pagina(x,g,i===pac.length-1?4:0);});
 const tot=paginas.reduce((s,x)=>s+x.length,0);const out=new Uint8Array(tot);let o=0;paginas.forEach(x=>{out.set(x,o);o+=x.length;});return out;
}
function tmxEsc(s){return String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));}
function tmxCnpj(c){const d=String(c||'').replace(/\D/g,'');return d.length===14?d.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/,'$1.$2.$3/$4-$5'):d;}
function tmxHora(d){const x=new Date(d);return String(x.getHours()).padStart(2,'0')+':'+String(x.getMinutes()).padStart(2,'0');}
function tmxDia(d){const x=new Date(d);return String(x.getDate()).padStart(2,'0')+'/'+String(x.getMonth()+1).padStart(2,'0');}
const TMX_URL='https://lhqjfdexfexpmnoqhbyv.supabase.co',TMX_KEY='sb_publishable_wJLNCeunyVFZz4yUJAaJMQ_x7qPMU_v';
const TMX_ST={online:['Online','var(--verde)'],reuniao:['Em reunião','var(--azul)'],ausente:['Ausente','var(--ambar)'],nao_interromper:['Não me interrompam','var(--vermelho)'],offline:['Offline','var(--nevoa)']};
const TMX_PED={aberto:'Aberto',em_andamento:'Em andamento',concluido:'Concluído',cancelado:'Cancelado'};
let tmx=null,tmxEquipe=null,tmxCanais=[],tmxMsgs={},tmxPres={},tmxSel=null,tmxAba='conversas',tmxBusca='',tmxResp=null,tmxUrls={},tmxPedidos=[],tmxAvisos=[],tmxVistos=new Set(),tmxReunioes=[],tmxGrav=null,tmxPedFiltro='meus',tmxPronto=false,tmxIniciando=null;
function tmxPessoa(id){return (tmxEquipe&&tmxEquipe.pessoas||[]).find(p=>p.id===id)||{id,nome:'Usuário',setores:[]};}
function tmxSetorNome(id){const s=(tmxEquipe&&tmxEquipe.setores||[]).find(x=>x.id===id);return s?s.nome:'';}
function tmxCor(t){let h=0;for(const ch of String(t||''))h=(h*31+ch.charCodeAt(0))>>>0;return ['#2F6FED','#5b3f96','#1B7A44','#B25E09','#0891B2','#C0392B','#6D4AA0','#3A5A8C'][h%8];}
function tmxIni(n){const p=String(n||'').trim().split(/\s+/);return ((p[0]||'')[0]||'').concat(p.length>1?p[p.length-1][0]:'').toUpperCase();}
function tmxNomeCanal(c){if(!c)return '';if(c.tipo==='direta'){const o=(c.membros||[]).find(x=>x!==tmxEu.id);return tmxPessoa(o).nome;}if(c.tipo==='setor')return tmxSetorNome(c.setor_id)||c.nome||'Setor';if(c.tipo==='departamentos'){if(c.setor_id===c.setor_b_id)return tmxSetorNome(c.setor_id)||c.nome;const meus=tmxMeusSetores();const o=meus.includes(c.setor_id)?c.setor_b_id:meus.includes(c.setor_b_id)?c.setor_id:null;return o?tmxSetorNome(o):(tmxSetorNome(c.setor_id)+' + '+tmxSetorNome(c.setor_b_id));}return c.nome||'Grupo';}
let tmxPend={avisos:0,pedidos:0,reunioes:0};
function tmxNaoLidasTotal(){return tmxCanais.filter(c=>!c.silenciado).reduce((s,c)=>s+(c.nao_lidas||0),0);}
function tmxTotal(){return tmxNaoLidasTotal()+(tmxPend.avisos||0)+(tmxPend.pedidos||0)+(tmxPend.reunioes||0);}
async function tmxCarregarPend(){if(!tmx)return;const r=await tmx.rpc('chat_pendencias',{p_setores:(tmxPessoa(tmxEu.id).setores||[])});if(!r.error&&r.data){tmxPend=r.data;tmxBadge();if(tmxNoModulo())tmxDesenharLista();if(tmxFlutAberto&&!tmxFlutCanal)tmxFlutDesenhar();}}
function tmxBadge(){const n=tmxTotal();if(tmxCfg.aoContar){try{tmxCfg.aoContar(n);}catch(e){}}tmxBolinha();}
async function tmxIniciar(){
 if(tmxPronto)return true;if(tmxIniciando)return tmxIniciando;
 tmxIniciando=(async()=>{
  await tmxLibs();const cred=await tmxCfg.entrar();if(!cred)return false;
  const r=await fetch(TMX_URL+'/functions/v1/teams-entrar',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(cred)}).catch(()=>null);if(!r)return false;
  const j=await r.json().catch(()=>({}));if(!j.ok)return false;
  tmxEu=Object.assign({},j.usuario||{},tmxCfg.usuario?await tmxCfg.usuario():{});if(!tmxEu.id)return false;tmxBolCarregar();
  tmx=supabase.createClient(TMX_URL,TMX_KEY,{auth:{persistSession:false,autoRefreshToken:true,storageKey:'teams-sessao'}});
  const ss=await tmx.auth.setSession({access_token:j.access_token,refresh_token:j.refresh_token});if(ss.error)return false;
  const [eq]=await Promise.all([tmxCfg.pessoas(),tmxCarregarCanais()]);
  if(!eq.error)tmxEquipe=eq.data;
  await tmx.from('chat_presenca').upsert({usuario_id:tmxEu.id,status:'online',visto_por_ultimo_em:new Date().toISOString(),atualizado_em:new Date().toISOString()});
  const p=await tmx.from('chat_presenca').select('usuario_id,status,visto_por_ultimo_em');if(!p.error)p.data.forEach(x=>{tmxPres[x.usuario_id]=x.status;tmxVisto[x.usuario_id]=x.visto_por_ultimo_em;});
  tmx.channel('teams').on('postgres_changes',{event:'INSERT',schema:'public',table:'chat_mensagem'},tmxChegou)
   .on('postgres_changes',{event:'*',schema:'public',table:'chat_presenca'},x=>{const n=x.new||{};if(n.usuario_id){tmxPres[n.usuario_id]=n.status;if(n.visto_por_ultimo_em)tmxVisto[n.usuario_id]=n.visto_por_ultimo_em;tmxRedesenharPresenca();}})
   .on('postgres_changes',{event:'*',schema:'public',table:'chat_canal_membro'},()=>tmxCarregarCanais().then(()=>{if(tmxNoModulo())tmxDesenharLista();}))
   .on('postgres_changes',{event:'*',schema:'public',table:'chat_pedido'},()=>{tmxCarregarPend();tmxCarregarFeed();if(tmxNoModulo()&&tmxAba==='pedidos')tmxAbrirPedidos();})
   .on('postgres_changes',{event:'INSERT',schema:'public',table:'chat_aviso'},()=>{tmxCarregarPend();tmxCarregarFeed();if(tmxNoModulo()&&tmxAba==='avisos')tmxAbrirAvisos();})
   .on('postgres_changes',{event:'*',schema:'public',table:'chat_reuniao_participante'},()=>{tmxCarregarPend();tmxCarregarFeed();if(tmxNoModulo()&&tmxAba==='reunioes')tmxAbrirReunioes();})
   .on('postgres_changes',{event:'*',schema:'public',table:'chat_aviso_visto'},()=>tmxCarregarPend())
   .subscribe();
  tmxEscutarLigacoes();
  tmxOnlineLigar();
  window.addEventListener('beforeunload',()=>{try{tmx.from('chat_presenca').upsert({usuario_id:tmxEu.id,status:'offline',atualizado_em:new Date().toISOString()}).then(()=>{},()=>{});}catch(e){}});
  tmxPronto=true;tmxBadge();tmxCarregarPend();tmxCarregarFeed();return true;})();
 const ok=await tmxIniciando;tmxIniciando=null;return ok;
}
async function tmxCarregarCanais(){const r=await tmx.rpc('chat_resumo');if(!r.error)tmxCanais=r.data||[];tmxBadge();}
async function tmxChegou(p){
 const m=p.new;if(!m)return;
 const lista=tmxMsgs[m.canal_id];
 if(lista&&!lista.find(x=>x.id===m.id)){const i=lista.findIndex(x=>x.tmp&&x.corpo===m.corpo&&m.autor_id===tmxEu.id);if(i>=0)lista.splice(i,1);lista.push(m);if(['arquivo','audio'].includes(m.tipo))setTimeout(()=>tmxCarregarMsgs(m.canal_id),900);}
 let c=tmxCanais.find(x=>x.id===m.canal_id);
 if(!c){await tmxCarregarCanais();c=tmxCanais.find(x=>x.id===m.canal_id);}
 if(c){c.ultima={autor_id:m.autor_id,corpo:m.corpo,tipo:m.tipo,em:m.criada_em};
  if(m.autor_id!==tmxEu.id){tmxBolPulsar();const vendo=(tmxNoModulo()&&tmxSel===c.id&&tmxAba==='conversas')||(tmxFlutAberto&&tmxFlutCanal===c.id);if(vendo)tmx.rpc('chat_marcar_lido',{p_canal:c.id}).then(()=>{},()=>{});else c.nao_lidas=(c.nao_lidas||0)+1;if(!c.silenciado)tmxAvisar(c,m,vendo);}}
 tmxBadge();
 if(tmxNoModulo()){tmxDesenharLista();if(tmxSel===m.canal_id)tmxDesenharMsgs();}
 if(tmxFlutAberto){if(tmxFlutCanal===m.canal_id)tmxDesenharMsgs('tmfms',m.canal_id);else if(!tmxFlutCanal)tmxFlutDesenhar();}
}
function tmxAvisoTexto(c,m){const t=m.tipo==='audio'?'Áudio':m.tipo==='arquivo'?'Arquivo · '+(m.corpo||'arquivo'):m.tipo==='pedido'?'Pedido · '+(m.corpo||''):(m.corpo||'Nova mensagem');return c.tipo!=='direta'?tmxPessoa(m.autor_id).nome.split(' ')[0]+': '+t:t;}
function tmxAvisar(c,m,vendo){const p=tmxPessoa(m.autor_id);
 if(tmxCfg.aoMensagem){try{tmxCfg.aoMensagem({canal_id:c.id,nome:tmxNomeCanal(c),texto:tmxAvisoTexto(c,m),em:m.criada_em,grupo:c.tipo!=='direta',foto:c.tipo==='direta'?(p.foto_url||''):'',rodape:c.tipo==='setor'||c.tipo==='departamentos'?'Departamentos':c.tipo!=='direta'?'Grupo':'Conversa direta',vendo});}catch(e){}return;}
 if(!vendo)tmxNotifCanto(c,m);}
function tmxNotifAbrir(id){if(tmxCfg.abrirModulo)tmxCfg.abrirModulo();setTimeout(()=>{if(tmxNoModulo())tmxAbrirCanal(id);else{if(!tmxFlutAberto)tmxFlutAbrir();tmxFlutAbrirCanal(id);}},60);}
function tmxNotifCanto(c,m){
 const r=tmxCamada();let w=r.getElementById('tmxNotifs');
 if(!w){w=document.createElement('div');w.id='tmxNotifs';w.setAttribute('style','position:fixed;right:18px;bottom:18px;display:flex;flex-direction:column;gap:10px;pointer-events:none');r.appendChild(w);}
 const nome=tmxNomeCanal(c),p=tmxPessoa(m.autor_id);
 const foto=c.tipo==='direta'?(p.foto_url||''):'';
 const rod=c.tipo==='setor'?'Setor':c.tipo!=='direta'?'Grupo':'Conversa direta';
 const av=foto?`<img src="${tmxEsc(foto)}" style="width:40px;height:40px;border-radius:50%;object-fit:cover">`:`<span style="width:40px;height:40px;border-radius:50%;display:flex;align-items:center;justify-content:center;color:#fff;font-weight:700;font-size:15px;background:${tmxCor(nome)}">${tmxEsc(tmxIni(nome))}</span>`;
 const card=document.createElement('div');
 card.setAttribute('style','pointer-events:auto;cursor:pointer;width:320px;max-width:86vw;display:flex;gap:12px;align-items:center;padding:12px 14px;border-radius:14px;background:var(--pagina,#fff);color:var(--ink,#101820);box-shadow:0 12px 34px rgba(0,0,0,.2);border:1px solid var(--borda,#E3E8EE);font-family:var(--corpo,"Segoe UI",sans-serif);transform:translateX(120%);opacity:0;transition:transform .28s ease,opacity .28s ease');
 card.innerHTML=`<div style="flex:0 0 auto">${av}</div><div style="flex:1 1 auto;min-width:0"><div style="display:flex;justify-content:space-between;gap:8px;align-items:center"><b style="font-size:13.5px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${tmxEsc(nome)}</b><span style="font-size:11px;color:var(--apagado,#96A0AC);white-space:nowrap">${rod}</span></div><div style="font-size:12.5px;color:var(--apoio,#3D4854);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;margin-top:2px">${tmxEsc(tmxAvisoTexto(c,m))}</div></div>`;
 const fechar=()=>{card.style.transform='translateX(120%)';card.style.opacity='0';setTimeout(()=>card.remove(),300);};
 card.onclick=()=>{fechar();tmxNotifAbrir(c.id);};
 w.insertBefore(card,w.firstChild);
 requestAnimationFrame(()=>{card.style.transform='translateX(0)';card.style.opacity='1';});
 setTimeout(fechar,7000);
 while(w.children.length>4)w.lastChild.remove();}
async function tmxAvisoAcao(a){const id=a.id;const c=tmxCanais.find(x=>x.id===id);
 if(a.acao==='abrir'){if(tmxCfg.abrirModulo)tmxCfg.abrirModulo();setTimeout(()=>{if(tmxNoModulo())tmxAbrirCanal(id);else{if(!tmxFlutAberto)tmxFlutAbrir();tmxFlutAbrirCanal(id);}},60);return {ok:true};}
 if(a.acao==='lida'){if(c&&c.nao_lidas){c.nao_lidas=0;tmxBadge();}const r=await tmx.rpc('chat_marcar_lido',{p_canal:id});return {ok:!r.error};}
 if(a.acao==='responder'){const t=String(a.texto||'').trim();if(!t)return {ok:false,erro:'Mensagem vazia.'};const r=await tmxGravarMsg({tipo:'texto',corpo:t},tmxMencoes(t),id);return r?{ok:true}:{ok:false,erro:'Não foi possível enviar.'};}
 return {ok:false};}
let tmxOnline=new Set(),tmxVisto={},tmxItemSel=null;
const TMX_FEED={aviso:['Aviso','📣'],pedido:['Pedido','📌'],reuniao:['Reunião','📅']};
const TMX_OLHO='<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><circle cx="12" cy="12" r="3"/></svg>';
const TMX_ICO_BALAO='<svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 11.5a8.4 8.4 0 0 1-12.4 7.4L3 21l2.1-5.5A8.4 8.4 0 1 1 21 11.5z"/></svg>';
function tmxMeusSetores(){return ((tmxPessoa(tmxEu.id).setores)||[]).slice().sort((a,b)=>String(tmxSetorNome(a)).localeCompare(String(tmxSetorNome(b)),'pt-BR'));}
function tmxParDep(sid){const meus=tmxMeusSetores();const a=meus.includes(sid)?sid:(meus[0]||sid);return [a,sid].sort();}
function tmxCanalDep(sid){const [x,y]=tmxParDep(sid);return tmxCanais.find(c=>c.tipo==='departamentos'&&c.setor_id===x&&c.setor_b_id===y);}
function tmxDepsDoCanal(c){return [...new Set([c.setor_id,c.setor_b_id].filter(Boolean))];}
function tmxPessoasDoCanal(c){if(c.tipo==='setor')return (tmxEquipe.pessoas||[]).filter(p=>(p.setores||[]).includes(c.setor_id));
 const ds=tmxDepsDoCanal(c),ms=c.membros||[];return (tmxEquipe.pessoas||[]).filter(p=>ms.includes(p.id)||(p.setores||[]).some(x=>ds.includes(x)));}
async function tmxAbrirDep(sid,flut){const meus=tmxMeusSetores();const a=meus.includes(sid)?sid:(meus[0]||sid);
 const ids=[...new Set([tmxEu.id,...(tmxEquipe.pessoas||[]).filter(p=>(p.setores||[]).some(x=>x===a||x===sid)).map(p=>p.id)])];
 const nome=a===sid?tmxSetorNome(sid):tmxSetorNome(a)+' + '+tmxSetorNome(sid);
 const r=await tmx.rpc('chat_abrir_departamentos',{p_a:a,p_b:sid,p_nome:nome,p_membros:ids});if(r.error||!r.data){tmxToast('Não foi possível abrir o departamento.');return;}
 await tmxCarregarCanais();tmxAba='conversas';if(flut)tmxFlutAbrirCanal(r.data);else tmxAbrirCanal(r.data);}
const TMX_DEP_IMG=['adm','contabil','financeiro','fiscal','legalizacao','pessoal','recepcao','rh','societario','suporte'];
function tmxDepSlug(nome){return String(nome||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z]/g,'');}
function tmxDepImg(sid,t){const sl=tmxDepSlug(tmxSetorNome(sid));return TMX_DEP_IMG.includes(sl)?TMX_BASE+'img/departamentos/'+sl+'-'+t+'.webp':'';}
function tmxDepAlvo(c){if(!c)return null;if(c.tipo==='setor')return c.setor_id;if(c.tipo!=='departamentos')return null;if(c.setor_id===c.setor_b_id)return c.setor_id;
 const meus=tmxMeusSetores();return meus.includes(c.setor_id)?c.setor_b_id:meus.includes(c.setor_b_id)?c.setor_id:c.setor_b_id;}
function tmxDepFoto(c,alt){const d=tmxDepAlvo(c);const u=d?tmxDepImg(d,'perfil'):'';return u?`<img src="${tmxEsc(u)}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:inherit">`:alt;}
function tmxDepFundo(c){const d=tmxDepAlvo(c);const u=d?tmxDepImg(d,'fundo'):'';return u?` data-fundo="1" style="background-image:url(&quot;${encodeURI(u)}&quot;);background-size:420px;background-repeat:repeat"`:'';}
function tmxSetoresVisiveis(){const ss=(tmxEquipe&&tmxEquipe.setores||[]).slice().sort((a,b)=>a.nome.localeCompare(b.nome,'pt-BR'));const com=ss.filter(x=>TMX_DEP_IMG.includes(tmxDepSlug(x.nome)));return com.length?com:ss;}
function tmxOnlineAgora(id){return tmxOnline.has(id)&&(tmxPres[id]||'online')!=='offline';}
function tmxQuando(d){if(!d)return '';const x=new Date(d),h=new Date(),o=new Date();o.setDate(h.getDate()-1);const hr=tmxHora(d);
 if(x.toDateString()===h.toDateString())return 'hoje às '+hr;if(x.toDateString()===o.toDateString())return 'ontem às '+hr;return tmxDia(d)+' às '+hr;}
function tmxStatusPessoa(id){if(tmxOnlineAgora(id)){const st=TMX_ST[tmxPres[id]||'online']||TMX_ST.online;return {t:st[0],cor:st[1],on:true};}
 return {t:tmxVisto[id]?'Visto por último '+tmxQuando(tmxVisto[id]):'Offline',cor:'var(--nevoa)',on:false};}
function tmxDepsHtml(){
 const ss=tmxSetoresVisiveis();
 return `<div class="tm-sec">Chat Departamentos</div><div class="tm-deps">${ss.map(s=>{const c=tmxCanalDep(s.id);
  const n=c&&!c.silenciado?(c.nao_lidas||0):0;const on=c&&tmxSel===c.id&&tmxAba==='conversas';
  const k=(tmxEquipe.pessoas||[]).filter(p=>(p.setores||[]).includes(s.id)&&tmxOnlineAgora(p.id)).length;
  return `<button class="tm-dep${on?' on':''}${n?' nl':''}" onclick="tmxAbrirDep('${s.id}',false)"><span class="tm-depic" style="background:${tmxCor(s.nome)}">${tmxDepImg(s.id,'perfil')?`<img src="${tmxEsc(tmxDepImg(s.id,'perfil'))}" alt="">`:TMX_ICO_PREDIO}</span><span class="tm-depc"><b>${tmxEsc(s.nome)}</b><em>${k} online</em></span>${n?`<i>${n>99?'99+':n}</i>`:''}</button>`;}).join('')}</div>`;}
function tmxCaixaLista(){return tmxCaixa().filter(c=>c.tipo!=='setor'&&c.tipo!=='departamentos'&&(c.ultima||c.tipo==='direta'||c.id===tmxSel));}
function tmxFeedItens(){
 const a=tmxAvisos.map(x=>({tipo:'aviso',id:x.id,em:x.criado_em,titulo:x.titulo,quem:x.autor_id,meu:x.autor_id===tmxEu.id,
  sub:x.escopo==='setor'?(tmxSetorNome(x.setor_id)||'Departamento'):'Todos',novo:x.autor_id!==tmxEu.id&&!tmxVistos.has(x.id)}));
 const p=tmxPedidos.filter(x=>x.solicitante_id===tmxEu.id||x.responsavel_id===tmxEu.id).map(x=>({tipo:'pedido',id:x.id,em:x.criado_em,titulo:x.titulo,quem:x.solicitante_id,meu:x.solicitante_id===tmxEu.id,
  sub:(x.solicitante_id===tmxEu.id?'Para '+tmxPessoa(x.responsavel_id).nome.split(' ')[0]:'Comigo')+' · '+(TMX_PED[x.status]||x.status),novo:false}));
 const r=tmxReunioes.filter(x=>x.criado_por===tmxEu.id||(x.chat_reuniao_participante||[]).some(y=>y.usuario_id===tmxEu.id)).map(x=>({tipo:'reuniao',id:x.id,em:x.criado_em||x.inicio,titulo:x.titulo,quem:x.criado_por,meu:x.criado_por===tmxEu.id,
  sub:x.inicio?'Em '+tmxDia(x.inicio)+' às '+tmxHora(x.inicio):'Sem data',novo:false}));
 return a.concat(p,r).sort((x,y)=>new Date(y.em||0)-new Date(x.em||0));}
function tmxFeedHtml(){const it=tmxFeedItens();
 return `<div class="tm-sec">Avisos e pedidos<button title="Criar" onclick="tmxMenuCriar(event)">＋ Novo</button></div><div class="tm-feed" id="tmxFeed">${it.map(x=>`<div class="tm-fi ${x.tipo}${x.novo?' novo':''}${tmxItemSel===x.tipo+':'+x.id&&tmxAba!=='conversas'?' on':''}" onclick="tmxAbrirItem('${x.tipo}','${x.id}')"><span class="tm-fiic">${TMX_FEED[x.tipo][1]}</span><div class="tm-fic"><div class="tm-fil1"><em>${TMX_FEED[x.tipo][0]}</em><span>${tmxEsc(tmxDia(x.em))} ${tmxEsc(tmxHora(x.em))}</span></div><b>${tmxEsc(x.titulo||'')}</b><span>${tmxEsc(tmxPessoa(x.quem).nome.split(' ')[0])} · ${tmxEsc(x.sub)}</span></div>${x.meu?`<button class="tm-olho" title="Quem viu" onclick="event.stopPropagation();tmxQuemViu('${x.tipo}','${x.id}')">${TMX_OLHO}</button>`:''}</div>`).join('')}</div>`;}
function tmxMenuCriar(ev){tmxMenu(ev,[['Novo aviso',()=>tmxNovoAviso()],['Novo pedido',()=>{tmxSel=null;tmxNovoPedido(null);}],['Agendar reunião',()=>tmxNovaReuniao()]]);}
async function tmxCarregarFeed(){if(!tmx)return;
 const [a,v,p,r]=await Promise.all([tmx.from('chat_aviso').select('id,escopo,setor_id,titulo,corpo,autor_id,criado_em,nivel').order('criado_em',{ascending:false}).limit(100),
  tmx.from('chat_aviso_visto').select('aviso_id').eq('usuario_id',tmxEu.id),
  tmx.from('chat_pedido').select('id,titulo,descricao,solicitante_id,responsavel_id,status,prazo,criado_em,canal_id,cliente_id,empresa_ids,todas_empresas,chat_anexo(id,nome,url,tamanho)').order('criado_em',{ascending:false}).limit(300),
  tmx.from('chat_reuniao').select('id,titulo,pauta,inicio,fim,criado_por,criado_em,chat_reuniao_participante(usuario_id,confirmado)').order('inicio',{ascending:true}).limit(100)]);
 if(!a.error)tmxAvisos=a.data||[];if(!v.error)tmxVistos=new Set((v.data||[]).map(x=>x.aviso_id));if(!p.error){tmxPedidos=p.data||[];tmxPedResolver(tmxPedidos).then(n=>{if(n&&tmxSel)tmxCarregarMsgs(tmxSel);});}if(!r.error)tmxReunioes=r.data||[];
 if(tmxNoModulo())tmxDesenharLista();}
async function tmxAbrirItem(tipo,id){tmxItemSel=tipo+':'+id;tmx.rpc('chat_registrar_visto',{p_tipo:tipo,p_id:id}).then(()=>{},()=>{});
 if(tipo==='aviso')await tmxAbrirAvisos();else if(tipo==='pedido'){tmxPedFiltro='todos';await tmxAbrirPedidos();}else await tmxAbrirReunioes();
 const e=tmxEl('tmi-'+id);if(e){e.classList.add('tm-foco');e.scrollIntoView({block:'center'});}}
async function tmxQuemViu(tipo,id){const r=await tmx.rpc('chat_quem_viu',{p_tipo:tipo,p_id:id});const l=(!r.error&&Array.isArray(r.data))?r.data:[];
 tmxModal('Visto por '+l.length+(l.length===1?' pessoa':' pessoas'),l.map(x=>{const p=tmxPessoa(x.usuario_id);
  return `<div style="display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid var(--superf2)"><div class="av" style="width:32px;height:32px;font-size:11px;background:${tmxCor(p.nome)}">${tmxEsc(tmxIni(p.nome))}</div><b style="flex:1;font-size:12.5px">${tmxEsc(p.nome)}</b><span style="font-size:11.5px;color:var(--apagado)">${tmxEsc(tmxDia(x.visto_em)+' às '+tmxHora(x.visto_em))}</span></div>`;}).join(''),420);}
function tmxMembrosHtml(c){
 const ds=c.tipo==='setor'?[c.setor_id]:tmxDepsDoCanal(c);const todos=tmxPessoasDoCanal(c);const k=todos.filter(p=>tmxOnlineAgora(p.id)).length;
 const linha=p=>{const st=tmxStatusPessoa(p.id);const eu=p.id===tmxEu.id;
  return `<div class="tm-mb"><div class="tm-av" style="width:36px;height:36px;font-size:11.5px;background:${tmxCor(p.nome)}">${p.foto_url?`<img src="${tmxEsc(p.foto_url)}" alt="">`:tmxEsc(tmxIni(p.nome))}<span class="tm-pres" style="background:${st.cor}"></span></div><div class="tm-mbc"><b>${tmxEsc(p.nome)}${eu?' (você)':''}</b><span style="color:${st.on?st.cor:'var(--apagado)'}">${tmxEsc(st.t)}</span></div>${eu?'':`<div class="tm-mbb"><button title="Conversar" onclick="tmxAbrirDireta('${p.id}')">${TMX_ICO_BALAO}</button><button title="Ligar" onclick="tmxLigarPessoa('${p.id}','voz')">${TMX_ICO_FONE}</button><button title="Chamada de vídeo" onclick="tmxLigarPessoa('${p.id}','video')">${TMX_ICO_CAM}</button></div>`}</div>`;};
 const grupos=ds.map(d=>({d,ps:todos.filter(p=>(p.setores||[]).includes(d)).sort((a,b)=>a.nome.localeCompare(b.nome,'pt-BR'))}));
 const fora=todos.filter(p=>!(p.setores||[]).some(x=>ds.includes(x))).sort((a,b)=>a.nome.localeCompare(b.nome,'pt-BR'));
 return `<div class="tm-mcab"><b>${tmxEsc(ds.map(tmxSetorNome).join(' + ')||'Departamento')}</b><span>${todos.length} ${todos.length===1?'pessoa':'pessoas'} · ${k} online</span></div>${grupos.map(g=>(ds.length>1?`<div class="tm-sec">${tmxEsc(tmxSetorNome(g.d))}</div>`:'')+g.ps.map(linha).join('')).join('')}${fora.length?`<div class="tm-sec">Também na conversa</div>${fora.map(linha).join('')}`:''}`;}
async function tmxLigarPessoa(id,tipo){await tmxAbrirDireta(id);tmxLigar(tipo);}
function tmxRedesenharPresenca(){if(tmxNoModulo()){tmxDesenharLista();const m=tmxEl('tmxMembros');const c=tmxCanais.find(x=>x.id===tmxSel);if(m&&c&&(c.tipo==='setor'||c.tipo==='departamentos'))m.innerHTML=tmxMembrosHtml(c);}if(tmxFlutAberto&&!tmxFlutCanal)tmxFlutDesenhar();}
function tmxOnlineLigar(){const pc=tmx.channel('teams-online',{config:{presence:{key:tmxEu.id}}});
 pc.on('presence',{event:'sync'},()=>{tmxOnline=new Set(Object.keys(pc.presenceState()));tmxRedesenharPresenca();})
  .subscribe(st=>{if(st==='SUBSCRIBED')pc.track({desde:new Date().toISOString()}).then(()=>{},()=>{});});}
function tmxRenderTeams(){
 tmxModRaiz().innerHTML=`<div class="waweb"><div class="walist" id="tmxLista"></div><div class="wachat" id="tmxCentro"></div></div>`;
 if(!tmxPronto){tmxIniciar().then(ok=>{if(!tmxNoModulo())return;if(!ok){tmxEl('tmxCentro').innerHTML='';tmxToast('Não foi possível entrar no Team\'s.');return;}tmxDesenharTudo();});return;}
 tmxDesenharTudo();
}
function tmxDesenharTudo(){tmxDesenharLista();if(tmxAba==='avisos')tmxAbrirAvisos();else if(tmxAba==='pedidos')tmxAbrirPedidos();else if(tmxAba==='reunioes')tmxAbrirReunioes();else tmxDesenharConversa();}
function tmxPrevia(c){const u=c.ultima;if(!u)return {t:'',h:''};const quem=u.autor_id===tmxEu.id?'Você: ':(c.tipo!=='direta'?tmxPessoa(u.autor_id).nome.split(' ')[0]+': ':'');return {t:quem+(u.tipo==='audio'?'🎤 Áudio':u.tipo==='arquivo'?'📎 '+(u.corpo||'Arquivo'):u.tipo==='pedido'?'📌 '+(u.corpo||'Pedido'):(u.corpo||'')),h:u.em?tmxHora(u.em):''};}
let tmxNova=false,tmxNovaBusca='',tmxNovaDep='',tmxNovaNivel='';
const TMX_NIVEL={ceo:'CEO',diretor:'Diretor',gerente:'Gerente',assistente:'Assistente',colaborador:'Colaborador'};
function tmxNivelNome(n){return TMX_NIVEL[n]||(n?n.charAt(0).toUpperCase()+n.slice(1):'');}
function tmxItemCanal(c,on,fn){const nm=tmxNomeCanal(c);let av={cor:tmxCor(nm),html:tmxEsc(tmxIni(nm))};
 if(c.tipo==='grupo')av.html=TMX_ICO_GRUPO;
 if(c.tipo==='direta'){const o=(c.membros||[]).find(x=>x!==tmxEu.id);const pe=tmxPessoa(o);if(pe.foto_url)av.html=`<img src="${tmxEsc(pe.foto_url)}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:inherit">`;av.pres=tmxStatusPessoa(o).cor;}
 return tmxItem(c.id,nm,tmxPrevia(c),av,c.silenciado?0:c.nao_lidas,on,fn);}
function tmxNovaHtml(flut){
 const t=tmxNovaBusca.trim().toLowerCase();const ps=(tmxEquipe&&tmxEquipe.pessoas||[]).filter(p=>p.id!==tmxEu.id);
 const niveis=[...new Set(ps.map(p=>p.nivel).filter(Boolean))].sort((a,b)=>Object.keys(TMX_NIVEL).indexOf(a)-Object.keys(TMX_NIVEL).indexOf(b));
 const lista=ps.filter(p=>(!t||p.nome.toLowerCase().includes(t)||(p.setores||[]).some(s=>tmxSetorNome(s).toLowerCase().includes(t))||tmxNivelNome(p.nivel).toLowerCase().includes(t))
  &&(!tmxNovaDep||(p.setores||[]).includes(tmxNovaDep))&&(!tmxNovaNivel||p.nivel===tmxNovaNivel));
 const setores=(tmxEquipe&&tmxEquipe.setores||[]).filter(s=>(!tmxNovaDep||s.id===tmxNovaDep)&&(!t||s.nome.toLowerCase().includes(t))&&!tmxNovaNivel);
 const pf=flut?'tmxFlut':'tm';
 return `<div class="tm-novacab"><button onclick="tmxNova=false;${flut?'tmxFlutDesenhar()':'tmxDesenharLista()'}">‹</button><b>Nova conversa</b></div>
  <div class="srch"><input id="${pf}nb" placeholder="🔎  Buscar por nome, departamento ou nível" value="${tmxEsc(tmxNovaBusca)}" oninput="tmxNovaBusca=this.value;tmxNovaRedesenhar(${flut})"></div>
  <div class="tm-filtros"><select onchange="tmxNovaDep=this.value;tmxNovaRedesenhar(${flut})"><option value="">Todos os departamentos</option>${(tmxEquipe&&tmxEquipe.setores||[]).map(s=>`<option value="${s.id}" ${s.id===tmxNovaDep?'selected':''}>${tmxEsc(s.nome)}</option>`).join('')}</select><select onchange="tmxNovaNivel=this.value;tmxNovaRedesenhar(${flut})"><option value="">Todos os níveis</option>${niveis.map(n=>`<option value="${tmxEsc(n)}" ${n===tmxNovaNivel?'selected':''}>${tmxEsc(tmxNivelNome(n))}</option>`).join('')}</select></div>
  <div class="rl" style="flex:1;overflow-y:auto;background:var(--pagina)">
   ${!t&&!tmxNovaDep&&!tmxNovaNivel?`<div class="waconv" onclick="tmxNovoGrupo()"><div class="av" style="background:var(--grad)">${TMX_ICO_GRUPO}</div><div style="flex:1"><div class="nm"><span>Novo grupo</span></div></div></div>`:''}
   ${setores.length?`<div class="tm-sec">Departamentos</div>${setores.map(s=>tmxItem(s.id,s.nome,{t:(n=>n+(n===1?' pessoa':' pessoas'))((tmxEquipe.pessoas||[]).filter(p=>(p.setores||[]).includes(s.id)).length),h:''},{cor:tmxCor(s.nome),html:tmxEsc(tmxIni(s.nome))},0,false,`tmxNovaSetor('${s.id}',${flut})`)).join('')}`:''}
   ${lista.length?`<div class="tm-sec">Contatos</div>${lista.map(p=>tmxItem(p.id,p.nome,{t:[tmxNivelNome(p.nivel),(p.setores||[]).map(tmxSetorNome).join(', ')].filter(Boolean).join(' · '),h:''},{cor:tmxCor(p.nome),html:p.foto_url?`<img src="${tmxEsc(p.foto_url)}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:inherit">`:tmxEsc(tmxIni(p.nome)),pres:(TMX_ST[tmxPres[p.id]||'offline']||TMX_ST.offline)[1]},0,false,`tmxNovaPessoa('${p.id}',${flut})`)).join('')}`:''}
  </div>`;
}
function tmxNovaRedesenhar(flut){const id=(flut?'tmxFlut':'tm')+'nb';const i=tmxEl(id);const pos=i?i.selectionStart:null;
 if(flut)tmxFlutDesenhar();else tmxDesenharLista();
 const j=tmxEl(id);if(j&&pos!=null){j.focus();j.setSelectionRange(pos,pos);}}
function tmxAbrirNova(flut){tmxNova=true;tmxNovaBusca='';tmxNovaDep='';tmxNovaNivel='';if(flut)tmxFlutDesenhar();else tmxDesenharLista();const i=tmxEl((flut?'tmxFlut':'tm')+'nb');if(i)i.focus();}
async function tmxNovaPessoa(pid,flut){tmxNova=false;if(!flut){tmxAbrirDireta(pid);return;}
 const r=await tmx.rpc('chat_abrir_direta',{p_outro:pid});if(r.error){tmxToast('Não foi possível abrir a conversa.');return;}await tmxCarregarCanais();tmxFlutAbrirCanal(r.data);}
function tmxNovaSetor(sid,flut){tmxNova=false;tmxAbrirDep(sid,!!flut);}
let tmxSub='entrada';
const TMX_ICO_PREDIO='<svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 21h18M5 21V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16M9 7h2M13 7h2M9 11h2M13 11h2M9 15h2M13 15h2"/></svg>';
function tmxItem(id,nome,sub,av,n,on,fn){
 return `<div class="tm-it${on?' on':''}${n?' nl':''}" onclick="${fn}"><div class="tm-av" style="background:${av.cor}">${av.html}${av.pres?`<span class="tm-pres" style="background:${av.pres}"></span>`:''}</div><div class="tm-itc"><div class="tm-l1"><b>${tmxEsc(nome)}</b><span>${tmxEsc(sub.h||'')}</span></div><div class="tm-l2"><span>${tmxEsc(sub.t||'')}</span>${n?`<i>${n>99?'99+':n}</i>`:''}</div></div></div>`;
}
function tmxHoje(c){const e=(c.ultima||{}).em;return !!e&&new Date(e).toDateString()===new Date().toDateString();}
function tmxCaixa(){
 const t=tmxBusca.trim().toLowerCase();
 return tmxCanais.filter(c=>!t||tmxNomeCanal(c).toLowerCase().includes(t)||String((c.ultima||{}).corpo||'').toLowerCase().includes(t))
  .sort((a,b)=>new Date((b.ultima||{}).em||0)-new Date((a.ultima||{}).em||0));
}
function tmxListaSub(sub,flut){
 const ab=id=>flut?`tmxFlutAbrirCanal('${id}')`:`tmxAbrirCanal('${id}')`;
 const sel=id=>!flut&&tmxSel===id&&tmxAba==='conversas';
 if(sub==='grupos'){
  const t=tmxBusca.trim().toLowerCase();
  const deps=tmxSetoresVisiveis().filter(s=>!t||s.nome.toLowerCase().includes(t)).map(s=>{const c=tmxCanalDep(s.id);
   const np=(tmxEquipe.pessoas||[]).filter(p=>(p.setores||[]).includes(s.id)).length;
   return tmxItem(s.id,s.nome,c&&c.ultima?tmxPrevia(c):{t:np+(np===1?' pessoa':' pessoas'),h:''},{cor:tmxCor(s.nome),html:tmxDepImg(s.id,'perfil')?`<img src="${tmxEsc(tmxDepImg(s.id,'perfil'))}" alt="">`:TMX_ICO_PREDIO},c&&!c.silenciado?c.nao_lidas:0,c&&sel(c.id),`tmxAbrirDep('${s.id}',${flut?'true':'false'})`);}).join('');
  const grs=tmxCanais.filter(c=>c.tipo==='grupo'&&(!t||String(c.nome).toLowerCase().includes(t))).sort((a,b)=>String(a.nome).localeCompare(String(b.nome))).map(c=>tmxItemCanal(c,sel(c.id),ab(c.id))).join('');
  return `<div class="tm-sec">Departamentos</div>${deps}<div class="tm-sec">Grupos<button onclick="tmxNovoGrupo()" title="Novo grupo">＋ Novo</button></div>${grs}`;
 }
 const lista=tmxCaixaLista();
 return lista.map(c=>tmxItemCanal(c,sel(c.id),ab(c.id))).join('');
}
function tmxNaEntrada(c,flut){return tmxHoje(c)||(c.nao_lidas||0)>0||(c.id===tmxSel&&!flut);}
function tmxContSub(sub){const cs=sub==='grupos'?tmxCanais.filter(c=>c.tipo!=='direta'):tmxCanais.filter(c=>c.tipo!=='setor'&&c.tipo!=='departamentos');return cs.filter(c=>!c.silenciado).reduce((s,c)=>s+(c.nao_lidas||0),0);}
function tmxSubAbas(flut){
 const b=(id,t)=>{const n=tmxContSub(id);return `<button class="${tmxSub===id?'on':''}" onclick="tmxSub='${id}';${flut?'tmxFlutDesenhar()':'tmxDesenharLista()'}">${t}${n?`<i>${n>99?'99+':n}</i>`:''}</button>`;};
 if(tmxSub==='anteriores')tmxSub='entrada';
 return `<div class="tm-subs">${b('entrada','Caixa de entrada')}${b('grupos','Departamentos')}</div>`;
}
function tmxDesenharLista(){
 const box=tmxEl('tmxLista');if(!box)return;
 const meuSt=tmxPres[tmxEu.id]||'online';const st=TMX_ST[meuSt]||TMX_ST.online;
 const qtd={conversas:tmxNaoLidasTotal(),avisos:tmxPend.avisos||0,pedidos:tmxPend.pedidos||0,reunioes:tmxPend.reunioes||0};
 const ferr=(id,tit)=>`<button class="${tmxAba===id?'on':''}" onclick="tmxIrAba('${id}')">${tit}${qtd[id]?`<i>${qtd[id]>99?'99+':qtd[id]}</i>`:''}</button>`;
 const pe=tmxPessoa(tmxEu.id);
 const topo=`<div class="tm-perfil"><div class="tm-av g" style="background:${tmxCor(tmxEu.nome)}">${pe.foto_url?`<img src="${tmxEsc(pe.foto_url)}" alt="">`:tmxEsc(tmxIni(tmxEu.nome))}<span class="tm-pres" style="background:${st[1]}"></span></div>
   <div class="tm-perfc"><b>${tmxEsc(tmxEu.nome)}</b><span>${tmxEsc((pe.setores||[]).map(tmxSetorNome).filter(Boolean).join(' · ')||'Team\'s')}</span>
   <label class="tm-stsel"><i style="background:${st[1]}"></i><select onchange="tmxMudarStatus(this.value)">${Object.keys(TMX_ST).filter(k=>k!=='offline').map(k=>`<option value="${k}" ${k===meuSt?'selected':''}>${TMX_ST[k][0]}</option>`).join('')}</select></label></div>
   <button class="tm-novo" title="Nova conversa" onclick="tmxIrAba('conversas');tmxAbrirNova(false)">＋</button></div>`;
 if(tmxNova){box.innerHTML=topo+tmxNovaHtml(false);return;}
 const busca=tmxEl('tmbusca');const foco=busca&&tmxAtivo()===busca;const fe=tmxEl('tmxFeed'),cx=tmxEl('tmxCx'),la=tmxEl('tmxLado3');const rf=fe?fe.scrollTop:0,rc=cx?cx.scrollTop:0,rl=la?la.scrollTop:0;
 const sel=c=>tmxSel===c.id&&tmxAba==='conversas';
 box.innerHTML=topo+`<div class="tm-lado3" id="tmxLado3">${tmxDepsHtml()}<div class="tm-sec">Caixa de entrada</div><div class="tm-busca2"><input id="tmbusca" placeholder="Buscar conversa ou pessoa" value="${tmxEsc(tmxBusca)}" oninput="tmxBusca=this.value;tmxDesenharLista()"></div><div class="tm-rl tm-cx" id="tmxCx">${tmxCaixaLista().map(c=>tmxItemCanal(c,sel(c),`tmxAba='conversas';tmxAbrirCanal('${c.id}')`)).join('')}</div>${tmxFeedHtml()}</div>`;
 const fe2=tmxEl('tmxFeed'),cx2=tmxEl('tmxCx'),la2=tmxEl('tmxLado3');if(fe2)fe2.scrollTop=rf;if(cx2)cx2.scrollTop=rc;if(la2)la2.scrollTop=rl;
 if(foco){const b=tmxEl('tmbusca');b.focus();b.setSelectionRange(b.value.length,b.value.length);}
}
function tmxLadoResumo(){
 const it=(ic,t,n,sub)=>`<div class="tm-res"><span class="tm-resic">${ic}</span><div><b>${n}</b><span>${t}</span>${sub?`<em>${sub}</em>`:''}</div></div>`;
 if(tmxAba==='avisos')return it('📣','avisos sem ver',tmxPend.avisos||0,'');
 if(tmxAba==='pedidos'){const meus=tmxPedidos.filter(p=>p.responsavel_id===tmxEu.id&&p.status!=='concluido'&&p.status!=='cancelado');const venc=meus.filter(p=>p.prazo&&p.prazo<new Date().toISOString().slice(0,10)).length;
  return it('📌','pedidos comigo em aberto',meus.length,venc?venc+' com prazo vencido':'')+it('📤','pedidos que eu fiz em aberto',tmxPedidos.filter(p=>p.solicitante_id===tmxEu.id&&p.status!=='concluido'&&p.status!=='cancelado').length,'');}
 if(tmxAba==='reunioes'){const prox=tmxReunioes.filter(r=>r.inicio&&r.inicio>=new Date().toISOString());const hoje=prox.filter(r=>new Date(r.inicio).toDateString()===new Date().toDateString()).length;
  return it('📅','próximas reuniões',prox.length,hoje?hoje+' hoje':'');}
 return '';
}
function tmxIrAba(a){tmxAba=a;tmxDesenharTudo();}
async function tmxMudarStatus(s){tmxPres[tmxEu.id]=s;const r=await tmx.from('chat_presenca').upsert({usuario_id:tmxEu.id,status:s,visto_por_ultimo_em:new Date().toISOString(),atualizado_em:new Date().toISOString()}).select('usuario_id');if(r.error||!r.data||!r.data.length)tmxToast('Não foi possível mudar o status.');}
async function tmxAbrirSetor(sid){const r=await tmx.rpc('chat_abrir_setor',{p_setor:sid,p_nome:tmxSetorNome(sid)});if(r.error){tmxToast('Não foi possível abrir o setor.');return;}if(!tmxCanais.find(c=>c.id===r.data))await tmxCarregarCanais();tmxAbrirCanal(r.data);}
async function tmxAbrirDireta(pid){const r=await tmx.rpc('chat_abrir_direta',{p_outro:pid});if(r.error){tmxToast('Não foi possível abrir a conversa.');return;}tmxBusca='';await tmxCarregarCanais();tmxAbrirCanal(r.data);}
function tmxAbrirCanal(id){tmxAba='conversas';tmxSel=id;tmxResp=null;const c=tmxCanais.find(x=>x.id===id);if(c&&c.nao_lidas){c.nao_lidas=0;tmxBadge();}tmx.rpc('chat_marcar_lido',{p_canal:id}).then(()=>{},()=>{});tmxDesenharLista();tmxDesenharConversa();}
async function tmxCarregarMsgs(id){
 const r=await tmx.from('chat_mensagem').select('id,canal_id,autor_id,tipo,corpo,meta,responde_a,criada_em,editada_em,excluida_em,chat_anexo(id,tipo,nome,url,tamanho,transcricao)').eq('canal_id',id).is('excluida_em',null).order('criada_em',{ascending:false}).limit(300);
 if(r.error){tmxToast('Não foi possível carregar as mensagens.');return;}
 tmxMsgs[id]=r.data.reverse();if(tmxNoModulo()&&tmxSel===id)tmxDesenharMsgs();if(tmxFlutAberto&&tmxFlutCanal===id)tmxDesenharMsgs('tmfms',id);
}
function tmxDesenharConversa(){
 const box=tmxEl('tmxCentro');if(!box)return;const c=tmxCanais.find(x=>x.id===tmxSel);
 if(!c){box.innerHTML='';return;}
 const nome=tmxNomeCanal(c);let sub='';
 if(c.tipo==='direta'){const o=(c.membros||[]).find(x=>x!==tmxEu.id);sub=tmxStatusPessoa(o).t+' · '+(tmxPessoa(o).setores||[]).map(tmxSetorNome).join(', ');}
 else if(c.tipo==='setor'||c.tipo==='departamentos'){const ps=tmxPessoasDoCanal(c);sub=(c.tipo==='departamentos'&&c.setor_id!==c.setor_b_id?tmxSetorNome(c.setor_id)+' + '+tmxSetorNome(c.setor_b_id)+' · ':'')+ps.length+(ps.length===1?' pessoa · ':' pessoas · ')+ps.filter(p=>tmxOnlineAgora(p.id)).length+' online';}
 else sub=(c.membros||[]).length+' participantes';
 const html=`<div class="wa-head tm-head"><span class="avc" style="overflow:hidden">${c.tipo==='grupo'?TMX_ICO_GRUPO:tmxDepFoto(c,tmxEsc(tmxIni(nome)))}</span><div class="nm" style="cursor:pointer" onclick="tmxParticipantes()"><b>${tmxEsc(nome)}</b><span>${tmxEsc(sub)}</span></div><button class="wa-hbtn" title="Ligar" onclick="tmxLigar('voz')">${TMX_ICO_FONE}</button><button class="wa-hbtn" title="Chamada de vídeo" onclick="tmxLigar('video')">${TMX_ICO_CAM}</button><button class="wa-hbtn" onclick="tmxMenuCanal(event)">${TMX_ICO_MAIS}</button></div>
  <div class="wa-msgs" id="tmms"${tmxDepFundo(c)}></div>
  <div id="tmxComp">${tmxComposer()}</div>`;
 box.innerHTML=(c.tipo==='setor'||c.tipo==='departamentos')?`<div class="tm-depwrap"><div class="tm-depchat">${html}</div><aside class="tm-membros" id="tmxMembros">${tmxMembrosHtml(c)}</aside></div>`:html;
 if(!tmxMsgs[c.id])tmxCarregarMsgs(c.id);else tmxDesenharMsgs();
}
function tmxComposer(){
 const c=tmxCanais.find(x=>x.id===tmxSel);const msgs=tmxMsgs[tmxSel]||[];const r=tmxResp?msgs.find(m=>m.id===tmxResp):null;
 return `${r?`<div class="wa-resp"><div class="q"><b>${tmxEsc(r.autor_id===tmxEu.id?'Você':tmxPessoa(r.autor_id).nome)}</b><span>${tmxEsc(r.corpo||'')}</span></div><button onclick="tmxResp=null;tmxEl('tmxComp').innerHTML=tmxComposer()">✕</button></div>`:''}
 ${tmxGrav?`<div class="wa-comp"><span class="wa-rec">● Gravando ${tmxGrav.seg||0}s</span><span style="flex:1"></span><button class="miniB" onclick="tmxGravarCancelar()">Cancelar</button><button class="snd" onclick="tmxGravarParar()">➤</button></div>`
 :`${tmxToolsHtml()}<div id="tmxBand" data-canal="${tmxEsc(tmxSel||'')}">${tmxBandejaHtml(tmxSel)}</div><div class="wa-comp"><span class="pl" onclick="tmxMenuAnexo(event)">${TMX_ICO_CLIPE}</span><textarea id="tmin" rows="1" placeholder="Mensagem — use @ para mencionar" oninput="this.style.height='auto';this.style.height=Math.min(this.scrollHeight,130)+'px';if(this.value.endsWith('@'))tmxMencionar()" onkeydown="if(event.key==='Enter'&&!event.shiftKey&&!event.ctrlKey&&!event.isComposing){event.preventDefault();tmxEnviar();}"></textarea><span class="pl" title="Gravar áudio" onclick="tmxGravar()">${TMX_MIC}</span><button class="snd" onclick="tmxEnviar()">➤</button></div>`}`;
}
function tmxTexto(t){let h=tmxEsc(t||'');(tmxEquipe&&tmxEquipe.pessoas||[]).forEach(p=>{const n=tmxEsc('@'+p.nome);if(h.includes(n))h=h.split(n).join(`<span class="tm-men">${n}</span>`);});return h;}
function tmxDesenharMsgs(boxId,canalId){
 boxId=boxId||'tmms';canalId=canalId||tmxSel;const flut=boxId!=='tmms';
 const box=tmxEl(boxId);if(!box)return;const c=tmxCanais.find(x=>x.id===canalId);const msgs=tmxMsgs[canalId]||[];
 let ult=null,html='';
 msgs.forEach(m=>{const d=tmxDia(m.criada_em);if(d!==ult){html+=`<span class="ap-dia">${tmxEsc(d)}</span>`;ult=d;}
  if(m.tipo==='sistema'){html+=`<span class="ap-dia tm-sis">${tmxEsc(m.corpo||'')} · ${tmxEsc(tmxPessoa(m.autor_id).nome.split(' ')[0])} · ${tmxHora(m.criada_em)}</span>`;return;}
  const mine=m.autor_id===tmxEu.id,cls=mine?'ag':'cl',pe=tmxPessoa(m.autor_id);
  const q=m.responde_a?msgs.find(x=>x.id===m.responde_a):null;
  let inner='';
  if(!mine&&c&&c.tipo!=='direta')inner+=`<div class="wa-autor" style="color:${tmxCor(pe.nome)}">${tmxEsc(pe.nome)}</div>`;
  if(m.responde_a)inner+=`<div class="wa-cit"><b>${q?tmxEsc(q.autor_id===tmxEu.id?'Você':tmxPessoa(q.autor_id).nome):''}</b><span>${q?tmxEsc(q.corpo||''):'Mensagem'}</span></div>`;
  (m.chat_anexo||[]).forEach(a=>{const u=tmxUrls[a.url];
   if(a.tipo==='imagem')inner+=u?`<img class="wa-img" src="${tmxEsc(u)}" alt="" data-p="${tmxEsc(a.url||'')}" data-n="${tmxEsc(a.nome||'foto.jpg')}" onclick="tmxVerImagem(this.src,this.dataset.p,this.dataset.n)">`:`<div class="wa-doc"><span class="fi">IMG</span>Carregando…</div>`;
   else if(a.tipo==='audio')inner+=u?`<audio src="${tmxEsc(u)}" controls style="max-width:240px;height:34px"></audio>`:`<div class="wa-doc"><span class="fi">ÁUD</span>Carregando…</div>`;
   else inner+=`<div class="wa-doc" style="cursor:pointer" data-p="${tmxEsc(a.url||'')}" data-n="${tmxEsc(a.nome||'arquivo')}" onclick="tmxBaixar(this.dataset.p,this.dataset.n)"><span class="fi">${tmxEsc((String(a.nome||'').split('.').pop()||'ARQ').slice(0,4).toUpperCase())}</span>${tmxEsc(a.nome||'Arquivo')}</div>`;});
  if(m.tipo==='pedido'&&m.meta&&m.meta.pedido_id){const p=tmxPedidos.find(x=>x.id===m.meta.pedido_id);inner+=`<div class="tm-ped"><b>📌 Pedido</b><span>${tmxEsc(m.corpo||'')}</span><span>Responsável: ${tmxEsc(tmxPessoa(m.meta.responsavel_id).nome)}${m.meta.prazo?' · prazo '+tmxEsc(m.meta.prazo.split('-').reverse().join('/')):''}${p?' · '+tmxEsc(TMX_PED[p.status]||p.status):''}</span>${tmxPedClienteHtml(p)}${p?`<span>${tmxPedAnexosHtml(p)}</span>`:''}</div>`;}
  else if(m.tipo!=='audio'&&m.tipo!=='arquivo'){if(!(m.meta&&m.meta.cliente_id&&m.corpo==='Cliente citado'))inner+=tmxTexto(m.corpo);if(m.meta&&m.meta.cliente_id)inner+=tmxCartaoCliente(m.meta.cliente_id);}
  else if(m.tipo==='arquivo'&&m.corpo&&!(m.chat_anexo||[]).some(a=>a.nome===m.corpo))inner+=tmxTexto(m.corpo);
  html+=`<div class="wa-linha ${cls}"><div class="wa-b ${cls}">${inner}${m.tmp||flut?'':`<button class="wa-bseta" onclick="tmxMenuMsg(event,'${m.id}')">${TMX_ICO_SETA}</button>`}</div></div><div class="wa-t ${cls}">${tmxHora(m.criada_em)}${m.editada_em?' · editada':''}${m.tmp?' · enviando':''}${mine&&!m.tmp?`<button class="tm-olho" title="Quem viu" onclick="tmxQuemViu('mensagem','${m.id}')">${TMX_OLHO}</button>`:''}</div>`;});
 box.innerHTML=html;box.scrollTop=box.scrollHeight;tmxAssinar(msgs);
 tmxResolverClientes(msgs.map(m=>m.meta&&m.meta.cliente_id).filter(Boolean)).then(n=>{if(n)tmxDesenharMsgs(boxId,canalId);});
}
const tmxUrlsAte={};
function tmxVerImagem(u,p,n){tmxModal('Foto',`<img src="${tmxEsc(u)}" alt="" style="display:block;max-width:100%;max-height:68vh;margin:0 auto;border-radius:10px"><div style="display:flex;justify-content:flex-end;gap:8px;margin-top:12px"><button class="apubtn" onclick="tmxFecharModal()">Fechar</button><button class="bt-assumir" data-p="${tmxEsc(p||'')}" data-n="${tmxEsc(n||'foto.jpg')}" onclick="tmxBaixar(this.dataset.p,this.dataset.n)">Baixar</button></div>`,760);}
function tmxBaixar(p,n){if(!p)return;tmx.storage.from('chat-anexo').createSignedUrl(p,600,tmxCfg.baixar?undefined:{download:n||'arquivo'}).then(r=>{if(r.error||!r.data){tmxToast('Não foi possível baixar o arquivo.');return;}if(tmxCfg.baixar){tmxCfg.baixar(r.data.signedUrl,n||'arquivo');return;}const a=document.createElement('a');a.href=r.data.signedUrl;a.rel='noopener';document.body.appendChild(a);a.click();a.remove();});}
async function tmxAssinar(msgs){
 const ag=Date.now();const faltam=[...new Set(msgs.flatMap(m=>(m.chat_anexo||[]).map(a=>a.url)).filter(u=>u&&(!(u in tmxUrls)||(tmxUrls[u]&&(tmxUrlsAte[u]||0)<ag))))];if(!faltam.length)return;
 faltam.forEach(u=>tmxUrls[u]=null);const r=await tmx.storage.from('chat-anexo').createSignedUrls(faltam,3600);
 if(!r.error&&r.data){r.data.forEach(x=>{if(x.signedUrl){tmxUrls[x.path]=x.signedUrl;tmxUrlsAte[x.path]=ag+50*60e3;}});if(tmxNoModulo())tmxDesenharMsgs();if(tmxFlutAberto&&tmxFlutCanal)tmxDesenharMsgs('tmfms',tmxFlutCanal);}
}
function tmxMencoes(t){return (tmxEquipe&&tmxEquipe.pessoas||[]).filter(p=>t.includes('@'+p.nome)).map(p=>p.id);}
async function tmxGravarMsg(dados,mencoes,canal){
 canal=canal||tmxSel;
 const r=await tmx.from('chat_mensagem').insert(Object.assign({canal_id:canal,autor_id:tmxEu.id},dados)).select('id').single();
 if(r.error){tmxToast('Não foi possível enviar.');return null;}
 if(mencoes&&mencoes.length){const x=await tmx.from('chat_mencao').insert(mencoes.map(u=>({mensagem_id:r.data.id,usuario_id:u})));if(x.error)tmxToast('Mensagem enviada, mas a menção não foi registrada.');}
 tmx.from('chat_evento').insert({tipo:'mensagem',origem:tmxCfg.origem||'java',canal_id:canal,mensagem_id:r.data.id,payload:{tipo:dados.tipo||'texto'}}).then(()=>{},()=>{});
 return r.data.id;
}
async function tmxEnviar(){
 const i=tmxEl('tmin');if(!i||!tmxSel)return;const t=i.value.trim();const temPend=(tmxPendentes[tmxSel]||[]).length>0;if(!t&&!temPend)return;i.value='';
 if(temPend){await tmxEnviarPendentes(tmxSel);if(!t)return;}
 const lista=tmxMsgs[tmxSel]||(tmxMsgs[tmxSel]=[]);lista.push({id:'tmp-'+Date.now(),tmp:true,autor_id:tmxEu.id,corpo:t,tipo:'texto',criada_em:new Date().toISOString(),responde_a:tmxResp});tmxDesenharMsgs();
 const resp=tmxResp;tmxResp=null;tmxEl('tmxComp').innerHTML=tmxComposer();
 const id=await tmxGravarMsg({tipo:'texto',corpo:t,responde_a:resp},tmxMencoes(t));
 if(!id){tmxMsgs[tmxSel]=lista.filter(m=>!m.tmp);tmxDesenharMsgs();}
 const c=tmxEl('tmin');if(c)c.focus();
}
function tmxMenuMsg(ev,id){
 const m=(tmxMsgs[tmxSel]||[]).find(x=>x.id===id);if(!m)return;const mine=m.autor_id===tmxEu.id;
 tmxMenu(ev,[['Responder',()=>{tmxResp=m.id;tmxEl('tmxComp').innerHTML=tmxComposer();const i=tmxEl('tmin');if(i)i.focus();}],
  m.corpo?['Copiar',()=>navigator.clipboard.writeText(m.corpo).then(()=>tmxToast('Copiado.'),()=>tmxToast('Não foi possível copiar.'))]:null,
  ['Criar pedido a partir desta',()=>tmxNovoPedido(m)],
  mine&&m.tipo==='texto'?['Editar',()=>tmxEditar(m)]:null,
  mine?['Apagar',()=>tmxConfirmar('Apagar esta mensagem para todos?','Apagar',()=>tmxApagar(m)),true]:null]);
}
function tmxEditar(m){tmxModal('Editar mensagem',`<textarea class="fi" id="tmed" rows="4">${tmxEsc(m.corpo||'')}</textarea><div style="display:flex;justify-content:flex-end;gap:8px;margin-top:14px"><button class="apubtn" onclick="tmxFecharModal()">Cancelar</button><button class="bt-assumir" onclick="tmxSalvarEdicao('${m.id}')">Salvar</button></div>`);}
async function tmxSalvarEdicao(id){const t=tmxEl('tmed').value.trim();if(!t)return;const r=await tmx.from('chat_mensagem').update({corpo:t,editada_em:new Date().toISOString()}).eq('id',id).select('id');
 if(r.error||!r.data.length){tmxToast('Não foi possível editar.');return;}tmxFecharModal();const m=(tmxMsgs[tmxSel]||[]).find(x=>x.id===id);if(m){m.corpo=t;m.editada_em=new Date().toISOString();}tmxDesenharMsgs();}
async function tmxApagar(m){const r=await tmx.from('chat_mensagem').update({excluida_em:new Date().toISOString()}).eq('id',m.id).select('id');
 if(r.error||!r.data.length){tmxToast('Não foi possível apagar.');return;}tmxMsgs[tmxSel]=(tmxMsgs[tmxSel]||[]).filter(x=>x.id!==m.id);tmxDesenharMsgs();}
function tmxMenuCanal(ev){
 const c=tmxCanais.find(x=>x.id===tmxSel);if(!c)return;
 tmxMenu(ev,[[c.tipo==='direta'?'Dados da pessoa':'Participantes',()=>tmxParticipantes()],['Novo pedido',()=>tmxNovoPedido(null)],['Agendar reunião',()=>tmxNovaReuniao()],
  c.tipo!=='setor'||true?[c.silenciado?'Reativar notificações':'Silenciar notificações',()=>tmxSilenciar(c)]:null,
  c.tipo==='grupo'?['Adicionar pessoas',()=>tmxAdicionar(c)]:null]);
}
async function tmxSilenciar(c){await tmx.rpc('chat_marcar_lido',{p_canal:c.id});const r=await tmx.from('chat_canal_membro').update({silenciado:!c.silenciado}).eq('canal_id',c.id).eq('usuario_id',tmxEu.id).select('canal_id');
 if(r.error||!r.data.length){tmxToast('Não foi possível alterar.');return;}c.silenciado=!c.silenciado;tmxBadge();tmxToast(c.silenciado?'Notificações silenciadas.':'Notificações reativadas.');tmxDesenharLista();}
function tmxParticipantes(){
 const c=tmxCanais.find(x=>x.id===tmxSel);if(!c)return;
 const ids=c.tipo==='setor'?(tmxEquipe.pessoas||[]).filter(p=>(p.setores||[]).includes(c.setor_id)).map(p=>p.id):(c.membros||[]);
 tmxModal(c.tipo==='direta'?'Dados da pessoa':'Participantes',ids.map(id=>{const p=tmxPessoa(id);const st=TMX_ST[tmxPres[id]||'offline']||TMX_ST.offline;
  return `<div style="display:flex;align-items:center;gap:10px;padding:8px 0;border-bottom:1px solid var(--superf2)"><div class="av" style="width:34px;height:34px;font-size:11px;background:${tmxCor(p.nome)}">${tmxEsc(tmxIni(p.nome))}</div><div style="flex:1;min-width:0"><b style="font-size:12.5px">${tmxEsc(p.nome)}</b><div style="font-size:11px;color:var(--apagado)">${tmxEsc((p.setores||[]).map(tmxSetorNome).join(', '))}${p.email?' · '+tmxEsc(p.email):''}</div></div><span style="font-size:11px;color:${st[1]};font-weight:700">● ${st[0]}</span>${id!==tmxEu.id&&c.tipo!=='direta'?`<button class="miniB" onclick="tmxFecharModal();tmxAbrirDireta('${id}')">Conversar</button>`:''}</div>`;}).join(''),520);
}
function tmxEscolherPessoas(titulo,botao,acao,excluir){
 const ps=(tmxEquipe&&tmxEquipe.pessoas||[]).filter(p=>p.id!==tmxEu.id&&!(excluir||[]).includes(p.id));
 tmxModal(titulo,`${acao==='grupo'?'<span class="fl">Nome do grupo</span><input class="fi" id="tmgn" maxlength="120">':''}<span class="fl">Pessoas</span><input class="fi" placeholder="Buscar" oninput="tmxQS('#tmps label').forEach(l=>l.style.display=l.dataset.n.includes(this.value.toLowerCase())?'':'none')"><div id="tmps" style="max-height:44vh;overflow-y:auto;margin-top:6px">${ps.map(p=>`<label data-n="${tmxEsc(p.nome.toLowerCase())}" style="display:flex;gap:9px;align-items:center;padding:6px 2px;font-size:12.5px;cursor:pointer"><input type="${acao==='direta'?'radio':'checkbox'}" name="tmp" value="${p.id}"> ${tmxEsc(p.nome)} <span style="color:var(--apagado);font-size:11px">${tmxEsc((p.setores||[]).map(tmxSetorNome).join(', '))}</span></label>`).join('')}</div><div style="display:flex;justify-content:flex-end;gap:8px;margin-top:14px"><button class="apubtn" onclick="tmxFecharModal()">Cancelar</button><button class="bt-assumir" onclick="tmxConfirmarPessoas('${acao}')">${tmxEsc(botao)}</button></div>`,500);
}
function tmxNovaDireta(){tmxEscolherPessoas('Nova conversa','Conversar','direta');}
function tmxNovoGrupo(){tmxEscolherPessoas('Novo grupo','Criar grupo','grupo');}
function tmxAdicionar(c){tmxEscolherPessoas('Adicionar pessoas','Adicionar','adicionar',c.membros);}
async function tmxConfirmarPessoas(acao){
 const ids=[...tmxQS('#tmps input:checked')].map(i=>i.value);
 if(acao==='direta'){if(!ids.length)return;tmxFecharModal();tmxAbrirDireta(ids[0]);return;}
 if(acao==='grupo'){const n=tmxEl('tmgn').value.trim();if(!n){tmxToast('Escreva o nome do grupo.');return;}if(!ids.length){tmxToast('Escolha pelo menos uma pessoa.');return;}
  const r=await tmx.rpc('chat_criar_grupo',{p_nome:n,p_membros:ids});if(r.error){tmxToast('Não foi possível criar o grupo.');return;}tmxFecharModal();await tmxCarregarCanais();tmxAbrirCanal(r.data);return;}
 if(acao==='adicionar'){if(!ids.length)return;const r=await tmx.from('chat_canal_membro').insert(ids.map(u=>({canal_id:tmxSel,usuario_id:u,papel:'membro'})));
  if(r.error){tmxToast('Só quem administra o grupo pode adicionar pessoas.');return;}tmxFecharModal();await tmxCarregarCanais();tmxDesenharConversa();tmxToast('Pessoas adicionadas.');}
}
function tmxMenuAnexo(ev){tmxMenu(ev,[['Documento',()=>tmxEscolherArquivo('*/*')],['Fotos',()=>tmxEscolherArquivo('image/*')]],true);}
function tmxEscolherArquivo(aceita){const i=document.createElement('input');i.type='file';i.accept=aceita;i.multiple=true;i.onchange=()=>tmxMandarArquivos([...i.files],tmxAlvo());i.click();}
async function tmxEnviarArquivo(blob,nome,tipo,destino){
 const canal=destino||tmxAlvo();if(!canal)return;if(blob.size>100*1048576){tmxToast(nome+' passa de 100 MB.');return;}
 const ext=(nome.split('.').pop()||'bin').toLowerCase().replace(/[^a-z0-9]/g,'').slice(0,5)||'bin';const caminho=`${canal}/${crypto.randomUUID()}.${ext}`;
 const up=await tmx.storage.from('chat-anexo').upload(caminho,blob,{contentType:(blob.type||'application/octet-stream').split(';')[0]});
 if(up.error){tmxToast('Não foi possível subir '+nome+'.');return;}
 const id=await tmxGravarMsg({tipo:tipo==='audio'?'audio':'arquivo',corpo:tipo==='audio'?'Áudio':nome},null,canal);if(!id)return;
 const a=await tmx.from('chat_anexo').insert({mensagem_id:id,tipo,nome,url:caminho,tamanho:blob.size});if(a.error)tmxToast('Arquivo enviado sem o anexo registrado.');
 tmxCarregarMsgs(canal);
}
async function tmxGravar(){
 if(!navigator.mediaDevices||!window.MediaRecorder){tmxToast('Este computador não permite gravar áudio.');return;}
 let st;try{st=await navigator.mediaDevices.getUserMedia({audio:true});}catch(e){tmxToast('Sem acesso ao microfone.');return;}
 const rec=new MediaRecorder(st,{mimeType:'audio/webm;codecs=opus',audioBitsPerSecond:32000});const partes=[];rec.ondataavailable=e=>{if(e.data.size)partes.push(e.data);};
 tmxGrav={rec,st,partes,seg:0,canal:tmxAlvo(),cancelado:false};
 tmxGrav.timer=setInterval(()=>{if(!tmxGrav)return;tmxGrav.seg++;const s=tmxQ1('#tmxComp .wa-rec,#tmfComp .wa-rec');if(s)s.textContent='● Gravando '+tmxGrav.seg+'s';if(tmxGrav.seg>=900)tmxGravarParar();},1000);
 rec.onstop=async()=>{const g=tmxGrav;tmxGrav=null;clearInterval(g.timer);g.st.getTracks().forEach(t=>t.stop());tmxCompAtualizar();
  if(g.cancelado||!g.partes.length)return;try{const ogg=tmxOgg(new Uint8Array(await new Blob(g.partes).arrayBuffer()));const ant=tmxSel;if(!(tmxFlutAberto&&tmxFlutCanal===g.canal))tmxSel=g.canal;await tmxEnviarArquivo(new Blob([ogg],{type:'audio/ogg'}),'audio.ogg','audio');tmxSel=ant;}catch(e){tmxToast('Não foi possível preparar o áudio.');}};
 rec.start(250);tmxCompAtualizar();
}
function tmxGravarParar(){if(tmxGrav&&tmxGrav.rec.state!=='inactive')tmxGrav.rec.stop();}
function tmxGravarCancelar(){if(tmxGrav){tmxGrav.cancelado=true;tmxGravarParar();}}
function tmxOpcoesPessoas(sel){return (tmxEquipe&&tmxEquipe.pessoas||[]).map(p=>`<option value="${p.id}" ${p.id===sel?'selected':''}>${tmxEsc(p.nome)}</option>`).join('');}
let tmxPedNovo=null,tmxPesCache={},tmxPedBuscaT=null;
function tmxFone(w){const d=String(w||'').replace(/\D/g,'');if(d.length===13&&d.startsWith('55'))return '+55 '+d.slice(2,4)+' '+d.slice(4,9)+'-'+d.slice(9);if(d.length===12&&d.startsWith('55'))return '+55 '+d.slice(2,4)+' '+d.slice(4,8)+'-'+d.slice(8);return d?'+'+d:'';}
function tmxTam(n){return n>=1048576?(n/1048576).toFixed(1).replace('.',',')+' MB':Math.max(1,Math.round(n/1024))+' KB';}
async function tmxNovoPedido(m){
 tmxPedNovo={msg:m?m.id:'',canal:tmxSel||null,arqs:[],cliente:null,empresas:[],todas:false,resp:[]};
 const temCli=!!(tmxCfg.buscarPessoas&&tmxCfg.pessoasContato);
 tmxModal('Novo pedido',`<span class="fl">O que precisa ser feito</span><input class="fi" id="tmpt" maxlength="200" value="${tmxEsc(m&&m.corpo?m.corpo.slice(0,200):'')}"><span class="fl">Detalhes</span><textarea class="fi" id="tmpd" rows="3"></textarea><span class="fl">Responsável</span><select class="fi" id="tmpr" disabled><option value=""></option></select>${temCli?'<span class="fl">Cliente</span><div id="tmpc"></div>':''}<span class="fl">Anexos</span><div id="tmpa"></div><span class="fl">Prazo</span><input class="fi" type="date" id="tmpp"><div style="display:flex;justify-content:flex-end;gap:8px;margin-top:14px"><button class="apubtn" onclick="tmxFecharModal()">Cancelar</button><button class="bt-assumir" id="tmpok" onclick="tmxCriarPedido()">Criar pedido</button></div>`,560);
 if(temCli)tmxPedCliDesenhar();tmxPedArqDesenhar();
 if(tmxModalEl)tmxModalEl.addEventListener('paste',e=>{const fs=[...(e.clipboardData&&e.clipboardData.files||[])];if(fs.length){e.preventDefault();tmxPedArqAdd(fs);}});
 const r=await tmx.rpc('chat_pedido_responsaveis',{p_canal:tmxPedNovo.canal});const s=tmxEl('tmpr');if(!s)return;
 if(r.error){tmxToast('Não foi possível carregar os responsáveis.');return;}
 const ids=(r.data||[]).map(x=>typeof x==='string'?x:x.chat_pedido_responsaveis).filter(Boolean);
 const ps=ids.map(id=>({id,nome:tmxPessoa(id).nome})).sort((a,b)=>String(a.nome).localeCompare(String(b.nome),'pt-BR'));
 s.innerHTML=(ps.length===1?'':'<option value="">Escolha</option>')+ps.map(p=>`<option value="${p.id}">${tmxEsc(p.nome)}</option>`).join('');
 s.disabled=ps.length<=1;
}
function tmxPedCliDesenhar(){
 const box=tmxEl('tmpc');if(!box||!tmxPedNovo)return;const c=tmxPedNovo.cliente;
 if(!c){box.innerHTML=`<input class="fi" id="tmpcb" placeholder="Nome, CPF ou WhatsApp do cliente" oninput="clearTimeout(tmxPedBuscaT);tmxPedBuscaT=setTimeout(tmxPedCliBuscar,350)"><div id="tmpcr" style="max-height:200px;overflow-y:auto"></div>`;return;}
 const emp=c.empresas||[];
 box.innerHTML=`<div class="tm-it" style="cursor:default;border:1px solid var(--superf2);border-radius:10px"><div class="tm-av" style="background:${tmxCor(c.nome)}">${tmxEsc(tmxIni(c.nome))}</div><div class="tm-itc"><div class="tm-l1"><b>${tmxEsc(c.nome)}</b></div><div class="tm-l2"><span>${tmxEsc(tmxFone(c.whatsapp))}</span></div></div><button class="miniB" onclick="tmxPedNovo.cliente=null;tmxPedNovo.empresas=[];tmxPedNovo.todas=false;tmxPedCliDesenhar()">Trocar</button></div>
  ${emp.length?`<div style="margin-top:8px;border:1px solid var(--superf2);border-radius:10px;max-height:190px;overflow-y:auto">
   <label style="display:flex;align-items:center;gap:8px;padding:8px 10px;border-bottom:1px solid var(--superf2);font-size:12.5px;font-weight:700;cursor:pointer"><input type="checkbox" ${tmxPedNovo.todas?'checked':''} onchange="tmxPedNovo.todas=this.checked;tmxPedNovo.empresas=[];tmxPedCliDesenhar()"> Todas as empresas (${emp.length})</label>
   ${emp.map(e=>`<label style="display:flex;align-items:center;gap:8px;padding:7px 10px;font-size:12.5px;cursor:pointer;${tmxPedNovo.todas?'opacity:.5':''}"><input type="checkbox" value="${e.empresa_id}" ${tmxPedNovo.todas||tmxPedNovo.empresas.includes(e.empresa_id)?'checked':''} ${tmxPedNovo.todas?'disabled':''} onchange="tmxPedEmp(this)"><span style="flex:1;min-width:0"><b style="font-weight:600">${tmxEsc(e.nome||'')}</b><span style="display:block;font-size:11px;color:var(--apagado)">${tmxEsc(tmxCnpj(e.doc))}</span></span></label>`).join('')}</div>`:''}`;
}
function tmxPedEmp(i){const l=tmxPedNovo.empresas;if(i.checked){if(!l.includes(i.value))l.push(i.value);}else tmxPedNovo.empresas=l.filter(x=>x!==i.value);}
async function tmxPedCliBuscar(){
 const i=tmxEl('tmpcb'),box=tmxEl('tmpcr');if(!i||!box)return;const t=i.value.trim();if(t.length<2){box.innerHTML='';return;}
 const r=await tmxCfg.buscarPessoas(t);if(!tmxEl('tmpcr')||tmxEl('tmpcb').value.trim()!==t)return;
 if(r.error){tmxToast('Não foi possível buscar.');return;}
 const l=r.data||[];l.forEach(p=>tmxPesCache[p.pessoa_id]=p);
 box.innerHTML=l.slice(0,30).map(p=>`<div class="tm-it" onclick="tmxPedCliEscolher('${p.pessoa_id}')"><div class="tm-av" style="background:${tmxCor(p.nome)}">${tmxEsc(tmxIni(p.nome))}</div><div class="tm-itc"><div class="tm-l1"><b>${tmxEsc(p.nome)}</b></div><div class="tm-l2"><span>${tmxEsc(tmxFone(p.whatsapp))}${(p.empresas||[]).length?' · '+(p.empresas.length===1?tmxEsc(p.empresas[0].nome||''):p.empresas.length+' empresas'):''}</span></div></div></div>`).join('');
}
function tmxPedCliEscolher(id){const p=tmxPesCache[id];if(!p||!tmxPedNovo)return;tmxPedNovo.cliente=p;tmxPedNovo.empresas=(p.empresas||[]).length===1?[p.empresas[0].empresa_id]:[];tmxPedNovo.todas=false;tmxPedCliDesenhar();}
function tmxPedArqDesenhar(){
 const box=tmxEl('tmpa');if(!box||!tmxPedNovo)return;const a=tmxPedNovo.arqs;
 box.innerHTML=`<div id="tmpaz" style="border:1.5px dashed var(--superf2);border-radius:10px;padding:12px;text-align:center;font-size:12px;color:var(--apagado);cursor:pointer" onclick="tmxPedArqEscolher()" ondragover="event.preventDefault();this.style.borderColor='var(--laranja)'" ondragleave="this.style.borderColor=''" ondrop="event.preventDefault();this.style.borderColor='';tmxPedArqAdd([...event.dataTransfer.files])">Arraste os arquivos aqui, cole com Ctrl+V ou clique para escolher</div>
  ${a.map((f,i)=>`<div style="display:flex;align-items:center;gap:8px;padding:6px 2px;font-size:12.5px;border-bottom:1px solid var(--superf2)"><span style="flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${tmxEsc(f.name)}</span><span style="font-size:11px;color:var(--apagado)">${tmxTam(f.size)}</span><button class="miniB" onclick="tmxPedNovo.arqs.splice(${i},1);tmxPedArqDesenhar()">✕</button></div>`).join('')}`;
}
function tmxPedArqEscolher(){const i=document.createElement('input');i.type='file';i.multiple=true;i.onchange=()=>tmxPedArqAdd([...i.files]);i.click();}
function tmxPedArqAdd(fs){if(!tmxPedNovo)return;fs.forEach(f=>{if(f.size>100*1048576){tmxToast(f.name+' passa de 100 MB.');return;}tmxPedNovo.arqs.push(f);});tmxPedArqDesenhar();}
async function tmxCriarPedido(){
 const P=tmxPedNovo;if(!P)return;const t=tmxEl('tmpt').value.trim(),resp=tmxEl('tmpr').value,prazo=tmxEl('tmpp').value||null;
 if(!t||!resp){tmxToast('Preencha o pedido e o responsável.');return;}
 const b=tmxEl('tmpok');if(b)b.disabled=true;
 const c=P.cliente;
 const r=await tmx.from('chat_pedido').insert({canal_id:P.canal,mensagem_id:P.msg||null,titulo:t,descricao:tmxEl('tmpd').value||null,solicitante_id:tmxEu.id,responsavel_id:resp,prazo,
  cliente_id:c?c.pessoa_id:null,empresa_ids:c&&!P.todas?P.empresas:[],todas_empresas:!!(c&&P.todas)}).select('id').single();
 if(r.error){if(b)b.disabled=false;tmxToast(r.error.message||'Não foi possível criar o pedido.');return;}
 const pid=r.data.id;let falhou=0;
 for(const f of P.arqs){const ext=(f.name.split('.').pop()||'bin').toLowerCase().replace(/[^a-z0-9]/g,'').slice(0,5)||'bin';const caminho=`pedido/${pid}/${crypto.randomUUID()}.${ext}`;
  const up=await tmx.storage.from('chat-anexo').upload(caminho,f,{contentType:(f.type||'application/octet-stream').split(';')[0]});
  if(up.error){falhou++;continue;}
  const a=await tmx.from('chat_anexo').insert({pedido_id:pid,tipo:'arquivo',nome:f.name,url:caminho,tamanho:f.size});if(a.error)falhou++;}
 tmxFecharModal();tmxPedNovo=null;
 if(P.canal){await tmxGravarMsg({tipo:'pedido',corpo:t,meta:{pedido_id:pid,responsavel_id:resp,prazo}},[resp]);tmxPedidos.push({id:pid,status:'aberto'});tmxCarregarMsgs(P.canal);}
 tmxToast(falhou?'Pedido criado, mas '+falhou+' anexo(s) não subiram.':'Pedido criado.');
}
async function tmxPedResolver(lista){
 if(!tmxCfg.pessoasContato)return false;const faltam=[...new Set(lista.map(p=>p.cliente_id).filter(x=>x&&!(x in tmxPesCache)))];if(!faltam.length)return false;
 faltam.forEach(x=>tmxPesCache[x]=null);const r=await tmxCfg.pessoasContato(faltam);if(r.error)return false;(r.data||[]).forEach(p=>tmxPesCache[p.pessoa_id]=p);return true;
}
function tmxPedClienteHtml(p){
 if(!p||!p.cliente_id)return '';const c=tmxPesCache[p.cliente_id];if(!c)return '';
 const emp=(c.empresas||[]).filter(e=>p.todas_empresas||(p.empresa_ids||[]).includes(e.empresa_id));
 return `<div style="font-size:11.5px;margin-top:4px">👤 <b>${tmxEsc(c.nome)}</b>${c.whatsapp?' · '+tmxEsc(tmxFone(c.whatsapp)):''}</div>${emp.map(e=>`<div style="font-size:11px;color:var(--apagado)">🏢 ${tmxEsc(e.nome||'')} · ${tmxEsc(tmxCnpj(e.doc))}</div>`).join('')}`;
}
function tmxPedAnexosHtml(p){return (p&&p.chat_anexo||[]).map(a=>`<button class="miniB" style="margin:4px 4px 0 0" data-p="${tmxEsc(a.url||'')}" data-n="${tmxEsc(a.nome||'arquivo')}" onclick="tmxBaixar(this.dataset.p,this.dataset.n)">📎 ${tmxEsc(a.nome||'arquivo')}</button>`).join('');}
async function tmxAbrirPedidos(){
 tmxAba='pedidos';tmxDesenharLista();const box=tmxEl('tmxCentro');if(!box)return;
 const r=await tmx.from('chat_pedido').select('id,titulo,descricao,solicitante_id,responsavel_id,status,prazo,criado_em,canal_id,cliente_id,empresa_ids,todas_empresas,chat_anexo(id,nome,url,tamanho)').order('criado_em',{ascending:false}).limit(300);
 if(r.error){tmxToast('Não foi possível carregar os pedidos.');return;}tmxPedidos=r.data;tmxDesenharLista();tmxPedResolver(tmxPedidos).then(n=>{if(n&&tmxAba==='pedidos'&&tmxNoModulo())tmxAbrirPedidos();});if(tmxPend.pedidos){tmx.rpc('chat_marcar_visto',{p_o_que:'pedidos'}).then(()=>tmxCarregarPend());}
 const lista=tmxPedidos.filter(p=>tmxPedFiltro==='meus'?p.responsavel_id===tmxEu.id:tmxPedFiltro==='pedi'?p.solicitante_id===tmxEu.id:true);
 const f=(k,t)=>`<button class="ap-fil ${tmxPedFiltro===k?'on':''}" onclick="tmxPedFiltro='${k}';tmxAbrirPedidos()">${t}</button>`;
 box.innerHTML=`<div class="tm-pag"><div class="tm-pagcab"><b>Pedidos</b><div class="ap-fils">${f('meus','Para mim')}${f('pedi','Que eu pedi')}${f('todos','Todos')}</div><span style="flex:1"></span><button class="bt-assumir" onclick="tmxSel=null;tmxNovoPedido(null)">Novo pedido</button></div>
  <div class="tbwrap"><table><thead><tr><th>Pedido</th><th>Quem pediu</th><th>Responsável</th><th>Prazo</th><th>Situação</th><th></th></tr></thead><tbody>${lista.map(p=>{const venc=p.prazo&&p.status!=='concluido'&&p.status!=='cancelado'&&p.prazo<new Date().toISOString().slice(0,10);
   return `<tr id="tmi-${p.id}"><td style="white-space:normal"><b>${tmxEsc(p.titulo)}</b>${p.descricao?`<div style="font-size:11px;color:var(--apagado)">${tmxEsc(p.descricao)}</div>`:''}${tmxPedClienteHtml(p)}${tmxPedAnexosHtml(p)}</td><td>${tmxEsc(tmxPessoa(p.solicitante_id).nome)}</td><td>${tmxEsc(tmxPessoa(p.responsavel_id).nome)}</td><td${venc?' style="color:var(--vermelho);font-weight:700"':''}>${p.prazo?tmxEsc(p.prazo.split('-').reverse().join('/')):'—'}</td><td><span class="pill ${p.status==='concluido'?'ok':p.status==='cancelado'?'falta':'pend'}">${TMX_PED[p.status]||p.status}</span></td><td>${(p.responsavel_id===tmxEu.id||p.solicitante_id===tmxEu.id)&&p.status!=='concluido'&&p.status!=='cancelado'?`<button class="miniB" onclick="tmxAvancarPedido('${p.id}')">${p.status==='aberto'?'Começar':'Concluir'}</button>`:''}${p.solicitante_id===tmxEu.id?`<button class="tm-olho" title="Quem viu" onclick="tmxQuemViu('pedido','${p.id}')">${TMX_OLHO}</button>`:''}</td></tr>`;}).join('')}</tbody></table></div></div>`;
}
async function tmxAvancarPedido(id){const p=tmxPedidos.find(x=>x.id===id);if(!p)return;const nv=p.status==='aberto'?'em_andamento':'concluido';
 const r=await tmx.from('chat_pedido').update({status:nv,atualizado_em:new Date().toISOString()}).eq('id',id).select('id');if(r.error||!r.data.length){tmxToast('Não foi possível atualizar o pedido.');return;}tmxToast(nv==='concluido'?'Pedido concluído.':'Pedido em andamento.');tmxAbrirPedidos();}
async function tmxAbrirAvisos(){
 tmxAba='avisos';tmxDesenharLista();const box=tmxEl('tmxCentro');if(!box)return;
 const [a,v]=await Promise.all([tmx.from('chat_aviso').select('id,escopo,setor_id,titulo,corpo,autor_id,criado_em,nivel').order('criado_em',{ascending:false}).limit(100),tmx.from('chat_aviso_visto').select('aviso_id,usuario_id')]);
 if(a.error){tmxToast('Não foi possível carregar os avisos.');return;}tmxAvisos=a.data;const vistos=v.data||[];tmxVistos=new Set(vistos.filter(x=>x.usuario_id===tmxEu.id).map(x=>x.aviso_id));
 const total=(tmxEquipe&&tmxEquipe.pessoas||[]).length;
 box.innerHTML=`<div class="tm-pag"><div class="tm-pagcab"><b>Central de avisos</b><span style="flex:1"></span><button class="bt-assumir" onclick="tmxNovoAviso()">Novo aviso</button></div>${tmxAvisos.map(x=>{const vi=vistos.filter(y=>y.aviso_id===x.id).length;const alvo=x.escopo==='setor'?(tmxEquipe.pessoas||[]).filter(p=>(p.setores||[]).includes(x.setor_id)).length:total;
   return `<div class="cg-card tm-aviso ${tmxEsc(x.nivel||'info')}" id="tmi-${x.id}" style="margin-bottom:10px"><div style="display:flex;gap:10px;align-items:flex-start"><div style="flex:1">${x.nivel==='urgente'?'<span class="tm-avtag u">Urgente</span>':x.nivel==='visto'?'<span class="tm-avtag v">Exige visto</span>':''}<b style="font-size:13.5px">${tmxEsc(x.titulo)}</b><div style="font-size:11px;color:var(--apagado);margin-top:2px">${tmxEsc(tmxPessoa(x.autor_id).nome)} · ${tmxEsc(tmxDia(x.criado_em))} ${tmxEsc(tmxHora(x.criado_em))} · ${x.escopo==='setor'?tmxEsc(tmxSetorNome(x.setor_id)):'Todos'}</div></div><span style="font-size:11px;color:var(--apagado)">${vi} de ${alvo} viram</span>${x.autor_id===tmxEu.id?`<button class="tm-olho" title="Quem viu" onclick="tmxQuemViu('aviso','${x.id}')">${TMX_OLHO}</button>`:''}</div>${x.corpo?`<div style="font-size:12.5px;margin-top:8px;white-space:pre-line">${tmxEsc(x.corpo)}</div>`:''}<div style="margin-top:10px">${tmxVistos.has(x.id)?'<span class="pill ok">Visto</span>':`<button class="miniB" onclick="tmxDarVisto('${x.id}')">Marcar como visto</button>`}</div></div>`;}).join('')}</div>`;
}
async function tmxDarVisto(id){const r=await tmx.from('chat_aviso_visto').upsert({aviso_id:id,usuario_id:tmxEu.id}).select('aviso_id');if(r.error){tmxToast('Não foi possível marcar.');return;}tmxCarregarPend();tmxAbrirAvisos();}
function tmxNovoAviso(){tmxModal('Novo aviso',`<span class="fl">Nível</span><select class="fi" id="tman"><option value="info">Informativo</option><option value="visto">Exige visto</option><option value="urgente">Urgente</option></select><span class="fl">Título</span><input class="fi" id="tmat" maxlength="160"><span class="fl">Texto</span><textarea class="fi" id="tmac" rows="4"></textarea><span class="fl">Para quem</span><select class="fi" id="tmas"><option value="">Todos</option>${(tmxEquipe.setores||[]).map(s=>`<option value="${s.id}">${tmxEsc(s.nome)}</option>`).join('')}</select><div style="display:flex;justify-content:flex-end;gap:8px;margin-top:14px"><button class="apubtn" onclick="tmxFecharModal()">Cancelar</button><button class="bt-assumir" onclick="tmxCriarAviso()">Enviar aviso</button></div>`);}
async function tmxCriarAviso(){const t=tmxEl('tmat').value.trim();if(!t){tmxToast('Dê um título ao aviso.');return;}const s=tmxEl('tmas').value;
 const r=await tmx.from('chat_aviso').insert({nivel:tmxEl('tman').value,titulo:t,corpo:tmxEl('tmac').value||null,escopo:s?'setor':'central',setor_id:s||null,autor_id:tmxEu.id}).select('id');if(r.error||!r.data.length){tmxToast('Não foi possível enviar o aviso.');return;}tmxFecharModal();tmxToast('Aviso enviado.');tmxAbrirAvisos();}
async function tmxAbrirReunioes(){
 tmxAba='reunioes';tmxDesenharLista();const box=tmxEl('tmxCentro');if(!box)return;
 const r=await tmx.from('chat_reuniao').select('id,titulo,pauta,inicio,fim,criado_por,criado_em,chat_reuniao_participante(usuario_id,confirmado)').order('inicio',{ascending:true}).limit(100);
 if(r.error){tmxToast('Não foi possível carregar as reuniões.');return;}tmxReunioes=r.data;tmxDesenharLista();if(tmxPend.reunioes){tmx.rpc('chat_marcar_visto',{p_o_que:'reunioes'}).then(()=>tmxCarregarPend());}const hoje=new Date(Date.now()-3600e3).toISOString();
 const prox=tmxReunioes.filter(x=>!x.inicio||x.inicio>=hoje),pass=tmxReunioes.filter(x=>x.inicio&&x.inicio<hoje).reverse().slice(0,10);
 const card=x=>{const me=(x.chat_reuniao_participante||[]).find(p=>p.usuario_id===tmxEu.id);return `<div class="cg-card" id="tmi-${x.id}" style="margin-bottom:10px"><div style="display:flex;gap:10px"><div style="flex:1"><b style="font-size:13.5px">${tmxEsc(x.titulo)}</b>${x.criado_por===tmxEu.id?`<button class="tm-olho" title="Quem viu" onclick="tmxQuemViu('reuniao','${x.id}')">${TMX_OLHO}</button>`:''}<div style="font-size:11.5px;color:var(--apoio);margin-top:3px">${x.inicio?tmxEsc(tmxDia(x.inicio)+' '+tmxHora(x.inicio)):'Sem data'}${x.fim?' até '+tmxEsc(tmxHora(x.fim)):''} · organizada por ${tmxEsc(tmxPessoa(x.criado_por).nome)}</div>${x.pauta?`<div style="font-size:12px;margin-top:6px">${tmxEsc(x.pauta)}</div>`:''}<div style="font-size:11px;color:var(--apagado);margin-top:6px">${(x.chat_reuniao_participante||[]).map(p=>tmxEsc(tmxPessoa(p.usuario_id).nome)+(p.confirmado?' ✓':'')).join(', ')}</div></div>${me&&!me.confirmado?`<button class="miniB" style="align-self:flex-start;white-space:nowrap" onclick="tmxConfirmar('${x.id}')">Confirmar presença</button>`:''}</div></div>`;};
 box.innerHTML=`<div class="tm-pag"><div class="tm-pagcab"><b>Reuniões</b><span style="flex:1"></span><button class="bt-assumir" onclick="tmxNovaReuniao()">Agendar reunião</button></div>${prox.map(card).join('')}${pass.length?`<div class="tm-sec" style="padding-left:0">Anteriores</div>${pass.map(card).join('')}`:''}</div>`;
}
async function tmxConfirmar(id){const r=await tmx.from('chat_reuniao_participante').update({confirmado:true}).eq('reuniao_id',id).eq('usuario_id',tmxEu.id).select('reuniao_id');if(r.error||!r.data.length){tmxToast('Não foi possível confirmar.');return;}tmxAbrirReunioes();}
function tmxNovaReuniao(){
 const ps=(tmxEquipe.pessoas||[]).filter(p=>p.id!==tmxEu.id);
 tmxModal('Agendar reunião',`<span class="fl">Assunto</span><input class="fi" id="tmrt" maxlength="160"><span class="fl">Pauta</span><textarea class="fi" id="tmrp" rows="2"></textarea><div style="display:flex;gap:10px"><div style="flex:1"><span class="fl">Começa</span><input class="fi" type="datetime-local" id="tmri"></div><div style="flex:1"><span class="fl">Termina</span><input class="fi" type="datetime-local" id="tmrf"></div></div><span class="fl">Participantes</span><div id="tmps" style="max-height:30vh;overflow-y:auto">${ps.map(p=>`<label data-n="${tmxEsc(p.nome.toLowerCase())}" style="display:flex;gap:9px;align-items:center;padding:5px 2px;font-size:12.5px"><input type="checkbox" value="${p.id}"> ${tmxEsc(p.nome)}</label>`).join('')}</div><div style="display:flex;justify-content:flex-end;gap:8px;margin-top:14px"><button class="apubtn" onclick="tmxFecharModal()">Cancelar</button><button class="bt-assumir" onclick="tmxCriarReuniao()">Agendar</button></div>`,520);
}
async function tmxCriarReuniao(){
 const t=tmxEl('tmrt').value.trim(),i=tmxEl('tmri').value,f=tmxEl('tmrf').value;if(!t||!i){tmxToast('Preencha o assunto e o horário.');return;}if(f&&f<=i){tmxToast('O fim precisa ser depois do começo.');return;}
 const ids=[...tmxQS('#tmps input:checked')].map(x=>x.value);
 const r=await tmx.from('chat_reuniao').insert({titulo:t,pauta:tmxEl('tmrp').value||null,inicio:new Date(i).toISOString(),fim:f?new Date(f).toISOString():null,canal_id:tmxSel||null,criado_por:tmxEu.id}).select('id').single();
 if(r.error){tmxToast('Não foi possível agendar.');return;}
 const p=await tmx.from('chat_reuniao_participante').insert([tmxEu.id,...ids].map(u=>({reuniao_id:r.data.id,usuario_id:u,confirmado:u===tmxEu.id})));
 if(p.error){tmxToast('Reunião criada, mas os participantes não foram registrados.');}
 tmxFecharModal();tmxToast('Reunião agendada.');if(tmxAba==='reunioes')tmxAbrirReunioes();
}
/* ---------- TEAM'S flutuante ---------- */
let tmxFlutAberto=false,tmxFlutCanal=null;
function tmxAlvo(){return tmxFlutAberto&&tmxFlutCanal?tmxFlutCanal:tmxSel;}
function tmxCompAtualizar(){if(tmxFlutAberto&&tmxFlutCanal){const c=tmxEl('tmfComp');if(c)c.innerHTML=tmxFlutComposer();}else{const c=tmxEl('tmxComp');if(c)c.innerHTML=tmxComposer();}}
function tmxFlutComposer(){return tmxGrav?`<div class="wa-comp"><span class="wa-rec">● Gravando ${tmxGrav.seg||0}s</span><span style="flex:1"></span><button class="miniB" onclick="tmxGravarCancelar()">Cancelar</button><button class="snd" onclick="tmxGravarParar()">➤</button></div>`:`<div id="tmfBand" data-canal="${tmxEsc(tmxFlutCanal||'')}">${tmxBandejaHtml(tmxFlutCanal)}</div><div class="wa-comp"><span class="pl" onclick="tmxMenuAnexo(event)">${TMX_ICO_CLIPE}</span><span class="pl" title="Ações" onclick="tmxMenuAcoes(event)">${TMX_ICO_ACOES}</span><textarea id="tmfin" rows="1" placeholder="Mensagem" oninput="this.style.height='auto';this.style.height=Math.min(this.scrollHeight,130)+'px';if(this.value.endsWith('@'))tmxMencionar()" onkeydown="if(event.key==='Enter'&&!event.shiftKey&&!event.ctrlKey&&!event.isComposing){event.preventDefault();tmxFlutEnviar();}"></textarea><span class="pl" title="Gravar áudio" onclick="tmxGravar()">${TMX_MIC}</span><button class="snd" onclick="tmxFlutEnviar()">➤</button></div>`;}
let tmxBolY=null,tmxBolArrastou=false;
function tmxBolCarregar(){try{const v=parseInt(localStorage.getItem(tmxChave()),10);if(v>0)tmxBolY=v;}catch(e){}}
function tmxBolLimite(y){return Math.max(12,Math.min(window.innerHeight-70,y));}
function tmxBolPosicionar(){
 const b=tmxEl('tmxBol');if(!b)return;
 if(tmxBolY==null)b.style.bottom='';else b.style.bottom=tmxBolLimite(tmxBolY)+'px';
 const f=tmxEl('tmxFlut');if(f&&b.style.display!=='none'){const W=window.innerWidth,Hj=window.innerHeight,H=Math.min(500,Hj-24),m=10,bot=tmxBolY!=null?tmxBolLimite(tmxBolY):(b.classList.contains('alto')?92:24),r={top:Hj-bot-56,bottom:Hj-bot,left:W-24-56,height:56};
  f.style.height=H+'px';f.style.maxHeight='none';f.style.bottom='auto';f.style.left='auto';
  if(r.top-m-12>=H){f.style.top=(r.top-m-H)+'px';f.style.right='24px';}
  else if(Hj-r.bottom-m-12>=H){f.style.top=(r.bottom+m)+'px';f.style.right='24px';}
  else{f.style.right=(W-r.left+m)+'px';f.style.top=Math.max(12,Math.min(Hj-12-H,r.top+r.height/2-H/2))+'px';}}
}
function tmxBolSalvar(){try{if(tmxBolY==null)localStorage.removeItem(tmxChave());else localStorage.setItem(tmxChave(),String(tmxBolY));}catch(e){}}
function tmxBolResetar(){tmxBolY=null;tmxBolSalvar();tmxBolPosicionar();}
function tmxBolArrastavel(b){
 let ini=null;
 b.addEventListener('pointerdown',e=>{if(e.button!==0)return;ini={y:e.clientY,base:parseInt(getComputedStyle(b).bottom,10)||24,moveu:false};try{b.setPointerCapture(e.pointerId);}catch(x){}});
 b.addEventListener('pointermove',e=>{if(!ini)return;const dy=e.clientY-ini.y;if(!ini.moveu&&Math.abs(dy)<5)return;ini.moveu=true;b.style.transition='none';tmxBolY=tmxBolLimite(ini.base-dy);tmxBolPosicionar();});
 b.addEventListener('pointerup',e=>{if(!ini)return;if(ini.moveu){tmxBolArrastou=true;tmxBolSalvar();b.style.transition='';}ini=null;});
 b.addEventListener('dblclick',e=>{e.preventDefault();tmxBolResetar();});
 b.addEventListener('contextmenu',e=>{e.preventDefault();tmxBolResetar();});
 window.addEventListener('resize',tmxBolPosicionar);
}
function tmxBolinha(){
 let b=tmxEl('tmxBol');
 if(!b){b=document.createElement('button');b.id='tmxBol';b.className='tm-bol';b.title="Team's";b.onclick=()=>{if(tmxBolArrastou){tmxBolArrastou=false;return;}tmxFlutAlternar();};tmxBolArrastavel(b);b.innerHTML=`<img src="${tmxEsc(tmxTema.bolinha||TMX_BASE+'img/teams-bolinha.png')}" alt=""><span class="tm-bolb" id="tmxBolB"></span>`;tmxCamada().appendChild(b);}
 b.classList.toggle('alto',tmxBolAlta);tmxBolPosicionar();
 const mostra=tmxPronto&&!tmxNoModulo();b.style.display=mostra?'':'none';
 if(!mostra&&tmxFlutAberto)tmxFlutFechar();
 const n=tmxTotal();const bb=tmxEl('tmxBolB');if(bb){bb.textContent=n>99?'99+':n;bb.style.display=n?'':'none';}
}
function tmxBolPulsar(){const b=tmxEl('tmxBol');if(!b||b.style.display==='none')return;b.classList.remove('pulsa');void b.offsetWidth;b.classList.add('pulsa');b.onanimationend=()=>b.classList.remove('pulsa');}
function tmxFlutAlternar(){tmxFlutAberto?tmxFlutFechar():tmxFlutAbrir();}
function tmxFlutAbrir(){
 if(!tmxPronto)return;tmxFlutAberto=true;
 let f=tmxEl('tmxFlut');if(!f){f=document.createElement('div');f.id='tmxFlut';f.className='tm-flut';tmxCamada().appendChild(f);}
 f.classList.remove('sai');tmxBolPosicionar();requestAnimationFrame(()=>f.classList.add('on'));tmxFlutDesenhar();
}
function tmxFlutFechar(){tmxFlutAberto=false;const f=tmxEl('tmxFlut');if(!f)return;f.classList.remove('on');f.classList.add('sai');setTimeout(()=>{if(!tmxFlutAberto)f.remove();},160);}
function tmxFlutDesenhar(){
 const f=tmxEl('tmxFlut');if(!f)return;const c=tmxFlutCanal?tmxCanais.find(x=>x.id===tmxFlutCanal):null;
 const cab=`<div class="wa-head">${c?`<button class="wa-hbtn" onclick="tmxFlutCanal=null;tmxFlutDesenhar()">‹</button><span class="avc" style="overflow:hidden">${c.tipo==='grupo'?TMX_ICO_GRUPO:tmxDepFoto(c,tmxEsc(tmxIni(tmxNomeCanal(c))))}</span>`:`<span class="avc">${TMX_ICO_GRUPO}</span>`}<div class="nm"><b>${tmxEsc(c?tmxNomeCanal(c):"Team's")}</b><span>${c?'':tmxEsc(tmxTotal()+' não vistas')}</span></div>${c?`<button class="wa-hbtn" title="Ligar" onclick="tmxLigar('voz')">${TMX_ICO_FONE}</button><button class="wa-hbtn" title="Chamada de vídeo" onclick="tmxLigar('video')">${TMX_ICO_CAM}</button>`:''}<button class="tm-abrir" onclick="tmxFlutExpandir()">Abrir no Team's ⤢</button><button class="wa-hbtn" onclick="tmxFlutFechar()">✕</button></div>`;
 if(!c&&tmxNova){f.innerHTML=cab+`<div style="flex:1;min-height:0;display:flex;flex-direction:column;background:var(--pagina)">${tmxNovaHtml(true)}</div>`;return;}
 if(!c){
  f.innerHTML=cab+tmxSubAbas(true)+`<div class="tm-busca2 tm-srchmais"><input id="tmfbusca" placeholder="Buscar conversa ou pessoa" value="${tmxEsc(tmxBusca)}" oninput="tmxBusca=this.value;tmxFlutDesenhar();const b=tmxEl('tmfbusca');b.focus();b.setSelectionRange(b.value.length,b.value.length)"><button class="tm-mais" title="Nova conversa" onclick="tmxAbrirNova(true)">＋</button></div><div class="rl tm-rl">${tmxListaSub(tmxSub,true)}</div>`;
  return;}
 f.innerHTML=cab+`<div class="wa-msgs" id="tmfms"${tmxDepFundo(c)}></div><div id="tmfComp">${tmxFlutComposer()}</div>`;
 if(!tmxMsgs[c.id])tmxCarregarMsgs(c.id).then(()=>tmxDesenharMsgs('tmfms',c.id));else tmxDesenharMsgs('tmfms',c.id);
 const i=tmxEl('tmfin');if(i)i.focus();
}
async function tmxFlutAbrirSetor(sid){const r=await tmx.rpc('chat_abrir_setor',{p_setor:sid,p_nome:tmxSetorNome(sid)});if(r.error){tmxToast('Não foi possível abrir o setor.');return;}if(!tmxCanais.find(c=>c.id===r.data))await tmxCarregarCanais();tmxFlutAbrirCanal(r.data);}
function tmxFlutAbrirCanal(id){tmxFlutCanal=id;const c=tmxCanais.find(x=>x.id===id);if(c&&c.nao_lidas){c.nao_lidas=0;tmxBadge();}tmx.rpc('chat_marcar_lido',{p_canal:id}).then(()=>{},()=>{});tmxFlutDesenhar();}
function tmxFlutExpandir(){const c=tmxFlutCanal;tmxFlutFechar();tmxCfg.abrirModulo&&tmxCfg.abrirModulo();if(c)setTimeout(()=>tmxAbrirCanal(c),0);}
async function tmxFlutEnviar(){
 const i=tmxEl('tmfin');if(!i||!tmxFlutCanal)return;const t=i.value.trim(),canal=tmxFlutCanal;const temPend=(tmxPendentes[canal]||[]).length>0;if(!t&&!temPend)return;i.value='';
 if(temPend){await tmxEnviarPendentes(canal);if(!t)return;}
 const lista=tmxMsgs[canal]||(tmxMsgs[canal]=[]);lista.push({id:'tmp-'+Date.now(),tmp:true,autor_id:tmxEu.id,corpo:t,tipo:'texto',criada_em:new Date().toISOString()});tmxDesenharMsgs('tmfms',canal);
 const id=await tmxGravarMsg({tipo:'texto',corpo:t},tmxMencoes(t),canal);
 if(!id){tmxMsgs[canal]=lista.filter(m=>!m.tmp);tmxDesenharMsgs('tmfms',canal);}
}
/* ---------- TEAM'S ferramentas ---------- */
const TMX_ICO_FONE='<svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1.9.4 1.8.7 2.7a2 2 0 0 1-.5 2.1L8 9.8a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.4c.9.3 1.8.6 2.7.7a2 2 0 0 1 1.7 2z"/></svg>';
const TMX_ICO_CAM='<svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M23 7l-7 5 7 5V7zM1 5h15v14H1z"/></svg>';
const TMX_TOOLS=[['pedido','📌 Pedido'],['aviso','📣 Aviso'],['reuniao','📅 Reunião'],['anexo','📎 Anexo'],['audio','🎤 Áudio'],['voz','📞 Chamar'],['video','🎥 Vídeo'],['cliente','🏢 Cliente'],['mencao','@ Menção']];
const TMX_ICO_ACOES='<svg viewBox="0 0 24 24"><path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z"/></svg>';
function tmxMenuAcoes(ev){tmxMenu(ev,TMX_TOOLS.map(([k,t])=>[t,()=>tmxFerramenta(k)]),true);}
function tmxToolsHtml(){return `<div class="tm-tools">${TMX_TOOLS.map(([k,t])=>`<button onclick="tmxFerramenta('${k}')">${t}</button>`).join('')}</div>`;}
function tmxFerramenta(k){
 if(k==='pedido')tmxNovoPedido(null);else if(k==='aviso')tmxNovoAviso();else if(k==='reuniao')tmxNovaReuniao();
 else if(k==='anexo')tmxEscolherArquivo('*/*');else if(k==='audio')tmxGravar();
 else if(k==='voz'||k==='video')tmxLigar(k);else if(k==='cliente')tmxCitarCliente();else if(k==='mencao')tmxMencionar();
}
function tmxInputAtual(){return tmxEl(tmxFlutAberto&&tmxFlutCanal?'tmfin':'tmin');}
function tmxMencionar(){
 const ps=(tmxEquipe&&tmxEquipe.pessoas||[]).filter(p=>p.id!==tmxEu.id);
 tmxModal('Mencionar',`<input class="fi" placeholder="Buscar pessoa" oninput="tmxQS('#tmmen .tm-it').forEach(l=>l.style.display=l.dataset.n.includes(this.value.toLowerCase())?'':'none')"><div id="tmmen" style="max-height:50vh;overflow-y:auto;margin-top:8px">${ps.map(p=>`<div class="tm-it" data-n="${tmxEsc(p.nome.toLowerCase())}" onclick="tmxInserirMencao('${p.id}')"><div class="tm-av" style="background:${tmxCor(p.nome)}">${tmxEsc(tmxIni(p.nome))}</div><div class="tm-itc"><div class="tm-l1"><b>${tmxEsc(p.nome)}</b></div><div class="tm-l2"><span>${tmxEsc((p.setores||[]).map(tmxSetorNome).join(', '))}</span></div></div></div>`).join('')}</div>`,440);
}
function tmxInserirMencao(pid){const i=tmxInputAtual();tmxFecharModal();if(!i)return;const p=tmxPessoa(pid);const v=i.value.replace(/@$/,'');i.value=(v&&!v.endsWith(' ')?v+' ':v)+'@'+p.nome+' ';i.focus();}
let tmxCliCache={},tmxCliBuscaT=null;
function tmxCitarCliente(){
 tmxModal('Citar cliente',`<input class="fi" id="tmclb" placeholder="Nome ou CNPJ do cliente" oninput="clearTimeout(tmxCliBuscaT);tmxCliBuscaT=setTimeout(tmxCliBuscar,300)"><div id="tmclr" style="max-height:50vh;overflow-y:auto;margin-top:8px"></div>`,480);
 setTimeout(()=>{const i=tmxEl('tmclb');if(i)i.focus();},0);
}
async function tmxCliBuscar(){
 const i=tmxEl('tmclb'),box=tmxEl('tmclr');if(!i||!box)return;const t=i.value.trim();if(t.length<2){box.innerHTML='';return;}
 const r=await tmxCfg.buscarClientes(t);if(!tmxEl('tmclr'))return;
 if(r.error){tmxToast('Não foi possível buscar.');return;}
 (r.data||[]).forEach(c=>tmxCliCache[c.empresa_id]=c);
 box.innerHTML=(r.data||[]).map(c=>{const nm=c.razao_social||c.nome_fantasia||'';return `<div class="tm-it" onclick="tmxEnviarCliente('${c.empresa_id}')"><div class="tm-av" style="background:${tmxCor(nm)}">${TMX_ICO_PREDIO}</div><div class="tm-itc"><div class="tm-l1"><b>${tmxEsc(nm)}</b></div><div class="tm-l2"><span>${tmxEsc(tmxCnpj(c.cnpj))}${c.nome_fantasia&&c.razao_social?' · '+tmxEsc(c.nome_fantasia):''}</span></div></div></div>`;}).join('');
}
async function tmxEnviarCliente(eid){
 tmxFecharModal();const canal=tmxAlvo();if(!canal)return;const i=tmxInputAtual();const coment=i&&i.value.trim()?i.value.trim():'';if(i)i.value='';
 const id=await tmxGravarMsg({tipo:'texto',corpo:coment||'Cliente citado',meta:{cliente_id:eid}},tmxMencoes(coment),canal);
 if(id)tmxCarregarMsgs(canal);
}
async function tmxResolverClientes(ids){
 const faltam=[...new Set(ids)].filter(x=>x&&!(x in tmxCliCache));if(!faltam.length)return false;
 faltam.forEach(x=>tmxCliCache[x]=null);
 const r=await tmxCfg.clientes(faltam);if(r.error)return false;
 (r.data||[]).forEach(c=>tmxCliCache[c.empresa_id]=c);return true;
}
function tmxCartaoCliente(eid){const c=tmxCliCache[eid];const nm=c?(c.razao_social||c.nome_fantasia):'Cliente';
 return `<div class="tm-cli" onclick="tmxVerCliente('${eid}')"><span class="tm-cli-ic">${TMX_ICO_PREDIO}</span><div><b>${tmxEsc(nm||'Cliente')}</b><span>${c?tmxEsc(tmxCnpj(c.cnpj)):''}</span></div></div>`;}
function tmxVerCliente(eid){const c=tmxCliCache[eid];if(!c){tmxToast('Cliente fora da sua carteira.');return;}
 tmxModal('Cliente',`<span class="fl">Razão social</span><div style="font-size:13px;font-weight:600">${tmxEsc(c.razao_social||'—')}</div><span class="fl">Nome fantasia</span><div style="font-size:13px">${tmxEsc(c.nome_fantasia||'—')}</div><span class="fl">CNPJ</span><div style="font-size:13px">${tmxEsc(tmxCnpj(c.cnpj))}</div><span class="fl">Situação</span><div style="font-size:13px">${c.ativa===false?'Inativa':'Ativa'}</div>`);}

/* ---------- TEAM'S ligacoes ---------- */
let tmxCall=null,tmxSinal=null,tmxToque=null;
const TMX_ICE={iceServers:[{urls:'stun:stun.l.google.com:19302'},{urls:'stun:stun1.l.google.com:19302'}]};
async function tmxEnviarSinal(uid,event,payload){
 const s=(await tmx.auth.getSession()).data.session;if(!s)return;
 await fetch(TMX_URL+'/realtime/v1/api/broadcast',{method:'POST',headers:{'Content-Type':'application/json',apikey:TMX_KEY,Authorization:'Bearer '+s.access_token},
  body:JSON.stringify({messages:[{topic:'tm-u-'+uid,event,payload:Object.assign({chamada:tmxCall?tmxCall.id:payload.chamada,de:tmxEu.id},payload),private:true}]})}).catch(()=>{});
}
function tmxEscutarLigacoes(){
 tmxSinal=tmx.channel('tm-u-'+tmxEu.id,{config:{private:true}}).on('broadcast',{event:'*'},m=>tmxSinalChegou(m.event,m.payload||{})).subscribe();
}
function tmxAlvosDoCanal(c){if(!c)return [];if(c.tipo==='departamentos')return (c.membros||[]).filter(x=>x!==tmxEu.id);if(c.tipo==='setor')return (tmxEquipe.pessoas||[]).filter(p=>(p.setores||[]).includes(c.setor_id)).map(p=>p.id).filter(x=>x!==tmxEu.id);return (c.membros||[]).filter(x=>x!==tmxEu.id);}
async function tmxMidia(video){try{return await navigator.mediaDevices.getUserMedia({audio:true,video:video?{width:640,height:480}:false});}catch(e){if(video){try{return await navigator.mediaDevices.getUserMedia({audio:true});}catch(x){}}tmxToast('Sem acesso ao microfone'+(video?' ou à câmera':'')+'.');return null;}}
async function tmxLkPasse(canal){
 if(window.tmxLkPasseTeste)return window.tmxLkPasseTeste(canal);
 const s=(await tmx.auth.getSession()).data.session;if(!s)return null;
 const r=await fetch(TMX_URL+'/functions/v1/teams-ligacao-token',{method:'POST',headers:{'Content-Type':'application/json',apikey:TMX_KEY,Authorization:'Bearer '+s.access_token},body:JSON.stringify({canal_id:canal})}).catch(()=>null);
 if(!r)return null;const j=await r.json().catch(()=>({}));return j.ok?j:null;
}
function tmxLkLocal(){const L=window.LivekitClient,lp=tmxCall.lk.localParticipant,s=new MediaStream();
 [L.Track.Source.Microphone,L.Track.Source.Camera].forEach(src=>{const pub=lp.getTrackPublication(src);if(pub&&pub.track&&!pub.isMuted)s.addTrack(pub.track.mediaStreamTrack);});return s;}
async function tmxLkEntrar(video){
 const L=window.LivekitClient;if(!L||!tmxCall)return false;
 const p=await tmxLkPasse(tmxCall.canal);if(!p||!tmxCall)return false;
 const room=new L.Room({adaptiveStream:true,dynacast:true});
 const ativar=()=>{if(tmxCall&&tmxCall.estado!=='ativa'){tmxCall.estado='ativa';tmxCall.inicio=tmxCall.inicio||Date.now();clearTimeout(tmxCall.limite);}};
 room.on(L.RoomEvent.TrackSubscribed,(track,pub,part)=>{if(!tmxCall)return;let st=tmxCall.remotos[part.identity];if(!st){st=new MediaStream();tmxCall.remotos[part.identity]=st;}
  st.getTracks().filter(t=>t.kind===track.kind).forEach(t=>st.removeTrack(t));st.addTrack(track.mediaStreamTrack);ativar();tmxDesenharLigacao();});
 room.on(L.RoomEvent.TrackUnsubscribed,(track,pub,part)=>{const st=tmxCall&&tmxCall.remotos[part.identity];if(st)st.removeTrack(track.mediaStreamTrack);tmxDesenharLigacao();});
 room.on(L.RoomEvent.ParticipantConnected,part=>{if(!tmxCall)return;tmxCall.remotos[part.identity]=tmxCall.remotos[part.identity]||new MediaStream();ativar();tmxDesenharLigacao();});
 room.on(L.RoomEvent.ParticipantDisconnected,part=>{if(!tmxCall)return;delete tmxCall.remotos[part.identity];if(!room.remoteParticipants.size&&tmxCall.estado==='ativa')tmxEncerrar();else tmxDesenharLigacao();});
 room.on(L.RoomEvent.Disconnected,()=>{if(tmxCall&&tmxCall.lk===room){tmxCall.lk=null;tmxEncerrar('A conexão caiu');}});
 try{await room.connect(p.url,p.token);}catch(e){return false;}
 if(!tmxCall){room.disconnect();return false;}
 tmxCall.lk=room;tmxCall.modo='lk';
 try{await room.localParticipant.setMicrophoneEnabled(true);}catch(e){tmxToast('Sem acesso ao microfone.');}
 if(video){try{await room.localParticipant.setCameraEnabled(true);}catch(e){tmxToast('Sem acesso à câmera.');}}
 tmxCall.local=tmxLkLocal();
 room.remoteParticipants.forEach(part=>{tmxCall.remotos[part.identity]=tmxCall.remotos[part.identity]||new MediaStream();ativar();});
 return true;
}
async function tmxLigar(tipo){
 if(tmxCall){tmxToast('Você já está numa ligação.');return;}
 const canal=tmxAlvo();const c=tmxCanais.find(x=>x.id===canal);if(!c)return;
 const alvos=tmxAlvosDoCanal(c);if(!alvos.length){tmxToast('Ninguém para chamar nesta conversa.');return;}
 const r=await tmx.from('chat_chamada').insert({canal_id:canal,tipo:tipo==='video'?'video':'voz',iniciada_por:tmxEu.id}).select('id').single();
 if(r.error){tmxToast('Não foi possível iniciar a ligação.');return;}
 await tmx.from('chat_chamada_participante').insert({chamada_id:r.data.id,usuario_id:tmxEu.id,entrou_em:new Date().toISOString()});
 tmxCall={id:r.data.id,canal,tipo,local:null,pcs:{},remotos:{},participantes:[tmxEu.id,...alvos],estado:'chamando',inicio:null,dono:true,nome:tmxNomeCanal(c),modo:'p2p'};
 tmxDesenharLigacao();
 if(!(await tmxLkEntrar(tipo==='video'))){if(!tmxCall)return;const st=await tmxMidia(tipo==='video');if(!st){tmxCall=null;tmxDesenharLigacao();return;}tmxCall.local=st;}
 if(!tmxCall)return;tmxDesenharLigacao();
 alvos.forEach(u=>tmxEnviarSinal(u,'ligar',{chamada:r.data.id,canal,tipo,modo:tmxCall.modo,nome:tmxEu.nome,canal_nome:tmxNomeCanal(c),participantes:tmxCall.participantes}));
 tmxCall.limite=setTimeout(()=>{if(tmxCall&&tmxCall.estado==='chamando'){tmxEncerrar('Chamada não atendida');}},45000);
}
function tmxTocar(liga){
 if(!liga){if(tmxToque){clearInterval(tmxToque.i);try{tmxToque.ctx.close();}catch(e){}tmxToque=null;}return;}
 if(tmxToque)return;try{const ctx=new (window.AudioContext||window.webkitAudioContext)();const bip=()=>{const o=ctx.createOscillator(),g=ctx.createGain();o.frequency.value=620;g.gain.value=.08;o.connect(g);g.connect(ctx.destination);o.start();o.stop(ctx.currentTime+.35);};bip();tmxToque={ctx,i:setInterval(bip,1400)};}catch(e){}
}
function tmxSinalChegou(ev,p){
 if(ev==='ligar'){
  if(tmxCall){tmxEnviarSinal(p.de,'ocupado',{chamada:p.chamada});return;}
  tmxCall={id:p.chamada,canal:p.canal,tipo:p.tipo,modo:p.modo||'p2p',local:null,pcs:{},remotos:{},participantes:p.participantes||[p.de],estado:'tocando',de:p.de,nome:p.canal_nome,dono:false};
  tmxTocar(true);tmxDesenharLigacao();
  tmxCall.limite=setTimeout(()=>{if(tmxCall&&tmxCall.estado==='tocando'){tmxTocar(false);tmxCall=null;tmxDesenharLigacao();}},45000);
  return;}
 if(!tmxCall||p.chamada!==tmxCall.id)return;
 if(ev==='entrou'){if(tmxCall.estado==='tocando'){return;}
  if(!tmxCall.participantes.includes(p.de))tmxCall.participantes.push(p.de);
  if(tmxCall.estado==='chamando'){tmxCall.estado='ativa';tmxCall.inicio=Date.now();clearTimeout(tmxCall.limite);tmx.from('chat_chamada').update({atendida_em:new Date().toISOString()}).eq('id',tmxCall.id).then(()=>{},()=>{});}
  if(!tmxCall.lk)tmxOfertar(p.de);tmxDesenharLigacao();}
 else if(ev==='sdp')tmxRecebeuSdp(p.de,p.sdp);
 else if(ev==='ice'){const pc=tmxCall.pcs[p.de];if(pc&&p.cand)pc.addIceCandidate(p.cand).catch(()=>{});}
 else if(ev==='sair'||ev==='recusar'||ev==='ocupado'){
  if(tmxCall.estado==='tocando'&&ev==='sair'&&p.de===tmxCall.de){tmxTocar(false);clearTimeout(tmxCall.limite);tmxCall=null;tmxDesenharLigacao();return;}
  const pc=tmxCall.pcs[p.de];if(pc){pc.close();delete tmxCall.pcs[p.de];delete tmxCall.remotos[p.de];}
  const ativos=Object.keys(tmxCall.pcs).length;
  if(ev!=='sair'&&tmxCall.estado==='chamando'){tmxCall.recusas=(tmxCall.recusas||0)+1;if(tmxCall.recusas>=tmxCall.participantes.length-1)tmxEncerrar(ev==='ocupado'?'Ocupado':'Chamada recusada');else tmxDesenharLigacao();return;}
  if(!ativos&&tmxCall.estado==='ativa')tmxEncerrar();else tmxDesenharLigacao();}
}
function tmxNovoPc(uid){
 const pc=new RTCPeerConnection(TMX_ICE);tmxCall.pcs[uid]=pc;
 if(tmxCall.local)tmxCall.local.getTracks().forEach(t=>pc.addTrack(t,tmxCall.local));
 pc.onicecandidate=e=>{if(e.candidate)tmxEnviarSinal(uid,'ice',{cand:e.candidate.toJSON()});};
 pc.ontrack=e=>{tmxCall.remotos[uid]=e.streams[0];tmxDesenharLigacao();};
 pc.onconnectionstatechange=()=>{if(['failed','closed'].includes(pc.connectionState)&&tmxCall&&tmxCall.pcs[uid]===pc){delete tmxCall.pcs[uid];delete tmxCall.remotos[uid];if(!Object.keys(tmxCall.pcs).length&&tmxCall.estado==='ativa')tmxEncerrar('A conexão caiu');else tmxDesenharLigacao();}};
 return pc;
}
async function tmxOfertar(uid){if(tmxCall.pcs[uid])return;const pc=tmxNovoPc(uid);const of=await pc.createOffer();await pc.setLocalDescription(of);tmxEnviarSinal(uid,'sdp',{sdp:pc.localDescription.toJSON()});}
async function tmxRecebeuSdp(uid,sdp){
 if(!tmxCall||!sdp)return;let pc=tmxCall.pcs[uid];
 if(sdp.type==='offer'){if(!pc)pc=tmxNovoPc(uid);await pc.setRemoteDescription(sdp);const an=await pc.createAnswer();await pc.setLocalDescription(an);tmxEnviarSinal(uid,'sdp',{sdp:pc.localDescription.toJSON()});if(tmxCall.estado!=='ativa'){tmxCall.estado='ativa';tmxCall.inicio=Date.now();}tmxDesenharLigacao();}
 else if(pc)await pc.setRemoteDescription(sdp);
}
async function tmxAtender(comVideo){
 if(!tmxCall||tmxCall.estado!=='tocando')return;tmxTocar(false);clearTimeout(tmxCall.limite);
 tmxCall.estado='conectando';tmxDesenharLigacao();
 if(tmxCall.modo==='lk'){if(!(await tmxLkEntrar(comVideo))){tmxToast('Não foi possível entrar na ligação.');tmxRecusar();return;}}
 else{const st=await tmxMidia(comVideo);if(!st){tmxRecusar();return;}tmxCall.local=st;}
 if(!tmxCall)return;tmxCall.inicio=tmxCall.inicio||Date.now();
 tmx.from('chat_chamada_participante').insert({chamada_id:tmxCall.id,usuario_id:tmxEu.id,entrou_em:new Date().toISOString()}).then(()=>{},()=>{});
 tmxCall.participantes.filter(u=>u!==tmxEu.id).forEach(u=>tmxEnviarSinal(u,'entrou',{}));
 tmxDesenharLigacao();
}
function tmxRecusar(){if(!tmxCall)return;if(tmxCall.lk){try{tmxCall.lk.disconnect();}catch(e){}}tmxTocar(false);clearTimeout(tmxCall.limite);tmxEnviarSinal(tmxCall.de,'recusar',{});tmxCall=null;tmxDesenharLigacao();}
async function tmxEncerrar(motivo){
 if(!tmxCall)return;const c=tmxCall;tmxCall=null;tmxTocar(false);clearTimeout(c.limite);clearInterval(c.relogio);
 c.participantes.filter(u=>u!==tmxEu.id).forEach(u=>tmxEnviarSinal(u,'sair',{chamada:c.id}));
 Object.values(c.pcs).forEach(pc=>{try{pc.close();}catch(e){}});if(c.lk){const r=c.lk;c.lk=null;try{r.disconnect();}catch(e){}}
 if(c.local)c.local.getTracks().forEach(t=>t.stop());if(c.tela)c.tela.getTracks().forEach(t=>t.stop());
 tmx.from('chat_chamada_participante').update({saiu_em:new Date().toISOString()}).eq('chamada_id',c.id).eq('usuario_id',tmxEu.id).then(()=>{},()=>{});
 if(c.dono||c.inicio){
  const dur=c.inicio?Math.round((Date.now()-c.inicio)/1000):0;const mm=String(Math.floor(dur/60)).padStart(2,'0')+':'+String(dur%60).padStart(2,'0');
  if(c.dono){await tmx.from('chat_chamada').update({encerrada_em:new Date().toISOString()}).eq('id',c.id);
   await tmxGravarMsg({tipo:'sistema',corpo:(c.tipo==='video'?'🎥 Chamada de vídeo':'📞 Chamada de voz')+(motivo?' · '+motivo:' · '+mm),meta:{chamada_id:c.id}},null,c.canal);
   if(tmxMsgs[c.canal])tmxCarregarMsgs(c.canal);}
 }
 tmxDesenharLigacao();
}
async function tmxMudo(){if(!tmxCall)return;tmxCall.mudo=!tmxCall.mudo;if(tmxCall.lk){await tmxCall.lk.localParticipant.setMicrophoneEnabled(!tmxCall.mudo);}else if(tmxCall.local)tmxCall.local.getAudioTracks().forEach(t=>t.enabled=!tmxCall.mudo);tmxDesenharLigacao();}
async function tmxCamera(){if(!tmxCall)return;if(tmxCall.lk){const on=!tmxCall.lk.localParticipant.isCameraEnabled;try{await tmxCall.lk.localParticipant.setCameraEnabled(on);}catch(e){tmxToast('Sem acesso à câmera.');}tmxCall.semCam=!on;tmxCall.local=tmxLkLocal();tmxDesenharLigacao();return;}if(!tmxCall.local)return;const v=tmxCall.local.getVideoTracks();if(!v.length){tmxToast('Ligação só de voz.');return;}tmxCall.semCam=!tmxCall.semCam;v.forEach(t=>t.enabled=!tmxCall.semCam);tmxDesenharLigacao();}
async function tmxTela(){
 if(tmxCall&&tmxCall.lk){const on=!tmxCall.tela;try{await tmxCall.lk.localParticipant.setScreenShareEnabled(on);tmxCall.tela=on;}catch(e){tmxToast('Não foi possível compartilhar a tela.');}tmxDesenharLigacao();return;}
 if(!tmxCall||!tmxCall.local)return;const v=tmxCall.local.getVideoTracks()[0];if(!v){tmxToast('Compartilhar a tela só em ligação de vídeo.');return;}
 if(tmxCall.tela){const t=tmxCall.tela;tmxCall.tela=null;t.getTracks().forEach(x=>x.stop());Object.values(tmxCall.pcs).forEach(pc=>pc.getSenders().forEach(s=>{if(s.track&&s.track.kind==='video')s.replaceTrack(v);}));tmxDesenharLigacao();return;}
 try{const t=await navigator.mediaDevices.getDisplayMedia({video:true});tmxCall.tela=t;const tr=t.getVideoTracks()[0];
  Object.values(tmxCall.pcs).forEach(pc=>pc.getSenders().forEach(s=>{if(s.track&&s.track.kind==='video')s.replaceTrack(tr);}));tr.onended=()=>{if(tmxCall&&tmxCall.tela)tmxTela();};tmxDesenharLigacao();}
 catch(e){tmxToast('Não foi possível compartilhar a tela.');}
}
function tmxDesenharLigacao(){
 let o=tmxEl('tmxLig');
 if(!tmxCall){if(o)o.remove();return;}
 if(!o){o=document.createElement('div');o.id='tmxLig';o.className='tm-lig';tmxCamada().appendChild(o);}
 const c=tmxCall;const quem=c.dono||c.estado!=='tocando'?c.nome:tmxPessoa(c.de).nome;
 if(c.estado==='tocando'){
  o.innerHTML=`<div class="tm-ligbox tm-toc"><div class="tm-av g" style="width:84px;height:84px;font-size:26px;background:${tmxCor(quem)}">${tmxEsc(tmxIni(quem))}</div><b>${tmxEsc(quem)}</b><span>${c.tipo==='video'?'Chamada de vídeo':'Chamada de voz'}${c.nome&&c.nome!==quem?' · '+tmxEsc(c.nome):''}</span>
   <div class="tm-ligctl"><button class="tm-lb no" onclick="tmxRecusar()">Recusar</button><button class="tm-lb ok" onclick="tmxAtender(false)">${TMX_ICO_FONE} Atender</button>${c.tipo==='video'?`<button class="tm-lb ok" onclick="tmxAtender(true)">${TMX_ICO_CAM} Com vídeo</button>`:''}</div></div>`;
  return;}
 const rem=Object.keys(c.remotos);
 const tempo=c.inicio&&c.estado==='ativa'?(()=>{const d=Math.round((Date.now()-c.inicio)/1000);return String(Math.floor(d/60)).padStart(2,'0')+':'+String(d%60).padStart(2,'0');})():(c.estado==='chamando'?'Chamando…':'Conectando…');
 o.innerHTML=`<div class="tm-ligbox"><div class="tm-ligtop"><b>${tmxEsc(c.nome||'')}</b><span id="tmxLigTempo">${tempo}</span></div>
  <div class="tm-ligpal">${rem.length?rem.map(u=>{const sv=c.remotos[u]&&c.remotos[u].getVideoTracks().length;return `<div class="tm-tile${sv?'':' vazio'}">${sv?'':`<div class="tm-av g" style="width:84px;height:84px;font-size:26px;background:${tmxCor(tmxPessoa(u).nome)}">${tmxEsc(tmxIni(tmxPessoa(u).nome))}</div>`}<video autoplay playsinline data-u="${u}"${sv?'':' style="display:none"'}></video><span>${tmxEsc(tmxPessoa(u).nome)}</span></div>`;}).join(''):`<div class="tm-tile vazio"><div class="tm-av g" style="width:84px;height:84px;font-size:26px;background:${tmxCor(c.nome||'')}">${tmxEsc(tmxIni(c.nome||''))}</div><span>${tmxEsc(c.nome||'')}</span></div>`}
   ${c.local&&c.local.getVideoTracks().length?`<video class="tm-eu-v" autoplay playsinline muted id="tmxEuV"></video>`:''}</div>
  <div class="tm-ligctl"><button class="tm-lb${c.mudo?' on':''}" onclick="tmxMudo()">${c.mudo?'🔇 Sem som':'🎤 Mudo'}</button>${c.lk||c.local&&c.local.getVideoTracks().length?`<button class="tm-lb${c.semCam?' on':''}" onclick="tmxCamera()">${TMX_ICO_CAM} ${c.semCam?'Ligar câmera':'Câmera'}</button><button class="tm-lb${c.tela?' on':''}" onclick="tmxTela()">🖥 ${c.tela?'Parar tela':'Tela'}</button>`:''}<button class="tm-lb no" onclick="tmxEncerrar()">Encerrar</button></div></div>`;
 o.querySelectorAll('video[data-u]').forEach(v=>{const s=c.remotos[v.dataset.u];if(s&&v.srcObject!==s)v.srcObject=s;});
 const ev=tmxEl('tmxEuV');if(ev)ev.srcObject=c.lk?c.local:(c.tela||c.local);
 clearInterval(c.relogio);if(c.estado==='ativa')c.relogio=setInterval(()=>{const t=tmxEl('tmxLigTempo');if(!t||!tmxCall||!tmxCall.inicio){clearInterval(c.relogio);return;}const d=Math.round((Date.now()-tmxCall.inicio)/1000);t.textContent=String(Math.floor(d/60)).padStart(2,'0')+':'+String(d%60).padStart(2,'0');},1000);
}

/* ---------- TEAM'S API ---------- */
window.TeamsIT={
 versao:'2026.10.07',
 iniciar(cfg){
  tmxCfg=cfg||{};tmxTema=Object.assign({},tmxCfg.tema||{});
  if(tmxTema.fonteCss&&!document.querySelector('link[data-tmx-fonte]')){const l=document.createElement('link');l.rel='stylesheet';l.href=tmxTema.fonteCss;l.setAttribute('data-tmx-fonte','');document.head.appendChild(l);}
  [tmxModHost,tmxCamHost].forEach(h=>{if(h)tmxAplicarTema(h);});
  return tmxIniciar();
 },
 avisoAcao(a){return tmxAvisoAcao(a);},
 abrirModulo(caixa){
  if(!caixa)return;if(!tmxModHost)tmxModHost=tmxHost('tmx-mod');
  caixa.innerHTML='';caixa.appendChild(tmxModHost);tmxRenderTeams();tmxBolinha();
 },
 tela(o){tmxBolAlta=!!(o&&o.bolinhaAlta);tmxBolinha();},
 total(){return tmxTotal();},
 abrirConversa(id){if(tmxNoModulo())tmxAbrirCanal(id);}
};
