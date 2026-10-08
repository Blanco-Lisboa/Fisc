import hashlib, mimetypes, os, subprocess, threading, time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

REPO = os.environ.get('TEAMS_REPO', '/opt/teams-web/repo')
PASTA = os.path.realpath(os.path.join(REPO, 'app/src/main/resources/static/teams-web'))
PORTA = int(os.environ.get('TEAMS_PORTA', '7890'))
TIPOS = {'.js': 'application/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.png': 'image/png', '.svg': 'image/svg+xml', '.json': 'application/json'}
trava = threading.Lock()
ultima = [0.0]


def assinatura():
    try:
        return hashlib.sha256(open(os.path.abspath(__file__), 'rb').read()).hexdigest()
    except OSError:
        return ''


PROPRIO = assinatura()


def atualizar():
    with trava:
        subprocess.run(['git', '-C', REPO, 'fetch', '--depth', '1', 'origin', 'main'], timeout=120, check=False)
        subprocess.run(['git', '-C', REPO, 'reset', '--hard', 'origin/main'], timeout=60, check=False)
        if assinatura() != PROPRIO:
            os._exit(0)


class Pedido(BaseHTTPRequestHandler):
    server_version = 'teams-web'
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
        caminho = self.path.split('?', 1)[0].lstrip('/')
        if not caminho or self.headers.get('Sec-Fetch-Dest', '') in ('document', 'iframe', 'frame', 'embed', 'object'):
            return self.responder(404, b'nao encontrado')
        alvo = os.path.realpath(os.path.join(PASTA, caminho))
        if not alvo.startswith(PASTA + os.sep) or not os.path.isfile(alvo):
            return self.responder(404, b'nao encontrado')
        corpo = open(alvo, 'rb').read()
        etag = '"' + hashlib.sha256(corpo).hexdigest()[:32] + '"'
        cab = {'Cache-Control': 'no-cache', 'ETag': etag, 'Access-Control-Allow-Origin': '*'}
        if self.headers.get('If-None-Match') == etag:
            self.send_response(304)
            for k, v in cab.items():
                self.send_header(k, v)
            self.end_headers()
            return
        tipo = TIPOS.get(os.path.splitext(alvo)[1]) or mimetypes.guess_type(alvo)[0] or 'application/octet-stream'
        self.responder(200, corpo, tipo, cab)

    do_HEAD = do_GET

    def do_POST(self):
        if self.path.split('?', 1)[0] != '/_atualizar':
            return self.responder(404, b'nao encontrado')
        if time.time() - ultima[0] < 15:
            return self.responder(429, b'aguarde')
        ultima[0] = time.time()
        threading.Thread(target=atualizar, daemon=True).start()
        self.responder(202, b'atualizando')


if __name__ == '__main__':
    atualizar()
    ThreadingHTTPServer(('127.0.0.1', PORTA), Pedido).serve_forever()
