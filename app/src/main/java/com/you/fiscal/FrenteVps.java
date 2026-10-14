package com.you.fiscal;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.*;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.HashSet;
import java.util.HexFormat;
import java.util.Map;
import java.util.Set;
import java.util.stream.Stream;

final class FrenteVps {

    private static final String ENDERECO = "https://app.it-ia.tec.br/";
    private static final HttpClient HTTP = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(8))
            .followRedirects(HttpClient.Redirect.NEVER).build();
    private static final Object TRAVA = new Object();

    private FrenteVps() { }

    static String canal() {
        String c = System.getProperty("fiscal.front", "");
        return c.equals("teste") || c.equals("estavel") ? c : null;
    }

    static boolean ativo() { return canal() != null; }

    static Path pasta() {
        String base = System.getProperty("fiscal.base", System.getProperty("user.home") + "/." + Departamento.id());
        return Paths.get(base, "frente", canal()).toAbsolutePath().normalize();
    }

    static Map<String, Object> sincronizar(String token) throws Exception {
        if (!ativo()) return Map.of("ok", false);
        if (token == null || token.isBlank() || token.length() > 8192) return Map.of("ok", false);
        synchronized (TRAVA) {
            String raiz = ENDERECO + canal() + "/";
            HttpResponse<byte[]> r = HTTP.send(pedido(raiz + "manifesto.json", token), HttpResponse.BodyHandlers.ofByteArray());
            if (r.statusCode() != 200) return Map.of("ok", false, "status", r.statusCode());
            JsonNode man = new ObjectMapper().readTree(r.body());
            Path dir = pasta();
            Files.createDirectories(dir);
            Set<Path> manter = new HashSet<>();
            int novos = 0;
            for (JsonNode a : man.path("arquivos")) {
                String caminho = a.path("caminho").asText(""), sha = a.path("sha256").asText("");
                if (!caminho.matches("[A-Za-z0-9._/-]+") || caminho.contains("..") || !sha.matches("[0-9a-f]{64}")) continue;
                Path alvo = dir.resolve(caminho).normalize();
                if (!alvo.startsWith(dir)) continue;
                manter.add(alvo);
                if (Files.isRegularFile(alvo) && sha.equals(sha(Files.readAllBytes(alvo)))) continue;
                HttpResponse<byte[]> f = HTTP.send(pedido(raiz + caminho, token), HttpResponse.BodyHandlers.ofByteArray());
                if (f.statusCode() != 200 || !sha.equals(sha(f.body()))) return Map.of("ok", false, "arquivo", caminho);
                Files.createDirectories(alvo.getParent());
                Path tmp = alvo.resolveSibling(alvo.getFileName() + ".baixando");
                Files.write(tmp, f.body());
                Files.move(tmp, alvo, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
                novos++;
            }
            if (manter.isEmpty()) return Map.of("ok", false);
            try (Stream<Path> s = Files.walk(dir)) {
                s.filter(Files::isRegularFile).filter(p -> !manter.contains(p)).forEach(p -> {
                    try { Files.deleteIfExists(p); } catch (Exception ignorado) { }
                });
            }
            return Map.of("ok", true, "novos", novos, "commit", man.path("commit").asText(""));
        }
    }

    private static HttpRequest pedido(String url, String token) {
        return HttpRequest.newBuilder(URI.create(url)).timeout(Duration.ofSeconds(30))
                .header("Authorization", "Bearer " + token).GET().build();
    }

    private static String sha(byte[] b) throws Exception {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(b));
    }
}
