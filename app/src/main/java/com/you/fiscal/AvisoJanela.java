package com.you.fiscal;

import com.fasterxml.jackson.databind.ObjectMapper;

import javax.imageio.ImageIO;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Clip;
import javax.sound.sampled.LineEvent;
import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.geom.Ellipse2D;
import java.awt.geom.RoundRectangle2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.net.URI;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

final class AvisoJanela extends JFrame {

    record Tema(Color fundo, Color fundo2, Color borda, Color texto, Color apagado, Color destaque, Color destaqueTx,
                String rotulo, String abrir, String som) { }

    static final Color LARANJA = new Color(0xFE4901);
    static final Color LARANJA_CL = new Color(0xFFB08A);
    static final Tema WA = new Tema(new Color(0x0e3d2c), new Color(0x12513a), new Color(0x1f7a52), new Color(0xdff5ea),
            new Color(0x9ccbb4), new Color(0x1f8f5a), Color.WHITE, "WhatsApp", "Abrir no WhatsApp", "Windows Notify Messaging.wav");
    static final Tema TEAMS = new Tema(new Color(0x0e2a4d), new Color(0x13386a), new Color(0x1f4f8f), new Color(0xdfe9f8),
            new Color(0xa3b8d9), new Color(0x2f6fed), Color.WHITE, "Team's", "Abrir no Team's", "Windows Message Nudge.wav");
    static final Tema DIRETORIA = new Tema(new Color(0xD9480F), new Color(0xFE6A1F), new Color(0xFFD2B8), Color.WHITE,
            new Color(0xFFE6D6), Color.WHITE, new Color(0xC2410C), "Team's · Diretoria", "Abrir no Team's", "Windows Message Nudge.wav");

    static final Tema LEMBRETE = new Tema(new Color(0x3d1606), new Color(0x55200a), new Color(0xa8380a), new Color(0xffe7da),
            new Color(0xffb99a), new Color(0xFE4901), Color.WHITE, "Lembrete · ROOM", "Concluir", "Windows Notify Calendar.wav");
    static final Tema ALARME = new Tema(new Color(0x4a0f0b), new Color(0x641610), new Color(0xc0392b), new Color(0xffe2de),
            new Color(0xf3a59c), new Color(0xC0392B), Color.WHITE, "Alarme · ROOM", "Concluir", "Alarm01.wav");

    static final int LARG = 376, RAIO = 16, PAD = 14, MAX = 4, ESPACO = 10;
    static final Color[] CORES = {new Color(0xC2410C), new Color(0x2F5DA8), new Color(0x6D4AA0), new Color(0x0E7490),
            new Color(0xB45309), new Color(0x475569), new Color(0x18794A), new Color(0xBE185D)};
    static final List<AvisoJanela> abertos = new ArrayList<>();
    static final ObjectMapper JSON = new ObjectMapper();
    static long ultimoSom;

    final String canal, id, chave;
    final Tema tema;
    String nome, texto, rodape, fotoUrl;
    Instant em, janelaAte;
    boolean podeResponder, somenteLeitura, grupo;
    int quantidade = 1;
    Image foto;

    boolean respondendo, saindo;
    String estado, estadoErro;
    float opacidade;
    int alvoX, alvoY, arrasto, pressX;
    boolean arrastou, sobre;
    javax.swing.Timer anim, sumir, relogio, repetirSom;

    final JPanel painel;
    final JTextField campo = new JTextField();
    Rectangle rFechar, rResponder, rAbrir, rEnviar, rCorpo;

    // entrada
    static void mostrar(Map<String, Object> d) {
        SwingUtilities.invokeLater(() -> {
            Object cv = d.get("canal");
            String canal = "teams".equals(cv) ? "teams" : "lembrete".equals(cv) ? "lembrete" : "alarme".equals(cv) ? "alarme" : "wa";
            String id = String.valueOf(d.get("id"));
            String chave = canal + ":" + id;
            for (AvisoJanela a : abertos) {
                if (a.chave.equals(chave) && !a.saindo) { a.atualizar(d); return; }
            }
            AvisoJanela a = new AvisoJanela(canal, id, d);
            abertos.add(0, a);
            while (abertos.stream().filter(x -> !x.saindo).count() > MAX) {
                AvisoJanela velho = null;
                for (int i = abertos.size() - 1; i >= 0; i--) if (!abertos.get(i).saindo && !abertos.get(i).respondendo && !abertos.get(i).alarme()) { velho = abertos.get(i); break; }
                if (velho == null) break;
                velho.sair(false);
            }
            a.entrar();
            tocar(a.tema);
        });
    }

    static void resultado(String chave, boolean ok, String erro) {
        SwingUtilities.invokeLater(() -> {
            for (AvisoJanela a : abertos) {
                if (!a.chave.equals(chave)) continue;
                if (ok) {
                    a.estado = "Enviada";
                    a.estadoErro = null;
                    a.repaint();
                    javax.swing.Timer t = new javax.swing.Timer(900, e -> a.sair(false));
                    t.setRepeats(false);
                    t.start();
                } else {
                    a.estado = null;
                    a.estadoErro = erro == null || erro.isBlank() ? "Não foi possível enviar." : erro;
                    a.campo.setEnabled(true);
                    a.repaint();
                }
            }
        });
    }

    static void fecharTodos() { SwingUtilities.invokeLater(() -> new ArrayList<>(abertos).forEach(a -> a.sair(false))); }

    AvisoJanela(String canal, String id, Map<String, Object> d) {
        this.canal = canal;
        this.id = id;
        this.chave = canal + ":" + id;
        this.tema = "teams".equals(canal) ? TEAMS : "lembrete".equals(canal) ? LEMBRETE : "alarme".equals(canal) ? ALARME : Boolean.TRUE.equals(d.get("diretoria")) ? DIRETORIA : WA;
        ler(d);
        setUndecorated(true);
        setType(Window.Type.UTILITY);
        setAlwaysOnTop(true);
        setFocusableWindowState(false);
        setBackground(new Color(0, 0, 0, 0));
        painel = new JPanel(null) {
            @Override protected void paintComponent(Graphics g) { desenhar((Graphics2D) g); }
        };
        painel.setOpaque(false);
        setContentPane(painel);
        campo.setBorder(BorderFactory.createEmptyBorder(0, 12, 0, 12));
        campo.setBackground(new Color(255, 255, 255, 236));
        campo.setForeground(new Color(0x16161A));
        campo.setCaretColor(new Color(0x16161A));
        campo.setFont(fonte(Font.PLAIN, 13));
        campo.setVisible(false);
        campo.addActionListener(e -> enviar());
        campo.addKeyListener(new KeyAdapter() {
            @Override public void keyPressed(KeyEvent e) { if (e.getKeyCode() == KeyEvent.VK_ESCAPE) fecharResposta(); }
        });
        campo.getDocument().addDocumentListener(new javax.swing.event.DocumentListener() {
            public void insertUpdate(javax.swing.event.DocumentEvent e) { repaint(); }
            public void removeUpdate(javax.swing.event.DocumentEvent e) { repaint(); }
            public void changedUpdate(javax.swing.event.DocumentEvent e) { repaint(); }
        });
        painel.add(campo);
        ouvirMouse();
        dimensionar();
        carregarFoto();
        relogio = new javax.swing.Timer(30000, e -> repaint());
        relogio.start();
    }

    void ler(Map<String, Object> d) {
        nome = txt(d.get("nome"), "Contato");
        texto = txt(d.get("texto"), "");
        rodape = txt(d.get("rodape"), "");
        em = instante(d.get("em"));
        if (em == null) em = Instant.now();
        janelaAte = instante(d.get("janelaAte"));
        podeResponder = Boolean.TRUE.equals(d.get("podeResponder"));
        somenteLeitura = Boolean.TRUE.equals(d.get("somenteLeitura"));
        grupo = Boolean.TRUE.equals(d.get("grupo"));
        String f = txt(d.get("foto"), "");
        if (!f.equals(fotoUrl == null ? "" : fotoUrl)) { fotoUrl = f.isEmpty() ? null : f; foto = null; }
    }

    void atualizar(Map<String, Object> d) {
        String velhaFoto = fotoUrl;
        ler(d);
        quantidade++;
        if (fotoUrl != null && !fotoUrl.equals(velhaFoto)) carregarFoto();
        if (!respondendo) reiniciarSumir(9000);
        dimensionar();
        posicionarTodos(true);
        balancar();
        if (System.currentTimeMillis() - ultimoSom > 2500) tocar(tema);
        repaint();
    }

    boolean room() { return "lembrete".equals(canal) || "alarme".equals(canal); }

    boolean alarme() { return "alarme".equals(canal); }

    static String txt(Object o, String padrao) { return o == null || String.valueOf(o).isBlank() || "null".equals(String.valueOf(o)) ? padrao : String.valueOf(o); }

    static Instant instante(Object o) {
        if (o == null) return null;
        try { return java.time.OffsetDateTime.parse(String.valueOf(o)).toInstant(); } catch (Exception e) { }
        try { return Instant.parse(String.valueOf(o)); } catch (Exception e) { return null; }
    }

    static Font fonte(int estilo, float tam) { return new Font("Segoe UI", estilo, 1).deriveFont(estilo, tam); }

    // medidas
    int alturaTexto() { return Math.max(46, 20 + linhas().size() * 18); }

    List<String> linhas() {
        FontMetrics fm = painel.getFontMetrics(fonte(Font.PLAIN, 13));
        return quebrar(texto, fm, LARG - PAD - 60 - PAD, 2);
    }

    boolean temChip() { return "wa".equals(canal) && !grupo || somenteLeitura || !rodape.isEmpty(); }

    int altura() {
        int h = PAD + 18 + 10 + alturaTexto();
        if (temChip()) h += 8 + 22;
        h += 12 + 32 + PAD;
        if (estadoErro != null || estado != null) h += 18;
        return h;
    }

    void dimensionar() {
        int h = altura();
        setSize(LARG, h);
        int yBot = h - PAD - 32;
        if (estadoErro != null || estado != null) yBot -= 18;
        rFechar = new Rectangle(LARG - PAD - 20, PAD - 2, 22, 22);
        int larguraBtn = (LARG - PAD * 2 - 8) / 2;
        boolean responde = room() || podeResponder && janelaAberta();
        if (responde) {
            rResponder = new Rectangle(PAD, yBot, larguraBtn, 32);
            rAbrir = new Rectangle(PAD + larguraBtn + 8, yBot, larguraBtn, 32);
        } else {
            rResponder = null;
            rAbrir = new Rectangle(PAD, yBot, LARG - PAD * 2, 32);
        }
        rEnviar = new Rectangle(LARG - PAD - 36, yBot - 2, 36, 36);
        campo.setBounds(PAD, yBot - 2, LARG - PAD * 2 - 44, 36);
        rCorpo = new Rectangle(0, 0, LARG, yBot - 6);
    }

    boolean janelaAberta() {
        if (!"wa".equals(canal) || grupo) return true;
        return janelaAte != null && janelaAte.isAfter(Instant.now());
    }

    // desenho
    void desenhar(Graphics2D g0) {
        Graphics2D g = (Graphics2D) g0.create();
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_LCD_HRGB);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        int w = getWidth(), h = getHeight();
        RoundRectangle2D forma = new RoundRectangle2D.Float(0.5f, 0.5f, w - 1, h - 1, RAIO * 2, RAIO * 2);
        g.setPaint(new GradientPaint(0, 0, tema.fundo2, 0, h, tema.fundo));
        g.fill(forma);
        g.setClip(forma);
        Color acento = tema == DIRETORIA ? new Color(255, 255, 255, 0) : new Color(254, 73, 1, 0);
        g.setPaint(new GradientPaint(0, 0, tema == DIRETORIA ? new Color(255, 255, 255, 90) : new Color(254, 73, 1, 60), w * 0.55f, 0, acento));
        g.fillRect(0, 0, w, 3);
        g.setColor(tema == DIRETORIA ? new Color(255, 255, 255, 200) : new Color(254, 73, 1, 150));
        g.fillRoundRect(0, RAIO, 3, h - RAIO * 2, 3, 3);
        g.setClip(null);
        g.setColor(tema.borda);
        g.setStroke(new BasicStroke(1f));
        g.draw(forma);

        int y = PAD;
        g.setColor(tema.destaque);
        g.fill(new Ellipse2D.Float(PAD, y + 4, 9, 9));
        g.setColor(new Color(255, 176, 138, 230));
        g.fill(new Ellipse2D.Float(PAD + 6, y + 1, 5, 5));
        g.setFont(fonte(Font.BOLD, 11.5f));
        g.setColor(tema.texto);
        g.drawString(tema.rotulo, PAD + 16, y + 13);
        int xr = PAD + 16 + g.getFontMetrics().stringWidth(tema.rotulo);
        g.setFont(fonte(Font.PLAIN, 11.5f));
        g.setColor(tema.apagado);
        g.drawString("  ·  " + quando(), xr, y + 13);
        desenharX(g, rFechar);

        y += 18 + 10;
        int av = 46;
        desenharAvatar(g, PAD, y, av);
        int xt = PAD + av + 14;
        int larguraTexto = LARG - xt - PAD;
        g.setFont(fonte(Font.BOLD, 14));
        FontMetrics fn = g.getFontMetrics();
        int espacoBadge = quantidade > 1 ? 34 : 0;
        String n = cortar(nome, fn, larguraTexto - espacoBadge);
        g.setColor(Color.WHITE);
        g.drawString(n, xt, y + 15);
        if (quantidade > 1) {
            String q = quantidade > 99 ? "99+" : String.valueOf(quantidade);
            g.setFont(fonte(Font.BOLD, 10.5f));
            int bw = Math.max(20, g.getFontMetrics().stringWidth(q) + 10);
            int bx = xt + fn.stringWidth(n) + 8;
            g.setColor(tema == DIRETORIA ? Color.WHITE : LARANJA);
            g.fillRoundRect(bx, y + 2, bw, 17, 17, 17);
            g.setColor(tema == DIRETORIA ? tema.destaqueTx : Color.WHITE);
            g.drawString(q, bx + (bw - g.getFontMetrics().stringWidth(q)) / 2, y + 14);
        }
        g.setFont(fonte(Font.PLAIN, 13));
        g.setColor(tema.texto);
        int yl = y + 34;
        for (String l : linhas()) { g.drawString(l, xt, yl); yl += 18; }

        y += alturaTexto();
        if (temChip()) {
            y += 8;
            int x = PAD;
            String chip = chipTexto();
            if (chip != null) {
                g.setFont(fonte(Font.BOLD, 11));
                int cw = g.getFontMetrics().stringWidth(chip) + 22;
                boolean aberta = janelaAberta() && !somenteLeitura;
                g.setColor(aberta ? (tema == DIRETORIA ? new Color(255, 255, 255, 40) : new Color(254, 73, 1, 46)) : new Color(255, 255, 255, 22));
                g.fillRoundRect(x, y, cw, 22, 22, 22);
                g.setColor(aberta ? (tema == DIRETORIA ? new Color(255, 255, 255, 140) : new Color(254, 73, 1, 120)) : new Color(255, 255, 255, 40));
                g.drawRoundRect(x, y, cw - 1, 21, 22, 22);
                g.setColor(aberta ? (tema == DIRETORIA ? Color.WHITE : LARANJA_CL) : tema.apagado);
                g.fill(new Ellipse2D.Float(x + 8, y + 8, 6, 6));
                g.drawString(chip, x + 18, y + 15);
                x += cw + 8;
            }
            if (!rodape.isEmpty()) {
                g.setFont(fonte(Font.PLAIN, 11.5f));
                g.setColor(tema.apagado);
                g.drawString(cortar(rodape, g.getFontMetrics(), LARG - PAD - x), x, y + 15);
            }
        }

        if (respondendo) {
            desenharEnviar(g, rEnviar);
        } else {
            if (rResponder != null) desenharBotao(g, rResponder, room() ? (alarme() ? "Adiar 5 min" : "Adiar 15 min") : "Responder", false);
            desenharBotao(g, rAbrir, tema.abrir, true);
        }
        if (estado != null || estadoErro != null) {
            g.setFont(fonte(Font.PLAIN, 11.5f));
            g.setColor(estadoErro != null ? (tema == DIRETORIA ? Color.WHITE : new Color(0xFF8A80)) : (tema == DIRETORIA ? Color.WHITE : LARANJA_CL));
            g.drawString(cortar(estadoErro != null ? estadoErro : estado, g.getFontMetrics(), LARG - PAD * 2), PAD, h - PAD - 2);
        }
        g.dispose();
    }

    String chipTexto() {
        if (somenteLeitura) return "Somente leitura";
        if (!"wa".equals(canal) || grupo) return null;
        if (janelaAte == null || !janelaAte.isAfter(Instant.now())) return "Janela fechada";
        long min = Math.max(1, Duration.between(Instant.now(), janelaAte).toMinutes());
        return min >= 60 ? "Janela aberta · " + (min / 60) + "h" + String.format("%02d", min % 60) : "Janela aberta · " + min + "min";
    }

    String quando() {
        ZonedDateTime z = em.atZone(ZoneId.systemDefault());
        LocalDate hoje = LocalDate.now();
        String hora = z.format(DateTimeFormatter.ofPattern("HH:mm"));
        if (z.toLocalDate().equals(hoje)) return "Hoje, " + hora;
        if (z.toLocalDate().equals(hoje.minusDays(1))) return "Ontem, " + hora;
        return z.format(DateTimeFormatter.ofPattern("dd/MM")) + ", " + hora;
    }

    void desenharAvatar(Graphics2D g, int x, int y, int s) {
        Shape c = new Ellipse2D.Float(x, y, s, s);
        if (room()) {
            g.setColor(tema.destaque);
            g.fill(c);
            g.setColor(Color.WHITE);
            g.setStroke(new BasicStroke(2.2f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
            int cx = x + s / 2, cy = y + s / 2 + 1, r = s / 2 - 12;
            g.drawOval(cx - r, cy - r, r * 2, r * 2);
            g.drawLine(cx, cy, cx, cy - r + 4);
            g.drawLine(cx, cy, cx + r - 5, cy + 2);
            if (alarme()) { g.drawLine(x + 9, y + 12, x + 15, y + 7); g.drawLine(x + s - 9, y + 12, x + s - 15, y + 7); }
            g.setStroke(new BasicStroke(1f));
            return;
        }
        if (foto != null) {
            Shape antes = g.getClip();
            g.setClip(c);
            g.drawImage(foto, x, y, s, s, null);
            g.setClip(antes);
        } else {
            int hsh = 0;
            for (char ch : nome.toCharArray()) hsh = hsh * 31 + ch;
            g.setColor(CORES[Math.floorMod(hsh, CORES.length)]);
            g.fill(c);
            g.setColor(Color.WHITE);
            g.setFont(fonte(Font.BOLD, 15));
            String ini = iniciais(nome);
            FontMetrics fm = g.getFontMetrics();
            g.drawString(ini, x + (s - fm.stringWidth(ini)) / 2, y + (s + fm.getAscent() - fm.getDescent()) / 2);
        }
        g.setColor(new Color(255, 255, 255, 60));
        g.draw(c);
        g.setColor(tema.fundo);
        g.fill(new Ellipse2D.Float(x + s - 15, y + s - 15, 16, 16));
        g.setColor(tema.destaque);
        g.fill(new Ellipse2D.Float(x + s - 13, y + s - 13, 12, 12));
    }

    static String iniciais(String n) {
        String[] p = n.replaceAll("[^\\p{L}\\s]", " ").trim().split("\\s+");
        if (p.length == 0 || p[0].isEmpty()) {
            String dig = n.replaceAll("\\D", "");
            return dig.length() >= 2 ? dig.substring(dig.length() - 2) : "?";
        }
        String r = p[0].substring(0, 1) + (p.length > 1 ? p[p.length - 1].substring(0, 1) : "");
        return r.toUpperCase();
    }

    void desenharX(Graphics2D g, Rectangle r) {
        if (sobreRet(r)) {
            g.setColor(new Color(255, 255, 255, 30));
            g.fillOval(r.x, r.y, r.width, r.height);
        }
        g.setColor(tema.apagado);
        g.setStroke(new BasicStroke(1.6f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        int cx = r.x + r.width / 2, cy = r.y + r.height / 2;
        g.drawLine(cx - 4, cy - 4, cx + 4, cy + 4);
        g.drawLine(cx + 4, cy - 4, cx - 4, cy + 4);
        g.setStroke(new BasicStroke(1f));
    }

    void desenharBotao(Graphics2D g, Rectangle r, String t, boolean cheio) {
        boolean s = sobreRet(r);
        if (cheio) {
            g.setColor(s ? tema.destaque.brighter() : tema.destaque);
            g.fillRoundRect(r.x, r.y, r.width, r.height, 12, 12);
        } else {
            g.setColor(new Color(255, 255, 255, s ? 34 : 18));
            g.fillRoundRect(r.x, r.y, r.width, r.height, 12, 12);
            g.setColor(new Color(255, 255, 255, 50));
            g.drawRoundRect(r.x, r.y, r.width - 1, r.height - 1, 12, 12);
        }
        g.setFont(fonte(Font.BOLD, 12.5f));
        FontMetrics fm = g.getFontMetrics();
        g.setColor(cheio ? tema.destaqueTx : tema.texto);
        String tc = cortar(t, fm, r.width - 16);
        g.drawString(tc, r.x + (r.width - fm.stringWidth(tc)) / 2, r.y + (r.height + fm.getAscent() - fm.getDescent()) / 2);
    }

    void desenharEnviar(Graphics2D g, Rectangle r) {
        boolean pode = campo.isEnabled() && !campo.getText().isBlank();
        Color base = tema == DIRETORIA ? Color.WHITE : LARANJA;
        g.setColor(pode ? (sobreRet(r) && tema != DIRETORIA ? base.brighter() : base) : new Color(255, 255, 255, 40));
        g.fillOval(r.x, r.y, r.width, r.height);
        g.setColor(tema == DIRETORIA && pode ? tema.destaqueTx : Color.WHITE);
        g.setStroke(new BasicStroke(1.8f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        int cx = r.x + r.width / 2, cy = r.y + r.height / 2;
        int[] xs = {cx - 7, cx + 8, cx - 7, cx - 4};
        int[] ys = {cy - 7, cy, cy + 7, cy};
        g.drawPolygon(xs, ys, 4);
        g.setStroke(new BasicStroke(1f));
    }

    Point mouse;

    boolean sobreRet(Rectangle r) { return r != null && mouse != null && r.contains(mouse); }

    static List<String> quebrar(String t, FontMetrics fm, int largura, int max) {
        List<String> out = new ArrayList<>();
        String s = t.replace('\n', ' ').replaceAll("\\s+", " ").trim();
        while (!s.isEmpty() && out.size() < max) {
            if (fm.stringWidth(s) <= largura) { out.add(s); s = ""; break; }
            int corte = s.length();
            while (corte > 1 && fm.stringWidth(s.substring(0, corte)) > largura) corte--;
            int esp = s.lastIndexOf(' ', corte);
            if (esp > corte / 2) corte = esp;
            if (out.size() == max - 1) { out.add(cortar(s, fm, largura)); s = ""; break; }
            out.add(s.substring(0, corte).trim());
            s = s.substring(corte).trim();
        }
        return out;
    }

    static String cortar(String t, FontMetrics fm, int largura) {
        if (fm.stringWidth(t) <= largura) return t;
        String r = t;
        while (r.length() > 1 && fm.stringWidth(r + "…") > largura) r = r.substring(0, r.length() - 1);
        return r.trim() + "…";
    }

    // foto
    void carregarFoto() {
        String u = fotoUrl;
        if (u == null || !u.startsWith("https://")) return;
        new Thread(() -> {
            try {
                BufferedImage img = ImageIO.read(URI.create(u).toURL());
                if (img == null) return;
                int s = Math.min(img.getWidth(), img.getHeight());
                BufferedImage q = img.getSubimage((img.getWidth() - s) / 2, (img.getHeight() - s) / 2, s, s);
                Image f = q.getScaledInstance(92, 92, Image.SCALE_SMOOTH);
                SwingUtilities.invokeLater(() -> { if (u.equals(fotoUrl)) { foto = f; repaint(); } });
            } catch (Exception ignorado) { }
        }, "aviso-foto").start();
    }

    // som
    static void tocar(Tema t) {
        ultimoSom = System.currentTimeMillis();
        new Thread(() -> {
            try {
                File f = new File(System.getenv().getOrDefault("WINDIR", "C:\\Windows"), "Media\\" + t.som);
                if (!f.exists()) f = new File(System.getenv().getOrDefault("WINDIR", "C:\\Windows"), "Media\\Windows Notify.wav");
                if (!f.exists()) { Toolkit.getDefaultToolkit().beep(); return; }
                AudioInputStream in = AudioSystem.getAudioInputStream(f);
                Clip c = AudioSystem.getClip();
                c.addLineListener(e -> { if (e.getType() == LineEvent.Type.STOP) c.close(); });
                c.open(in);
                c.start();
            } catch (Exception e) {
                Toolkit.getDefaultToolkit().beep();
            }
        }, "aviso-som").start();
    }

    // posicao e movimento
    static Rectangle area() {
        return GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds();
    }

    static void posicionarTodos(boolean animar) {
        Rectangle a = area();
        int y = a.y + a.height - 12;
        for (AvisoJanela j : abertos) {
            if (j.saindo) continue;
            y -= j.getHeight();
            j.alvoY = y;
            j.alvoX = a.x + a.width - LARG - 12;
            if (animar && j.isVisible()) j.deslizarPara(j.alvoX + j.arrasto, y, 220, null);
            y -= ESPACO;
        }
    }

    void entrar() {
        Rectangle a = area();
        if (alarme()) {
            repetirSom = new javax.swing.Timer(7000, e -> { if (!saindo) tocar(tema); });
            repetirSom.start();
        }
        posicionarTodos(true);
        opacidade = 0f;
        setOpacity(0f);
        setLocation(a.x + a.width, alvoY);
        setVisible(true);
        deslizarPara(alvoX, alvoY, 300, null);
        reiniciarSumir(9000);
    }

    void deslizarPara(int x, int y, int ms, Runnable fim) {
        if (anim != null) anim.stop();
        int x0 = getX(), y0 = getY();
        float o0 = opacidade, o1 = saindo ? 0f : 1f;
        long ini = System.nanoTime();
        anim = new javax.swing.Timer(12, null);
        anim.addActionListener(e -> {
            double p = Math.min(1, (System.nanoTime() - ini) / 1e6 / ms);
            double k = saindo ? p * p : 1 - Math.pow(1 - p, 3);
            setLocation((int) Math.round(x0 + (x - x0) * k), (int) Math.round(y0 + (y - y0) * k));
            opacidade = (float) (o0 + (o1 - o0) * k);
            try { setOpacity(Math.max(0f, Math.min(1f, opacidade))); } catch (Exception ignorado) { }
            if (p >= 1) { anim.stop(); if (fim != null) fim.run(); }
        });
        anim.start();
    }

    void balancar() {
        if (anim != null && anim.isRunning()) return;
        int x = getX();
        long ini = System.nanoTime();
        javax.swing.Timer t = new javax.swing.Timer(12, null);
        t.addActionListener(e -> {
            double p = Math.min(1, (System.nanoTime() - ini) / 1e6 / 320);
            setLocation(x - (int) Math.round(Math.sin(p * Math.PI) * 8), getY());
            if (p >= 1) t.stop();
        });
        t.start();
    }

    void sair(boolean pelaDireita) {
        if (saindo) return;
        saindo = true;
        if (sumir != null) sumir.stop();
        if (relogio != null) relogio.stop();
        if (repetirSom != null) repetirSom.stop();
        Rectangle a = area();
        deslizarPara(a.x + a.width + 20, getY(), pelaDireita ? 180 : 240, () -> {
            setVisible(false);
            dispose();
            abertos.remove(this);
            posicionarTodos(true);
        });
        posicionarTodos(true);
    }

    void reiniciarSumir(int ms) {
        if (sumir != null) sumir.stop();
        if (alarme()) return;
        if ("lembrete".equals(canal)) ms = Math.max(ms, 14000);
        sumir = new javax.swing.Timer(ms, e -> { if (!sobre && !respondendo) sair(false); });
        sumir.setRepeats(false);
        sumir.start();
    }

    // mouse
    void ouvirMouse() {
        MouseAdapter m = new MouseAdapter() {
            @Override public void mouseEntered(MouseEvent e) { sobre = true; if (sumir != null) sumir.stop(); }
            @Override public void mouseExited(MouseEvent e) {
                Point p = e.getPoint();
                if (p.x >= 0 && p.y >= 0 && p.x < getWidth() && p.y < getHeight()) return;
                sobre = false;
                mouse = null;
                repaint();
                if (!respondendo && !saindo) reiniciarSumir(4000);
            }
            @Override public void mouseMoved(MouseEvent e) {
                mouse = e.getPoint();
                boolean mao = sobreRet(rFechar) || sobreRet(respondendo ? rEnviar : rAbrir) || (!respondendo && sobreRet(rResponder)) || sobreRet(rCorpo);
                painel.setCursor(Cursor.getPredefinedCursor(mao ? Cursor.HAND_CURSOR : Cursor.DEFAULT_CURSOR));
                repaint();
            }
            @Override public void mousePressed(MouseEvent e) {
                if (SwingUtilities.isRightMouseButton(e)) { menu(e); return; }
                pressX = e.getXOnScreen();
                arrastou = false;
                arrasto = 0;
            }
            @Override public void mouseDragged(MouseEvent e) {
                if (!SwingUtilities.isLeftMouseButton(e) || saindo) return;
                int dx = Math.max(0, e.getXOnScreen() - pressX);
                if (dx > 6) arrastou = true;
                if (!arrastou) return;
                arrasto = dx;
                setLocation(alvoX + dx, getY());
                opacidade = Math.max(0.25f, 1f - dx / (float) LARG);
                try { setOpacity(opacidade); } catch (Exception ignorado) { }
            }
            @Override public void mouseReleased(MouseEvent e) {
                if (SwingUtilities.isRightMouseButton(e)) return;
                if (arrastou) {
                    if (arrasto > LARG * 0.28) { if (alarme()) acao("adiar5", null); sair(true); }
                    else { arrasto = 0; opacidade = Math.max(opacidade, 0.3f); deslizarPara(alvoX, alvoY, 200, null); }
                    arrastou = false;
                    return;
                }
                clicar(e.getPoint());
            }
        };
        painel.addMouseListener(m);
        painel.addMouseMotionListener(m);
    }

    void clicar(Point p) {
        if (room()) {
            if (rFechar.contains(p)) { if (alarme()) acao("adiar5", null); sair(false); return; }
            if (rResponder != null && rResponder.contains(p)) { acao("adiar", null); sair(false); return; }
            if (rAbrir.contains(p)) { acao("concluir", null); sair(false); return; }
            if (rCorpo.contains(p)) { acao("abrir", null); FiscalApplication.mostrar(); }
            return;
        }
        if (rFechar.contains(p)) { sair(false); return; }
        if (respondendo) {
            if (rEnviar.contains(p)) enviar();
            return;
        }
        if (rResponder != null && rResponder.contains(p)) { abrirResposta(); return; }
        if (rAbrir.contains(p) || rCorpo.contains(p)) { acao("abrir", null); FiscalApplication.mostrar(); sair(false); }
    }

    void menu(MouseEvent e) {
        JPopupMenu pm = new JPopupMenu();
        if (room()) {
            JMenuItem ab = new JMenuItem("Abrir o ROOM");
            ab.addActionListener(x -> { acao("abrir", null); FiscalApplication.mostrar(); });
            pm.add(ab);
            pm.show(painel, e.getX(), e.getY());
            return;
        }
        JMenuItem lida = new JMenuItem("Marcar como lida");
        lida.addActionListener(x -> { acao("lida", null); sair(false); });
        pm.add(lida);
        if ("wa".equals(canal)) {
            JMenuItem sil = new JMenuItem("Silenciar conversa");
            sil.addActionListener(x -> { acao("silenciar", null); sair(false); });
            pm.add(sil);
        }
        pm.addSeparator();
        JMenuItem todos = new JMenuItem("Fechar todos os avisos");
        todos.addActionListener(x -> fecharTodos());
        pm.add(todos);
        pm.show(painel, e.getX(), e.getY());
    }

    // resposta
    void abrirResposta() {
        respondendo = true;
        estado = null;
        estadoErro = null;
        if (sumir != null) sumir.stop();
        setFocusableWindowState(true);
        campo.setVisible(true);
        campo.setEnabled(true);
        campo.setText("");
        dimensionar();
        repaint();
        toFront();
        requestFocus();
        SwingUtilities.invokeLater(() -> { campo.requestFocusInWindow(); campo.requestFocus(); });
    }

    void fecharResposta() {
        respondendo = false;
        campo.setVisible(false);
        setFocusableWindowState(false);
        estadoErro = null;
        dimensionar();
        repaint();
        reiniciarSumir(5000);
    }

    void enviar() {
        String t = campo.getText().trim();
        if (t.isEmpty() || !campo.isEnabled()) return;
        campo.setEnabled(false);
        estado = "Enviando…";
        estadoErro = null;
        int h0 = getHeight();
        dimensionar();
        if (getHeight() != h0) posicionarTodos(true);
        repaint();
        acao("responder", t);
    }

    void acao(String a, String texto) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("canal", canal);
        m.put("id", id);
        m.put("chave", chave);
        m.put("acao", a);
        if (texto != null) m.put("texto", texto);
        try {
            FiscalApplication.js("window.fiscalAvisoAcao&&window.fiscalAvisoAcao(" + JSON.writeValueAsString(m) + ")");
        } catch (Exception ignorado) { }
    }
}
