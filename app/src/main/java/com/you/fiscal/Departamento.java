package com.you.fiscal;

import java.io.InputStream;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Properties;

final class Departamento {

    private static final Properties P = new Properties();

    static {
        String id = System.getProperty("fiscal.departamento", "fiscal").replaceAll("[^a-z]", "");
        try (InputStream in = Departamento.class.getResourceAsStream("/departamentos/" + id + ".properties")) {
            if (in != null) P.load(in);
        } catch (Exception ignorado) { }
    }

    private Departamento() { }

    static String id() { return P.getProperty("id", "fiscal"); }
    static String nome() { return P.getProperty("nome", "Fiscal"); }
    static String porta() { return P.getProperty("porta", "47120"); }
    static String perfil() { return P.getProperty("perfil", "fiscal-jcef-perfil"); }
    static String registro() { return P.getProperty("registro", "Fiscal"); }

    static Map<String, Object> paraTela() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", id());
        m.put("nome", nome());
        m.put("sb_url", P.getProperty("sb_url", "https://vvohwixeokxydmbhqklu.supabase.co"));
        m.put("sb_key", P.getProperty("sb_key", "sb_publishable_jQVklnYdEmsbVYzsp7_0Nw_ZLht78GM"));
        m.put("front", FrenteVps.ativo());
        String fundo = P.getProperty("fundo_login", "");
        if (fundo.matches("img/[a-z0-9-]+\\.(png|jpg|webp)")) m.put("fundo_login", fundo);
        return m;
    }
}
