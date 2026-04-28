const vscode = require("vscode");
const { LanguageClient, TransportKind } = require("vscode-languageclient/node");
const path = require("path");
const fs = require("fs");

let client;

function findServer(context) {
  // Check user config
  const config = vscode.workspace.getConfiguration("supabasePurescript");
  const configPath = config.get("serverPath");
  if (configPath && fs.existsSync(configPath)) return configPath;

  // Check workspace node_modules (if library is a dependency)
  const folders = vscode.workspace.workspaceFolders;
  if (folders) {
    const wsPath = path.join(folders[0].uri.fsPath, "node_modules", "purescript-supabase", "output", "LSP.Server", "index.js");
    if (fs.existsSync(wsPath)) return wsPath;

    // Check workspace output directly (if working in the library itself)
    const directPath = path.join(folders[0].uri.fsPath, "output", "LSP.Server", "index.js");
    if (fs.existsSync(directPath)) return directPath;
  }

  // Check relative to extension
  const extPath = path.join(context.extensionPath, "..", "output", "LSP.Server", "index.js");
  if (fs.existsSync(extPath)) return extPath;

  return null;
}

function activate(context) {
  const serverModule = findServer(context);
  if (!serverModule) {
    vscode.window.showWarningMessage(
      "Supabase PureScript: LSP server not found. Run `spago build` in the purescript-supabase directory first."
    );
    return;
  }

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
