const vscode = require("vscode");
const { LanguageClient, TransportKind } = require("vscode-languageclient/node");
const path = require("path");

let client;

function activate(context) {
  const serverModule = path.join(context.extensionPath, "server.cjs");

  const serverOptions = {
    run: { module: serverModule, transport: TransportKind.stdio },
    debug: { module: serverModule, transport: TransportKind.stdio },
  };

  const clientOptions = {
    documentSelector: [{ scheme: "file", language: "purescript" }],
  };

  client = new LanguageClient(
    "supabasePurescript",
    "Supabase PureScript",
    serverOptions,
    clientOptions
  );

  client.start();
}

function deactivate() {
  if (client) return client.stop();
}

module.exports = { activate, deactivate };
