package com.you.fiscal.lancador;

import javax.swing.*;
import java.awt.*;
import java.io.*;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.MessageDigest;
import java.time.Duration;
import java.util.*;
import java.util.List;

public class Lancador {

    static final String URL = "https://vvohwixeokxydmbhqklu.supabase.co";
    static final String CHAVE = "sb_publishable_jQVklnYdEmsbVYzsp7_0Nw_ZLht78GM";
    static final String APP = "fiscal";
    static final int PORTA = 47120;

    static final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8)).followRedirects(HttpClient.Redirect.NORMAL).build();
    static Path base;
    static Path arquivos;
    static JWindow janela;
    static JProgressBar barra;

    public static void main(String[] args) {
        try {
            executar(args);
        } catch (Throwable t) {
            registrar(t);
            erro("Não foi possível abrir o Fiscal.\n" + t.getMessage());
        }
        System.exit(0);
    }

    static void executar(String[] args) throws Exception {
        base = Paths.get(System.getenv().getOrDefault("LOCALAPPDATA", System.getProperty("user.home")), "Fiscal");
        arquivos = base.resolve("arquivos");
        Files.createDirectories(arquivos);
        Files.createDirectories(base.resolve("logs"));

        long esperar = 0;
        for (String a : args) if (a.startsWith("--esperar=")) esperar = Long.parseLong(a.substring(10));
        if (esperar > 0) {
            Optional<ProcessHandle> p = ProcessHandle.of(esperar);
            if (p.isPresent()) {
                try { p.get().onExit().get(60, java.util.concurrent.TimeUnit.SECONDS); } catch (Exception ignorado) { }
            }
        } else if (jaAberto()) {
            return;
        }

        Map<String, Object> atual = null;
        Path atualArq = base.resolve("atual.json");
        Map<String, Object> remoto = null;
        try { remoto = buscarVersao(); } catch (Exception e) { registrar(e); }

        if (remoto != null) {
            try {
                baixarArquivos(remoto);
                atual = remoto;
                Files.writeString(atualArq, Json.escrever(remoto), StandardCharsets.UTF_8);
            } catch (Exception e) {
                registrar(e);
            }
        }
        fecharJanela();
        Map<String, Object> anterior = null;
        if (Files.exists(atualArq)) {
            try { anterior = Json.objeto(Files.readString(atualArq, StandardCharsets.UTF_8)); } catch (Exception e) { registrar(e); }
        }
        if (atual == null) atual = anterior;
        if (atual == null || !arquivosPresentes(atual)) {
            erro("Não foi possível baixar o Fiscal. Verifique a internet e abra de novo.");
            return;
        }
        abrir(atual);
        limpar(atual);
    }

    static boolean jaAberto() {
        try {
            HttpRequest r = HttpRequest.newBuilder(URI.create("http://127.0.0.1:" + PORTA + "/sistema/frente"))
                    .timeout(Duration.ofSeconds(2)).header("X-Fiscal", "1").POST(HttpRequest.BodyPublishers.noBody()).build();
            return http.send(r, HttpResponse.BodyHandlers.discarding()).statusCode() == 200;
        } catch (Exception e) {
            return false;
        }
    }

    @SuppressWarnings("unchecked")
    static Map<String, Object> buscarVersao() throws Exception {
        HttpRequest r = HttpRequest.newBuilder(URI.create(URL + "/rest/v1/fiscal_app_versao?aplicativo=eq." + APP + "&select=versao,manifesto"))
                .timeout(Duration.ofSeconds(12)).header("apikey", CHAVE).GET().build();
        HttpResponse<String> resp = http.send(r, HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
        if (resp.statusCode() != 200) throw new IOException("versao " + resp.statusCode());
        List<Object> linhas = (List<Object>) Json.ler(resp.body());
        if (linhas.isEmpty()) throw new IOException("sem versao publicada");
        return (Map<String, Object>) linhas.get(0);
    }

    @SuppressWarnings("unchecked")
    static List<Map<String, Object>> lista(Map<String, Object> v) {
        Map<String, Object> m = (Map<String, Object>) v.get("manifesto");
        List<Map<String, Object>> r = new ArrayList<>();
        for (Object o : (List<Object>) m.get("arquivos")) r.add((Map<String, Object>) o);
        Object l = m.get("lancador");
        if (l instanceof Map) r.add((Map<String, Object>) l);
        return r;
    }

    static Path local(Map<String, Object> a) {
        return arquivos.resolve((String) a.get("sha256"));
    }

    static long tamanho(Map<String, Object> a) {
        return ((Number) a.get("tamanho")).longValue();
    }

    static boolean presente(Map<String, Object> a) {
        Path p = local(a);
        try { return Files.exists(p) && Files.size(p) == tamanho(a); } catch (IOException e) { return false; }
    }

    static boolean arquivosPresentes(Map<String, Object> v) {
        for (Map<String, Object> a : lista(v)) if (!presente(a)) return false;
        return true;
    }

    static void baixarArquivos(Map<String, Object> v) throws Exception {
        List<Map<String, Object>> faltam = new ArrayList<>();
        long total = 0;
        for (Map<String, Object> a : lista(v)) if (!presente(a)) { faltam.add(a); total += tamanho(a); }
        if (faltam.isEmpty()) return;
        mostrarJanela();
        long feito = 0;
        for (Map<String, Object> a : faltam) {
            String sha = (String) a.get("sha256");
            Path tmp = arquivos.resolve(sha + ".baixando");
            HttpRequest r = HttpRequest.newBuilder(URI.create(URL + "/storage/v1/object/public/fiscal-app/arquivos/" + sha))
                    .timeout(Duration.ofMinutes(10)).GET().build();
            HttpResponse<InputStream> resp = http.send(r, HttpResponse.BodyHandlers.ofInputStream());
            if (resp.statusCode() != 200) throw new IOException("arquivo " + resp.statusCode());
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            try (InputStream in = resp.body(); OutputStream out = Files.newOutputStream(tmp)) {
                byte[] buf = new byte[65536];
                int n;
                while ((n = in.read(buf)) > 0) {
                    out.write(buf, 0, n);
                    md.update(buf, 0, n);
                    feito += n;
                    progresso(total == 0 ? 100 : (int) (feito * 100 / total));
                }
            }
            if (!hex(md.digest()).equals(sha)) {
                Files.deleteIfExists(tmp);
                throw new IOException("arquivo corrompido " + sha);
            }
            Files.move(tmp, local(a), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
        }
    }

    @SuppressWarnings("unchecked")
    static void abrir(Map<String, Object> v) throws Exception {
        Map<String, Object> m = (Map<String, Object>) v.get("manifesto");
        String javaw = Paths.get(System.getProperty("java.home"), "bin", "javaw.exe").toString();
        if (!new File(javaw).exists()) javaw = Paths.get(System.getProperty("java.home"), "bin", "java").toString();
        List<String> cmd = new ArrayList<>();
        cmd.add(javaw);
        Object jvm = m.get("jvm");
        if (jvm instanceof List) for (Object o : (List<Object>) jvm) cmd.add(String.valueOf(o));
        cmd.add("-Dfiscal.versao=" + v.get("versao"));
        cmd.add("-Dfiscal.base=" + base);
        String exe = System.getProperty("jpackage.app-path");
        if (exe != null) cmd.add("-Dfiscal.lancador=" + exe);
        Object l = m.get("lancador");
        Path meuJar = meuJar();
        if (l instanceof Map && meuJar != null) {
            Map<String, Object> lm = (Map<String, Object>) l;
            if (!lm.get("sha256").equals(sha(meuJar))) {
                cmd.add("-Dfiscal.lancador.novo=" + local(lm));
                cmd.add("-Dfiscal.lancador.jar=" + meuJar);
            }
        }
        StringBuilder cp = new StringBuilder();
        for (Object o : (List<Object>) m.get("arquivos")) {
            if (cp.length() > 0) cp.append(File.pathSeparator);
            cp.append(local((Map<String, Object>) o));
        }
        cmd.add("-cp");
        cmd.add(cp.toString());
        cmd.add((String) m.get("principal"));
        ProcessBuilder pb = new ProcessBuilder(cmd).directory(base.toFile());
        File log = base.resolve("logs").resolve("fiscal.log").toFile();
        pb.redirectErrorStream(true).redirectOutput(ProcessBuilder.Redirect.to(log));
        pb.start();
    }

    static void limpar(Map<String, Object> v) {
        Set<String> manter = new HashSet<>();
        for (Map<String, Object> a : lista(v)) manter.add((String) a.get("sha256"));
        try (DirectoryStream<Path> ds = Files.newDirectoryStream(arquivos)) {
            for (Path p : ds) if (!manter.contains(p.getFileName().toString())) {
                try { Files.deleteIfExists(p); } catch (IOException ignorado) { }
            }
        } catch (IOException ignorado) { }
    }

    static Path meuJar() {
        try {
            Path p = Paths.get(Lancador.class.getProtectionDomain().getCodeSource().getLocation().toURI());
            return Files.isRegularFile(p) ? p : null;
        } catch (Exception e) {
            return null;
        }
    }

    static String sha(Path p) {
        try {
            return hex(MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(p)));
        } catch (Exception e) {
            return "";
        }
    }

    static String hex(byte[] b) {
        StringBuilder s = new StringBuilder();
        for (byte x : b) s.append(String.format("%02x", x));
        return s.toString();
    }

    static void mostrarJanela() {
        try {
            SwingUtilities.invokeAndWait(() -> {
                janela = new JWindow();
                JPanel p = new JPanel(new BorderLayout(0, 14));
                p.setBackground(Color.WHITE);
                p.setBorder(BorderFactory.createCompoundBorder(BorderFactory.createLineBorder(new Color(0xDDDDDD)),
                        BorderFactory.createEmptyBorder(22, 26, 22, 26)));
                java.net.URL u = Lancador.class.getResource("/fiscal-64.png");
                JLabel t = new JLabel("Atualizando o Fiscal", u != null ? new ImageIcon(u) : null, SwingConstants.LEFT);
                t.setIconTextGap(14);
                t.setFont(t.getFont().deriveFont(Font.BOLD, 15f));
                p.add(t, BorderLayout.CENTER);
                barra = new JProgressBar(0, 100);
                barra.setPreferredSize(new Dimension(320, 6));
                barra.setBorderPainted(false);
                barra.setForeground(new Color(0x1F1F1F));
                barra.setBackground(new Color(0xEEEEEE));
                p.add(barra, BorderLayout.SOUTH);
                janela.setContentPane(p);
                janela.pack();
                janela.setLocationRelativeTo(null);
                janela.setAlwaysOnTop(true);
                janela.setVisible(true);
            });
        } catch (Exception ignorado) { }
    }

    static void progresso(int v) {
        if (barra != null) SwingUtilities.invokeLater(() -> barra.setValue(v));
    }

    static void fecharJanela() {
        if (janela != null) SwingUtilities.invokeLater(() -> janela.dispose());
    }

    static void erro(String msg) {
        fecharJanela();
        try { JOptionPane.showMessageDialog(null, msg, "Fiscal", JOptionPane.ERROR_MESSAGE); } catch (Throwable ignorado) { }
    }

    static void registrar(Throwable t) {
        try {
            Path f = (base != null ? base : Paths.get(System.getProperty("java.io.tmpdir"))).resolve("logs").resolve("lancador.log");
            Files.createDirectories(f.getParent());
            StringWriter sw = new StringWriter();
            t.printStackTrace(new PrintWriter(sw));
            Files.writeString(f, new Date() + " " + sw + "\n", StandardCharsets.UTF_8,
                    StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (Exception ignorado) { }
    }
}
