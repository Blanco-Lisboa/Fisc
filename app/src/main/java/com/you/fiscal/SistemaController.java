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
