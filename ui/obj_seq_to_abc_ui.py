"""
OBJ Sequence to Alembic Cache Exporter
Standalone UI (OBJ → Alembic tab only)
Window Title: OBJ Sequence to Alembic Cache Exporter

Project layout assumption:
- <project_root>/ui/obj_seq_to_abc_ui.py  (this file)
- <project_root>/deploy/obj2abc.exe       (external converter binary)
- <project_root>/example/obj_sequence/... (sample OBJ sequence, ~120 files)

This UI locates obj2abc.exe automatically using these candidates:
  1) <project_root>/deploy/obj2abc.exe          (dev layout; this file in /ui)
  2) <same folder as this UI EXE>/obj2abc.exe   (when packaged and placed next to the exporter)
  3) <parent of this EXE>/deploy/obj2abc.exe    (when the EXE is placed into /deploy)
If not found, the app shows an error instructing to place obj2abc.exe into /deploy.
"""

import sys
import os
import subprocess
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QGridLayout, QGroupBox,
    QLabel, QLineEdit, QPushButton, QFileDialog, QMessageBox, QSpinBox,
    QTextEdit, QProgressBar, QAction, QFrame
)
from PyQt5.QtCore import QThread, pyqtSignal, Qt
from PyQt5.QtGui import QFont


def _norm(p: str) -> str:
    return os.path.abspath(os.path.normpath(p))


def resolve_default_exporter_path() -> str:
    """Resolve obj2abc.exe near this project using robust relative paths."""
    # Determine base path of this app (script path during dev, executable dir when frozen)
    if getattr(sys, 'frozen', False):
        base_dir = os.path.dirname(sys.executable)
    else:
        base_dir = os.path.dirname(_norm(__file__))

    candidates = [
        _norm(os.path.join(base_dir, '..', 'deploy', 'obj2abc.exe')),
        _norm(os.path.join(base_dir, 'obj2abc.exe')),
        _norm(os.path.join(os.path.dirname(base_dir), 'deploy', 'obj2abc.exe')),
    ]
    for p in candidates:
        if os.path.isfile(p):
            return p
    return candidates[0]  # show intent even if missing


class WorkerThread(QThread):
    finished = pyqtSignal()
    error = pyqtSignal(str)
    output = pyqtSignal(str)

    def __init__(self, command):
        super().__init__()
        self.command = command

    def run(self):
        try:
            env = os.environ.copy()
            env['PYTHONIOENCODING'] = 'utf-8'
            env['PYTHONLEGACYWINDOWSSTDIO'] = '1'

            process = subprocess.Popen(
                self.command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                shell=True,
                env=env,
                encoding='utf-8',
                errors='replace'
            )

            # Stream stdout
            while True:
                line = process.stdout.readline()
                if line == '' and process.poll() is not None:
                    break
                if line:
                    self.output.emit(line.rstrip())

            rc = process.poll()
            if rc != 0:
                err = process.stderr.read()
                self.error.emit(f"Process failed with return code {rc}: {err}")
            else:
                self.finished.emit()
        except Exception as e:
            self.error.emit(f"Error running command: {str(e)}")


class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("OBJ Sequence to Alembic Cache Exporter")
        self.setGeometry(100, 100, 760, 520)
        self.worker_thread = None
        self._exe_path = resolve_default_exporter_path()
        self._build_ui()
        self._create_menu_bar()

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)

        main_layout = QVBoxLayout()
        central.setLayout(main_layout)

        # Header
        header = QLabel("OBJ Sequence to Alembic Cache Exporter")
        header.setFont(QFont("Arial", 16, QFont.Bold))
        header.setAlignment(Qt.AlignCenter)
        main_layout.addWidget(header)

        # --- IO group ---
        io_group = QGroupBox("Input/Output Settings")
        io_layout = QGridLayout()

        # Input folder
        io_layout.addWidget(QLabel("Input Folder:"), 0, 0)
        self.input_folder_edit = QLineEdit()
        btn_in = QPushButton("Browse...")
        btn_in.clicked.connect(self._browse_input_folder)
        io_layout.addWidget(self.input_folder_edit, 0, 1)
        io_layout.addWidget(btn_in, 0, 2)

        # Output file
        io_layout.addWidget(QLabel("Output File:"), 1, 0)
        self.output_file_edit = QLineEdit()
        btn_out = QPushButton("Browse...")
        btn_out.clicked.connect(self._browse_output_file)
        io_layout.addWidget(self.output_file_edit, 1, 1)
        io_layout.addWidget(btn_out, 1, 2)

        # FPS
        io_layout.addWidget(QLabel("FPS:"), 2, 0)
        self.fps_spin = QSpinBox()
        self.fps_spin.setMinimum(1)
        self.fps_spin.setMaximum(120)
        self.fps_spin.setValue(24)
        io_layout.addWidget(self.fps_spin, 2, 1)

        # Info
        info = QLabel("Note: All OBJ files in the input folder will be processed sequentially (filename order).")
        info.setStyleSheet("color: gray; font-style: italic;")
        io_layout.addWidget(info, 3, 0, 1, 3)

        io_group.setLayout(io_layout)
        main_layout.addWidget(io_group)

        # --- Separator line ---
        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        line.setFrameShadow(QFrame.Sunken)
        main_layout.addWidget(line)

        # Process button
        self.btn_process = QPushButton("Convert to Alembic")
        self.btn_process.clicked.connect(self._process)
        main_layout.addWidget(self.btn_process)

        # Progress + logs
        self.progress = QProgressBar()
        self.progress.setVisible(False)
        main_layout.addWidget(self.progress)

        self.log = QTextEdit()
        self.log.setReadOnly(True)
        self.log.setMaximumHeight(200)
        main_layout.addWidget(self.log)

        # Show detected exporter path
        self.log.append(f"[Init] Detected exporter (candidate): {self._exe_path}")

    def _create_menu_bar(self):
        menubar = self.menuBar()
        help_menu = menubar.addMenu("Help")

        act_help = QAction("How to Use", self)
        act_help.triggered.connect(self._show_help)
        help_menu.addAction(act_help)

        act_about = QAction("About", self)
        act_about.triggered.connect(self._show_about)
        help_menu.addAction(act_about)

        # NOTE: No 'Tools' menu per user request. Exporter path is auto-detected only.

    # ---- UI handlers ----
    def _browse_input_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Input OBJ Sequence Folder")
        if folder:
            self.input_folder_edit.setText(folder)

    def _browse_output_file(self):
        path, _ = QFileDialog.getSaveFileName(self, "Save Alembic File", "", "Alembic Files (*.abc)")
        if path:
            if not path.lower().endswith(".abc"):
                path += ".abc"
            self.output_file_edit.setText(path)

    def _process(self):
        input_folder = self.input_folder_edit.text().strip()
        output_file = self.output_file_edit.text().strip()
        fps = int(self.fps_spin.value())

        # Validate
        if not input_folder or not output_file:
            QMessageBox.warning(self, "Warning", "Please fill all required fields.")
            return
        if not os.path.isdir(input_folder):
            QMessageBox.warning(self, "Warning", "Input folder does not exist.")
            return
        obj_files = [f for f in os.listdir(input_folder) if f.lower().endswith(".obj")]
        if not obj_files:
            QMessageBox.warning(self, "Warning", "No OBJ files found in the input folder.")
            return
        if not output_file.lower().endswith(".abc"):
            output_file += ".abc"
            self.output_file_edit.setText(output_file)

        # Ensure exporter executable
        exe_path = self._exe_path
        if not os.path.isfile(exe_path):
            msg = (
                "Exporter executable was not found.\n\n"
                "Expected at:\n"
                f"  {exe_path}\n\n"
                "Place obj2abc.exe into <project_root>\\deploy and try again."
            )
            QMessageBox.critical(self, "Exporter Not Found", msg)
            self.log.append("[Error] Exporter not found. Place obj2abc.exe into /deploy.")
            return

        # Create output directory if needed
        out_dir = os.path.dirname(output_file)
        if out_dir and not os.path.isdir(out_dir):
            try:
                os.makedirs(out_dir, exist_ok=True)
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to create output directory:\n{e}")
                return

        # Log
        self.log.append(f"Found {len(obj_files)} OBJ files in folder.")
        self.log.append(f"FPS: {fps}")
        self.log.append(f'Using exporter: "{exe_path}"')
        self.log.append(f'Output: "{output_file}"')

        # Build command (use UTF-8 codepage for Windows shell)
        command = f'chcp 65001 >nul && "{exe_path}" -input "{input_folder}" -output "{output_file}" -fps {fps}'
        self._execute_command(command)

    def _execute_command(self, command):
        if self.worker_thread and self.worker_thread.isRunning():
            QMessageBox.warning(self, "Warning", "Another process is already running.")
            return

        self.log.append("=== Starting conversion ===")
        self.log.append(f"Command: {command}")
        self.progress.setVisible(True)
        self.progress.setRange(0, 0)  # indeterminate

        self.worker_thread = WorkerThread(command)
        self.worker_thread.finished.connect(self._on_finished)
        self.worker_thread.error.connect(self._on_error)
        self.worker_thread.output.connect(self._on_output)
        self.worker_thread.start()

    def _on_finished(self):
        self.progress.setVisible(False)
        self.log.append("=== Conversion completed successfully ===\n")
        QMessageBox.information(self, "Success", "Conversion completed successfully!")

    def _on_error(self, msg):
        self.progress.setVisible(False)
        self.log.append(f"ERROR: {msg}")
        self.log.append("=== Conversion failed ===\n")
        QMessageBox.critical(self, "Error", f"Process failed:\n{msg}")

    def _on_output(self, line):
        self.log.append(line)
        self.log.ensureCursorVisible()

    # ---- Help / About ----
    def _show_help(self):
        text = (
            "====================================\n"
            "OBJ Sequence to Alembic Converter 사용법\n"
            "====================================\n\n"
            "기능 설명:\n"
            "OBJ 시퀀스 파일들을 하나의 Alembic(.abc) 애니메이션 파일로 변환합니다.\n\n"
            "사용 방법:\n"
            "1) Input Folder: OBJ 시퀀스 폴더를 선택\n"
            "2) Output File: 저장할 Alembic 파일(.abc) 경로 지정\n"
            "3) FPS: 재생 프레임레이트(기본 24)\n"
            "4) Convert to Alembic 버튼 클릭\n\n"
            "중요 사항:\n"
            "- 폴더 내 모든 OBJ 파일이 파일명 순으로 처리됩니다\n"
            "- Maya에서 import 시 씬 FPS를 동일하게 맞추세요\n\n"
            "CLI 예시:\n"
            'obj2abc.exe -input \"<obj_folder>\" -output \"<output.abc>\" -fps 24\n'
        )
        QMessageBox.information(self, "How to Use", text)

    def _show_about(self):
        text = (
            "OBJ Sequence to Alembic Cache Exporter\n"
            "Version 1.2 (no-Tools menu)\n\n"
            "Dexter Studios — R&D\n"
            "Standalone UI for OBJ→Alembic exporter.\n"
        )
        QMessageBox.information(self, "About", text)


def main():
    app = QApplication(sys.argv)
    app.setStyle('Fusion')
    win = MainWindow()
    win.show()
    sys.exit(app.exec_())


if __name__ == "__main__":
    main()
