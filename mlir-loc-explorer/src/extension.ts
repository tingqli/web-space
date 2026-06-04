import * as vscode from "vscode";
import * as fs from "fs";
import * as path from "path";

export function activate(context: vscode.ExtensionContext) {
  context.subscriptions.push(
    vscode.commands.registerCommand("mlirLocExplorer.open", () => {
      createExplorerPanel(context);
    }),
    vscode.commands.registerCommand(
      "mlirLocExplorer.openFolder",
      (resource: vscode.Uri) => {
        createExplorerPanel(context, resource);
      }
    )
  );
}

function createExplorerPanel(
  context: vscode.ExtensionContext,
  initialDirUri?: vscode.Uri
) {
  const panel = vscode.window.createWebviewPanel(
    "mlirLocExplorer",
    "MLIR Loc Explorer",
    vscode.ViewColumn.One,
    {
      enableScripts: true,
      retainContextWhenHidden: true,
      localResourceRoots: [
        vscode.Uri.joinPath(context.extensionUri, "media"),
      ],
    }
  );

  panel.webview.html = getWebviewHtml(context);

  panel.webview.onDidReceiveMessage(
    async (msg) => {
      if (msg.command === "openSourceLocation") {
        await openSourceLocation(msg.file, msg.line, msg.col);
      }
    },
    undefined,
    context.subscriptions
  );

  setTimeout(async () => {
    if (initialDirUri) {
      await loadMlirFilesFromDir(panel, initialDirUri);
      return;
    }
    await promptAndLoadDir(panel);
  }, 300);
}

async function promptAndLoadDir(panel: vscode.WebviewPanel) {
  const uris = await vscode.window.showOpenDialog({
    canSelectFiles: false,
    canSelectFolders: true,
    canSelectMany: false,
    openLabel: "选择包含 .mlir 文件的目录",
  });
  if (!uris || uris.length === 0) {
    panel.webview.postMessage({ command: "loadCancelled" });
    return;
  }
  await loadMlirFilesFromDir(panel, uris[0]);
}

async function loadMlirFilesFromDir(
  panel: vscode.WebviewPanel,
  dirUri: vscode.Uri
) {
  panel.webview.postMessage({ command: "loadStart" });
  try {
    const entries = await vscode.workspace.fs.readDirectory(dirUri);
    const fileEntries = entries.filter(([, type]) => type === vscode.FileType.File);

    const files: { name: string; text: string }[] = [];
    const mlirFiles: string[] = [];
    const allFiles: string[] = [];
    const mlirTextByName = new Map<string, string>();
    for (const [name] of fileEntries) {
      const fileUri = vscode.Uri.joinPath(dirUri, name);
      const bytes = await vscode.workspace.fs.readFile(fileUri);
      const text = Buffer.from(bytes).toString("utf8");
      files.push({ name, text });
      allFiles.push(name);
      if (name.toLowerCase().endsWith(".mlir")) {
        mlirFiles.push(name);
        mlirTextByName.set(name, text);
      }
    }

    const preferredLeftSources = await collectPreferredLeftSources(
      dirUri,
      mlirTextByName
    );
    for (const sourcePath of preferredLeftSources) {
      if (allFiles.includes(sourcePath)) {
        continue;
      }
      const sourceUri = await resolveSourceUri(sourcePath);
      if (!sourceUri) {
        continue;
      }
      const bytes = await vscode.workspace.fs.readFile(sourceUri);
      files.push({ name: sourcePath, text: Buffer.from(bytes).toString("utf8") });
      allFiles.push(sourcePath);
    }

    files.sort((a, b) => a.name.localeCompare(b.name));
    allFiles.sort((a, b) => a.localeCompare(b));
    mlirFiles.sort((a, b) => a.localeCompare(b));
    panel.webview.postMessage({
      command: "loadFiles",
      files,
      mlirFiles,
      allFiles,
      preferredLeftFiles: preferredLeftSources,
    });
  } catch (err) {
    panel.webview.postMessage({
      command: "loadError",
      message: String(err),
    });
  }
}

async function collectPreferredLeftSources(
  dirUri: vscode.Uri,
  mlirTextByName: Map<string, string>
): Promise<string[]> {
  const preferredMlirName = Array.from(mlirTextByName.keys())
    .filter((name) => /^00_.*\.mlir$/i.test(name))
    .sort((a, b) => a.localeCompare(b))[0];
  if (!preferredMlirName) {
    return [];
  }

  const mlirText = mlirTextByName.get(preferredMlirName);
  if (!mlirText) {
    return [];
  }

  const candidatePaths = extractLocFilePaths(mlirText)
    .filter((filePath) => !filePath.includes("python/flydsl/"));

  const results: string[] = [];
  for (const filePath of candidatePaths) {
    const resolved = await resolveSourceUri(filePath);
    if (!resolved) {
      continue;
    }
    results.push(filePath);
  }
  return Array.from(new Set(results));
}

function extractLocFilePaths(mlirText: string): string[] {
  const locPathRe = /loc\("((?:[^"\\]|\\.)+)":\d+:\d+\)/g;
  const paths = new Set<string>();
  let match: RegExpExecArray | null;
  locPathRe.lastIndex = 0;
  while ((match = locPathRe.exec(mlirText)) !== null) {
    const rawPath = match[1]
      .replace(/\\"/g, '"')
      .replace(/\\\\/g, "\\");
    if (rawPath.length > 0) {
      paths.add(rawPath);
    }
  }
  return Array.from(paths);
}

async function openSourceLocation(
  rawFile: string,
  rawLine: number,
  rawCol: number
) {
  if (typeof rawFile !== "string" || rawFile.length === 0) {
    void vscode.window.showWarningMessage("无法跳转：loc 中没有有效文件路径。");
    return;
  }

  const line = Number.isFinite(rawLine) ? Math.max(1, Math.floor(rawLine)) : 1;
  const col = Number.isFinite(rawCol) ? Math.max(1, Math.floor(rawCol)) : 1;
  const targetUri = await resolveSourceUri(rawFile);

  if (!targetUri) {
    void vscode.window.showWarningMessage(`无法在工作区中找到文件: ${rawFile}`);
    return;
  }

  const document = await vscode.workspace.openTextDocument(targetUri);
  const editor = await vscode.window.showTextDocument(document, {
    preview: false,
    preserveFocus: false,
  });
  const position = new vscode.Position(line - 1, col - 1);
  editor.selection = new vscode.Selection(position, position);
  editor.revealRange(
    new vscode.Range(position, position),
    vscode.TextEditorRevealType.InCenter
  );
}

async function resolveSourceUri(rawFile: string): Promise<vscode.Uri | null> {
  if (path.isAbsolute(rawFile) && fs.existsSync(rawFile)) {
    return vscode.Uri.file(rawFile);
  }

  const normalized = rawFile.replace(/\\/g, "/");
  const workspaceMatch = await findWorkspaceFile(normalized);
  if (workspaceMatch) {
    return workspaceMatch;
  }

  const basename = path.posix.basename(normalized);
  if (basename !== normalized) {
    return findWorkspaceFile(`**/${basename}`);
  }

  return null;
}

async function findWorkspaceFile(
  patternOrPath: string
): Promise<vscode.Uri | null> {
  const escaped = patternOrPath
    .split("/")
    .map((segment) => segment.replace(/[\[\]{}()*?+!@]/g, "\\$&"))
    .join("/");
  const exactMatches = await vscode.workspace.findFiles(
    `**/${escaped}`,
    "**/node_modules/**",
    2
  );
  if (exactMatches.length > 0) {
    return exactMatches[0];
  }

  if (patternOrPath.startsWith("**/")) {
    const wildcardMatches = await vscode.workspace.findFiles(
      patternOrPath,
      "**/node_modules/**",
      2
    );
    if (wildcardMatches.length > 0) {
      return wildcardMatches[0];
    }
  }

  return null;
}

function getWebviewHtml(context: vscode.ExtensionContext): string {
  const htmlPath = path.join(context.extensionPath, "media", "explorer.html");
  return fs.readFileSync(htmlPath, "utf8");
}

export function deactivate() {}

