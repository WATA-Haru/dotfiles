#!/bin/bash
curl -L https://go.microsoft.com/fwlink/?LinkID=760868 -o vscode.deb
sudo apt install ./vscode.deb
rm vscode.deb

