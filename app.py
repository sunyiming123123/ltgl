from flask import Flask

app = Flask(__name__)


@app.route("/")
def index():
    return "<h1>ltgl 服务运行中</h1><p>云服务器 Docker 访问成功！</p>"


@app.route("/health")
def health():
    return {"status": "ok"}
