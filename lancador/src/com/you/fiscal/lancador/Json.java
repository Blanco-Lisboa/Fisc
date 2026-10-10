package com.you.fiscal.lancador;

import java.util.*;

final class Json {

    private final String s;
    private int i;

    private Json(String s) {
        this.s = s;
    }

    static Object ler(String texto) {
        Json j = new Json(texto);
        Object v = j.valor();
        j.espaco();
        if (j.i != j.s.length()) throw new IllegalArgumentException("json");
        return v;
    }

    @SuppressWarnings("unchecked")
    static Map<String, Object> objeto(String texto) {
        return (Map<String, Object>) ler(texto);
    }

    private void espaco() {
        while (i < s.length() && Character.isWhitespace(s.charAt(i))) i++;
    }

    private Object valor() {
        espaco();
        char c = s.charAt(i);
        if (c == '{') {
            Map<String, Object> m = new LinkedHashMap<>();
            i++;
            espaco();
            if (s.charAt(i) == '}') { i++; return m; }
            while (true) {
                espaco();
                String k = texto();
                espaco();
                i++;
                m.put(k, valor());
                espaco();
                if (s.charAt(i++) == '}') return m;
            }
        }
        if (c == '[') {
            List<Object> l = new ArrayList<>();
            i++;
            espaco();
            if (s.charAt(i) == ']') { i++; return l; }
            while (true) {
                l.add(valor());
                espaco();
                if (s.charAt(i++) == ']') return l;
            }
        }
        if (c == '"') return texto();
        if (s.startsWith("true", i)) { i += 4; return Boolean.TRUE; }
        if (s.startsWith("false", i)) { i += 5; return Boolean.FALSE; }
        if (s.startsWith("null", i)) { i += 4; return null; }
        int ini = i;
        while (i < s.length() && "+-0123456789.eE".indexOf(s.charAt(i)) >= 0) i++;
        String n = s.substring(ini, i);
        if (n.isEmpty()) throw new IllegalArgumentException("json");
        if (n.contains(".") || n.contains("e") || n.contains("E")) return Double.parseDouble(n);
        return Long.parseLong(n);
    }

    private String texto() {
        StringBuilder b = new StringBuilder();
        i++;
        while (true) {
            char c = s.charAt(i++);
            if (c == '"') return b.toString();
            if (c == '\\') {
                char e = s.charAt(i++);
                switch (e) {
                    case 'n' -> b.append('\n');
                    case 't' -> b.append('\t');
                    case 'r' -> b.append('\r');
                    case 'b' -> b.append('\b');
                    case 'f' -> b.append('\f');
                    case 'u' -> { b.append((char) Integer.parseInt(s.substring(i, i + 4), 16)); i += 4; }
                    default -> b.append(e);
                }
            } else {
                b.append(c);
            }
        }
    }

    static String escrever(Object v) {
        StringBuilder b = new StringBuilder();
        escrever(v, b);
        return b.toString();
    }

    @SuppressWarnings("unchecked")
    private static void escrever(Object v, StringBuilder b) {
        if (v == null) b.append("null");
        else if (v instanceof String t) {
            b.append('"');
            for (char c : t.toCharArray()) {
                if (c == '"' || c == '\\') b.append('\\').append(c);
                else if (c < 0x20) b.append(String.format("\\u%04x", (int) c));
                else b.append(c);
            }
            b.append('"');
        } else if (v instanceof Map) {
            b.append('{');
            boolean p = true;
            for (Map.Entry<String, Object> e : ((Map<String, Object>) v).entrySet()) {
                if (!p) b.append(',');
                p = false;
                escrever(e.getKey(), b);
                b.append(':');
                escrever(e.getValue(), b);
            }
            b.append('}');
        } else if (v instanceof List) {
            b.append('[');
            boolean p = true;
            for (Object o : (List<Object>) v) {
                if (!p) b.append(',');
                p = false;
                escrever(o, b);
            }
            b.append(']');
        } else b.append(v);
    }
}
