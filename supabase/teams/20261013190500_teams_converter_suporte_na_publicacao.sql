update public.chat_canal set tipo = 'departamentos',
       setor_id = least('85aa9f03-b91d-4d25-9f6d-366c6fe2d813'::uuid, 'f0da68d1-45c9-44e6-9d5f-5f9e01434163'::uuid),
       setor_b_id = greatest('85aa9f03-b91d-4d25-9f6d-366c6fe2d813'::uuid, 'f0da68d1-45c9-44e6-9d5f-5f9e01434163'::uuid),
       nome = 'Fiscal + Suporte'
 where id = '1a153f51-a3a4-43f1-8f7d-d4657cf5226f' and tipo = 'setor';
insert into public.chat_canal_membro (canal_id, usuario_id, papel, entrou_em)
select '1a153f51-a3a4-43f1-8f7d-d4657cf5226f', u, 'membro', (select min(criada_em) - interval '1 second' from public.chat_mensagem where canal_id = '1a153f51-a3a4-43f1-8f7d-d4657cf5226f')
  from unnest(array['b9458e7c-6a21-430f-8c9a-acd1ba53ac27'::uuid, '36c44c11-3555-43e6-b2eb-ca0cd6c43c27'::uuid]) u
on conflict (canal_id, usuario_id) do nothing;
