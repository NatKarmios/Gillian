/*---------------------------------------------------------
 * Copyright (C) Microsoft Corporation. All rights reserved.
 *--------------------------------------------------------*/

'use strict';

import * as vscode from 'vscode';
import { ProviderResult } from 'vscode';
import { activateCodeLens } from './activateCodeLens';
import { activateDebug } from './activateDebug';
import * as ml from './ml';

export function activate(context: vscode.ExtensionContext) {
    let panel: vscode.WebviewPanel;

	activateDebug(context, new DebugAdapterExecutableFactory());
	activateCodeLens(context);

	vscode.debug.onDidStartDebugSession((debugSession) => {
		panel = vscode.window.createWebviewPanel(
			'gillianHelper',
			'Gillian Debugger',
			vscode.ViewColumn.One,
			{ enableScripts: true }
		);

		panel.webview.html = `
		    <!DOCTYPE html>
		    <html lang="en">
		    <head>
		        <meta charset="UTF-8">
			    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>Gillian Debug Helper</title>
				<script>
					const vscode = acquireVsCodeApi();
				</script>
		    </head>
			<body>
				<i>Value from OCaml:</i> <b>${ml.getValFromGillian()}</b>
				<br/>
				<button type="button" onClick="vscode.postMessage({ command: 'step' })">
					Step forward (via custom event)
				</button>
				<br/>
				<button type="button" onClick="vscode.postMessage({ command: 'twoWay' })">
					Test two-way custom event
				</button>
			</body>
			</html>
		`;

		panel.webview.onDidReceiveMessage(msg => {
			switch (msg.command) {
				case 'step':
					vscode.window.showInformationMessage("Step!");
					debugSession.customRequest('customStep');
					break;
				case 'twoWay':
					vscode.window.showInformationMessage("Two way!");
					debugSession.customRequest('twoWay');
					break;
			}
		});
	});

	vscode.debug.onDidTerminateDebugSession((debugSession) => {
		panel.dispose();
	});

	vscode.debug.onDidReceiveDebugSessionCustomEvent(e => {
		const items = Object.entries(e.body).map(([k, v]) => `- ${k} : ${v}`).join("\n");
		vscode.window.showInformationMessage(`Custom event fired! '${e.event}'\n${items}`);
	});
}

export function deactivate() {
	// nothing to do
}

class DebugAdapterExecutableFactory implements vscode.DebugAdapterDescriptorFactory {

	// The following use of a DebugAdapter factory shows how to control what debug adapter executable is used.
	// Since the code implements the default behavior, it is absolutely not neccessary and we show it here only for educational purpose.

	createDebugAdapterDescriptor(_session: vscode.DebugSession, executable: vscode.DebugAdapterExecutable | undefined): ProviderResult<vscode.DebugAdapterDescriptor> {
		const fileExtension = _session.configuration.program.split('.').pop();
		let gillianExecutableCommand : string;
		// Match of the file extension first
		switch (fileExtension) {
			case "js":
				gillianExecutableCommand = "gillian-js";
				break;
			case "wisl":
				gillianExecutableCommand = "wisl";
				break;
			case "gil":
				// Check the target language if it is a GIL file
				switch (_session.configuration.targetLanguage) {
					case "js":
						gillianExecutableCommand = "gillian-js";
						break;
					case "wisl":
					default:
						// Default to WISL
						gillianExecutableCommand = "wisl";
						break;
				}
				break;
			default:
				// Default to WISL
				gillianExecutableCommand = "wisl";
				break;
		}

		const gillianSourceRepository : string =
			vscode.workspace.getConfiguration('gillianDebugger').gillianSourceRepository === null ?
				__dirname + "/../../.." :
				vscode.workspace.getConfiguration('gillianDebugger').gillianSourceRepository;

		const command = "esy";
		const args = ["x", gillianExecutableCommand, "debugverify", "-r", "db,file"];
		const options = {
			cwd: gillianSourceRepository
		};
		executable = new vscode.DebugAdapterExecutable(command, args, options);

		// make VS Code launch the DA executable
		return executable;
	}
}