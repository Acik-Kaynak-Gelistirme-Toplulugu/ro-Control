import sys
import os
from PySide6.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget
from PySide6.QtWebEngineWidgets import QWebEngineView
from PySide6.QtCore import QUrl

class QtSimulationWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("ro-Control — macOS Native Qt Simulation")
        self.resize(1100, 850)

        # WebEngine View
        self.browser = QWebEngineView()
        
        # Simülasyon dosyasının yolunu bul
        current_dir = os.path.dirname(os.path.abspath(__file__))
        sim_path = os.path.abspath(os.path.join(current_dir, "../../simulation/index.html"))
        
        # Dosyayı yükle
        self.browser.setUrl(QUrl.fromLocalFile(sim_path))

        # Layout
        layout = QVBoxLayout()
        layout.setContentsMargins(0, 0, 0, 0)
        layout.addWidget(self.browser)
        
        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    
    # Modern stili ayarla (istenirse)
    app.setStyle("Fusion")
    
    window = QtSimulationWindow()
    window.show()
    sys.exit(app.exec())
