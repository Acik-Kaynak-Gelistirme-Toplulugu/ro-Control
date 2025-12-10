import sys
print("DEBUG: Python main.py loaded")
try:
    import logging
    print("DEBUG: logging imported")
    import traceback
    print("DEBUG: traceback imported")
    from src.utils.logger import setup_logger
    print("DEBUG: setup_logger imported")
except Exception as e:
    print(f"DEBUG: Import error detected: {e}")
    sys.exit(1)

def main():
    print("DEBUG: main() started")
    try:
        # Loglama sistemini başlat
        print("DEBUG: Calling setup_logger...")
        setup_logger()
        print("DEBUG: setup_logger finished")

        # ÖNCE BAĞIMLILIK KONTROLÜ VE TAMİRİ
        from src.utils.dependency_manager import DependencyManager
        print("DEBUG: Running dependency check...")
        DependencyManager.check_and_fix()
        print("DEBUG: Dependency check completed.")

        # CLI Modu Kontrolü
        if "--cli" in sys.argv:
            print("DEBUG: CLI mode detected")
            # ... CLI kodları ...
            return

        # GUI Modu
        print("DEBUG: Attempting to import GUI...")
        try:
            import gi
            print("DEBUG: 'gi' module found")
        except ImportError:
            print("CRITICAL: 'python3-gi' paketi yüklü değil! Uygulama çalışamaz.")
            print("Lütfen terminalden şunu çalıştırın: sudo apt install python3-gi gir1.2-gtk-4.0")
            sys.exit(1)

        from src.ui.main_window import start_gui
        print("DEBUG: start_gui imported, launching...")
        start_gui()
        print("DEBUG: start_gui finished (App closed)")

    except Exception as e:
        print(f"CRITICAL ERROR in main: {e}")
        traceback.print_exc()

if __name__ == "__main__":
    print("DEBUG: __name__ == __main__")
    main()
