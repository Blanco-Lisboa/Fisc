const SB_URL='https://vvohwixeokxydmbhqklu.supabase.co',SB_KEY='sb_publishable_jQVklnYdEmsbVYzsp7_0Nw_ZLht78GM';
const BL_URL='https://wfqcoocfastgsfgegpcm.supabase.co',BL_KEY='sb_publishable_88ukR4t1KNTc73DxbF6-Pw_0CKW16Fe';
const CHAVE_MANTER='fiscal-manter';

function armazem(){let m=false;try{m=localStorage.getItem(CHAVE_MANTER)==='1';}catch(e){}return m?localStorage:sessionStorage;}
function blCliente(){return supabase.createClient(BL_URL,BL_KEY,{auth:{persistSession:false,autoRefreshToken:false}});}
let _fiscal=null;
function fiscalCliente(){
  if(!_fiscal)_fiscal=supabase.createClient(SB_URL,SB_KEY,{auth:{persistSession:true,autoRefreshToken:true,storage:armazem(),storageKey:'fiscal-sessao'}});
  return _fiscal;
}
async function fiscalSessaoAtual(){const r=await fiscalCliente().auth.getSession();return r.data.session;}

function loginBL(v){const s=String(v||'').trim();if(s.includes('@'))return s.toLowerCase();
  const cpf=s.replace(/\D/g,'');return cpf.length===11?cpf+'@cpf.youcontabilidade.local':s;}
async function fiscalEntrar(email,senha,manter){
  email=loginBL(email);
  try{localStorage.setItem(CHAVE_MANTER,manter?'1':'0');}catch(e){}
  _fiscal=null;
  const bl=blCliente();
  const a=await bl.auth.signInWithPassword({email,password:senha});
  if(a.error)throw new Error('E-mail ou senha inválidos.');
  const f=await fetch(SB_URL+'/functions/v1/fiscal-entrar',{method:'POST',headers:{'Content-Type':'application/json',apikey:SB_KEY},
    body:JSON.stringify({bl_token:a.data.session.access_token})});
  const j=await f.json().catch(()=>({}));
  await bl.auth.signOut().catch(()=>{});
  if(!j.ok)throw new Error(f.status===403?'Sem acesso ao Fiscal.':'Não foi possível entrar.');
  const s=await fiscalCliente().auth.setSession({access_token:j.access_token,refresh_token:j.refresh_token});
  if(s.error)throw new Error('Não foi possível entrar.');
  return j.usuario;
}
async function fiscalSair(){try{await fiscalCliente().auth.signOut();}catch(e){}location.href='login.html';}
