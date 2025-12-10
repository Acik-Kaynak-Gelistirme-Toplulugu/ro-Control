import sys
import logging
from src.utils.logger import setup_logger

def main():
    # Loglama sistemini başlat
    setup_logger()

    # CLI Modu Kontrolü
    if "--cli" in sys.argv:
        from src.core.detector import SystemDetector
        from src.core.installer import DriverInstaller
        
        print("="*50)
        print("   DISPLAY DRIVER APP - CLI MODE")
        print("="*50)
        
        detector = SystemDetector()
        gpu_info = detector.detect()
        print(f"GPU: {gpu_info['vendor']} {gpu_info['model']}")
        print(f"Driver: {gpu_info['driver_in_use']}")

        if "--install" in sys.argv:
            print("\n[+] Kurulum Başlatılıyor (Simülasyon)...")
            installer = DriverInstaller()
            if gpu_info['vendor'] == "NVIDIA":
                installer.install_nvidia_closed()
            else:
                print("Sadece NVIDIA için otomatik kurulum aktif.")
        
        return

    # GUI Modu
    try:
        from src.ui.main_window import start_gui
        start_gui()
    except Exception as e:
        print(f"GUI başlatılamadı: {e}")
        print("Lütfen gerekli GTK kütüphanelerinin yüklü olduğundan emin olun.")
        logging.error(f"GUI Crash: {e}", exc_info=True)

if __name__ == "__main__":
    main()
