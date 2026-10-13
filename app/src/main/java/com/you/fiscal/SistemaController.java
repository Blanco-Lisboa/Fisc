package com.you.fiscal;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.swing.*;
import java.awt.*;
import java.util.Map;

@RestController
@RequestMapping("/sistema")
public class SistemaController {

    @GetMapping("/versao")
    public Map<String, Object> versao() {
        return Map.of("versao", System.getProperty("fiscal.versao", "dev"),
                "atualizavel", System.getProperty("fiscal.lancador") != null);
    }

    @PostMapping("/frente")
    public ResponseEntity<Void> frente(@RequestHeader(value = "X-Fiscal", required = false) String h) {
        if (!"1".equals(h)) return ResponseEntity.status(403).build();
        FiscalApplication.mostrar();
        return ResponseEntity.ok().build();
    }

    @PostMapping("/aviso")
    public ResponseEntity<Void> aviso(@RequestHeader(value = "X-Fiscal", required = false) String h, @RequestBody Map<String, Object> d) {
        if (!"1".equals(h)) return ResponseEntity.status(403).build();
        AvisoJanela.mostrar(d);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/baixar")
    public ResponseEntity<Map<String, Object>> baixar(@RequestHeader(value = "X-Fiscal", required = false) String h, @RequestBody Map<String, Object> d) {
        if (!"1".equals(h)) return ResponseEntity.status(403).build();
        String url = String.valueOf(d.get("url"));
        java.net.URI u;
        try { u = java.net.URI.create(url); } catch (Exception e) { return ResponseEntity.ok(Map.of("ok", false)); }
        if (!"https".equals(u.getScheme()) || u.getHost() == null || !u.getHost().endsWith(".supabase.co") || !u.getPath().startsWith("/storage/v1/object/"))
            return ResponseEntity.ok(Map.of("ok", false));
        String nome = String.valueOf(d.getOrDefault("nome", "arquivo")).replaceAll("[\\\\/:*?\"<>|\\r\\n]", "_").trim();
        if (nome.isEmpty() || "null".equals(nome)) nome = "arquivo";
        try {
            java.io.File pasta = new java.io.File(System.getProperty("user.home"), "Downloads");
            pasta.mkdirs();
            java.io.File alvo = new java.io.File(pasta, nome);
            int ponto = nome.lastIndexOf('.');
            String base = ponto > 0 ? nome.substring(0, ponto) : nome, ext = ponto > 0 ? nome.substring(ponto) : "";
            for (int i = 1; alvo.exists(); i++) alvo = new java.io.File(pasta, base + " (" + i + ")" + ext);
            java.net.http.HttpResponse<java.nio.file.Path> r = java.net.http.HttpClient.newBuilder()
                    .followRedirects(java.net.http.HttpClient.Redirect.NORMAL).build()
                    .send(java.net.http.HttpRequest.newBuilder(u).timeout(java.time.Duration.ofMinutes(5)).GET().build(),
                            java.net.http.HttpResponse.BodyHandlers.ofFile(alvo.toPath()));
            if (r.statusCode() != 200) { alvo.delete(); return ResponseEntity.ok(Map.of("ok", false)); }
            java.io.File arq = alvo;
            if (!Boolean.FALSE.equals(d.get("abrir"))) new Thread(() -> {
                try { if (Desktop.isDesktopSupported()) Desktop.getDesktop().open(arq); } catch (Exception ignorado) { }
            }, "abrir-arquivo").start();
            return ResponseEntity.ok(Map.of("ok", true, "arquivo", arq.getName()));
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of("ok", false));
        }
    }

    @PostMapping("/aviso/resultado")
    public ResponseEntity<Void> avisoResultado(@RequestHeader(value = "X-Fiscal", required = false) String h, @RequestBody Map<String, Object> d) {
        if (!"1".equals(h)) return ResponseEntity.status(403).build();
        AvisoJanela.resultado(String.valueOf(d.get("chave")), Boolean.TRUE.equals(d.get("ok")),
                d.get("erro") == null ? null : String.valueOf(d.get("erro")));
        return ResponseEntity.ok().build();
    }

    @PostMapping("/atualizar")
    public ResponseEntity<Map<String, Object>> atualizar(@RequestHeader(value = "X-Fiscal", required = false) String h) {
        if (!"1".equals(h)) return ResponseEntity.status(403).build();
        String exe = System.getProperty("fiscal.lancador");
        if (exe == null) return ResponseEntity.ok(Map.of("ok", false));
        try {
            new ProcessBuilder(exe, "--esperar=" + ProcessHandle.current().pid()).start();
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of("ok", false));
        }
        new Thread(() -> {
            try { Thread.sleep(400); } catch (InterruptedException ignorado) { }
            Thread trava = new Thread(() -> {
                try { Thread.sleep(6000); } catch (InterruptedException ignorado) { }
                Runtime.getRuntime().halt(0);
            });
            trava.setDaemon(true);
            trava.start();
            FiscalApplication.encerrar();
        }).start();
        return ResponseEntity.ok(Map.of("ok", true));
    }
}
