import hashlib, json, mimetypes, os, subprocess, threading, time, urllib.request
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

BASE = os.environ.get('APP_BASE', '/opt/app-web')
PORTA = int(os.environ.get('APP_PORTA', '7891'))
CANAIS = {'teste': 'main', 'estavel': 'app-estavel'}
SUB = 'app/src/main/resources/static'
FORA = ('teams-web/',)
TIPOS = {'.js': 'application/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.html': 'text/html; charset=utf-8',
         '.png': 'image/png', '.svg': 'image/svg+xml', '.json': 'application/json', '.woff2': 'font/woff2', '.ico': 'image/x-icon'}
AUTH_URL = os.environ.get('APP_AUTH_URL', 'https://wfqcoocfastgsfgegpcm.supabase.co')
AUTH_CHAVE = os.environ.get('APP_AUTH_CHAVE', 'sb_publishable_88ukR4t1KNTc73DxbF6-Pw_0CKW16Fe')
validos = {}
trava = threading.Lock()
ultima = [0.0]
manifestos = {}


def repo(canal):
    return os.path.join(BASE, canal)


def pasta(canal):
    return os.path.realpath(os.path.join(repo(canal), SUB))


def assinatura():
    try:
        return hashlib.sha256(open(os.path.abspath(__file__), 'rb').read()).hexdigest()
    except OSError:
        return ''


PROPRIO = assinatura()


def montar_manifesto(canal):
    raiz = pasta(canal)
    itens = []
    if os.path.isdir(raiz):
        for dirpath, _, nomes in os.walk(raiz):
            for n in nomes:
                cam = os.path.join(dirpath, n)
                rel = os.path.relpath(cam, raiz).replace(os.sep, '/')
                if rel.startswith(FORA):
                    continue
                corpo = open(cam, 'rb').read()
                itens.append({'caminho': rel, 'sha256': hashlib.sha256(corpo).hexdigest(), 'tamanho': len(corpo)})
    itens.sort(key=lambda x: x['caminho'])
    commit = subprocess.run(['git', '-C', repo(canal), 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True).stdout.strip()
    manifestos[canal] = json.dumps({'canal': canal, 'commit': commit, 'arquivos': itens}).encode('utf-8')


def atualizar():
    with trava:
        for canal, ramo in CANAIS.items():
            r = repo(canal)
            if not os.path.isdir(os.path.join(r, '.git')):
                continue
            subprocess.run(['git', '-C', r, 'fetch', '--depth', '1', 'origin', ramo], timeout=120, check=False)
            subprocess.run(['git', '-C', r, 'reset', '--hard', 'FETCH_HEAD'], timeout=60, check=False)
            montar_manifesto(canal)
        if assinatura() != PROPRIO:
            os._exit(0)


def logado(cabecalho):
    if not cabecalho.startswith('Bearer ') or len(cabecalho) > 8192:
        return False
    token = cabecalho[7:].strip()
    chave = hashlib.sha256(token.encode('utf-8')).hexdigest()
    agora = time.time()
    if validos.get(chave, 0) > agora:
        return True
    pedido = urllib.request.Request(AUTH_URL + '/auth/v1/user', headers={'apikey': AUTH_CHAVE, 'Authorization': 'Bearer ' + token})
    try:
        with urllib.request.urlopen(pedido, timeout=8) as r:
            ok = r.status == 200 and bool(json.loads(r.read() or b'{}').get('id'))
    except Exception:
        ok = False
    if ok:
        if len(validos) > 5000:
            validos.clear()
        validos[chave] = agora + 300
    return ok


class Pedido(BaseHTTPRequestHandler):
    server_version = 'app-web'
    sys_version = ''

    def log_message(self, *a):
        pass

    def responder(self, codigo, corpo=b'', tipo='text/plain; charset=utf-8', extra=None):
        self.send_response(codigo)
        self.send_header('Content-Type', tipo)
        self.send_header('Content-Length', str(len(corpo)))
        self.send_header('X-Content-Type-Options', 'nosniff')
        for k, v in (extra or {}).items():
            self.send_header(k, v)
        self.end_headers()
        if self.command != 'HEAD':
            self.wfile.write(corpo)

    def do_GET(self):
        partes = self.path.split('?', 1)[0].lstrip('/').split('/', 1)
        canal = partes[0]
        if canal not in CANAIS or self.headers.get('Sec-Fetch-Dest', '') in ('document', 'iframe', 'frame', 'embed', 'object') or not logado(self.headers.get('Authorization', '')):
            return self.responder(404, b'nao encontrado')
        resto = partes[1] if len(partes) > 1 else ''
        if resto == 'manifesto.json':
            corpo = manifestos.get(canal)
            if not corpo:
                return self.responder(404, b'nao encontrado')
            return self.responder(200, corpo, 'application/json', {'Cache-Control': 'no-cache, no-transform'})
        raiz = pasta(canal)
        alvo = os.path.realpath(os.path.join(raiz, resto))
        rel = os.path.relpath(alvo, raiz).replace(os.sep, '/')
        if not resto or not alvo.startswith(raiz + os.sep) or rel.startswith(FORA) or not os.path.isfile(alvo):
            return self.responder(404, b'nao encontrado')
        corpo = open(alvo, 'rb').read()
        tipo = TIPOS.get(os.path.splitext(alvo)[1]) or mimetypes.guess_type(alvo)[0] or 'application/octet-stream'
        self.responder(200, corpo, tipo, {'Cache-Control': 'no-cache, no-transform', 'ETag': '"' + hashlib.sha256(corpo).hexdigest()[:32] + '"'})

    do_HEAD = do_GET

    def do_POST(self):
        if self.path.split('?', 1)[0] != '/_atualizar':
            return self.responder(404, b'nao encontrado')
        if time.time() - ultima[0] < 15:
            return self.responder(404, b'nao encontrado')
        ultima[0] = time.time()
        threading.Thread(target=atualizar, daemon=True).start()
        self.responder(404, b'nao encontrado')


if __name__ == '__main__':
    atualizar()
    ThreadingHTTPServer(('127.0.0.1', PORTA), Pedido).serve_forever()
