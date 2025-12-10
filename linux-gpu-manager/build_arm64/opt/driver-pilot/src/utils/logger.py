import logging
import os
import sys

def setup_logger():
    """
    Loglama sistemini yapılandırır.
    Loglar hem terminale hem de ~/.local/share/display-driver-app/app.log dosyasına yazılır.
    """
    # Log dosyasının kaydedileceği dizin
    log_dir = os.path.expanduser("~/.local/share/display-driver-app")
    log_file = os.path.join(log_dir, "app.log")

    # Dizin yoksa oluştur
    if not os.path.exists(log_dir):
        try:
            os.makedirs(log_dir)
        except OSError as e:
            print(f"Log dizini oluşturulamadı: {e}")
            return None

    # Logger yapılandırması
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    # Format
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')

    # 1. Dosyaya Yazma Handler'ı
    file_handler = logging.FileHandler(log_file, mode='a', encoding='utf-8')
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    # 2. Terminale Yazma Handler'ı
    if not any(isinstance(h, logging.StreamHandler) for h in logger.handlers):
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)

    logging.info("="*40)
    logging.info("Display Driver App Başlatıldı")
    logging.info(f"Log Dosyası: {log_file}")
    logging.info("="*40)

    return log_file