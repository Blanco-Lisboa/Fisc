(function(){
'use strict';
/* base */
const MES=['janeiro','fevereiro','março','abril','maio','junho','julho','agosto','setembro','outubro','novembro','dezembro'];
const DIAS=['Domingo','Segunda','Terça','Quarta','Quinta','Sexta','Sábado'];
const SEM=['DOM','SEG','TER','QUA','QUI','SEX','SÁB'];
const TIPO={alarme:'Alarme',lembrete:'Lembrete',tarefa:'Tarefa',os:'O.S.'};
const TCLS={alarme:'al',lembrete:'le',tarefa:'ta',os:'os'};
const PAL=['#C0392B','#3A5A8C','#1B7A44','#6D4AA0','#B25E09','#FE4901','#0E7490','#52525B'];
const LH=32;
const esc=s=>String(s==null?'':s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const z=n=>String(n).padStart(2,'0');
const iso=d=>d.getFullYear()+'-'+z(d.getMonth()+1)+'-'+z(d.getDate());
const deIso=s=>{const [a,m,d]=String(s).slice(0,10).split('-').map(Number);return new Date(a,m-1,d);};
const somaDias=(d,n)=>new Date(d.getFullYear(),d.getMonth(),d.getDate()+n);
const hhmm=d=>z(d.getHours())+':'+z(d.getMinutes());
const ICO={
 rel:'<svg class="i" viewBox="0 0 24 24"><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2"/></svg>',
 ck:'<svg class="i" viewBox="0 0 24 24"><path d="m5 12 4 4 10-10"/></svg>',
 pin:'<svg class="i" viewBox="0 0 24 24"><path d="M12 17v5M9 3h6l-1 6 4 4H6l4-4Z"/></svg>',
 lixo:'<svg class="i" viewBox="0 0 24 24"><path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/></svg>',
 sino:'<svg class="i" viewBox="0 0 24 24"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10.3 21a1.9 1.9 0 0 0 3.4 0"/></svg>',
 mic:'<svg class="i" viewBox="0 0 24 24"><rect x="9" y="2" width="6" height="12" rx="3"/><path d="M5 10a7 7 0 0 0 14 0M12 17v5"/></svg>',
 env:'<svg class="i" viewBox="0 0 24 24"><path d="M22 2 11 13M22 2l-7 20-4-9-9-4Z"/></svg>',
 cal:'<svg class="i" viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 10h18"/></svg>',
 esq:'<svg class="i" viewBox="0 0 24 24"><path d="m15 18-6-6 6-6"/></svg>',
 dir:'<svg class="i" viewBox="0 0 24 24"><path d="m9 18 6-6-6-6"/></svg>',
 busca:'<svg class="i" viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>',
 clip:'<svg class="i" viewBox="0 0 24 24"><path d="M21.4 11.1 12.2 20.3a6 6 0 0 1-8.5-8.5l9.2-9.2a4 4 0 0 1 5.7 5.7l-9.2 9.2a2 2 0 0 1-2.8-2.8l8.5-8.5"/></svg>',
 pred:'<svg class="i" viewBox="0 0 24 24"><path d="M3 21h18M5 21V7l7-4 7 4v14"/><path d="M9 21v-6h6v6"/></svg>',
 tag:'<svg class="i" viewBox="0 0 24 24"><path d="M20.6 13.4 13.4 20.6a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8Z"/><circle cx="7.5" cy="7.5" r="1.5"/></svg>',
 relA:'<svg class="i" viewBox="0 0 24 24"><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2.5 2M5 3 2 6M19 3l3 3"/></svg>',
 arq:'<svg class="i" viewBox="0 0 24 24"><path d="M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8Z"/><path d="M14 3v5h5"/></svg>',
 baixar:'<svg class="i" viewBox="0 0 24 24"><path d="M12 4v11M7 10l5 5 5-5M5 20h14"/></svg>',
 x:'<svg class="i" viewBox="0 0 24 24"><path d="M18 6 6 18M6 6l12 12"/></svg>'
};

/* estado */
let cfg=null,sb=null,uid=null,host=null,raiz=null;
let D={hoje:new Date(),categorias:[],notas:[],itens:[],dias:new Set()};
let faixa=null,carregando=null,canal=null,recarregaTm=null;
let aba='notas',filtro='',busca='',diaPg=null,virando=false,diaAg=null,mcMes=null;
let empresas={},timers=[],ouvintes=[];
let rascunho={categoria_id:'',empresa_id:'',competencia:''};
let grav=null;

function hojeD(){const h=new Date();return new Date(h.getFullYear(),h.getMonth(),h.getDate());}
function cat(id){return D.categorias.find(c=>c.id===id)||null;}
function cor(id){const c=cat(id);return c?c.cor:'#A1A1AA';}
function nomeCat(id){const c=cat(id);return c?c.nome:'';}
function avisar(){ouvintes.forEach(f=>{try{f();}catch(e){}});}
function toast(t){if(cfg&&cfg.toast)cfg.toast(t);}

/* dados */
async function carregar(de,ate){
 const r=await sb.rpc('room_dados',{p_de:iso(de),p_ate:iso(ate)});
 if(r.error){toast('Não foi possível carregar o ROOM.');return false;}
 const x=r.data||{};D.hoje=x.hoje?deIso(x.hoje):hojeD();D.categorias=x.categorias||[];D.notas=x.notas||[];D.itens=x.itens||[];
 D.dias=new Set((x.dias_com_nota||[]).map(String));faixa={de,ate};
 if(D.notas.some(n=>n.empresa_id&&!empresas[n.empresa_id])&&cfg.clientes){const l=await Promise.resolve(cfg.clientes()).catch(()=>[]);(l||[]).forEach(c=>{empresas[c.id]=c.nome;});}
 return true;
}
function garantir(d){
 const de=new Date(d.getFullYear(),d.getMonth()-1,1),ate=new Date(d.getFullYear(),d.getMonth()+2,0);
 if(faixa&&de>=faixa.de&&ate<=faixa.ate)return Promise.resolve(true);
 const a=faixa?new Date(Math.min(de,faixa.de)):de,b=faixa?new Date(Math.max(ate,faixa.ate)):ate;
 const de2=(b-a)/86400000>380?de:a,ate2=(b-a)/86400000>380?ate:b;
 carregando=carregar(de2,ate2).then(ok=>{carregando=null;return ok;});return carregando;
}
async function recarregar(){if(!faixa)return;await carregar(faixa.de,faixa.ate);agendar();desenhar();avisar();}
function ouvir(){
 if(canal)return;
 const f=()=>{clearTimeout(recarregaTm);recarregaTm=setTimeout(recarregar,250);};
 canal=sb.channel('room-'+uid).on('postgres_changes',{event:'*',schema:'public',table:'room_nota',filter:'usuario_id=eq.'+uid},f)
  .on('postgres_changes',{event:'*',schema:'public',table:'room_item',filter:'usuario_id=eq.'+uid},f)
  .on('postgres_changes',{event:'*',schema:'public',table:'room_categoria',filter:'usuario_id=eq.'+uid},f).subscribe(st=>{if(st==='SUBSCRIBED'&&faixa)f();});
}
const COM_P=new Set(['room_nota_salvar','room_item_salvar','room_categoria_salvar']);
async function rpc(nome,args){const r=await sb.rpc(nome,COM_P.has(nome)?{p:args}:args);if(r.error){toast(msgErro(r.error));return null;}return r.data;}
function msgErro(e){const m=String(e&&e.message||'');if(/hora/.test(m))return 'Lembrete e alarme precisam de hora.';if(/categoria/.test(m))return 'Categoria inválida.';return 'Não foi possível salvar.';}

/* itens */
function quandoDe(i){if(i.adiado_ate)return new Date(i.adiado_ate);if(!i.hora)return null;const d=deIso(i.dia);const [h,m]=String(i.hora).split(':').map(Number);d.setHours(h,m,0,0);return d;}
function itensDia(d){const k=iso(d);return D.itens.filter(i=>String(i.dia)===k);}
function checklistItens(){const h=iso(D.hoje);return D.itens.filter(i=>String(i.dia)===h||(!i.feito_em&&String(i.dia)<h)).sort((a,b)=>(a.feito_em?1:0)-(b.feito_em?1:0)||String(a.dia).localeCompare(String(b.dia))||String(a.hora||'').localeCompare(String(b.hora||'')));}
function pendentes(){return checklistItens().filter(i=>!i.feito_em).length;}
function agendar(){
 timers.forEach(clearTimeout);timers=[];const ag=Date.now();
 D.itens.forEach(i=>{if(i.feito_em||i.tipo==='tarefa')return;const q=quandoDe(i);if(!q)return;const t=q.getTime();
  if(t<=ag){if(i.disparado_em&&new Date(i.disparado_em)>=q)return;if(ag-t>36*3600000)return;disparar(i);return;}
  if(t-ag<2147000000)timers.push(setTimeout(()=>disparar(i),t-ag+200));});
}
function disparar(i){
 const atual=D.itens.find(x=>x.id===i.id)||i;if(atual.feito_em)return;
 if(cfg.aviso)cfg.aviso({canal:atual.tipo==='alarme'?'alarme':'lembrete',id:atual.id,nome:atual.titulo,texto:nomeCat(atual.categoria_id)||(atual.tipo==='alarme'?'Alarme':'Lembrete'),em:new Date().toISOString(),rodape:atual.repetir!=='nao'?'Repete '+({dia:'todo dia',semana:'toda semana',mes:'todo mês'}[atual.repetir]):''});
 atual.disparado_em=new Date().toISOString();sb.rpc('room_item_disparado',{p_id:atual.id}).then(()=>{},()=>{});
}
async function concluir(id,feito){const r=await rpc('room_item_concluir',{p_id:id,p_feito:feito});if(r){const k=D.itens.findIndex(x=>x.id===id);if(k>=0)D.itens[k]=r;desenhar();avisar();}return !!r;}
async function adiar(id,min){const r=await rpc('room_item_adiar',{p_id:id,p_minutos:min});if(r){const k=D.itens.findIndex(x=>x.id===id);if(k>=0)D.itens[k]=r;agendar();desenhar();}return !!r;}

/* montagem */
function montar(c){
 host=c;host.innerHTML='';const caixa=document.createElement('div');caixa.className='room-host';caixa.style.cssText='height:100%;min-height:0;display:block';host.appendChild(caixa);
 raiz=caixa.attachShadow({mode:'open'});
 raiz.innerHTML=`<link rel="stylesheet" href="room/room.css"><style>:host{display:block;height:100%}.main{height:100%}</style>
 <main class="main">
  <div class="tabs" role="tablist">${[['notas','Anotações'],['lemb','Lembretes e alarmes'],['ck','No meu checklist'],['cats','Categorias']].map(([k,t])=>`<button class="tab${aba===k?' on':''}" data-v="${k}">${t}</button>`).join('')}
   <div class="direita" id="dirNotas"${aba==='notas'?'':' hidden'}><div class="filtros" id="filtros"></div><label class="busca">${ICO.busca}<input id="busca" placeholder="Buscar nas anotações" value="${esc(busca)}"></label></div></div>
  <section class="view" id="v-notas"${aba==='notas'?'':' hidden'}>
   <div class="cad" id="cad"><div class="espiral" aria-hidden="true"></div><div class="folha2">
    <div class="pg" id="pg"><div class="rolo" id="rolo"><div class="rows" id="rows"></div></div>
     <div class="flutua"><div class="card"><div class="bloco-h"><b>Hoje</b><small id="hjData"></small></div><ul class="ck" id="ckHoje"></ul></div>
      <div class="card"><div class="bloco-h"><b>Próximas datas</b><small>marcadas no calendário</small></div><div class="prox" id="prox"></div></div></div>
     <div class="minical" id="miniCal" role="dialog" aria-label="Escolher data" hidden></div>
     <div class="pager2"><button id="pgAnt" aria-label="Dia anterior">${ICO.esq}</button><span class="pgs" id="pgNums"></span><button id="pgProx" aria-label="Próximo dia">${ICO.dir}</button></div></div>
    <div class="base"><div class="compo">
     <div class="campo2" id="campo2">
      <button class="ib" data-f="anexo" title="Anexo ou print">${ICO.clip}</button>
      <button class="ib" data-f="cliente" title="Ligar a um cliente">${ICO.pred}</button>
      <button class="ib" data-f="mes" title="Mês (competência)">${ICO.cal}</button>
      <button class="ib" data-f="cat" title="Categoria">${ICO.tag}<span class="dot" id="catDot" style="display:none"></span></button>
      <button class="ib" data-f="lemb" title="Lembrar / alarme">${ICO.relA}</button>
      <span class="sep"></span><span class="rasc" id="rasc"></span>
      <textarea id="txt" rows="1" placeholder="Escreva uma anotação"></textarea>
     </div>
     <div class="grav" id="grav" hidden><button class="lix" id="lixo" aria-label="Descartar áudio">${ICO.lixo}</button><span class="rd"></span><span class="tempo" id="tempo">0:00</span><div class="ondas" id="ondas"></div>
      <button class="pausa" id="pausa" aria-label="Pausar"><svg class="i" viewBox="0 0 24 24"><path d="M9 5v14M15 5v14"/></svg></button></div>
     <button class="acao" id="acao" aria-label="Gravar áudio">${ICO.mic}</button>
     <input type="file" id="arqIn" multiple hidden>
    </div></div></div></div>
  </section>
  <section class="view" id="v-lemb"${aba==='lemb'?'':' hidden'}></section>
  <section class="view" id="v-ck"${aba==='ck'?'':' hidden'}></section>
  <section class="view" id="v-cats"${aba==='cats'?'':' hidden'}></section>
 </main><div id="modalBox"></div>`;
 ligar();
}
const $=id=>raiz&&raiz.getElementById(id);
function noAr(){return raiz&&host&&host.isConnected&&host.contains(raiz.host);}

/* desenho */
function desenhar(){if(!noAr())return;filtrosDesenhar();paginaDesenhar();cardsDesenhar();
 if(aba==='lemb')lembDesenhar();if(aba==='ck')ckDesenhar();if(aba==='cats')catsDesenhar();}
function filtrosDesenhar(){const f=$('filtros');if(!f)return;
 f.innerHTML=`<button class="chip ${filtro?'':'on'}" data-c="">Todas</button>`+D.categorias.map(c=>`<button class="chip ${filtro===c.id?'on':''}" data-c="${esc(c.id)}"><span class="dot" style="background:${esc(c.cor)}"></span>${esc(c.nome)}</button>`).join('');}
function rotuloDia(d){const dif=Math.round((D.hoje-d)/86400000);const b=`${DIAS[d.getDay()]}, ${d.getDate()} de ${MES[d.getMonth()]}`;return dif===0?'Hoje · '+b:dif===1?'Ontem · '+b:b;}
function diasPaginas(){const s=new Set(D.dias);s.add(iso(D.hoje));if(diaPg)s.add(iso(diaPg));return [...s].sort();}
function mkHtml(n){return (n.categoria_id?`<span class="mk" title="${esc(nomeCat(n.categoria_id))}"><span class="dot" style="background:${esc(cor(n.categoria_id))}"></span></span>`:'')+(n.empresa_id&&empresas[n.empresa_id]?`<span class="mk cli">${esc(empresas[n.empresa_id])}</span>`:'')+(n.competencia?`<span class="mk">${esc(n.competencia)}</span>`:'');}
function lembDaNota(n){const i=D.itens.find(x=>x.nota_id===n.id&&!x.feito_em);if(!i)return '';const d=deIso(i.dia);const q=String(i.dia)===iso(D.hoje)?'Hoje':z(d.getDate())+'/'+z(d.getMonth()+1);return `<span class="lb">${ICO.rel}${esc(q+(i.hora?', '+String(i.hora).slice(0,5):'')+(i.tipo==='alarme'?' · alarme':''))}</span>`;}
function tamTxt(b){if(!b)return '';return b>1048576?(b/1048576).toFixed(1).replace('.',',')+' MB':Math.max(1,Math.round(b/1024))+' KB';}
function chipArq(a,ni,ai){const nome=String(a.nome||'arquivo');const ext=(nome.split('.').pop()||'').toUpperCase().slice(0,5);
 return `<span class="arq2" data-n="${esc(ni)}" data-a="${ai}" title="${esc(nome)}"><span class="arq2-ic e-${esc(ext.toLowerCase())}">${ICO.arq}</span><span class="arq2-n">${esc(nome.replace(/\.[^.]+$/,''))}</span><span class="arq2-t">${esc(ext)}${a.tamanho?' · '+tamTxt(a.tamanho):''}</span><span class="arq2-b" aria-hidden="true">${ICO.baixar}</span></span>`;}
function linhasNota(n){
 const ac=`<span class="ac"><button data-acn="lemb" data-id="${esc(n.id)}" title="Lembrar / alarme">${ICO.rel}</button><button data-acn="tarefa" data-id="${esc(n.id)}" title="Virar tarefa do checklist">${ICO.ck}</button><button data-acn="fixar" data-id="${esc(n.id)}" title="${n.fixada?'Desafixar':'Fixar'}">${ICO.pin}</button><button data-acn="apagar" data-id="${esc(n.id)}" title="Apagar">${ICO.lixo}</button></span>`;
 const h=hhmm(new Date(n.criado_em)),mk=mkHtml(n),lb=lembDaNota(n),pin=n.fixada?`<span class="lb" style="color:var(--laranjaTx)">${ICO.pin}</span>`:'';
 const out=[];
 if(n.topico)out.push(`<div class="row topi"><span class="tx">${esc(n.topico)}</span></div>`);
 const arqs=n.arquivos||[];
 if(arqs.length){out.push(`<div class="row"><span class="hr">${h}</span><span class="tx">${mk}<span class="mk">${arqs.length} ${arqs.length===1?'arquivo':'arquivos'}</span>${pin}</span>${n.texto||n.audio?'':ac}</div>`);
  out.push(`<div class="row arqs-row"><span class="tx">${arqs.map((a,i)=>chipArq(a,n.id,i)).join('')}</span></div>`);}
 if(n.audio){out.push(`<div class="row"><span class="hr">${arqs.length?'':h}</span><span class="tx">${arqs.length?'':mk}<span class="au"><button data-play="${esc(n.id)}" aria-label="Ouvir"><svg class="i" viewBox="0 0 24 24" style="width:10px;height:10px;fill:#fff;stroke:none"><path d="M7 4v16l13-8Z"/></svg></button><i></i><span class="seg">${esc(n.audio.dur||'')}</span></span>${n.texto?`<span class="tr">${esc(n.texto)}</span>`:''}${lb}</span>${ac}</div>`);}
 else if(n.texto)out.push(`<div class="row"><span class="hr">${arqs.length?'':h}</span><span class="tx">${arqs.length?'':mk}${esc(n.texto)}${lb}${arqs.length?'':pin}</span>${ac}</div>`);
 return out.join('');
}
function notasDoDia(d){const k=iso(d);const q=busca.toLowerCase();return D.notas.filter(n=>String(n.dia)===k&&(!filtro||n.categoria_id===filtro)&&(!q||[n.texto,n.topico,n.competencia,empresas[n.empresa_id],(n.arquivos||[]).map(a=>a.nome).join(' ')].join(' ').toLowerCase().includes(q)));}
function htmlPagina(d){return `<div class="row rdia"><span class="tx">${esc(rotuloDia(d))}</span></div>`+notasDoDia(d).map(linhasNota).join('');}
function acertarLinha(){const pg=$('pg');if(!pg)return;const r=document.createElement('div');r.className='row';r.style.cssText='position:absolute;left:0;top:0;visibility:hidden';
 r.innerHTML='<span class="tx">Hg<span class="bl" style="display:inline-block;width:1px;height:0;vertical-align:baseline"></span></span>';pg.appendChild(r);
 const y=r.querySelector('.bl').getBoundingClientRect().top-r.getBoundingClientRect().top;r.remove();if(y>4)pg.style.setProperty('--linhaY',Math.round(y+3)+'px');}
function paginaDesenhar(manter){const pg=$('pg');if(!pg)return;if(!diaPg)diaPg=D.hoje;
 acertarLinha();pg.style.setProperty('--livre',(pg.clientWidth>980?360:24)+'px');
 const rolo=$('rolo'),top=rolo.scrollTop;$('rows').innerHTML=htmlPagina(diaPg);rolo.scrollTop=manter?top:0;pagerDesenhar();}
function pagerDesenhar(){const ds=diasPaginas(),k=ds.indexOf(iso(diaPg));
 $('pgAnt').disabled=k<=0;$('pgProx').disabled=k>=ds.length-1;
 $('pgNums').innerHTML=`<button class="num on calbt" id="calBt" aria-haspopup="dialog" title="Escolher data">${ICO.cal}${z(diaPg.getDate())}/${z(diaPg.getMonth()+1)} · ${DIAS[diaPg.getDay()].slice(0,3).toLowerCase()}</button>`;}
function cardsDesenhar(){const hj=$('hjData');if(!hj)return;
 hj.textContent=`${DIAS[D.hoje.getDay()].toLowerCase()}, ${D.hoje.getDate()} de ${MES[D.hoje.getMonth()]}`;
 const its=checklistItens().slice(0,6);
 $('ckHoje').innerHTML=its.map(c=>{const atr=String(c.dia)<iso(D.hoje);return `<li class="${c.feito_em?'feito':''}"><input type="checkbox" id="h-${esc(c.id)}" ${c.feito_em?'checked':''} data-it="${esc(c.id)}"><label class="t" for="h-${esc(c.id)}"><b>${esc(c.titulo)}</b><small><span class="tipo ${TCLS[c.tipo]}">${TIPO[c.tipo]}</span>${c.categoria_id?`<span class="dot" style="background:${esc(cor(c.categoria_id))}"></span>${esc(nomeCat(c.categoria_id))}`:''}<span class="${atr&&!c.feito_em?'atr':''}">${atr?'de '+z(deIso(c.dia).getDate())+'/'+z(deIso(c.dia).getMonth()+1):c.hora?String(c.hora).slice(0,5):'hoje'}</span></small></label></li>`;}).join('');
 const prox=D.itens.filter(i=>!i.feito_em&&String(i.dia)>iso(D.hoje)).slice(0,5);
 $('prox').innerHTML=prox.map(i=>{const d=deIso(i.dia);return `<div><span class="d" style="border-color:${esc(cor(i.categoria_id))}">${d.getDate()}<small>${MES[d.getMonth()].slice(0,3).toUpperCase()}</small></span><span>${esc(i.titulo)}<br><small style="color:var(--apagado)">${esc(nomeCat(i.categoria_id)||TIPO[i.tipo])}${i.hora?' · '+String(i.hora).slice(0,5):''}</small></span></div>`;}).join('');}

/* virada */
function refletir(p,a,b){const dx=b.x-a.x,dy=b.y-a.y,l=dx*dx+dy*dy;const t=((p.x-a.x)*dx+(p.y-a.y)*dy)/l;const fx=a.x+t*dx,fy=a.y+t*dy;return {x:2*fx-p.x,y:2*fy-p.y};}
function gradDobra(W,H,a,b,paraEsq,stops){let nx=-(b.y-a.y),ny=b.x-a.x;const ln=Math.hypot(nx,ny);nx/=ln;ny/=ln;if((nx<0)!==paraEsq){nx=-nx;ny=-ny;}
 const ang=Math.atan2(nx,-ny)*180/Math.PI;const L=Math.abs(W*nx)+Math.abs(H*ny);const sx=W/2-nx*L/2,sy=H/2-ny*L/2;const p0=(a.x-sx)*nx+(a.y-sy)*ny;
 return `linear-gradient(${ang.toFixed(2)}deg,${stops.map(([c,o])=>`${c} ${(p0+o).toFixed(1)}px`).join(',')})`;}
function curvar(cam,W,H,t){const e=t<.5?2*t*t:1-Math.pow(-2*t+2,2)/2;
 const xt=W*1.03-e*(W*1.28),cur=Math.sin(Math.PI*Math.min(1,e*1.1))*H*.45;const xb=xt-cur;const a={x:xt,y:0},b={x:xb,y:H};
 let nx=-(b.y-a.y),ny=b.x-a.x;const ln=Math.hypot(nx,ny);nx/=ln;ny/=ln;if(nx<0){nx=-nx;ny=-ny;}
 const bojo=Math.sin(Math.PI*e)*Math.min(W,H)*.09;const c={x:(a.x+b.x)/2+nx*bojo,y:(a.y+b.y)/2+ny*bojo};const f=v=>v.toFixed(1);
 const curva=`Q ${f(c.x)} ${f(c.y)} ${f(b.x)} ${f(b.y)}`;
 cam.velha.style.clipPath=`path('M -2 -2 L ${f(a.x)} -2 L ${f(a.x)} ${f(a.y)} ${curva} L ${f(b.x)} ${H+2} L -2 ${H+2} Z')`;
 const r1=refletir({x:W+2,y:-2},a,b),r2=refletir({x:W+2,y:H+2},a,b),rc=refletir(c,a,b);
 cam.aba.style.clipPath=`path('M ${f(a.x)} ${f(a.y)} Q ${f(rc.x)} ${f(rc.y)} ${f(b.x)} ${f(b.y)} L ${f(r2.x)} ${f(r2.y)} L ${f(r1.x)} ${f(r1.y)} Z')`;
 cam.aba.style.background=gradDobra(W,H,a,b,true,[['rgba(150,140,120,1)',-4],['rgba(255,252,244,1)',14],['rgba(244,239,229,1)',60],['rgba(226,219,205,1)',200],['rgba(206,198,182,1)',520]]);
 cam.som.style.clipPath=`path('M ${f(a.x)} ${f(a.y)} ${curva} L ${W+2} ${H+2} L ${W+2} -2 Z')`;
 cam.som.style.background=gradDobra(W,H,a,b,false,[['rgba(17,17,20,.34)',0],['rgba(17,17,20,.10)',30],['rgba(17,17,20,0)',110]]);
 cam.som.style.opacity=String(Math.min(1,(1-e)*2.2));}
function irDia(novo){
 if(virando||!novo||iso(novo)===iso(diaPg))return;const pg=$('pg');const frente=novo>diaPg;
 garantir(novo).then(()=>{
  if(window.matchMedia('(prefers-reduced-motion: reduce)').matches){diaPg=novo;paginaDesenhar();return;}
  virando=true;const rolo=$('rolo');const W=pg.clientWidth,H=pg.clientHeight;
  const velha=document.createElement('div');velha.className='curva-velha';const aba=document.createElement('div');aba.className='curva-aba';const som=document.createElement('div');som.className='curva-som';
  if(frente){const c=rolo.cloneNode(true);c.removeAttribute('id');velha.appendChild(c);pg.appendChild(velha);c.scrollTop=rolo.scrollTop;diaPg=novo;paginaDesenhar();}
  else{const c=document.createElement('div');c.className='rolo';c.innerHTML=`<div class="rows">${htmlPagina(novo)}</div>`;velha.appendChild(c);pg.appendChild(velha);diaPg=novo;}
  pg.appendChild(som);pg.appendChild(aba);const cam={velha,aba,som};const dur=820;let t0=null;
  const passo=ts=>{if(t0===null)t0=ts;const t=Math.min(1,(ts-t0)/dur);curvar(cam,W,H,frente?t:1-t);if(t<1){requestAnimationFrame(passo);return;}
   velha.remove();aba.remove();som.remove();if(!frente)paginaDesenhar();virando=false;};
  curvar(cam,W,H,frente?0:1);requestAnimationFrame(passo);});
}
function passoDia(n){const ds=diasPaginas();const k=ds.indexOf(iso(diaPg))+n;if(k>=0&&k<ds.length)irDia(deIso(ds[k]));}

/* mini calendario */
function miniCal(){const box=$('miniCal');const a=mcMes.getFullYear(),m=mcMes.getMonth();const ini=new Date(a,m,1-new Date(a,m,1).getDay());
 let g='';['D','S','T','Q','Q','S','S'].forEach(x=>g+=`<i>${x}</i>`);
 for(let k=0;k<42;k++){const x=new Date(ini.getFullYear(),ini.getMonth(),ini.getDate()+k);const c=[x.getMonth()!==m?'fora':'',iso(x)===iso(D.hoje)?'hj':'',iso(x)===iso(diaPg)?'sel':'',D.dias.has(iso(x))?'tem':''].filter(Boolean).join(' ');g+=`<button class="${c}" data-d="${iso(x)}">${x.getDate()}</button>`;}
 box.innerHTML=`<div class="mc-c"><button data-mc="-1" aria-label="Mês anterior">${ICO.esq}</button><b>${MES[m]} ${a}</b><button data-mc="1" aria-label="Próximo mês">${ICO.dir}</button></div><div class="mc-g">${g}</div><div class="mc-r"><span><i class="tem-d"></i>tem anotação</span><button data-hoje>Ir para hoje</button></div>`;}

/* composicao */
function rascDesenhar(){const r=$('rasc');if(!r)return;const p=[];if(rascunho.empresa_id)p.push(`<span class="mk cli">${esc(empresas[rascunho.empresa_id]||'Cliente')}<button data-tira="empresa_id" aria-label="Tirar">${ICO.x}</button></span>`);
 if(rascunho.competencia)p.push(`<span class="mk">${esc(rascunho.competencia)}<button data-tira="competencia" aria-label="Tirar">${ICO.x}</button></span>`);
 r.innerHTML=p.join('');const dt=$('catDot');if(dt){dt.style.display=rascunho.categoria_id?'':'none';dt.style.background=cor(rascunho.categoria_id);}}
function estadoAcao(){const g=!$('grav').hidden,t=$('txt').value.trim().length>0;$('acao').innerHTML=g||t?ICO.env:ICO.mic;$('acao').setAttribute('aria-label',g?'Enviar áudio':t?'Guardar':'Gravar áudio');}
async function guardar(extra){
 const t=$('txt').value.trim();if(!t&&!extra)return null;
 const p=Object.assign({dia:iso(diaPg||D.hoje),texto:t},rascunho,extra||{});
 const r=await rpc('room_nota_salvar',p);if(!r)return null;
 D.notas.push(r);D.dias.add(String(r.dia));$('txt').value='';$('txt').style.height='34px';estadoAcao();paginaDesenhar(true);
 const rolo=$('rolo');rolo.scrollTop=rolo.scrollHeight;avisar();return r;}
async function anexar(files){
 const lista=[];for(const f of files){if(f.size>50*1048576){toast('Arquivo acima de 50 MB: '+f.name);continue;}
  const cam=`${uid}/${crypto.randomUUID()}-${f.name.replace(/[^\w.\-]+/g,'_').slice(-80)}`;
  const u=await sb.storage.from('room').upload(cam,f,{contentType:f.type||'application/octet-stream',upsert:false});
  if(u.error){toast('Não foi possível enviar '+f.name);continue;}lista.push({caminho:cam,nome:f.name,tamanho:f.size,tipo:f.type||''});}
 if(lista.length)await guardar({arquivos:lista,texto:$('txt').value.trim()});}
async function baixarArq(nid,ai){const n=D.notas.find(x=>x.id===nid);const a=n&&(n.arquivos||[])[+ai];if(!a)return;
 const s=await sb.storage.from(a.bucket||'room').createSignedUrl(a.caminho,300);if(s.error||!s.data){toast('Não foi possível baixar.');return;}
 if(cfg.baixar)cfg.baixar(s.data.signedUrl,a.nome);else window.open(s.data.signedUrl,'_blank');}
let audioTocando=null;
async function tocar(nid){const n=D.notas.find(x=>x.id===nid);if(!n||!n.audio)return;
 if(audioTocando){audioTocando.pause();audioTocando=null;return;}
 const s=await sb.storage.from(n.audio.bucket||'room').createSignedUrl(n.audio.caminho,300);if(s.error||!s.data){toast('Não foi possível tocar o áudio.');return;}
 const a=new Audio(s.data.signedUrl);audioTocando=a;a.onended=()=>{audioTocando=null;};a.play().catch(()=>{audioTocando=null;toast('Não foi possível tocar o áudio.');});}
async function gravIniciar(){
 let st;try{st=await navigator.mediaDevices.getUserMedia({audio:true});}catch(e){toast('O microfone não está liberado neste computador.');return;}
 const tipo=['audio/ogg;codecs=opus','audio/webm;codecs=opus','audio/webm'].find(t=>window.MediaRecorder&&MediaRecorder.isTypeSupported(t))||'';
 const rec=new MediaRecorder(st,tipo?{mimeType:tipo}:{});const partes=[];rec.ondataavailable=e=>{if(e.data&&e.data.size)partes.push(e.data);};
 grav={rec,st,partes,seg:0,pausa:false,tipo:rec.mimeType||tipo||'audio/webm'};rec.start(250);
 $('campo2').hidden=true;$('grav').hidden=false;$('grav').classList.remove('pausado');$('ondas').innerHTML='';
 const ctx=new (window.AudioContext||window.webkitAudioContext)();const an=ctx.createAnalyser();an.fftSize=256;ctx.createMediaStreamSource(st).connect(an);const buf=new Uint8Array(an.frequencyBinCount);grav.ctx=ctx;
 grav.tm=setInterval(()=>{if(grav.pausa)return;grav.seg+=.1;$('tempo').textContent=Math.floor(grav.seg/60)+':'+z(Math.floor(grav.seg%60));
  an.getByteTimeDomainData(buf);let mx=0;for(const v of buf)mx=Math.max(mx,Math.abs(v-128));const o=$('ondas');const i=document.createElement('i');i.style.height=(3+Math.min(22,mx/2.2))+'px';o.appendChild(i);if(o.children.length>160)o.firstChild.remove();},100);
 estadoAcao();}
function gravParar(enviar){if(!grav)return;const g=grav;grav=null;clearInterval(g.tm);
 $('grav').hidden=true;$('campo2').hidden=false;estadoAcao();
 g.rec.onstop=async()=>{g.st.getTracks().forEach(t=>t.stop());try{g.ctx.close();}catch(e){}
  if(!enviar||g.seg<.5)return;const blob=new Blob(g.partes,{type:g.tipo.split(';')[0]});const ext=/ogg/.test(g.tipo)?'ogg':'webm';
  const cam=`${uid}/${crypto.randomUUID()}.${ext}`;const u=await sb.storage.from('room').upload(cam,blob,{contentType:g.tipo.split(';')[0]});
  if(u.error){toast('Não foi possível guardar o áudio.');return;}
  await guardar({audio:{caminho:cam,dur:Math.floor(g.seg/60)+':'+z(Math.max(1,Math.floor(g.seg%60))),tipo:g.tipo.split(';')[0]},texto:''});};
 try{g.rec.stop();}catch(e){}}

/* modais */
function modal(html,ao){const b=$('modalBox');b.innerHTML=`<div class="modal"><div class="card" role="dialog">${html}</div></div>`;
 const fechar=()=>{b.innerHTML='';};b.querySelector('.modal').addEventListener('click',e=>{if(e.target.classList.contains('modal')||e.target.closest('[data-fechar]'))fechar();});ao&&ao(b,fechar);
 const pri=b.querySelector('input,select,textarea');if(pri)setTimeout(()=>pri.focus(),30);}
function catOpts(sel){return `<option value="">Sem categoria</option>`+D.categorias.map(c=>`<option value="${esc(c.id)}"${c.id===sel?' selected':''}>${esc(c.nome)}</option>`).join('');}
function modalLembrete(pref){pref=pref||{};const ag=new Date();
 const ops=[['1h','Em 1 hora',new Date(ag.getTime()+3600000)],['fim','Fim do dia',(()=>{const d=new Date();d.setHours(17,30,0,0);if(d<ag)d.setDate(d.getDate()+1);return d;})()],['amanha','Amanhã cedo',(()=>{const d=somaDias(hojeD(),1);d.setHours(9,0,0,0);return d;})()]];
 const d0=pref.dia?deIso(pref.dia):ops[0][2];
 modal(`<h2>Me lembre</h2>
  <label class="campo">O que lembrar<input id="mT" value="${esc(pref.titulo||'')}" maxlength="300"></label>
  <div class="op">${ops.map(([k,t,d],i)=>`<button class="${i===0&&!pref.dia?'on':''}" data-op="${iso(d)}|${hhmm(d)}">${t}<small>${DIAS[d.getDay()].slice(0,3).toLowerCase()}, ${hhmm(d)}</small></button>`).join('')}<button data-op="">Escolher data<small>dia e hora</small></button></div>
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px"><label class="campo">Dia<input type="date" id="mD" value="${iso(d0)}"></label><label class="campo">Hora<input type="time" id="mH" value="${pref.hora||hhmm(d0)}"></label></div>
  <div class="niv"><label><input type="radio" name="niv" value="lembrete" ${pref.tipo!=='alarme'&&pref.tipo!=='tarefa'?'checked':''}>Lembrete<small>aviso no canto</small></label><label><input type="radio" name="niv" value="alarme" ${pref.tipo==='alarme'?'checked':''}>Alarme<small>fica até concluir</small></label><label><input type="radio" name="niv" value="tarefa" ${pref.tipo==='tarefa'?'checked':''}>Tarefa<small>só no checklist</small></label></div>
  <label class="campo">Repetir<select id="mR"><option value="nao">Não repetir</option><option value="dia">Todo dia</option><option value="semana">Toda semana</option><option value="mes">Todo mês, no mesmo dia</option></select></label>
  <label class="campo">Categoria<select id="mC">${catOpts(pref.categoria_id||rascunho.categoria_id)}</select></label>
  <div class="mod-r"><button class="mini" data-fechar>Cancelar</button><button class="mini pri" id="mOk">Salvar e pôr no checklist</button></div>`,(b,fechar)=>{
  b.querySelectorAll('[data-op]').forEach(x=>x.onclick=()=>{b.querySelectorAll('[data-op]').forEach(y=>y.classList.toggle('on',y===x));if(x.dataset.op){const [d,h]=x.dataset.op.split('|');b.querySelector('#mD').value=d;b.querySelector('#mH').value=h;}else b.querySelector('#mD').focus();});
  b.querySelector('#mOk').onclick=async()=>{const tipo=(b.querySelector('input[name=niv]:checked')||{}).value||'lembrete';
   const p={titulo:b.querySelector('#mT').value.trim(),tipo,dia:b.querySelector('#mD').value,hora:b.querySelector('#mH').value,repetir:b.querySelector('#mR').value,categoria_id:b.querySelector('#mC').value,nota_id:pref.nota_id||''};
   if(!p.titulo){toast('Escreva o que lembrar.');return;}if(!p.dia){toast('Escolha o dia.');return;}if(tipo!=='tarefa'&&!p.hora){toast('Escolha a hora.');return;}
   if(tipo==='tarefa'&&!b.querySelector('#mH').value)p.hora='';
   const r=await rpc('room_item_salvar',p);if(!r)return;D.itens.push(r);agendar();fechar();desenhar();avisar();toast(TIPO[r.tipo]+' salvo.');};});}
function modalCliente(){let lista=[];
 modal(`<h2>Ligar a um cliente</h2><label class="campo">Buscar<input id="cB" placeholder="Nome ou CNPJ"></label><div id="cL" style="max-height:46vh;overflow:auto;display:flex;flex-direction:column;gap:2px"></div><div class="mod-r" style="margin-top:10px"><button class="mini" data-fechar>Fechar</button></div>`,(b,fechar)=>{
  const des=()=>{const q=b.querySelector('#cB').value.trim().toLowerCase(),qd=q.replace(/\D/g,'');const l=lista.filter(c=>!q||String(c.nome||'').toLowerCase().includes(q)||(qd.length>=3&&String(c.cnpj||'').includes(qd))).slice(0,80);
   b.querySelector('#cL').innerHTML=l.map(c=>`<button class="mini" style="text-align:left;display:flex;justify-content:space-between;gap:10px" data-e="${esc(c.id)}" data-n="${esc(c.nome)}"><span>${esc(c.nome)}</span><small style="color:var(--apagado)">${esc(c.cnpj||'')}</small></button>`).join('');};
  b.querySelector('#cB').oninput=des;des();Promise.resolve(cfg.clientes?cfg.clientes():[]).then(l=>{lista=l||[];des();});
  b.querySelector('#cL').onclick=e=>{const x=e.target.closest('[data-e]');if(!x)return;rascunho.empresa_id=x.dataset.e;empresas[x.dataset.e]=x.dataset.n;rascDesenhar();fechar();$('txt').focus();};});}
function modalMes(){const h=new Date();
 modal(`<h2>Mês (competência)</h2><label class="campo">Mês<input type="month" id="mM" value="${h.getFullYear()}-${z(h.getMonth()+1)}"></label><div class="mod-r"><button class="mini" data-fechar>Cancelar</button><button class="mini pri" id="mOk">Usar</button></div>`,(b,fechar)=>{
  b.querySelector('#mOk').onclick=()=>{const v=b.querySelector('#mM').value;if(!v)return;const [a,m]=v.split('-');rascunho.competencia=m+'/'+a;rascDesenhar();fechar();$('txt').focus();};});}
function modalCat(){modal(`<h2>Categoria</h2><div style="display:flex;flex-direction:column;gap:6px">${[{id:'',nome:'Sem categoria',cor:'#D4D4D8'}].concat(D.categorias).map(c=>`<button class="mini" style="display:flex;gap:8px;align-items:center;text-align:left${rascunho.categoria_id===c.id?';border-color:var(--laranja)':''}" data-ct="${esc(c.id)}"><span class="dot" style="background:${esc(c.cor)}"></span>${esc(c.nome)}</button>`).join('')}</div><div class="mod-r" style="margin-top:10px"><button class="mini" data-fechar>Fechar</button></div>`,(b,fechar)=>{
  b.querySelectorAll('[data-ct]').forEach(x=>x.onclick=()=>{rascunho.categoria_id=x.dataset.ct;rascDesenhar();fechar();$('txt').focus();});});}

/* abas */
function lembDesenhar(){const el=$('v-lemb');if(!diaAg)diaAg=D.hoje;const dt=diaAg;const its=itensDia(dt);
 const ini0=somaDias(dt,-((dt.getDay()+6)%7));let semana='';
 for(let k=0;k<7;k++){const x=somaDias(ini0,k);const m=[...new Set(itensDia(x).map(i=>i.categoria_id))].slice(0,3);semana+=`<button class="${iso(x)===iso(dt)?'on':''}" data-dia="${iso(x)}">${SEM[x.getDay()]}<b>${x.getDate()}</b><i>${m.map(c=>`<span style="background:${esc(cor(c))}"></span>`).join('')}</i></button>`;}
 const HH=56,ini=7,fimH=Math.max(19,...its.filter(i=>i.hora).map(i=>+String(i.hora).slice(0,2)+1));
 let horas='';for(let h=ini;h<=fimH;h++)horas+=`<span class="lh" style="top:${(h-ini)*HH}px">${z(h)}:00</span><span class="lh meia" style="top:${(h-ini)*HH+HH/2}px">:30</span>`;
 const todo=its.filter(i=>!i.hora),com=its.filter(i=>i.hora).sort((a,b)=>String(a.hora).localeCompare(String(b.hora)));
 const fins=[];com.forEach(i=>{const [hh,mm]=String(i.hora).split(':').map(Number);const top=(Math.max(ini,hh)-ini+(hh<ini?0:mm/60))*HH+3;let c=fins.findIndex(f=>f<=top);if(c<0){c=fins.length;fins.push(0);}fins[c]=top+HH-6;i._col=c;i._top=top;});
 const duas=fins.length>1;
 const evs=com.map(i=>{const al=i.tipo==='alarme';const pos=!duas?'':i._col?'left:calc(50% + 44px);':'right:calc(50% - 36px);';
  return `<div class="ev ${al?'al':''}${i.feito_em?' feito':''}" style="--c:${esc(cor(i.categoria_id))};top:${i._top}px;min-height:${HH-8}px;${pos}">${al?`<span class="sino2">${ICO.sino}</span>`:''}<span class="hh">${esc(String(i.hora).slice(0,5))}</span><div><b>${esc(i.titulo)}</b><small><span class="tipo ${TCLS[i.tipo]}">${TIPO[i.tipo]}</span>${i.categoria_id?`<span class="dot" style="background:${esc(cor(i.categoria_id))}"></span>${esc(nomeCat(i.categoria_id))}`:''}${i.repetir!=='nao'?'<span>· repete</span>':''}</small></div><div class="bt">${i.feito_em?`<button class="mini" data-desf="${esc(i.id)}">Desfazer</button>`:`<button class="mini" data-adiar="${esc(i.id)}">Adiar</button><button class="mini" data-conc="${esc(i.id)}">Concluir</button>`}<button class="mini" data-apg="${esc(i.id)}" title="Apagar">${ICO.lixo}</button></div></div>`;}).join('');
 const ag=new Date();const agora=iso(dt)===iso(D.hoje)&&ag.getHours()>=ini&&ag.getHours()<=fimH?`<div class="agora" style="top:${(ag.getHours()-ini+ag.getMinutes()/60)*HH}px"></div>`:'';
 const recs=D.itens.filter(i=>i.repetir!=='nao'&&!i.feito_em);const RL={dia:'TODO DIA',semana:'TODA SEMANA',mes:'TODO MÊS'};
 const q=i=>{const d=deIso(i.dia);return i.repetir==='mes'?'dia '+d.getDate():i.repetir==='semana'?SEM[d.getDay()].toLowerCase():String(i.hora||'').slice(0,5)||'—';};
 const nomeDia=['Domingo','Segunda-feira','Terça-feira','Quarta-feira','Quinta-feira','Sexta-feira','Sábado'][dt.getDay()];
 el.innerHTML=`<div class="cad4"><div class="espiral" aria-hidden="true"></div><div class="agenda">
  <div class="ag-top"><div class="data"><small>${nomeDia}</small>${dt.getDate()} de ${MES[dt.getMonth()]}</div><div class="semana" id="semana"><button data-sem="-7" aria-label="Semana anterior" style="width:30px">${ICO.esq}</button>${semana}<button data-sem="7" aria-label="Próxima semana" style="width:30px">${ICO.dir}</button></div>
   <div class="acs"><button class="mini pri" id="novoLemb">+ Novo lembrete</button></div></div>
  <div class="ag-corpo"><div class="horas"><div class="diatodo" style="position:relative"><small>Dia todo</small>${todo.map(i=>`<span class="tg${i.feito_em?' feito':''}"><span class="dot" style="background:${esc(cor(i.categoria_id))}"></span>${esc(i.titulo)}</span>`).join('')}</div>
   <div class="grade-h" style="height:${(fimH-ini+1)*HH}px">${horas}${agora}${evs}</div></div>
   <aside class="rec"><h4>Repetem sempre</h4><p>Lembretes que voltam sozinhos.</p>${recs.map(r=>`<div class="ri" style="--c:${esc(cor(r.categoria_id))}"><span class="q">${esc(q(r))}<small>${RL[r.repetir]}</small></span><div><b>${esc(r.titulo)}</b><span>${esc(nomeCat(r.categoria_id)||TIPO[r.tipo])}</span></div></div>`).join('')}</aside></div></div></div>`;
 const h=el.querySelector('.horas');const alvo=iso(dt)===iso(D.hoje)?Math.max(0,(ag.getHours()-ini-1)*HH):(com[0]?Math.max(0,com[0]._top-40):HH);h.scrollTop=alvo;}
function ckDesenhar(){const el=$('v-ck');const its=checklistItens();const os=(cfg.checklistOs&&cfg.checklistOs())||[];
 const total=its.length+os.length,feitos=its.filter(i=>i.feito_em).length;const h=iso(D.hoje);
 const migr=its.filter(i=>String(i.dia)<h),hoje=its.filter(i=>String(i.dia)===h);
 const linha=c=>{const atr=String(c.dia)<h;const sig=c.feito_em?'×':atr?'›':'•';
  return `<label class="tf ${c.feito_em?'feito':''}"><span class="sig ${atr&&!c.feito_em?'mig':''}">${sig}</span><input type="checkbox" ${c.feito_em?'checked':''} data-it="${esc(c.id)}"><span class="tt">${esc(c.titulo)}</span><span class="meta">${atr&&!c.feito_em?'<span class="mg">veio de '+z(deIso(c.dia).getDate())+'/'+z(deIso(c.dia).getMonth()+1)+'</span>':''}<span class="tipo ${TCLS[c.tipo]}">${TIPO[c.tipo]}</span>${c.categoria_id?`<span class="dot" style="background:${esc(cor(c.categoria_id))}"></span>`:''}<span>${c.hora?String(c.hora).slice(0,5):'hoje'}</span></span></label>`;};
 const linhaOs=o=>`<div class="tf" data-os="${esc(o.id)}" style="cursor:pointer"><span class="sig">•</span><span class="tt">O.S. ${esc(String(o.codigo).padStart(4,'0'))} · ${esc(o.operacao||'')}</span><span class="meta"><span class="tipo os">O.S.</span><span>${esc(o.fase_nome||'')}</span></span></div>`;
 el.innerHTML=`<div class="cad4"><div class="espiral" aria-hidden="true"></div><div class="bloco">
  <div class="bloco-top"><div class="t1"><small>Checklist · aba ${esc(cfg.primeiroNome||'')}</small>${DIAS[D.hoje.getDay()]}, ${D.hoje.getDate()} de ${MES[D.hoje.getMonth()]}</div>
   <div class="legenda"><span><b>•</b> a fazer</span><span><b>›</b> passou pra hoje</span><span><b>×</b> feito</span></div>
   <div class="prog"><span>${feitos} de ${total} feitos</span><span class="qd">${its.map(a=>`<span class="${a.feito_em?'ok':''}"></span>`).join('')}${os.map(()=>'<span></span>').join('')}</span></div></div>
  <div class="folhaA">${migr.length?`<div class="sec">Passou de outros dias</div>${migr.map(linha).join('')}`:''}<div class="sec">Hoje</div>${hoje.map(linha).join('')}${os.length?`<div class="sec">Ordens de serviço</div>${os.map(linhaOs).join('')}`:''}</div></div></div>`;}
function catsDesenhar(){const el=$('v-cats');const cont=id=>D.notas.filter(n=>n.categoria_id===id).length+D.itens.filter(i=>i.categoria_id===id).length;const rot=['-1.6deg','1.1deg','-.8deg','1.6deg','-1.2deg','.7deg'];
 el.innerHTML=`<div class="cad4"><div class="espiral" aria-hidden="true"></div><div class="grid4"><div class="g4-top"><h2>Legenda das minhas cores</h2><p>A cor de cada fita é a borda do dia no calendário.</p></div>
  <div class="chaves">${D.categorias.map((c,i)=>`<div class="chave" style="--c:${esc(c.cor)}"><span class="fita" style="--r:${rot[i%rot.length]}">${esc(c.nome)}</span>
   <div class="ch-corpo"><div class="cnt"><b>${cont(c.id)}</b> anotações e lembretes</div><div class="canetas">${PAL.map(p=>`<button class="caneta ${p.toLowerCase()===String(c.cor).toLowerCase()?'on':''}" style="--p:${p}" data-cc="${esc(c.id)}" data-cor="${p}" aria-label="Trocar cor"><span class="ponta"></span><span class="corpo"></span></button>`).join('')}</div>
   <div class="ch-amostra"><span>${D.hoje.getDate()}</span>no calendário</div><div class="ch-acoes"><button class="mini" data-ren="${esc(c.id)}">Renomear</button><button class="mini" data-arq="${esc(c.id)}">Arquivar</button></div></div></div>`).join('')}
  <div class="nova-fita" id="novaCat" role="button" tabindex="0">+ nova categoria</div></div></div></div>`;}
function modalNomeCat(c){modal(`<h2>${c?'Renomear categoria':'Nova categoria'}</h2><label class="campo">Nome<input id="nN" maxlength="40" value="${esc(c?c.nome:'')}"></label>${c?'':`<div class="canetas" id="nC" style="margin:6px 0 12px">${PAL.map((p,i)=>`<button class="caneta ${i===0?'on':''}" style="--p:${p}" data-cor="${p}"><span class="ponta"></span><span class="corpo"></span></button>`).join('')}</div>`}<div class="mod-r"><button class="mini" data-fechar>Cancelar</button><button class="mini pri" id="mOk">Salvar</button></div>`,(b,fechar)=>{
 let corSel=PAL[0];const nc=b.querySelector('#nC');if(nc)nc.onclick=e=>{const k=e.target.closest('[data-cor]');if(!k)return;corSel=k.dataset.cor;nc.querySelectorAll('.caneta').forEach(x=>x.classList.toggle('on',x===k));};
 b.querySelector('#mOk').onclick=async()=>{const n=b.querySelector('#nN').value.trim();if(!n){toast('Escreva o nome.');return;}const r=await rpc('room_categoria_salvar',c?{id:c.id,nome:n}:{nome:n,cor:corSel});if(!r)return;fechar();await recarregar();};});}

/* eventos */
function ligar(){
 raiz.addEventListener('click',async e=>{const t=e.target;
  const tab=t.closest('.tab[data-v]');if(tab){aba=tab.dataset.v;raiz.querySelectorAll('.tab').forEach(x=>x.classList.toggle('on',x===tab));raiz.querySelectorAll('.view').forEach(v=>v.hidden=v.id!=='v-'+aba);$('dirNotas').hidden=aba!=='notas';desenhar();if(aba==='notas')paginaDesenhar();return;}
  const ch=t.closest('.chip[data-c]');if(ch){filtro=ch.dataset.c;filtrosDesenhar();paginaDesenhar();return;}
  if(t.closest('#pgAnt')){passoDia(-1);return;}if(t.closest('#pgProx')){passoDia(1);return;}
  if(t.closest('#calBt')){const b=$('miniCal');if(!b.hidden){b.hidden=true;return;}mcMes=new Date(diaPg.getFullYear(),diaPg.getMonth(),1);miniCal();b.hidden=false;return;}
  const mc=t.closest('[data-mc]');if(mc){mcMes=new Date(mcMes.getFullYear(),mcMes.getMonth()+(+mc.dataset.mc),1);miniCal();return;}
  if(t.closest('[data-hoje]')){$('miniCal').hidden=true;irDia(D.hoje);return;}
  const dd=t.closest('#miniCal [data-d]');if(dd){$('miniCal').hidden=true;irDia(deIso(dd.dataset.d));return;}
  if(!t.closest('#miniCal')){const b=$('miniCal');if(b&&!b.hidden)b.hidden=true;}
  const fb=t.closest('[data-f]');if(fb){const f=fb.dataset.f;if(f==='anexo')$('arqIn').click();if(f==='cliente')modalCliente();if(f==='mes')modalMes();if(f==='cat')modalCat();if(f==='lemb')modalLembrete({titulo:$('txt').value.trim()});return;}
  const tira=t.closest('[data-tira]');if(tira){rascunho[tira.dataset.tira]='';rascDesenhar();return;}
  if(t.closest('#acao')){if(grav){gravParar(true);return;}if($('txt').value.trim()){guardar();return;}gravIniciar();return;}
  if(t.closest('#lixo')){gravParar(false);return;}
  if(t.closest('#pausa')&&grav){grav.pausa=!grav.pausa;try{grav.pausa?grav.rec.pause():grav.rec.resume();}catch(x){}$('grav').classList.toggle('pausado',grav.pausa);return;}
  const acn=t.closest('[data-acn]');if(acn){const n=D.notas.find(x=>x.id===acn.dataset.id);if(!n)return;const a=acn.dataset.acn;
   if(a==='lemb')modalLembrete({titulo:n.texto||'',nota_id:n.id,categoria_id:n.categoria_id});
   if(a==='tarefa'){const r=await rpc('room_item_salvar',{titulo:(n.texto||'Tarefa').slice(0,300),tipo:'tarefa',dia:iso(D.hoje),categoria_id:n.categoria_id||'',nota_id:n.id});if(r){D.itens.push(r);desenhar();avisar();toast('Tarefa no checklist.');}}
   if(a==='fixar'){const r=await rpc('room_nota_salvar',{id:n.id,fixada:!n.fixada});if(r){Object.assign(n,r);paginaDesenhar(true);}}
   if(a==='apagar'){if(acn.dataset.ok!=='1'){acn.dataset.ok='1';acn.style.color='var(--vermelho)';acn.title='Clique de novo para apagar';setTimeout(()=>{acn.dataset.ok='';acn.style.color='';acn.title='Apagar';},2500);return;}
    if(await rpc('room_nota_apagar',{p_id:n.id})){D.notas=D.notas.filter(x=>x.id!==n.id);paginaDesenhar(true);avisar();}}
   return;}
  const ar=t.closest('.arq2[data-n]');if(ar){baixarArq(ar.dataset.n,ar.dataset.a);return;}
  const pl=t.closest('[data-play]');if(pl){tocar(pl.dataset.play);return;}
  const sd=t.closest('#semana [data-dia]');if(sd){diaAg=deIso(sd.dataset.dia);await garantir(diaAg);lembDesenhar();return;}
  const sm=t.closest('[data-sem]');if(sm){diaAg=somaDias(diaAg,+sm.dataset.sem);await garantir(diaAg);lembDesenhar();return;}
  if(t.closest('#novoLemb')){modalLembrete({dia:iso(diaAg||D.hoje),hora:'09:00'});return;}
  const cc=t.closest('[data-conc]');if(cc){await concluir(cc.dataset.conc,true);return;}
  const df=t.closest('[data-desf]');if(df){await concluir(df.dataset.desf,false);return;}
  const adj=t.closest('[data-adiar]');if(adj){await adiar(adj.dataset.adiar,15);toast('Adiado 15 min.');return;}
  const apg=t.closest('[data-apg]');if(apg){if(apg.dataset.ok!=='1'){apg.dataset.ok='1';apg.style.color='var(--vermelho)';setTimeout(()=>{apg.dataset.ok='';apg.style.color='';},2500);return;}if(await rpc('room_item_apagar',{p_id:apg.dataset.apg})){D.itens=D.itens.filter(x=>x.id!==apg.dataset.apg);agendar();desenhar();avisar();}return;}
  const osr=t.closest('[data-os]');if(osr&&cfg.abrirOs){cfg.abrirOs(osr.dataset.os);return;}
  const cn=t.closest('[data-cc]');if(cn){const r=await rpc('room_categoria_salvar',{id:cn.dataset.cc,cor:cn.dataset.cor});if(r){const c=cat(r.id);if(c)Object.assign(c,r);desenhar();avisar();}return;}
  const rn=t.closest('[data-ren]');if(rn){modalNomeCat(cat(rn.dataset.ren));return;}
  const aq=t.closest('[data-arq]');if(aq){if(aq.dataset.ok!=='1'){aq.dataset.ok='1';aq.textContent='Confirmar';setTimeout(()=>{aq.dataset.ok='';aq.textContent='Arquivar';},2500);return;}if(await rpc('room_categoria_salvar',{id:aq.dataset.arq,arquivada:true})){if(filtro===aq.dataset.arq)filtro='';await recarregar();}return;}
  if(t.closest('#novaCat')){modalNomeCat(null);return;}
 });
 raiz.addEventListener('change',async e=>{const i=e.target;if(i.dataset&&i.dataset.it){const ok=await concluir(i.dataset.it,i.checked);if(!ok)i.checked=!i.checked;}
  if(i.id==='arqIn'&&i.files&&i.files.length){const f=[...i.files];i.value='';anexar(f);}});
 raiz.addEventListener('input',e=>{if(e.target.id==='busca'){busca=e.target.value;paginaDesenhar();}if(e.target.id==='txt'){const t=e.target;t.style.height='34px';t.style.height=Math.min(120,t.scrollHeight)+'px';estadoAcao();}});
 raiz.addEventListener('keydown',e=>{if(e.target.id==='txt'&&e.key==='Enter'&&!e.shiftKey&&!e.ctrlKey){e.preventDefault();guardar();}
  if(e.key==='Escape'){const b=$('modalBox');if(b&&b.innerHTML)b.innerHTML='';const m=$('miniCal');if(m)m.hidden=true;}});
 raiz.addEventListener('paste',e=>{if(e.target.id!=='txt')return;const fs=[...(e.clipboardData&&e.clipboardData.files||[])];if(fs.length){e.preventDefault();anexar(fs);}});
 let rzT;window.addEventListener('resize',()=>{clearTimeout(rzT);rzT=setTimeout(()=>{if(noAr()&&aba==='notas')paginaDesenhar(true);},150);});
}

/* calendario do menu */
function marcasDia(d){const k=iso(d);const cs=[];D.itens.forEach(i=>{if(String(i.dia)===k&&!cs.includes(cor(i.categoria_id)))cs.push(cor(i.categoria_id));});
 D.notas.forEach(n=>{if(String(n.dia)===k&&n.categoria_id&&!cs.includes(cor(n.categoria_id)))cs.push(cor(n.categoria_id));});return cs;}
let popEl=null;
function popFechar(){if(popEl){popEl.remove();popEl=null;}}
function popDia(anchor,d){popFechar();const its=itensDia(d).slice().sort((a,b)=>String(a.hora||'').localeCompare(String(b.hora||'')));const ns=D.notas.filter(n=>String(n.dia)===iso(d));
 if(!its.length&&!ns.length){abrirDia(d);return;}
 const r=anchor.getBoundingClientRect();const p=document.createElement('div');p.className='room-pop';
 p.innerHTML=`<h4>${DIAS[d.getDay()].toLowerCase()}, ${d.getDate()} de ${MES[d.getMonth()]}<small>${its.length} ${its.length===1?'item':'itens'}${ns.length?' · '+ns.length+' '+(ns.length===1?'anotação':'anotações'):''}</small></h4>
  ${its.map(i=>`<div class="pi${i.feito_em?' feito':''}" style="border-color:${esc(cor(i.categoria_id))}"><span class="h">${i.hora?esc(String(i.hora).slice(0,5)):'Dia todo'}</span><div><b>${esc(i.titulo)}</b><small><span class="tipo ${TCLS[i.tipo]}">${TIPO[i.tipo]}</span>${i.categoria_id?`<span class="dot" style="background:${esc(cor(i.categoria_id))}"></span>${esc(nomeCat(i.categoria_id))}`:''}</small></div></div>`).join('')}
  <button class="room-pop-abrir">Abrir no ROOM</button>`;
 document.body.appendChild(p);popEl=p;const ph=p.offsetHeight;let top=r.top+r.height/2-24;top=Math.max(10,Math.min(top,window.innerHeight-ph-10));
 p.style.top=top+'px';p.style.left=(r.right+12)+'px';p.style.setProperty('--seta',Math.max(10,Math.min(ph-22,r.top+r.height/2-top-6))+'px');
 p.querySelector('.room-pop-abrir').onclick=()=>{popFechar();abrirDia(d);};
 setTimeout(()=>document.addEventListener('click',function f(e){if(!p.contains(e.target)){popFechar();document.removeEventListener('click',f);}}),0);}
function abrirDia(d){diaPg=d;aba='notas';diaAg=d;if(cfg.abrir)cfg.abrir();garantir(d).then(()=>{if(noAr())desenhar();});}

/* aviso */
async function acaoAviso(a){const id=a.id;
 if(a.acao==='concluir'){await concluir(id,true);return;}
 if(a.acao==='adiar'){const i=D.itens.find(x=>x.id===id);await adiar(id,i&&i.tipo==='alarme'?5:15);return;}
 if(a.acao==='adiar5'){await adiar(id,5);return;}
 if(a.acao==='abrir'){const i=D.itens.find(x=>x.id===id);aba='lemb';diaAg=i?deIso(i.dia):D.hoje;if(cfg.abrir)cfg.abrir();}}

/* api */
window.RoomIT={
 async iniciar(c){cfg=c;sb=c.sb;uid=c.uid;const h=hojeD();await garantir(h);ouvir();agendar();avisar();
  const meia=()=>{const a=new Date(),f=new Date(a.getFullYear(),a.getMonth(),a.getDate()+1,0,0,5);setTimeout(async()=>{D.hoje=hojeD();await garantir(D.hoje);agendar();desenhar();avisar();meia();},f-a);};meia();},
 abrir(c){if(!sb)return;if(!(raiz&&host===c&&noAr()))montar(c);garantir(diaPg||D.hoje).then(()=>{desenhar();if(aba==='notas'){paginaDesenhar();rascDesenhar();estadoAcao();}});},
 aoMudar(f){ouvintes.push(f);},
 marcas(d){return marcasDia(d);},
 garantirMes(a,m){return garantir(new Date(a,m,1));},
 popDia, popFechar,
 pendentes,
 checklist(){return checklistItens().map(i=>({id:i.id,titulo:i.titulo,tipo:i.tipo,feito:!!i.feito_em,atrasado:String(i.dia)<iso(D.hoje),hora:i.hora?String(i.hora).slice(0,5):'',dia:String(i.dia),cor:cor(i.categoria_id),categoria:nomeCat(i.categoria_id)}));},
 concluir,
 acaoAviso
};
})();
