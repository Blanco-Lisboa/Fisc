# Java do Fiscal — login pela BL e fim dos dados fictícios (05/10/2026)

## Regras do William
- O Java do Fiscal não pode ter dado fictício.
- Os usuários do Java do Fiscal são os permitidos pelo Java BL e pelo banco da BL (wfqcoocfastgsfgegpcm).

## O que existe (conferido)
- BL: 32 logins (auth.users), usuarios_internos, setores, usuario_setores. Setor "Fiscal" tem 11 pessoas.
- Fiscal: fiscal_usuario tem as mesmas 11 pessoas e os ids são IGUAIS aos da BL (11/11).
- Supabase não aceita, de forma oficial, o login de outro projeto Supabase como "login de terceiros"
  (lista oficial: Clerk, Firebase, Auth0, Cognito, WorkOS).

## Desenho
1. O Java do Fiscal faz login com a conta da BL (mesmo e-mail/senha do Java BL).
2. Uma função na nuvem do Fiscal recebe o token da BL, confere na BL que a pessoa está ativa e no setor Fiscal
   (ou nível que libera), e devolve um token do Fiscal com o mesmo id. Sem setor Fiscal = acesso negado.
3. Com o mesmo id, as regras de acesso que já existem no banco do Fiscal (nível, carteira) continuam valendo.
4. fiscal_usuario deixa de ser cadastro próprio: nível/setor vêm da BL (só ponteiro no Fiscal).
5. Tela: cada dado fictício do index.html é trocado pelo dado real do banco, sem mudar a aparência.
   O que não tiver dado real ainda fica sem conteúdo (lacuna avisada no chat, nunca texto na tela).

## Escopo a confirmar
- WhatsApp (conversas, mensagens, envio, modelos) = Zap.
- Apuração, Radar XML, Esteiras, Pendências, IA = existe o "Agent Fiscal" no Maestri; confirmar quem faz.
