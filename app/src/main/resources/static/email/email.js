/* Modulo E-mail's */
(function(){
 var SUPA=BL_URL;
 var ANON=BL_KEY;
 var MEU_ID=null;
 function meuId(){return MEU_ID;}
 function hdrs(){return blSessao().then(function(s){
  if(!s)throw new Error('sem_login');
  MEU_ID=s.user&&s.user.id;
  return {apikey:ANON,Authorization:'Bearer '+s.access_token,'Content-Type':'application/json'};});}

 function fn(nome,body){
  return hdrs().then(function(h){return fetch(SUPA+'/functions/v1/'+nome,{method:'POST',headers:h,body:JSON.stringify(body||{})});})
   .then(function(r){return r.json().then(function(d){if(!r.ok||d&&d.error)throw new Error((d&&d.error)||('http '+r.status));return d;});});
 }
 function rest(caminho,metodo,body){
  return hdrs().then(function(h){
   var o={method:metodo||'GET',headers:h};
   if(body)o.body=JSON.stringify(body);
   if(metodo==='POST')o.headers.Prefer='return=representation,resolution=merge-duplicates';
   return fetch(SUPA+'/rest/v1/'+caminho,o);
  }).then(function(r){if(!r.ok)throw new Error('http '+r.status);return r.status===204?null:r.json();});
 }
 function rpc(nome,args){return rest('rpc/'+nome,'POST',args||{});}
 function cx(m,b){return fn('gmail-listar-mensagens',Object.assign({contaId:E.contaId},m,b));}
 function ag(b){return fn('gmail-agenda',b);}
 function ex(b){return fn('gmail-extras',Object.assign({contaId:E.contaId},b));}

 /* ---- icones (mesmos do Gmail) ---- */
 function ic(d,cheio){return '<svg class="em-ic" viewBox="0 0 24 24" fill="'+(cheio?'currentColor':'none')+'" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">'+d+'</svg>';}
 var I={
  menu:'<path d="M3 6h18M3 12h18M3 18h18"/>',
  mail:'<rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M3 7l9 6 9-6"/>',
  funil:'<path d="M4 5h16l-6.5 7.5V19l-3 1.5v-8z"/>',
  busca:'<circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/>',
  estrela:'<path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z"/>',
  inbox:'<path d="M3 12h5l2 3h4l2-3h5"/><path d="M4.5 5.5h15l1.5 6.5v6a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-6z"/>',
  relogio:'<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  enviar:'<path d="M21 3L10.5 13.5"/><path d="M21 3l-6.5 18-4-8-8-4z"/>',
  arquivo:'<path d="M14.5 3.5H7a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z"/><path d="M14.5 3.5V8H19"/>',
  marcador:'<path d="M6.5 4.5h9l5 7.5-5 7.5h-9a2 2 0 0 1-2-2v-11a2 2 0 0 1 2-2z"/>',
  calclock:'<rect x="3.5" y="5" width="17" height="15" rx="2"/><path d="M3.5 9.5h17M8 3.5v3M16 3.5v3M12 12.5v3l2 1"/>',
  mails:'<rect x="6" y="6" width="15" height="11" rx="2"/><path d="M6.5 8l7 4.5L20.5 8"/><path d="M3 8.5v9a2 2 0 0 0 2 2h11"/>',
  spam:'<path d="M12 3.5l8 3v5.5c0 4.5-3.2 7.6-8 8.5-4.8-.9-8-4-8-8.5V6.5z"/><path d="M12 8.5v4M12 15.5v.5"/>',
  lixo:'<path d="M4 6.5h16"/><path d="M9.5 6.5V4.5h5v2"/><path d="M6.5 6.5l1 13a1 1 0 0 0 1 1h7a1 1 0 0 0 1-1l1-13"/>',
  users:'<circle cx="9" cy="8" r="3.2"/><path d="M3 19.5c.5-3 3-4.6 6-4.6s5.5 1.6 6 4.6"/><path d="M16 5.5a3 3 0 0 1 0 6M17.5 15c2 .5 3.4 2 3.8 4"/>',
  info:'<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8v.5"/>',
  forum:'<path d="M4 5.5h11a1.5 1.5 0 0 1 1.5 1.5v5A1.5 1.5 0 0 1 15 13.5H8l-4 3z"/><path d="M8 16.5v1A1.5 1.5 0 0 0 9.5 19H16l4 3v-10A1.5 1.5 0 0 0 18.5 10.5H17"/>',
  tag:'<path d="M3.5 11.5V5a1.5 1.5 0 0 1 1.5-1.5h6.5L20.5 12 12 20.5z"/><circle cx="7.5" cy="7.5" r="1.3" fill="currentColor"/>',
  book:'<path d="M6 3.5h12a1 1 0 0 1 1 1v16l-7-4-7 4v-16a1 1 0 0 1 1-1z"/>',
  lapis:'<path d="M4 20l4.5-1 11-11a2.1 2.1 0 0 0-3-3l-11 11z"/>',
  voltar:'<path d="M19 12H5M11 6l-6 6 6 6"/>',
  atualizar:'<path d="M20 11a8 8 0 1 0-2.3 6.3"/><path d="M20 4.5V11h-6.5"/>',
  esq:'<path d="M15 6l-6 6 6 6"/>',
  dir:'<path d="M9 6l6 6-6 6"/>',
  baixo:'<path d="M6 9l6 6 6-6"/>',
  cima:'<path d="M6 15l6-6 6 6"/>',
  dirp:'<path d="M9 6l6 6-6 6"/>',
  mais:'<path d="M12 5v14M5 12h14"/>',
  x:'<path d="M6 6l12 12M18 6L6 18"/>',
  config:'<circle cx="12" cy="12" r="3"/><path d="M12 2.5l1.2 2.3 2.6-.6.5 2.6 2.3 1.2-.8 2.5.8 2.5-2.3 1.2-.5 2.6-2.6-.6L12 21.5l-1.2-2.3-2.6.6-.5-2.6-2.3-1.2.8-2.5-.8-2.5 2.3-1.2.5-2.6 2.6.6z"/>',
  ajuda:'<circle cx="12" cy="12" r="8.5"/><path d="M9.7 9.2a2.4 2.4 0 1 1 3.1 2.7c-.6.3-.8.8-.8 1.4v.4M12 16.5v.5"/>',
  painel:'<path d="M7 6l6 6-6 6M14 6l6 6-6 6"/>',
  brilho:'<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z"/>',
  grade:'<circle cx="5" cy="5" r="1.9" fill="currentColor" stroke="none"/><circle cx="12" cy="5" r="1.9" fill="currentColor" stroke="none"/><circle cx="19" cy="5" r="1.9" fill="currentColor" stroke="none"/><circle cx="5" cy="12" r="1.9" fill="currentColor" stroke="none"/><circle cx="12" cy="12" r="1.9" fill="currentColor" stroke="none"/><circle cx="19" cy="12" r="1.9" fill="currentColor" stroke="none"/><circle cx="5" cy="19" r="1.9" fill="currentColor" stroke="none"/><circle cx="12" cy="19" r="1.9" fill="currentColor" stroke="none"/><circle cx="19" cy="19" r="1.9" fill="currentColor" stroke="none"/>',
  filtros:'<path d="M4 7h10M18 7h2M4 17h2M10 17h10"/><circle cx="16" cy="7" r="2"/><circle cx="8" cy="17" r="2"/>',
  chat:'<path d="M20.5 12.5a7.5 7.5 0 0 1-10.9 6.7L4 20.5l1.4-4.6A7.5 7.5 0 1 1 20.5 12.5z"/>',
  video:'<rect x="2.5" y="6" width="13" height="12" rx="2"/><path d="M15.5 10.5l6-3.5v10l-6-3.5z"/>',
  cal:'<rect x="3.5" y="5" width="17" height="15" rx="2"/><path d="M3.5 9.5h17M8 3.5v3M16 3.5v3"/>',
  check:'<path d="M5 12.5l5 5 9-11"/>',
  checkcirc:'<circle cx="12" cy="12" r="8.5"/><path d="M8.5 12.5l2.5 2.5 4.5-5.5"/>',
  circ:'<circle cx="12" cy="12" r="8.5"/>',
  resp:'<path d="M10 7L4 12l6 5"/><path d="M4 12h9a6 6 0 0 1 6 6v1"/>',
  enc:'<path d="M14 7l6 5-6 5"/><path d="M20 12h-9a6 6 0 0 0-6 6v1"/>',
  addu:'<circle cx="9.5" cy="8" r="3.3"/><path d="M3 19.5c.5-3 3-4.7 6.5-4.7 1 0 1.9.1 2.7.4"/><path d="M17.5 13.5v6M14.5 16.5h6"/>',
  down:'<path d="M12 4v11M7.5 11l4.5 4.5 4.5-4.5"/><path d="M4.5 19.5h15"/>',
  clip:'<path d="M20 11.5l-8 8a5 5 0 0 1-7-7l8.5-8.5a3.4 3.4 0 0 1 4.8 4.8l-8.5 8.5a1.8 1.8 0 0 1-2.5-2.5l7.7-7.7"/>',
  plug:'<path d="M7 3.5v6M13 3.5v6"/><path d="M4.5 9.5h11v3a5.5 5.5 0 0 1-11 0z"/><path d="M10 18v3"/>',
  aberto:'<path d="M4 9.5l8-5.5 8 5.5"/><path d="M4 9.5V19a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1V9.5l-8 5z"/>',
  alerta:'<path d="M12 4l9 16H3z"/><path d="M12 10v4M12 17v.5"/>',
  hd:'<rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M6 15h.5M10 15h.5"/>',
  lamp:'<path d="M9 18h6M10 21h4"/><path d="M12 3a6 6 0 0 0-3.5 10.9c.5.4.8 1 .8 1.6h5.4c0-.6.3-1.2.8-1.6A6 6 0 0 0 12 3z"/>',
  sqcheck:'<rect x="3.5" y="3.5" width="17" height="17" rx="3"/><path d="M8 12.5l2.7 2.7L16.5 9"/>',
  pessoa:'<circle cx="12" cy="8" r="3.5"/><path d="M5 20a7 7 0 0 1 14 0"/>',
  doc:'<path d="M14 3.5H7a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8.5z"/><path d="M14 3.5v5h5"/>',
  casa:'<path d="M4 11l8-6.5 8 6.5"/><path d="M6 10v9h12v-9"/>',
  arroba:'<circle cx="12" cy="12" r="4"/><path d="M16 8v5a3 3 0 0 0 5 2 9 9 0 1 0-3 5"/>',
  minus:'<rect x="2.5" y="5" width="19" height="14" rx="2"/><path d="M8 12h8"/>'
 };
 var PASTAS_FIXAS=[{id:'INBOX',nome:'Caixa de entrada'},{id:'STARRED',nome:'Com estrela'},
  {id:'SNOOZED',nome:'Adiados'},{id:'SENT',nome:'Enviados'},{id:'DRAFT',nome:'Rascunhos'}];
 var CATEGORIAS_FIXAS=[{id:'CATEGORY_PERSONAL',nome:'Principal'},{id:'CATEGORY_SOCIAL',nome:'Social'},
  {id:'CATEGORY_UPDATES',nome:'Atualizações'},{id:'CATEGORY_FORUMS',nome:'Fóruns'},{id:'CATEGORY_PROMOTIONS',nome:'Promoções'}];
 var MAIS_FIXO=[{id:'IMPORTANT',nome:'Importantes'},{id:'TODOS',nome:'Todos os e-mails'},
  {id:'SPAM',nome:'Spam'},{id:'TRASH',nome:'Lixeira'}];
 function listaPastas(){return E.pastas.length?E.pastas:PASTAS_FIXAS;}
 function listaCategorias(){return E.categorias.length?E.categorias:CATEGORIAS_FIXAS;}
 function listaMais(){return E.mais.length?E.mais:MAIS_FIXO;}
 var ICONE_PASTA={INBOX:I.inbox,STARRED:I.estrela,SNOOZED:I.relogio,SENT:I.enviar,DRAFT:I.arquivo,IMPORTANT:I.book,SCHEDULED:I.calclock,TODOS:I.mails,SPAM:I.spam,TRASH:I.lixo,
  CATEGORY_SOCIAL:I.users,CATEGORY_UPDATES:I.info,CATEGORY_FORUMS:I.forum,CATEGORY_PROMOTIONS:I.tag,CATEGORY_PERSONAL:I.inbox};
 var CORES=['#FE4901','#3A5A8C','#1B7A44','#6D4AA0','#B25E09','#C0392B'];


 /* ---- estado ---- */
 var E={raiz:null,contas:[],contaId:null,carregandoContas:true,
  trilho:'mail',lateral:true,catAberto:false,maisAberto:false,menuContas:false,
  pastas:[],categorias:[],mais:[],marcadores:[],pastaAtiva:'INBOX',busca:'',
  mensagens:[],total:0,proxPag:null,pilha:[],tokenAtual:'',carregandoLista:false,erroLista:null,
  msgAberta:null,carregandoMsg:false,
  painel:null,contatos:[],confirmDesc:null,
  agMes:'',agDia:'',agGrade:[],agEventos:[],agConfig:{},agCarregando:false,agErro:null,
  tarListas:[],tarListaAtiva:null,tarefas:[],tarCarregando:false,tarErro:null,
  porConversa:false,conversas:[],convAberta:null,
  rascunhoId:null,salvandoRascunho:false,anexos:[],menuMarcar:false,
  cfg:null,cfgCarregando:false,
  salas:[],modal:null};

 function esc2(v){return String(v==null?'':v).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');}
 function contaAtiva(){for(var i=0;i<E.contas.length;i++)if(E.contas[i].id===E.contaId)return E.contas[i];return E.contas[0]||null;}
 function idxConta(id){for(var i=0;i<E.contas.length;i++)if(E.contas[i].id===id)return i;return 0;}
 function cor(id){return CORES[idxConta(id)%CORES.length];}
 function nomeDe(de){if(!de)return '';var s=String(de).replace(/<[^>]*>/g,'').replace(/"/g,'').trim();return s||String(de).replace(/[<>]/g,'');}
 function emailDe(de){if(!de)return '';var m=String(de).match(/<([^>]+)>/);return (m?m[1]:de).trim();}
 function dataCurta(t){var d=new Date(t);if(isNaN(d.getTime()))return '';var a=new Date();
  if(d.toDateString()===a.toDateString())return d.toLocaleTimeString('pt-BR',{hour:'2-digit',minute:'2-digit'});
  return d.toLocaleDateString('pt-BR',{day:'numeric',month:'short'});}
 function dataLonga(t){var d=new Date(t);if(isNaN(d.getTime()))return t||'';
  return d.toLocaleDateString('pt-BR',{day:'numeric',month:'long',year:'numeric'})+' às '+d.toLocaleTimeString('pt-BR',{hour:'2-digit',minute:'2-digit'});}
 function dataSoDia(s){var p=String(s).slice(0,10).split('-');if(p.length!==3)return String(s);return p[2]+'/'+p[1];}
 function tamanho(b){if(!b)return '';if(b<1024)return b+' B';if(b<1048576)return Math.round(b/1024)+' KB';return (b/1048576).toFixed(1)+' MB';}
 function fora(u){try{window.open(u,'_blank','noopener');}catch(e){}}
 function avisar(m){try{toast(m);}catch(e){}}
 function motivo(e){var m=String(e&&e.message||e);
  if(m==='precisa_reconectar')return 'Essa conta precisa ser reconectada no Java da BL.';
  if(m==='sem_acesso')return 'Você não tem acesso a essa caixa.';
  if(m==='sem_login')return 'Entre de novo no Fiscal.';
  if(m==='config_pendente')return 'O Google ainda não foi configurado no banco da BL.';
  return 'Não foi possível concluir. Tente de novo.';}

 /* ---- datas da agenda ---- */
 function dLocal(d){return d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');}
 function somaDias(s,n){return dLocal(new Date(new Date(s+'T12:00:00').getTime()+n*86400000));}
 function inicioGrade(mes){var p=new Date(mes+'-01T12:00:00');return somaDias(dLocal(p),-p.getDay());}
 function montarGrade(){var i=inicioGrade(E.agMes);var g=[];for(var k=0;k<42;k++)g.push(somaDias(i,k));E.agGrade=g;}

 /* ---- carga: contas ---- */
 function carregarContas(){
  E.carregandoContas=true;desenhar();
  return rpc('gmail_contas_permitidas').then(function(r){
   E.contas=Array.isArray(r)?r:[];
   if(!contaAtiva()&&E.contas.length)E.contaId=E.contas[0].id;
   else if(contaAtiva())E.contaId=contaAtiva().id;
   E.carregandoContas=false;desenhar();
   if(E.contaId){carregarPastas();carregarLista({});}
  }).catch(function(){E.contas=[];E.carregandoContas=false;desenhar();});
 }
 /* ---- carga: caixa ---- */
 function carregarPastas(){
  if(!E.contaId)return Promise.resolve();
  return cx({acao:'pastas'}).then(function(d){
   E.pastas=d.pastas||[];E.categorias=d.categorias||[];E.mais=d.mais||[];E.marcadores=d.marcadores||[];desenhar();
  }).catch(function(){E.pastas=[];E.categorias=[];E.mais=[];E.marcadores=[];desenhar();});
 }
 function carregarLista(o){
  o=o||{};
  if(!E.contaId)return Promise.resolve();
  E.carregandoLista=true;E.erroLista=null;desenhar();
  var pasta=o.pasta!=null?o.pasta:E.pastaAtiva;
  var busca=o.busca!=null?o.busca:E.busca;
  var pg=o.paginaToken||'';
  return cx({acao:'listar',pasta:pasta,busca:busca,paginaToken:pg,quantidade:50}).then(function(d){
   E.mensagens=d.mensagens||[];E.proxPag=d.proxima_pagina||null;E.total=d.total_estimado||0;
   E.pilha=o.pilha||[];E.tokenAtual=pg;E.carregandoLista=false;desenhar();
  }).catch(function(e){E.mensagens=[];E.erroLista=motivo(e);E.carregandoLista=false;desenhar();});
 }
 function trocarPasta(p){
  E.pastaAtiva=p;E.busca='';E.msgAberta=null;E.convAberta=null;
  if(p==='DRAFT'){carregarRascunhos();return;}
  if(E.porConversa)carregarConversas({pasta:p,busca:'',pilha:[]});
  else carregarLista({pasta:p,busca:'',pilha:[]});
 }
 function buscar(t){E.busca=t;E.msgAberta=null;E.convAberta=null;if(E.porConversa)carregarConversas({busca:t,pilha:[]});else carregarLista({busca:t,pilha:[]});}
 function proxPagina(){if(!E.proxPag)return;carregarLista({paginaToken:E.proxPag,pilha:E.pilha.concat([E.tokenAtual])});}
 function pagAnterior(){if(!E.pilha.length)return;var t=E.pilha[E.pilha.length-1];carregarLista({paginaToken:t,pilha:E.pilha.slice(0,-1)});}
 function abrirMensagem(id){
  E.carregandoMsg=true;desenhar();
  cx({acao:'ler',mensagemId:id}).then(function(d){
   E.msgAberta=d;E.carregandoMsg=false;desenhar();
   if(!d.lida){cx({acao:'marcar_lida',mensagemId:id,lida:true}).then(function(){
    for(var i=0;i<E.mensagens.length;i++)if(E.mensagens[i].id===id)E.mensagens[i].lida=true;
    carregarPastas();desenhar();}).catch(function(){});}
  }).catch(function(e){E.carregandoMsg=false;E.erroLista=motivo(e);desenhar();});
 }
 function acaoMsg(p,depois){
  return cx(p).then(function(){if(depois)depois();carregarPastas();desenhar();})
   .catch(function(e){avisar(motivo(e));});
 }
 function alternarEstrela(id,com){
  for(var i=0;i<E.mensagens.length;i++)if(E.mensagens[i].id===id)E.mensagens[i].estrela=com;
  desenhar();
  cx({acao:'estrela',mensagemId:id,com:com}).catch(function(e){
   for(var j=0;j<E.mensagens.length;j++)if(E.mensagens[j].id===id)E.mensagens[j].estrela=!com;
   avisar(motivo(e));desenhar();});
 }
 function tiraDaLista(id){E.mensagens=E.mensagens.filter(function(m){return m.id!==id;});if(E.msgAberta&&E.msgAberta.id===id)E.msgAberta=null;}

 /* ---- carga: agenda ---- */
 function cfgDe(id){return E.agConfig[id]||{mostrar:true,avisar_conflito:true};}
 function carregarCfgAgenda(){
  return rest('gmail_agenda_config?select=conta_id,mostrar,avisar_conflito').then(function(r){
   var m={};(r||[]).forEach(function(x){m[x.conta_id]={mostrar:x.mostrar,avisar_conflito:x.avisar_conflito};});
   E.agConfig=m;}).catch(function(){});
 }
 function alternarCfg(id,campo){
  var a=cfgDe(id);var novo={mostrar:a.mostrar,avisar_conflito:a.avisar_conflito};novo[campo]=!a[campo];
  E.agConfig[id]=novo;desenhar();
  var u=meuId();if(!u)return;
  rest('gmail_agenda_config?on_conflict=usuario_id,conta_id','POST',{usuario_id:u,conta_id:id,mostrar:novo.mostrar,avisar_conflito:novo.avisar_conflito,atualizado_em:new Date().toISOString()})
   .then(function(){carregarAgenda();}).catch(function(){});
 }
 function carregarAgenda(){
  montarGrade();
  var ids=E.contas.filter(function(c){return cfgDe(c.id).mostrar;}).map(function(c){return c.id;});
  if(!ids.length){E.agEventos=[];desenhar();return Promise.resolve();}
  E.agCarregando=true;E.agErro=null;desenhar();
  var ini=new Date(E.agGrade[0]+'T00:00:00').toISOString();
  var fim=new Date(new Date(E.agGrade[41]+'T00:00:00').getTime()+86400000).toISOString();
  return ag({acao:'eventos',contaIds:ids,dataInicio:ini,dataFim:fim}).then(function(d){
   var todos=[];
   (d.agendas||[]).forEach(function(a){(a.eventos||[]).forEach(function(ev){
    todos.push(Object.assign({},ev,{contaId:a.contaId,rotulo:a.rotulo,email:a.email}));});});
   todos.sort(function(a,b){return String(a.inicio).localeCompare(String(b.inicio));});
   E.agEventos=todos;E.agCarregando=false;desenhar();
  }).catch(function(e){E.agEventos=[];E.agErro=motivo(e);E.agCarregando=false;desenhar();});
 }
 function eventosPorDia(){
  var m={};
  E.agEventos.forEach(function(ev){
   if(!ev.inicio)return;
   var di=String(ev.inicio).slice(0,10);
   if(ev.dia_todo&&ev.fim){var df=String(ev.fim).slice(0,10);
    for(var d=di;d<df;d=somaDias(d,1)){(m[d]=m[d]||[]).push(ev);} }
   else {(m[di]=m[di]||[]).push(ev);}
  });
  return m;
 }
 function diasEmConflito(){
  var mon=E.agEventos.filter(function(ev){return !ev.dia_todo&&ev.inicio&&ev.fim&&cfgDe(ev.contaId).avisar_conflito;});
  var dias={};
  for(var i=0;i<mon.length;i++)for(var j=i+1;j<mon.length;j++){
   var a=mon[i],b=mon[j];
   if(a.inicio<b.fim&&b.inicio<a.fim)dias[String(a.inicio).slice(0,10)]=true;
  }
  return dias;
 }

 /* ---- carga: tarefas ---- */
 function carregarTarefas(listaId){
  if(!E.contaId||!listaId)return Promise.resolve();
  E.tarCarregando=true;E.tarErro=null;desenhar();
  return ag({contaId:E.contaId,acao:'tarefas_listar',listaId:listaId}).then(function(d){
   E.tarefas=d.tarefas||[];E.tarCarregando=false;desenhar();
  }).catch(function(e){E.tarefas=[];E.tarErro=motivo(e);E.tarCarregando=false;desenhar();});
 }
 function carregarListasTarefas(){
  if(!E.contaId)return Promise.resolve();
  E.tarCarregando=true;E.tarErro=null;desenhar();
  return ag({contaId:E.contaId,acao:'tarefas_listas'}).then(function(d){
   E.tarListas=d.listas||[];
   var tem=E.tarListas.some(function(l){return l.id===E.tarListaAtiva;});
   E.tarListaAtiva=tem?E.tarListaAtiva:(E.tarListas[0]&&E.tarListas[0].id)||null;
   E.tarCarregando=false;desenhar();
   if(E.tarListaAtiva)carregarTarefas(E.tarListaAtiva);
  }).catch(function(e){E.tarListas=[];E.tarefas=[];E.tarErro=motivo(e);E.tarCarregando=false;desenhar();});
 }

 /* ---- carga: salas do meet ---- */
 function carregarSalas(){
  if(!E.contaId)return Promise.resolve();
  return ag({contaId:E.contaId,acao:'listar_salas'}).then(function(d){E.salas=d.salas||[];desenhar();})
   .catch(function(){E.salas=[];desenhar();});
 }
 function abrirMeet(u){fora(u);}

 function carregarConversas(o){
  o=o||{};
  if(!E.contaId)return Promise.resolve();
  E.carregandoLista=true;E.erroLista=null;desenhar();
  return ex({acao:'conversas_listar',pasta:o.pasta!=null?o.pasta:E.pastaAtiva,busca:o.busca!=null?o.busca:E.busca,
   paginaToken:o.paginaToken||'',quantidade:25}).then(function(d){
   E.conversas=d.conversas||[];E.proxPag=d.proxima_pagina||null;E.total=d.total_estimado||0;
   E.pilha=o.pilha||[];E.tokenAtual=o.paginaToken||'';E.carregandoLista=false;desenhar();
  }).catch(function(e){E.conversas=[];E.erroLista=motivo(e);E.carregandoLista=false;desenhar();});
 }
 function abrirConversa(id){
  E.carregandoMsg=true;desenhar();
  ex({acao:'conversa_ler',conversaId:id}).then(function(d){
   E.convAberta=d;E.carregandoMsg=false;desenhar();
   ex({acao:'conversa_acao',conversaId:id,tipo:'lida'}).then(function(){
    E.conversas.forEach(function(c){if(c.id===id)c.lida=true;});carregarPastas();desenhar();}).catch(function(){});
  }).catch(function(e){E.carregandoMsg=false;E.erroLista=motivo(e);desenhar();});
 }
 function acaoConversa(id,tipo,depois){
  return ex({acao:'conversa_acao',conversaId:id,tipo:tipo}).then(function(){
   if(depois)depois();carregarPastas();desenhar();
  }).catch(function(e){avisar(motivo(e));});
 }
 function recarregarAtual(){
  carregarPastas();
  if(E.porConversa)carregarConversas({pilha:[]});else carregarLista({pilha:[]});
 }

 /* ---- rascunho: salva sozinho enquanto digita ---- */
 var relogioRascunho=null;
 function agendarSalvarRascunho(){
  if(relogioRascunho)clearTimeout(relogioRascunho);
  relogioRascunho=setTimeout(salvarRascunho,2500);
 }
 function salvarRascunho(){
  if(!E.modal||E.modal.tipo!=='escrever')return;
  var para=val('emPara'),assunto=val('emAssunto'),texto=val('emTexto');
  if(!para&&!assunto&&!texto)return;
  E.salvandoRascunho=true;
  var marca=document.getElementById('emSalvo');
  if(marca)marca.textContent='salvando…';
  ex({acao:'rascunho_salvar',rascunhoId:E.rascunhoId,para:para,cc:val('emCc'),cco:val('emCco'),assunto:assunto,texto:texto})
   .then(function(d){
    E.rascunhoId=d.id;E.salvandoRascunho=false;
    var m2=document.getElementById('emSalvo');
    if(m2)m2.textContent='rascunho salvo';
   }).catch(function(){
    E.salvandoRascunho=false;
    var m3=document.getElementById('emSalvo');
    if(m3)m3.textContent='';
   });
 }
 function carregarRascunhos(){
  if(!E.contaId)return Promise.resolve();
  E.carregandoLista=true;desenhar();
  return ex({acao:'rascunhos_listar',quantidade:50}).then(function(d){
   E.mensagens=(d.rascunhos||[]).map(function(r){
    return {id:r.id,rascunho:true,de:'Para: '+(r.para||'(sem destinatário)'),assunto:r.assunto,
     data:r.data,resumo:r.resumo,lida:true,estrela:false};
   });
   E.proxPag=d.proxima_pagina||null;E.total=d.total_estimado||0;E.pilha=[];
   E.carregandoLista=false;desenhar();
  }).catch(function(e){E.mensagens=[];E.erroLista=motivo(e);E.carregandoLista=false;desenhar();});
 }
 function abrirRascunho(id){
  ex({acao:'rascunho_ler',rascunhoId:id}).then(function(d){
   E.rascunhoId=d.id;
   E.modal={tipo:'escrever',titulo:'Rascunho',para:d.para,assunto:d.assunto,texto:d.corpo_texto,cccco:!!(d.cc||d.cco)};
   desenhar();
  }).catch(function(e){avisar(motivo(e));});
 }

 /* ================= DESENHO ================= */
 function btnIc(icone,titulo,acao,extra){
  return '<button class="em-btn-ic'+(extra?' '+extra:'')+'" title="'+esc2(titulo)+'" data-a="'+acao+'">'+ic(icone)+'</button>';
 }
 function linhaPasta(p,rec){
  var on=E.pastaAtiva===p.id&&!E.busca;
  return '<button class="em-pasta'+(on?' on':'')+(rec?' rec':'')+'" data-a="pasta" data-p="'+esc2(p.id)+'">'+
   '<span class="em-pl">'+ic(ICONE_PASTA[p.id]||I.tag)+'<span class="em-pn">'+esc2(p.nome)+'</span></span>'+
   (p.nao_lidas>0?'<span class="em-pc">'+p.nao_lidas+'</span>':'')+'</button>';
 }

 function desenharTopo(){
  var c=contaAtiva();
  var contas=E.menuContas?('<div class="em-pop em-pop-contas" data-stop="1">'+
    '<div class="em-contas-cx">'+E.contas.map(function(x,i){
      return '<div class="em-conta-l">'+
       '<button class="em-conta-b" data-a="trocar-conta" data-id="'+x.id+'">'+
        '<span class="em-conta-av" style="background:'+CORES[i%CORES.length]+'">'+esc2((x.rotulo||'?').charAt(0).toUpperCase())+'</span>'+
        '<span style="min-width:0"><span class="em-conta-nm">'+esc2(x.rotulo)+'</span><span class="em-conta-em">'+esc2(x.email_conectado)+'</span></span>'+
        (c&&c.id===x.id?'<span style="margin-left:auto;color:var(--laranja)">'+ic(I.check)+'</span>':'')+
       '</button>'+
      '</div>';}).join('')+
    '</div>'+
   '</div>'):'';

  return '<div class="em-topo">'+
   '<div class="em-marca">'+
    btnIc(I.menu,'Menu','lateral')+
    '<span class="em-logo-txt">E-mail</span>'+
   '</div>'+
   '<form class="em-busca" data-a="form-busca">'+
    '<button class="em-btn-ic" type="submit" title="Pesquisar">'+ic(I.busca)+'</button>'+
    '<input id="emBusca" placeholder="Pesquisar e-mail" value="'+esc2(E.busca)+'">'+
    (E.busca?'<button class="em-btn-ic" type="button" title="Limpar busca" data-a="limpar-busca">'+ic(I.x)+'</button>':'')+
   '</form>'+
   '<div class="em-canto">'+
    (c?'<span style="position:relative">'+
     '<button class="em-conta-chip" title="'+esc2(c.email_conectado)+'" data-a="menu-contas">'+
      '<span class="em-chip-g">'+esc2(c.email_conectado)+'</span>'+
      '<span class="em-avatar" style="background:'+cor(c.id)+'">'+esc2((c.rotulo||'?').charAt(0).toUpperCase())+'</span>'+
     '</button>'+
     contas+
    '</span>':'')+
   '</div>'+
  '</div>';
 }

 function desenharLateral(){
  if(!E.lateral)return '';
  if(E.trilho==='meet')return desenharPainelMeet();
  if(E.trilho==='agenda')return desenharPainelAgenda();
  return '<div class="em-lateral">'+
   '<button class="em-escrever" data-a="escrever">'+ic(I.lapis)+' Escrever</button>'+
   listaPastas().map(function(p){return linhaPasta(p);}).join('')+
   '<button class="em-pasta" data-a="cat">'+'<span class="em-pl">'+ic(E.catAberto?I.baixo:I.dirp)+'<span class="em-pn">Categorias</span></span></button>'+
   (E.catAberto?listaCategorias().map(function(p){return linhaPasta(p,true);}).join(''):'')+
   '<button class="em-pasta'+(E.maisAberto?' on':'')+'" data-a="mais">'+'<span class="em-pl">'+ic(E.maisAberto?I.cima:I.baixo)+'<span class="em-pn">'+(E.maisAberto?'Menos':'Mais')+'</span></span></button>'+
   (E.maisAberto?(listaMais().map(function(p){return linhaPasta(p);}).join('')+
     '<button class="em-pasta" data-a="ger-marc"><span class="em-pl">'+ic(I.config)+'<span class="em-pn">Gerenciar marcadores</span></span></button>'+
     '<button class="em-pasta" data-a="novo-marc"><span class="em-pl">'+ic(I.mais)+'<span class="em-pn">Criar novo marcador</span></span></button>'):'')+
   '<div class="em-marc-cab"><span>Marcadores</span><button class="em-btn-ic" title="Criar novo marcador" data-a="novo-marc">'+ic(I.mais)+'</button></div>'+
   E.marcadores.map(function(m){return linhaPasta(m);}).join('')+
  '</div>';
 }

 function desenharPainelMeet(){
  return '<div class="em-lateral">'+
   '<button class="em-escrever" data-a="nova-reuniao">'+ic(I.video)+' Nova reunião</button>'+
   '<div style="display:flex;align-items:center;gap:8px;padding:0 4px 10px">'+
    '<input id="emCodigo" class="em-campo" placeholder="Inserir um código">'+
    '<button class="em-lnk" data-a="entrar-codigo">Entrar</button>'+
   '</div>'+
   '<div class="em-marc-cab"><span>Salas criadas pelo sistema</span><button class="em-btn-ic" title="Atualizar" data-a="rec-salas">'+ic(I.atualizar)+'</button></div>'+
   '<div style="padding:0 4px">'+E.salas.map(function(s){
     return '<div class="em-sala">'+
      '<div style="display:flex;align-items:center;justify-content:space-between;gap:8px">'+
       '<span style="font-size:13px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">'+esc2(s.codigo||'Sala do Meet')+'</span>'+
       (s.ativa===true?'<span class="em-aovivo"><i></i>AO VIVO</span>':'')+
      '</div>'+
      '<div style="margin-top:6px">'+
       '<button class="em-entrar" data-a="entrar-sala" data-u="'+esc2(s.link)+'">'+ic(I.video)+' Entrar</button>'+
       (s.ativa===true?'<button class="em-encerrar" data-a="encerrar-sala" data-id="'+s.id+'">Encerrar</button>':'')+
      '</div>'+
     '</div>';}).join('')+'</div>'+
  '</div>';
 }

 function desenharPainelAgenda(){
  var mapa=eventosPorDia();var doDia=mapa[E.agDia]||[];
  var d=new Date(E.agDia+'T12:00:00');
  return '<div class="em-lateral" style="width:300px">'+
   '<div style="display:flex;align-items:center;justify-content:space-between;padding:6px 6px 10px">'+
    '<span style="font-size:15px;font-weight:600">'+esc2(d.toLocaleDateString('pt-BR',{weekday:'long',day:'numeric',month:'long'}))+'</span>'+
    '<button class="em-btn-ic" title="Atualizar" data-a="rec-agenda">'+ic(I.atualizar)+'</button>'+
   '</div>'+
   '<button class="em-escrever" data-a="novo-evento">'+ic(I.mais)+' Criar</button>'+
   (doDia.length?doDia.map(function(ev){
     return '<button class="em-ev" data-a="ver-evento" data-id="'+esc2(ev.contaId+'|'+ev.id)+'" style="border-left-color:'+cor(ev.contaId)+'">'+
      '<span class="em-ev-t">'+esc2(ev.titulo)+'</span>'+
      '<span class="em-ev-h">'+(ev.dia_todo?'dia todo':esc2(new Date(ev.inicio).toLocaleTimeString('pt-BR',{hour:'2-digit',minute:'2-digit'})))+
       ' &middot; '+esc2(ev.rotulo)+(ev.link_meet?' &middot; Meet':'')+'</span>'+
     '</button>';}).join(''):'')+
   '<div class="em-marc-cab"><span>Agendas</span></div>'+
   '<div style="padding:0 6px">'+E.contas.map(function(c){
     var cf=cfgDe(c.id);
     return '<div class="em-toggle">'+
      '<button data-a="cfg-mostrar" data-id="'+c.id+'" title="Mostrar esta agenda" style="display:flex;align-items:center;gap:8px;flex:1;text-align:left">'+
       '<span class="em-pt" style="background:'+(cf.mostrar?cor(c.id):'var(--bordaF)')+'"></span>'+
       '<span style="flex:1;min-width:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">'+esc2(c.rotulo)+'</span>'+
      '</button>'+
      '<button data-a="cfg-conflito" data-id="'+c.id+'" title="Avisar conflito de horário" style="color:'+(cf.avisar_conflito?'var(--vermelho)':'var(--nevoa)')+'">'+ic(I.alerta)+'</button>'+
     '</div>';}).join('')+'</div>'+
  '</div>';
 }

 function linhaConversa(cv){
  return '<div class="em-linha'+(cv.lida?' lida':'')+'" data-a="abrir-conversa" data-id="'+esc2(cv.id)+'">'+
   '<button class="em-estrela'+(cv.estrela?' on':'')+'" title="'+(cv.estrela?'Tirar estrela':'Marcar com estrela')+'" data-a="conv-estrela" data-id="'+esc2(cv.id)+'" data-v="'+(cv.estrela?'0':'1')+'">'+ic(I.estrela,!!cv.estrela)+'</button>'+
   '<span class="em-de">'+esc2(cv.remetentes.map(nomeDe).join(', '))+(cv.mensagens>1?' <b style="font-weight:400;color:var(--apagado)">'+cv.mensagens+'</b>':'')+'</span>'+
   '<span class="em-as"><b>'+esc2(cv.assunto)+'</b><i> – '+esc2(cv.resumo)+'</i></span>'+
   '<span class="em-dt">'+esc2(dataCurta(cv.data))+'</span>'+
   '<span class="em-acoes">'+
    '<button title="Arquivar" data-a="conv-acao" data-id="'+esc2(cv.id)+'" data-t="arquivar">'+ic(I.arquivo)+'</button>'+
    '<button title="Excluir (vai pra lixeira)" data-a="conv-acao" data-id="'+esc2(cv.id)+'" data-t="lixeira">'+ic(I.lixo)+'</button>'+
    '<button title="'+(cv.lida?'Marcar como não lida':'Marcar como lida')+'" data-a="conv-acao" data-id="'+esc2(cv.id)+'" data-t="'+(cv.lida?'nao_lida':'lida')+'">'+ic(cv.lida?I.mail:I.aberto)+'</button>'+
   '</span>'+
  '</div>';
 }

 function desenharConversaAberta(){
  var cv=E.convAberta;
  return '<div class="em-leitura">'+
   '<div class="em-le-cab">'+btnIc(I.voltar,'Voltar','fechar-conversa')+'<span class="em-le-as">'+esc2(cv.assunto)+'</span>'+
    '<span style="font-size:12px;color:var(--apagado);flex:none">'+cv.mensagens.length+' mensagem'+(cv.mensagens.length>1?'s':'')+'</span></div>'+
   '<div style="flex:1;min-height:0;overflow-y:auto;padding:0 8px 8px">'+
    cv.mensagens.map(function(m,i){
     var ultima=i===cv.mensagens.length-1;
     return '<div style="border:1px solid var(--em-fio);border-radius:10px;margin-top:8px;overflow:hidden">'+
      '<div class="em-le-de" style="padding:10px 14px">'+
       '<div style="display:flex;align-items:center;gap:10px;min-width:0">'+
        '<span class="em-le-av" style="width:32px;height:32px;font-size:13px">'+esc2(nomeDe(m.de).charAt(0).toUpperCase()||'?')+'</span>'+
        '<span style="min-width:0"><span style="display:block;font-size:12.5px;font-weight:600">'+esc2(nomeDe(m.de))+'</span>'+
         '<span style="display:block;font-size:11px;color:var(--apagado)">para '+esc2(m.para||'mim')+'</span></span>'+
       '</div>'+
       '<span style="font-size:11px;color:var(--apagado);flex:none">'+esc2(dataLonga(m.data))+'</span>'+
      '</div>'+
      ((m.anexos&&m.anexos.length)?'<div class="em-le-anexos" style="padding:0 14px 8px">'+m.anexos.map(function(a){
        return '<button class="em-anexo" title="Baixar anexo" data-a="baixar" data-id="'+esc2(a.id)+'" data-msg="'+esc2(m.id)+'" data-n="'+esc2(a.nome)+'" data-m="'+esc2(a.mime)+'">'+ic(I.clip)+esc2(a.nome)+'</button>';}).join('')+'</div>':'')+
      '<div style="padding:0 14px 12px;font-size:13.5px;white-space:pre-wrap;word-break:break-word;max-height:'+(ultima?'none':'220px')+';overflow:hidden">'+
       esc2((m.corpo_texto||'').slice(0,ultima?100000:1200))+'</div>'+
     '</div>';}).join('')+
   '</div>'+
   '<div class="em-le-pe">'+
    '<button data-a="responder-conversa">'+ic(I.resp)+' Responder</button>'+
    '<button data-a="encaminhar-conversa">'+ic(I.enc)+' Encaminhar</button>'+
   '</div>'+
  '</div>';
 }

 function desenharLista(){
  var c=contaAtiva();
  var itens=E.porConversa?E.conversas:E.mensagens;
  var ini=itens.length?E.pilha.length*(E.porConversa?25:50)+1:0;
  var fim=E.pilha.length*(E.porConversa?25:50)+itens.length;
  return '<div class="em-barra">'+
    '<div class="em-barra-l">'+
     '<button class="em-btn-ic'+(E.carregandoLista?' em-spin':'')+'" title="Atualizar" data-a="recarregar">'+ic(I.atualizar)+'</button>'+
     '<button class="em-btn-ic'+(E.porConversa?' on':'')+'" title="'+(E.porConversa?'Ver mensagem por mensagem':'Agrupar por conversa')+'" data-a="alternar-visao" style="'+(E.porConversa?'background:var(--em-sel);color:var(--laranjaTx)':'')+'">'+ic(I.forum)+'</button>'+
     '<span style="margin-left:4px">'+esc2(c?c.email_conectado:'')+'</span>'+
    '</div>'+
    '<div class="em-barra-r">'+
     (fim>0?'<span>'+ini+'-'+fim+' de '+Math.max(E.total,fim)+'</span>':'')+
     '<button class="em-btn-ic" title="Pagina anterior" data-a="pag-ant"'+(E.pilha.length?'':' disabled style="opacity:.3"')+'>'+ic(I.esq)+'</button>'+
     '<button class="em-btn-ic" title="Proxima pagina" data-a="pag-prox"'+(E.proxPag?'':' disabled style="opacity:.3"')+'>'+ic(I.dir)+'</button>'+
    '</div>'+
   '</div>'+
   '<div class="em-lista">'+
    (E.carregandoLista?'<div class="em-carregando">'+ic(I.atualizar)+'</div>':
     E.erroLista?'<div class="em-erro">'+esc2(E.erroLista)+'</div>':
     E.porConversa?(!E.conversas.length?'<div class="em-vazio">'+ic(I.inbox)+'</div>':E.conversas.map(linhaConversa).join('')):
     !E.mensagens.length?'<div class="em-vazio">'+ic(I.inbox)+'</div>':
     E.mensagens.map(function(m){
      var acoes;
      if(E.pastaAtiva==='TRASH')acoes=[[I.inbox,'Restaurar da lixeira','restaurar']];
      else if(E.pastaAtiva==='SPAM')acoes=[[I.inbox,'Não é spam','nao-spam'],[I.lixo,'Excluir (vai pra lixeira)','lixeira']];
      else acoes=[[I.arquivo,'Arquivar','arquivar'],[I.lixo,'Excluir (vai pra lixeira)','lixeira'],
        [m.lida?I.mail:I.aberto,m.lida?'Marcar como não lida':'Marcar como lida','lida']];
      return '<div class="em-linha'+(m.lida?' lida':'')+'" data-a="abrir-msg" data-id="'+esc2(m.id)+'">'+
       '<button class="em-estrela'+(m.estrela?' on':'')+'" title="'+(m.estrela?'Tirar estrela':'Marcar com estrela')+'" data-a="estrela" data-id="'+esc2(m.id)+'" data-v="'+(m.estrela?'0':'1')+'">'+ic(I.estrela,!!m.estrela)+'</button>'+
       '<span class="em-de">'+esc2(nomeDe(m.de))+'</span>'+
       '<span class="em-as"><b>'+esc2(m.assunto)+'</b><i> – '+esc2(m.resumo)+'</i></span>'+
       '<span class="em-dt">'+esc2(dataCurta(m.data))+'</span>'+
       '<span class="em-acoes">'+acoes.map(function(a){
         return '<button title="'+esc2(a[1])+'" data-a="'+a[2]+'" data-id="'+esc2(m.id)+'" data-l="'+(m.lida?'1':'0')+'">'+ic(a[0])+'</button>';}).join('')+'</span>'+
      '</div>';}).join(''))+
   '</div>';
 }

 function desenharLeitura(){
  var m=E.msgAberta;
  var html=m.corpo_html?('<base target="_blank">'+m.corpo_html):null;
  return '<div class="em-leitura">'+
   '<div class="em-le-cab">'+btnIc(I.voltar,'Voltar','fechar-msg')+'<span class="em-le-as">'+esc2(m.assunto)+'</span>'+
    '<span style="margin-left:auto;display:flex;align-items:center;gap:2px;flex:none;position:relative">'+
     btnIc(I.marcador,'Aplicar marcador','menu-marcar')+
     btnIc(I.arquivo,'Arquivar','arquivar-aberta')+
     btnIc(I.lixo,'Excluir (vai pra lixeira)','lixeira-aberta')+
     btnIc(I.spam,'Marcar como spam','spam-aberta')+
     (E.menuMarcar?('<div class="em-menu-marc" data-stop="1"><div class="tit">Marcadores</div>'+
       (E.marcadores.length?E.marcadores.map(function(x){
         var temIt=(m.rotulos||[]).indexOf(x.id)>=0;
         return '<button class="em-marc-item" data-a="aplicar-marcador" data-id="'+esc2(x.id)+'" data-v="'+(temIt?'0':'1')+'">'+
          '<span class="em-marc-cx'+(temIt?' on':'')+'">'+(temIt?ic(I.check):'')+'</span>'+esc2(x.nome)+'</button>';}).join(''):'')+
       '<button class="em-marc-item" data-a="novo-marc" style="color:var(--laranja)">'+ic(I.mais)+' Criar novo marcador</button>'+
      '</div>'):'')+
    '</span>'+
   '</div>'+
   '<div class="em-le-de">'+
    '<div style="display:flex;align-items:center;gap:12px;min-width:0">'+
     '<span class="em-le-av">'+esc2(nomeDe(m.de).charAt(0).toUpperCase()||'?')+'</span>'+
     '<span style="min-width:0"><span style="display:block;font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">'+esc2(m.de)+'</span>'+
      '<span style="display:block;font-size:11.5px;color:var(--apagado)">para '+esc2(m.para||'mim')+'</span></span>'+
     '<button class="em-btn-ic" title="Adicionar remetente aos contatos" data-a="add-contato">'+ic(I.addu)+'</button>'+
    '</div>'+
    '<span style="font-size:11.5px;color:var(--apagado);flex:none">'+esc2(dataLonga(m.data))+'</span>'+
   '</div>'+
   ((m.anexos&&m.anexos.length)?'<div class="em-le-anexos">'+m.anexos.map(function(a){
     return '<button class="em-anexo" title="Baixar anexo" data-a="baixar" data-id="'+esc2(a.id)+'" data-n="'+esc2(a.nome)+'" data-m="'+esc2(a.mime)+'">'+ic(I.down)+ic(I.clip)+esc2(a.nome)+(a.tamanho?' ('+tamanho(a.tamanho)+')':'')+'</button>';}).join('')+'</div>':'')+
   '<div class="em-le-corpo">'+(html?'<iframe id="emCorpo" title="Conteúdo do e-mail" sandbox="allow-popups"></iframe>':'<pre>'+esc2(m.corpo_texto||'')+'</pre>')+'</div>'+
   '<div class="em-le-pe">'+
    '<button data-a="responder">'+ic(I.resp)+' Responder</button>'+
    '<button data-a="encaminhar">'+ic(I.enc)+' Encaminhar</button>'+
   '</div>'+
  '</div>';
 }

 function desenharAgendaMensal(){
  var mapa=eventosPorDia();var conf=diasEmConflito();
  var d=new Date(E.agMes+'-01T12:00:00');
  var titulo=d.toLocaleDateString('pt-BR',{month:'long',year:'numeric'});
  titulo=titulo.charAt(0).toUpperCase()+titulo.slice(1);
  var hoje=dLocal(new Date());
  return '<div class="em-ag">'+
   '<div class="em-ag-topo">'+
    '<button class="em-escrever" style="margin:0" data-a="novo-evento">'+ic(I.mais)+' Criar</button>'+
    '<button class="em-ag-hoje" data-a="ag-hoje">Hoje</button>'+
    btnIc(I.esq,'Mês anterior','ag-ant')+btnIc(I.dir,'Próximo mês','ag-prox')+
    '<span class="em-ag-mes">'+esc2(titulo)+'</span>'+
    (E.agCarregando?'<span class="em-spin" style="color:var(--apagado)">'+ic(I.atualizar)+'</span>':'')+
   '</div>'+
   '<div class="em-ag-sem">'+['DOM','SEG','TER','QUA','QUI','SEX','SAB'].map(function(x){return '<div>'+x+'</div>';}).join('')+'</div>'+
   '<div class="em-ag-grade">'+E.agGrade.map(function(dia){
     var doMes=dia.slice(0,7)===E.agMes;
     var evs=mapa[dia]||[];var vis=evs.slice(0,3);var resto=evs.length-vis.length;
     return '<div class="em-dia'+(doMes?'':' fora')+(dia===hoje?' hoje':'')+(dia===E.agDia?' sel':'')+'" data-a="dia-criar" data-d="'+dia+'">'+
      '<span class="em-dia-n"><b data-a="dia-sel" data-d="'+dia+'">'+Number(dia.slice(8,10))+'</b>'+
       (conf[dia]?'<span style="color:var(--vermelho)" title="Conflito de horário neste dia">'+ic(I.alerta)+'</span>':'')+'</span>'+
      vis.map(function(ev){
       return '<button class="em-pilula" data-a="ver-evento" data-id="'+esc2(ev.contaId+'|'+ev.id)+'" style="background:'+cor(ev.contaId)+'" title="'+esc2(ev.titulo+' ('+ev.rotulo+')')+'">'+
        (!ev.dia_todo?'<span style="opacity:.9;flex:none">'+esc2(new Date(ev.inicio).toLocaleTimeString('pt-BR',{hour:'2-digit',minute:'2-digit'}))+'</span>':'')+
        '<span style="overflow:hidden;text-overflow:ellipsis">'+esc2(ev.titulo)+'</span></button>';}).join('')+
      (resto>0?'<button class="em-mais-n" data-a="dia-sel" data-d="'+dia+'">mais '+resto+'</button>':'')+
     '</div>';}).join('')+'</div>'+
  '</div>';
 }

 function desenharTarefas(){
  return '<div class="em-painel">'+
   '<div class="em-pa-cab"><span>Tarefas</span><span>'+
    '<button class="em-btn-ic'+(E.tarCarregando?' em-spin':'')+'" title="Atualizar" data-a="rec-tarefas">'+ic(I.atualizar)+'</button>'+
    '<button class="em-btn-ic" title="Fechar" data-a="fechar-painel">'+ic(I.x)+'</button></span></div>'+
   '<div class="em-pa-corpo">'+
    (E.tarListas.length?'<select class="em-campo" style="margin-bottom:8px" data-a="tar-lista">'+E.tarListas.map(function(l){
      return '<option value="'+esc2(l.id)+'"'+(l.id===E.tarListaAtiva?' selected':'')+'>'+esc2(l.titulo)+'</option>';}).join('')+'</select>':'')+
    '<div style="display:flex;gap:6px;margin-bottom:10px">'+
     '<input id="emTarTitulo" class="em-campo" style="border-radius:999px" placeholder="Adicionar uma tarefa">'+
     '<input id="emTarData" type="date" class="em-campo" style="width:40px;padding:8px 4px" title="Data (opcional)">'+
     '<button class="em-btn-ic" style="background:var(--laranja);color:#fff" title="Adicionar" data-a="tar-criar">'+ic(I.mais)+'</button>'+
    '</div>'+
    (E.tarErro?'<div class="em-erro" style="margin:0 0 8px">'+esc2(E.tarErro)+'</div>':'')+
    E.tarefas.map(function(t){
     return '<div class="em-tar'+(t.concluida?' ok':'')+'">'+
      '<button title="'+(t.concluida?'Marcar como pendente':'Marcar como concluída')+'" data-a="tar-ok" data-id="'+esc2(t.id)+'" data-v="'+(t.concluida?'0':'1')+'" style="color:'+(t.concluida?'var(--laranja)':'var(--apagado)')+';flex:none">'+ic(t.concluida?I.checkcirc:I.circ)+'</button>'+
      '<span style="flex:1;min-width:0"><span class="em-tar-t" style="display:block">'+esc2(t.titulo)+'</span>'+
       (t.detalhes?'<span class="em-tar-d" style="display:block">'+esc2(t.detalhes)+'</span>':'')+
       (t.data?'<span class="em-tar-d" style="display:block">'+esc2(dataSoDia(t.data))+'</span>':'')+
      '</span>'+
      '<button class="em-btn-ic" title="Excluir tarefa" data-a="tar-excluir" data-id="'+esc2(t.id)+'">'+ic(I.lixo)+'</button>'+
     '</div>';}).join('')+
   '</div>'+
  '</div>';
 }

 function desenharDireita(){
  return '<div class="em-dir">'+
   '<button class="'+(E.painel==='agenda'?'on':'')+'" title="Agenda" data-a="p-agenda">'+ic(I.cal)+'</button>'+
   '<button class="'+(E.painel==='tarefas'?'on':'')+'" title="Tarefas" data-a="p-tarefas">'+ic(I.sqcheck)+'</button>'+
  '</div>';
 }

 /* ================= MODAIS ================= */
 function desenharModal(){
  var m=E.modal;if(!m)return '';
  if(m.tipo==='escrever'){
   return '<div class="em-modal canto" data-a="fechar-modal"><div class="em-mcx larga" data-stop="1">'+
    '<div class="em-mcab"><span>'+esc2(m.titulo||'Nova mensagem')+'</span><button class="em-btn-ic" data-a="fechar-modal">'+ic(I.x)+'</button></div>'+
    '<div class="em-mcorpo">'+
     '<div class="em-l"><input id="emPara" list="emContatos" placeholder="Para" value="'+esc2(m.para||'')+'">'+
      '<datalist id="emContatos">'+E.contatos.map(function(c){return '<option value="'+esc2(c.email)+'">'+esc2(c.nome)+'</option>';}).join('')+'</datalist>'+
      '<button class="em-btn-ic" title="Salvar endereço nos contatos" data-a="salvar-contato">'+ic(I.addu)+'</button>'+
      '<button style="font-size:12px;color:var(--apagado)" data-a="cccco">Cc/Cco</button></div>'+
     (m.cccco?'<div class="em-l"><input id="emCc" placeholder="Cc"></div><div class="em-l"><input id="emCco" placeholder="Cco"></div>':'')+
     '<div class="em-l"><input id="emAssunto" placeholder="Assunto" value="'+esc2(m.assunto||'')+'"></div>'+
     '<textarea id="emTexto">'+esc2(m.texto||'')+'</textarea>'+
    '</div>'+
    ((E.anexos||[]).length?'<div class="em-anexo-lista">'+E.anexos.map(function(a,i){
      return '<span class="em-anexo-chip">'+ic(I.clip)+'<span title="'+esc2(a.nome)+'">'+esc2(a.nome)+'</span><b>'+tamanho(a.bytes)+'</b>'+
       '<button class="em-btn-ic" style="padding:3px" title="Tirar anexo" data-a="tirar-anexo" data-i="'+i+'">'+ic(I.x)+'</button></span>';}).join('')+'</div>':'')+
    '<div class="em-mpe"><span style="display:flex;align-items:center;gap:8px">'+
      '<button class="em-red-b" data-a="enviar">'+ic(I.enviar)+' Enviar</button>'+
      '<button class="em-btn-ic" title="Anexar arquivo" data-a="anexar">'+ic(I.clip)+'</button>'+
      '<input type="file" id="emArquivo" multiple style="display:none">'+
     '</span>'+
     '<span style="display:flex;align-items:center;gap:10px">'+
      '<span id="emSalvo" style="font-size:11.5px;color:var(--nevoa)"></span>'+
      (E.rascunhoId?'<button class="em-btn-ic" title="Descartar rascunho" data-a="descartar-rascunho">'+ic(I.lixo)+'</button>':'')+
     '</span></div>'+
   '</div></div>';
  }
  if(m.tipo==='evento'){
   var ev=m.evento||{};
   var dia=m.dia||(ev.inicio?String(ev.inicio).slice(0,10):E.agDia);
   var hi=ev.inicio&&!ev.dia_todo?String(ev.inicio).slice(11,16):'09:00';
   var hf=ev.fim&&!ev.dia_todo?String(ev.fim).slice(11,16):'10:00';
   return '<div class="em-modal" data-a="fechar-modal"><div class="em-mcx" data-stop="1">'+
    '<div class="em-mcab"><span>'+(ev.id?'Editar compromisso':'Novo compromisso')+'</span><button class="em-btn-ic" data-a="fechar-modal">'+ic(I.x)+'</button></div>'+
    '<div class="em-form">'+
     '<label>Título<input id="evTitulo" class="em-campo" value="'+esc2(ev.titulo||'')+'"></label>'+
     '<label>Conta<select id="evConta" class="em-campo">'+E.contas.map(function(c){
       return '<option value="'+c.id+'"'+((ev.contaId||E.contaId)===c.id?' selected':'')+'>'+esc2(c.rotulo)+' - '+esc2(c.email_conectado)+'</option>';}).join('')+'</select></label>'+
     '<label>Dia<input id="evDia" type="date" class="em-campo" value="'+esc2(dia)+'"></label>'+
     '<div class="em-chk"><input type="checkbox" id="evDiaTodo"'+(ev.dia_todo?' checked':'')+'><label for="evDiaTodo" style="flex-direction:row">Dia todo</label></div>'+
     '<div class="em-dupla"><label>Início<input id="evHi" type="time" class="em-campo" value="'+hi+'"></label>'+
      '<label>Fim<input id="evHf" type="time" class="em-campo" value="'+hf+'"></label></div>'+
     '<label>Local<input id="evLocal" class="em-campo" value="'+esc2(ev.local||'')+'"></label>'+
     '<label>Descrição<textarea id="evDesc" class="em-campo" style="min-height:70px;resize:vertical">'+esc2(ev.descricao||'')+'</textarea></label>'+
     (ev.id?'':'<div class="em-chk"><input type="checkbox" id="evMeet"><label for="evMeet" style="flex-direction:row">Criar sala do Meet junto</label></div>')+
    '</div>'+
    '<div class="em-mpe"><button class="em-red-b" data-a="salvar-evento" data-id="'+esc2(ev.id||'')+'" data-cal="'+esc2(ev.agenda_id||'')+'">'+ic(I.check)+' Salvar</button>'+
     (ev.id?'<button style="color:var(--vermelho);font-size:13px;font-weight:600" data-a="excluir-evento" data-id="'+esc2(ev.id)+'" data-cal="'+esc2(ev.agenda_id||'')+'" data-c="'+esc2(ev.contaId)+'">Excluir</button>':'')+'</div>'+
   '</div></div>';
  }
  if(m.tipo==='ver-evento'){
   var e2=m.evento;
   return '<div class="em-modal" data-a="fechar-modal"><div class="em-mcx" style="max-width:440px" data-stop="1">'+
    '<div class="em-mcab"><span>Compromisso</span><button class="em-btn-ic" data-a="fechar-modal">'+ic(I.x)+'</button></div>'+
    '<div class="em-form">'+
     '<div style="font-size:16px;font-weight:600">'+esc2(e2.titulo)+'</div>'+
     '<div style="font-size:13px;color:var(--apagado)">'+(e2.dia_todo?'Dia todo &middot; '+esc2(String(e2.inicio).slice(0,10).split('-').reverse().join('/')):
       esc2(dataLonga(e2.inicio)))+'</div>'+
     '<div style="font-size:13px;color:var(--apagado)"><span class="em-pt" style="background:'+cor(e2.contaId)+'"></span> '+esc2(e2.rotulo)+' &middot; '+esc2(e2.email)+'</div>'+
     (e2.local?'<div style="font-size:13px">'+esc2(e2.local)+'</div>':'')+
     (e2.descricao?'<div style="font-size:13px;white-space:pre-wrap">'+esc2(e2.descricao)+'</div>':'')+
    '</div>'+
    '<div class="em-mpe">'+
     (e2.link_meet?'<button class="em-red-b" data-a="abrir-meet" data-u="'+esc2(e2.link_meet)+'">'+ic(I.video)+' Entrar no Meet</button>':'<span></span>')+
     '<span>'+(e2.pode_editar!==false?'<button style="font-size:13px;font-weight:600;color:var(--laranja)" data-a="editar-evento">Editar</button>':'')+'</span>'+
    '</div>'+
   '</div></div>';
  }
  if(m.tipo==='marcador'){
   return '<div class="em-modal" data-a="fechar-modal"><div class="em-mcx" style="max-width:420px" data-stop="1">'+
    '<div class="em-mcab"><span>Novo marcador</span><button class="em-btn-ic" data-a="fechar-modal">'+ic(I.x)+'</button></div>'+
    '<div class="em-form"><label>Nome do marcador<input id="emMarcNome" class="em-campo" placeholder="Ex.: Clientes"></label></div>'+
    '<div class="em-mpe"><button class="em-red-b" data-a="criar-marcador">'+ic(I.check)+' Criar</button></div>'+
   '</div></div>';
  }
  if(m.tipo==='ger-marcadores'){
   return '<div class="em-modal" data-a="fechar-modal"><div class="em-mcx" style="max-width:460px" data-stop="1">'+
    '<div class="em-mcab"><span>Gerenciar marcadores</span><button class="em-btn-ic" data-a="fechar-modal">'+ic(I.x)+'</button></div>'+
    '<div class="em-form"><div class="em-lista-simples">'+
     (E.marcadores.length?E.marcadores.map(function(x){
       return '<div class="em-item"><span>'+esc2(x.nome)+'</span>'+
        '<button class="em-btn-ic" title="Renomear" data-a="renomear-marc" data-id="'+esc2(x.id)+'" data-n="'+esc2(x.nome)+'">'+ic(I.lapis)+'</button>'+
        '<button class="em-btn-ic" title="Excluir" data-a="excluir-marc" data-id="'+esc2(x.id)+'" style="color:var(--vermelho)">'+ic(I.lixo)+'</button></div>';}).join(''):'')+
    '</div></div>'+
   '</div></div>';
  }
  return '';
 }

 /* ================= RENDER RAIZ ================= */
 function desenhar(){
  if(!E.raiz)return;
  var c=contaAtiva();
  var meio;
  if(E.carregandoContas)meio='<div class="em-carregando">'+ic(I.atualizar)+'</div>';
  else{
   var area;
   if(E.trilho==='agenda')area=desenharAgendaMensal();
   else if(E.trilho==='mail')area='<div class="em-area">'+(!c?('<div class="em-vazio">'+ic(I.inbox)+'</div>'):E.carregandoMsg?'<div class="em-carregando">'+ic(I.atualizar)+'</div>':E.convAberta?desenharConversaAberta():E.msgAberta?desenharLeitura():desenharLista())+'</div>';
   else area='<div class="em-area"><div class="em-vazio">'+ic(I.video)+'</div></div>';
   var naoLidas=0;E.pastas.forEach(function(p){if(p.id==='INBOX')naoLidas=p.nao_lidas||0;});
   meio='<div class="em-corpo">'+
    '<div class="em-trilho">'+[['mail','E-mail',I.mail,naoLidas],['agenda','Agenda',I.cal,0],['meet','Meet',I.video,0]].map(function(t){
      return '<button class="em-tr-b'+(E.trilho===t[0]?' on':'')+'" data-a="trilho" data-t="'+t[0]+'">'+
       '<span class="em-tr-p">'+ic(t[2])+(t[3]>0?'<span class="em-badge">'+t[3]+'</span>':'')+'</span>'+
       '<span class="em-tr-t">'+t[1]+'</span></button>';}).join('')+'</div>'+
    desenharLateral()+area+
    (E.painel==='tarefas'?desenharTarefas():'')+
    desenharDireita()+
   '</div>';
  }
  E.raiz.innerHTML=desenharTopo()+meio+desenharModal();
  var fr=document.getElementById('emCorpo');
  if(fr&&E.msgAberta&&E.msgAberta.corpo_html){try{fr.srcdoc='<base target="_blank">'+E.msgAberta.corpo_html;}catch(e){}}
 }

 /* ================= ACOES DA TELA ================= */
 function val(id){var e=document.getElementById(id);return e?e.value:'';}
 function corpoEmTexto(m){
  if(m.corpo_texto)return m.corpo_texto;
  if(m.corpo_html)return String(m.corpo_html).replace(/<style[\s\S]*?<\/style>/gi,'').replace(/<script[\s\S]*?<\/script>/gi,'')
   .replace(/<br\s*\/?>/gi,'\n').replace(/<\/(p|div|tr|li|h[1-6])>/gi,'\n').replace(/<[^>]+>/g,'')
   .replace(/&nbsp;/g,' ').replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/\n{3,}/g,'\n\n').trim();
  return '';
 }
 function abrirEscrever(d){
  if(!d||!d.manterRascunho){E.rascunhoId=null;E.anexos=[];}
  E.modal=Object.assign({tipo:'escrever'},d||{});desenhar();
  fn('gmail-contatos',{contaId:E.contaId}).then(function(r){E.contatos=r.contatos||[];if(E.modal&&E.modal.tipo==='escrever')desenhar();}).catch(function(){});
 }
 function baixarBase64(nome,mime,b64url){
  try{
   var b64=String(b64url).replace(/-/g,'+').replace(/_/g,'/');
   var bin=atob(b64);var bytes=new Uint8Array(bin.length);
   for(var i=0;i<bin.length;i++)bytes[i]=bin.charCodeAt(i);
   var url=URL.createObjectURL(new Blob([bytes],{type:mime||'application/octet-stream'}));
   var a=document.createElement('a');a.href=url;a.download=nome||'anexo';a.click();
   setTimeout(function(){URL.revokeObjectURL(url);},10000);
  }catch(e){avisar('Não foi possível baixar o anexo.');}
 }
 function achaEvento(chave){
  var p=String(chave).split('|');
  for(var i=0;i<E.agEventos.length;i++){var ev=E.agEventos[i];if(ev.contaId===p[0]&&String(ev.id)===p[1])return ev;}
  return null;
 }

 function tratar(ev){
  var alvo=ev.target.closest?ev.target.closest('[data-a]'):null;
  if(!alvo){ if(E.menuContas||E.menuMarcar){E.menuContas=false;E.menuMarcar=false;desenhar();} return; }
  var a=alvo.getAttribute('data-a');
  var id=alvo.getAttribute('data-id');
  if(a==='nada')return;
  if(a!=='menu-contas'&&!alvo.closest('[data-stop]')){ if(E.menuContas){E.menuContas=false;} }
  if(a!=='menu-marcar'&&a!=='aplicar-marcador'&&E.menuMarcar)E.menuMarcar=false;

  switch(a){
   case 'lateral': E.lateral=!E.lateral;desenhar();break;
   case 'menu-contas': E.menuContas=!E.menuContas;desenhar();break;
   case 'alternar-visao':
    E.porConversa=!E.porConversa;E.msgAberta=null;E.convAberta=null;
    if(E.porConversa)carregarConversas({pilha:[]});else carregarLista({pilha:[]});
    break;
   case 'abrir-conversa': if(!ev.target.closest('[data-a="conv-estrela"]')&&!ev.target.closest('.em-acoes'))abrirConversa(id);break;
   case 'fechar-conversa': E.convAberta=null;desenhar();break;
   case 'conv-estrela': {ev.stopPropagation();var lig=alvo.getAttribute('data-v')==='1';
    E.conversas.forEach(function(x){if(x.id===id)x.estrela=lig;});desenhar();
    acaoConversa(id,lig?'estrela':'sem_estrela');break;}
   case 'conv-acao': {ev.stopPropagation();var t2=alvo.getAttribute('data-t');
    acaoConversa(id,t2,function(){
     if(t2==='arquivar'||t2==='lixeira')E.conversas=E.conversas.filter(function(x){return x.id!==id;});
     else if(t2==='lida'||t2==='nao_lida')E.conversas.forEach(function(x){if(x.id===id)x.lida=(t2==='lida');});
    });break;}
   case 'responder-conversa': {var cv=E.convAberta;if(!cv||!cv.mensagens.length)break;
    var ult=cv.mensagens[cv.mensagens.length-1];
    abrirEscrever({titulo:'Responder',para:emailDe(ult.de),assunto:ult.assunto,
     texto:'\n\nEm '+dataLonga(ult.data)+', '+nomeDe(ult.de)+' escreveu:\n'+(ult.corpo_texto||'').split('\n').map(function(l){return '> '+l;}).join('\n'),
     responderA:ult.id});break;}
   case 'encaminhar-conversa': {var cv2=E.convAberta;if(!cv2||!cv2.mensagens.length)break;
    var u2=cv2.mensagens[cv2.mensagens.length-1];
    abrirEscrever({titulo:'Encaminhar',assunto:'Fwd: '+u2.assunto,
     texto:'\n\n---------- Mensagem encaminhada ----------\nDe: '+u2.de+'\nData: '+dataLonga(u2.data)+'\nAssunto: '+u2.assunto+'\n\n'+(u2.corpo_texto||'')});break;}

   case 'descartar-rascunho':
    if(!E.rascunhoId){E.modal=null;desenhar();break;}
    ex({acao:'rascunho_excluir',rascunhoId:E.rascunhoId}).then(function(){
     E.rascunhoId=null;E.modal=null;desenhar();
     if(E.pastaAtiva==='DRAFT')carregarRascunhos();
    }).catch(function(e){avisar(motivo(e));});
    break;

   case 'trocar-conta': E.contaId=id;E.menuContas=false;E.msgAberta=null;E.convAberta=null;E.pastaAtiva='INBOX';E.busca='';
    
    desenhar();carregarPastas();carregarLista({pasta:'INBOX',busca:'',pilha:[]});
    if(E.painel==='tarefas')carregarListasTarefas();
    if(E.trilho==='meet')carregarSalas();
    break;
   case 'trilho': E.trilho=alvo.getAttribute('data-t');E.msgAberta=null;desenhar();
    if(E.trilho==='agenda'){carregarCfgAgenda().then(carregarAgenda);}
    if(E.trilho==='meet')carregarSalas();
    break;
   case 'pasta': trocarPasta(alvo.getAttribute('data-p'));break;
   case 'cat': E.catAberto=!E.catAberto;desenhar();break;
   case 'mais': E.maisAberto=!E.maisAberto;desenhar();break;
   case 'recarregar': recarregarAtual();break;
   case 'pag-prox': proxPagina();break;
   case 'pag-ant': pagAnterior();break;
   case 'limpar-busca': buscar('');break;
   case 'abrir-msg': if(!ev.target.closest('[data-a="estrela"]')&&!ev.target.closest('.em-acoes')){
    var ehRasc=false;E.mensagens.forEach(function(m){if(m.id===id&&m.rascunho)ehRasc=true;});
    if(ehRasc)abrirRascunho(id);else abrirMensagem(id);
   }break;
   case 'fechar-msg': E.msgAberta=null;E.menuMarcar=false;desenhar();break;
   case 'menu-marcar': E.menuMarcar=!E.menuMarcar;desenhar();break;
   case 'aplicar-marcador': {
    var msg=E.msgAberta;if(!msg)break;
    var por=alvo.getAttribute('data-v')==='1';
    cx({acao:'aplicar_marcador',mensagemId:msg.id,marcadorId:id,aplicar:por}).then(function(){
     msg.rotulos=msg.rotulos||[];
     if(por){if(msg.rotulos.indexOf(id)<0)msg.rotulos.push(id);}
     else msg.rotulos=msg.rotulos.filter(function(x){return x!==id;});
     carregarPastas();desenhar();
    }).catch(function(e){avisar(motivo(e));});
    break;}
   case 'arquivar-aberta': {var mA=E.msgAberta;if(!mA)break;
    acaoMsg({acao:'arquivar',mensagemId:mA.id},function(){tiraDaLista(mA.id);E.msgAberta=null;});break;}
   case 'lixeira-aberta': {var mL=E.msgAberta;if(!mL)break;
    acaoMsg({acao:'lixeira',mensagemId:mL.id},function(){tiraDaLista(mL.id);E.msgAberta=null;});break;}
   case 'spam-aberta': {var mS=E.msgAberta;if(!mS)break;
    acaoMsg({acao:'spam',mensagemId:mS.id,marcar:true},function(){tiraDaLista(mS.id);E.msgAberta=null;});break;}
   case 'estrela': ev.stopPropagation();alternarEstrela(id,alvo.getAttribute('data-v')==='1');break;
   case 'arquivar': ev.stopPropagation();acaoMsg({acao:'arquivar',mensagemId:id},function(){if(E.pastaAtiva==='INBOX')tiraDaLista(id);});break;
   case 'lixeira': ev.stopPropagation();acaoMsg({acao:'lixeira',mensagemId:id},function(){tiraDaLista(id);});break;
   case 'restaurar': ev.stopPropagation();acaoMsg({acao:'restaurar',mensagemId:id},function(){tiraDaLista(id);});break;
   case 'nao-spam': ev.stopPropagation();acaoMsg({acao:'spam',mensagemId:id,marcar:false},function(){tiraDaLista(id);});break;
   case 'lida': {ev.stopPropagation();var eraLida=alvo.getAttribute('data-l')==='1';
    acaoMsg({acao:'marcar_lida',mensagemId:id,lida:!eraLida},function(){
     E.mensagens.forEach(function(m){if(m.id===id)m.lida=!eraLida;});});break;}

   case 'escrever': abrirEscrever({titulo:'Nova mensagem'});break;
   case 'responder': {var m1=E.msgAberta;if(!m1)break;
    abrirEscrever({titulo:'Responder',para:emailDe(m1.de),
     assunto:/^re:/i.test(m1.assunto)?m1.assunto:'Re: '+m1.assunto,
     texto:'\n\nEm '+dataLonga(m1.data)+', '+nomeDe(m1.de)+' escreveu:\n'+corpoEmTexto(m1).split('\n').map(function(l){return '> '+l;}).join('\n'),
     responderA:m1.id});break;}
   case 'encaminhar': {var m2=E.msgAberta;if(!m2)break;
    abrirEscrever({titulo:'Encaminhar',
     assunto:/^(fwd|enc):/i.test(m2.assunto)?m2.assunto:'Fwd: '+m2.assunto,
     texto:'\n\n---------- Mensagem encaminhada ----------\nDe: '+m2.de+'\nData: '+dataLonga(m2.data)+'\nAssunto: '+m2.assunto+'\nPara: '+(m2.para||'')+'\n\n'+corpoEmTexto(m2),
     avisoAnexos:(m2.anexos||[]).length>0});break;}
   case 'cccco': E.modal.cccco=!E.modal.cccco;desenhar();break;
   case 'enviar': {
    var para=val('emPara');if(!para.trim()){avisar('Falta o destinatário.');break;}
    alvo.setAttribute('disabled','');
    fn('gmail-enviar',{contaId:E.contaId,para:para.trim(),cc:val('emCc')||null,cco:val('emCco')||null,
     assunto:val('emAssunto'),texto:val('emTexto'),responderA:E.modal.responderA||null,
     comAssinatura:true,
     anexos:(E.anexos||[]).map(function(a){return {nome:a.nome,mime:a.mime,dados:a.dados};})})
     .then(function(){
      var rid=E.rascunhoId;
      E.modal=null;E.rascunhoId=null;E.anexos=[];desenhar();carregarPastas();
      if(rid)ex({acao:'rascunho_excluir',rascunhoId:rid}).catch(function(){});
     })
     .catch(function(e){
      var m=String(e&&e.message||e);
      avisar(m==='anexo_grande'?'Os anexos passam de 5 MB.':motivo(e));
      alvo.removeAttribute('disabled');
     });
    break;}
   case 'anexar': {var inp=document.getElementById('emArquivo');if(inp)inp.click();break;}
   case 'tirar-anexo': {var idx=Number(alvo.getAttribute('data-i'));
    E.anexos.splice(idx,1);desenhar();break;}
   case 'salvar-contato': {var em=val('emPara').split(',')[0].trim();if(!em)break;
    fn('gmail-contatos',{contaId:E.contaId,acao:'criar',nome:'',email:em}).catch(function(e){avisar(motivo(e));});break;}
   case 'add-contato': {var m3=E.msgAberta;if(!m3)break;
    fn('gmail-contatos',{contaId:E.contaId,acao:'criar',nome:nomeDe(m3.de),email:emailDe(m3.de)}).catch(function(e){avisar(motivo(e));});break;}
   case 'baixar': {var mid=E.msgAberta&&E.msgAberta.id;if(!mid)break;
    cx({acao:'baixar_anexo',mensagemId:mid,anexoId:id}).then(function(d){
     baixarBase64(alvo.getAttribute('data-n'),alvo.getAttribute('data-m'),d.dados);
    }).catch(function(e){avisar(motivo(e));});break;}

   case 'novo-marc': E.modal={tipo:'marcador'};desenhar();break;
   case 'ger-marc': E.modal={tipo:'ger-marcadores'};desenhar();break;
   case 'criar-marcador': {var nm=val('emMarcNome').trim();if(!nm)break;
    cx({acao:'criar_marcador',nome:nm}).then(function(){E.modal=null;carregarPastas();})
     .catch(function(e){avisar(String(e.message)==='ja_existe'?'Já existe um marcador com esse nome.':motivo(e));});break;}
   case 'renomear-marc': {var novo=window.prompt('Novo nome do marcador:',alvo.getAttribute('data-n'));
    if(!novo||!novo.trim())break;
    cx({acao:'renomear_marcador',marcadorId:id,nome:novo.trim()}).then(function(){carregarPastas();})
     .catch(function(e){avisar(motivo(e));});break;}
   case 'excluir-marc': cx({acao:'excluir_marcador',marcadorId:id}).then(function(){carregarPastas();})
     .catch(function(e){avisar(motivo(e));});break;

   case 'p-agenda': E.painel=E.painel==='agenda'?null:'agenda';
    if(E.painel==='agenda'){E.trilho='agenda';carregarCfgAgenda().then(carregarAgenda);}
    desenhar();break;
   case 'p-tarefas': E.painel=E.painel==='tarefas'?null:'tarefas';desenhar();
    if(E.painel==='tarefas')carregarListasTarefas();break;
   case 'fechar-painel': E.painel=null;desenhar();break;
   case 'rec-tarefas': carregarTarefas(E.tarListaAtiva);break;
   case 'tar-criar': {var tt=val('emTarTitulo').trim();if(!tt)break;
    ag({contaId:E.contaId,acao:'tarefas_criar',listaId:E.tarListaAtiva,titulo:tt,data:val('emTarData')||null})
     .then(function(){carregarTarefas(E.tarListaAtiva);}).catch(function(e){avisar(motivo(e));});break;}
   case 'tar-ok': {var ok=alvo.getAttribute('data-v')==='1';
    E.tarefas.forEach(function(t){if(t.id===id)t.concluida=ok;});desenhar();
    ag({contaId:E.contaId,acao:'tarefas_concluir',listaId:E.tarListaAtiva,tarefaId:id,concluida:ok})
     .catch(function(e){avisar(motivo(e));carregarTarefas(E.tarListaAtiva);});break;}
   case 'tar-excluir': ag({contaId:E.contaId,acao:'tarefas_excluir',listaId:E.tarListaAtiva,tarefaId:id})
     .then(function(){E.tarefas=E.tarefas.filter(function(t){return t.id!==id;});desenhar();})
     .catch(function(e){avisar(motivo(e));});break;

   case 'ag-hoje': {var h=dLocal(new Date());E.agDia=h;E.agMes=h.slice(0,7);carregarAgenda();break;}
   case 'ag-ant': case 'ag-prox': {var d2=new Date(E.agMes+'-01T12:00:00');
    d2.setMonth(d2.getMonth()+(a==='ag-prox'?1:-1));E.agMes=dLocal(d2).slice(0,7);carregarAgenda();break;}
   case 'rec-agenda': carregarAgenda();break;
   case 'dia-sel': ev.stopPropagation();E.agDia=alvo.getAttribute('data-d');
    if(E.agDia.slice(0,7)!==E.agMes){E.agMes=E.agDia.slice(0,7);carregarAgenda();}else desenhar();break;
   case 'dia-criar': E.agDia=alvo.getAttribute('data-d');E.modal={tipo:'evento',dia:E.agDia};desenhar();break;
   case 'novo-evento': E.modal={tipo:'evento',dia:E.agDia};desenhar();break;
   case 'ver-evento': {ev.stopPropagation();var evo=achaEvento(id);if(evo)E.modal={tipo:'ver-evento',evento:evo};desenhar();break;}
   case 'editar-evento': E.modal={tipo:'evento',evento:E.modal.evento};desenhar();break;
   case 'abrir-meet': abrirMeet(alvo.getAttribute('data-u'));break;
   case 'cfg-mostrar': alternarCfg(id,'mostrar');break;
   case 'cfg-conflito': alternarCfg(id,'avisar_conflito');break;
   case 'salvar-evento': {
    var tit=val('evTitulo').trim();if(!tit){avisar('Falta o título.');break;}
    var dt=document.getElementById('evDiaTodo');
    var dados={contaId:val('evConta'),titulo:tit,dia:val('evDia'),diaTodo:!!(dt&&dt.checked),
     horaInicio:val('evHi'),horaFim:val('evHf'),local:val('evLocal'),descricao:val('evDesc')};
    var mt=document.getElementById('evMeet');
    alvo.setAttribute('disabled','');
    var p2;
    if(id)p2=ag(Object.assign({acao:'editar_evento',eventoId:id,calendarioId:alvo.getAttribute('data-cal')||null},dados));
    else p2=ag(Object.assign({acao:'criar_evento',comMeet:!!(mt&&mt.checked)},dados));
    p2.then(function(){E.modal=null;carregarAgenda();}).catch(function(e){avisar(motivo(e));alvo.removeAttribute('disabled');});
    break;}
   case 'excluir-evento':
    ag({acao:'excluir_evento',contaId:alvo.getAttribute('data-c'),eventoId:id,calendarioId:alvo.getAttribute('data-cal')||null})
     .then(function(){E.modal=null;carregarAgenda();}).catch(function(e){avisar(motivo(e));});
    break;

   case 'nova-reuniao':
    ag({acao:'criar_reuniao',contaId:E.contaId}).then(function(d){abrirMeet(d.link);carregarSalas();})
     .catch(function(e){avisar(motivo(e));});
    break;
   case 'entrar-codigo': {var cod=val('emCodigo').trim().replace(/^https?:\/\/meet\.google\.com\//i,'');
    if(cod)abrirMeet('https://meet.google.com/'+cod);break;}
   case 'entrar-sala': abrirMeet(alvo.getAttribute('data-u'));break;
   case 'encerrar-sala': ag({acao:'encerrar_reuniao',salaId:id}).then(carregarSalas).catch(function(e){avisar(motivo(e));});break;
   case 'rec-salas': carregarSalas();break;

   case 'fechar-modal': if(!ev.target.closest('[data-stop]')||alvo.getAttribute('data-a')==='fechar-modal'){E.modal=null;desenhar();}break;
   default: break;
  }
 }

 function tratarSubmit(ev){
  var f=ev.target.closest?ev.target.closest('[data-a="form-busca"]'):null;
  if(!f)return;
  ev.preventDefault();
  buscar(val('emBusca'));
 }
 function tratarDigitacao(ev){
  if(!E.modal||E.modal.tipo!=='escrever')return;
  var t=ev.target;
  if(!t||!t.id)return;
  if(t.id==='emPara'||t.id==='emAssunto'||t.id==='emTexto'||t.id==='emCc'||t.id==='emCco')agendarSalvarRascunho();
 }
 function tratarMudanca(ev){
  var t=ev.target;
  if(t&&t.id==='emArquivo'){
   var arquivos=Array.prototype.slice.call(t.files||[]);
   t.value='';
   arquivos.forEach(function(f){
    var leitor=new FileReader();
    leitor.onload=function(){
     var d=String(leitor.result||'');
     var virgula=d.indexOf(',');
     E.anexos.push({nome:f.name,mime:f.type||'application/octet-stream',bytes:f.size,dados:virgula>=0?d.slice(virgula+1):''});
     desenhar();
    };
    leitor.readAsDataURL(f);
   });
   return;
  }
  var alvo=ev.target.closest?ev.target.closest('[data-a]'):null;
  if(!alvo)return;
  if(alvo.getAttribute('data-a')==='tar-lista'){E.tarListaAtiva=alvo.value;carregarTarefas(alvo.value);}
 }

 /* ================= ABRIR O MODULO ================= */
 window.EMAILS={
  aberto:function(caixa){return !!(E.raiz&&caixa.contains(E.raiz));},
  abrir:function(caixa){
   caixa.innerHTML='<div id="emRoot"></div>';
   E.raiz=document.getElementById('emRoot');
   E.raiz.addEventListener('click',tratar);
   E.raiz.addEventListener('submit',tratarSubmit);
   E.raiz.addEventListener('change',tratarMudanca);
   E.raiz.addEventListener('input',tratarDigitacao);
   var h=dLocal(new Date());
   if(!E.agDia){E.agDia=h;E.agMes=h.slice(0,7);montarGrade();}
   desenhar();
   carregarContas();
  }
 };
})();
