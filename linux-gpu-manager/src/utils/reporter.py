import platform
import urllib.parse
import webbrowser
import logging
import json
from src.core.detector import SystemDetector

from src.config import AppConfig

# Raporların gönderileceği geliştirici adresi (GitHub Repo)
GITHUB_REPO_URL = f"https://github.com/{AppConfig.GITHUB_REPO}/issues/new"

class ErrorReporter:
    @staticmethod
    def collect_system_info():
        """Sistem özetini toplar."""
        info = {
            "OS": f"{platform.system()} {platform.release()}",
            "Arch": platform.machine(),
            "Python": platform.python_version()
        }
        
        try:
            import os
            info["Desktop"] = os.environ.get("XDG_CURRENT_DESKTOP", "-")
            
            detector = SystemDetector()
            gpu = detector.detect()
            info["GPU"] = f"{gpu.get('vendor')} {gpu.get('model')}"
            info["Driver"] = str(gpu.get('driver_in_use'))
        except:
            pass
            
        return info

    @staticmethod
    def prepare_github_link(error_message, system_info, labels="bug"):
        """GitHub Issue linkini oluşturur."""
        
        # Markdown body oluştur
        body = f"**Hata Açıklaması**\n{error_message}\n\n" \
               "**Sistem Bilgileri**\n" \
               f"- OS: {system_info.get('OS', '-')}\n" \
               f"- Mimari: {system_info.get('Arch', '-')}\n" \
               f"- Masaüstü: {system_info.get('Desktop', '-')}\n" \
               f"- GPU: {system_info.get('GPU', '-')}\n" \
               f"- Sürücü: {system_info.get('Driver', '-')}\n\n" \
               "**Ek Loglar**\n(Lütfen terminal çıktılarını buraya ekleyin)"

        params = {
            "title": f"[BUG] {error_message[:50]}...",
            "body": body,
            "labels": labels
        }
        
        query = urllib.parse.urlencode(params, quote_via=urllib.parse.quote)
        return f"{GITHUB_REPO_URL}?{query}"

    @staticmethod
    def send_report(error_message, log_content):
        """
        Tarayıcıda GitHub Issue sayfasını açar.
        """
        try:
            logging.info("Sistem bilgileri toplanıyor...")
            sys_info = ErrorReporter.collect_system_info()
            
            link = ErrorReporter.prepare_github_link(error_message, sys_info)
            
            logging.info("GitHub Issue sayfası açılıyor...")
            
            try:
                webbrowser.open(link)
            except Exception:
                import subprocess
                subprocess.run(["xdg-open", link], check=False)

        except Exception as e:
            logging.error(f"Tarayıcı açılamadı: {e}")
            return False

    @staticmethod
    def send_feedback():
        """Genel geri bildirim için GitHub sayfasını açar."""
        try:
            # Sadece issue sayfasına yönlendir (şablonsuz)
            link = f"https://github.com/{AppConfig.GITHUB_REPO}/issues"
            logging.info("Geri bildirim sayfası açılıyor...")
            webbrowser.open(link)
            return True
        except Exception as e:
            logging.error(f"Sayfa açma hatası: {e}")
            return False