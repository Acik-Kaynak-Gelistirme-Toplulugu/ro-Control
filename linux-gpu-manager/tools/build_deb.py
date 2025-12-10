import os
import shutil
import subprocess
import sys
import argparse
import tempfile

# Proje kök dizinini path'e ekle
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
sys.path.append(project_root)

from src.config import AppConfig

def get_directory_size_kb(directory):
    """Bir dizinin boyutunu KB cinsinden hesaplar."""
    total_size = 0
    for dirpath, dirnames, filenames in os.walk(directory):
        for f in filenames:
            fp = os.path.join(dirpath, f)
            if not os.path.islink(fp):
                total_size += os.path.getsize(fp)
    # En az 1 KB
    return max(1, total_size // 1024)

def build_deb(target_arch="amd64"):
    os.chdir(project_root)
    
    app_name = AppConfig.APP_NAME
    version = AppConfig.VERSION
    # Eğer 'all' ise architecture 'all' olur, yoksa hedef mimari (amd64/arm64)
    # Python scriptleri genelde 'all' olur ama binary wrapper veya venv varsa spesifik olabilir.
    # Bu projede venv postinst ile kuruluyor, bu yüzden 'all' güvenlidir ancak
    # dpkg-deb --build komutu architecture flag'ini control dosyasından alır.
    
    # Kullanıcıdan gelen arch bilgisi, control dosyasına yazılacak.
    # Python pure olduğu için 'all' en mantıklısı ama kullanıcı özellikle arm64 istediyse kırmayalım.
    # Fakat 'all' en doğrusudur çünkü kod derlenmiyor.
    # Tek istisna: Eğer C extension varsa. Bizde yok.
    # Ancak report isteği 'arm64' de ayrı scripte sahipti. Biz bunu birleştiriyoruz.
    
    
    print(f"[+] {app_name} v{version} paketi hazırlanıyor... Hedef Mimari: {target_arch}")

    # Docker volume mount sorunlarını önlemek için /tmp içinde çalış
    build_dir = os.path.join(tempfile.gettempdir(), f"build_{target_arch}")
    if os.path.exists(build_dir):
        shutil.rmtree(build_dir, ignore_errors=True)
    os.makedirs(build_dir, exist_ok=True)

    # Klasör Yapısı
    opt_dir = os.path.join(build_dir, "opt", app_name)
    bin_dir = os.path.join(build_dir, "usr", "bin")
    desktop_dir = os.path.join(build_dir, "usr", "share", "applications")
    icon_dir = os.path.join(build_dir, "usr", "share", "icons", "hicolor", "256x256", "apps")
    debian_dir = os.path.join(build_dir, "DEBIAN")
    doc_dir = os.path.join(build_dir, "usr", "share", "doc", app_name)

    metainfo_dir = os.path.join(build_dir, "usr", "share", "metainfo")

    for d in [opt_dir, bin_dir, desktop_dir, icon_dir, debian_dir, doc_dir, metainfo_dir]:
        os.makedirs(d, exist_ok=True)

    # Dosyaları Kopyala
    print("Dosyalar kopyalanıyor...")
    src_source = os.path.join(project_root, "src")
    data_source = os.path.join(project_root, "data")
    req_source = os.path.join(project_root, "requirements.txt")

    shutil.copytree(src_source, os.path.join(opt_dir, "src"))
    shutil.copytree(data_source, os.path.join(opt_dir, "data"))
    shutil.copy(req_source, opt_dir)
    
    # Pyc dosyalarını temizle
    print("Gereksiz dosyalar temizleniyor (__pycache__)...")
    for root, dirs, files in os.walk(opt_dir):
        for d in dirs:
            if d == "__pycache__":
                shutil.rmtree(os.path.join(root, d))

    # Launcher Script
    launcher_path = os.path.join(bin_dir, app_name)
    with open(launcher_path, "w") as f:
        f.write("#!/bin/bash\n")
        f.write(f"cd /opt/{app_name}\n")
        f.write("echo 'Launcher: Dizine girildi, python başlatılıyor...' > /tmp/driver-pilot-debug.log\n")
        f.write(f"/usr/bin/python3 -u -m src.main \"$@\" >> /tmp/driver-pilot-debug.log 2>&1\n")
    os.chmod(launcher_path, 0o755)

    # Root Task Wrapper (Yeni Eklenen)
    wrapper_src = os.path.join(data_source, "driver-pilot-root-task")
    wrapper_dst = os.path.join(bin_dir, "driver-pilot-root-task")
    if os.path.exists(wrapper_src):
        shutil.copy(wrapper_src, wrapper_dst)
        os.chmod(wrapper_dst, 0o755)

    # Desktop & Icon
    shutil.copy(os.path.join(data_source, "driver-pilot.desktop"), os.path.join(desktop_dir, f"{app_name}.desktop"))
    # Eski isimle varsa diye clean install logic'i postinst'te, burada sadece yeni isim.
    
    # Logo
    logo_src = os.path.join(data_source, "logo.png")
    if os.path.exists(logo_src):
         shutil.copy(logo_src, os.path.join(icon_dir, f"{app_name}.png"))
    
    # AppStream Metadata
    metainfo_src = os.path.join(data_source, "driver-pilot.metainfo.xml")
    if os.path.exists(metainfo_src):
        shutil.copy(metainfo_src, os.path.join(metainfo_dir, f"{app_name}.metainfo.xml"))
    
    # Copyright
    # Copyright
    with open(os.path.join(doc_dir, "copyright"), "w") as f:
        f.write(f"Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/\n")
        f.write(f"Upstream-Name: {AppConfig.PRETTY_NAME}\n")
        # f.write(f"Source: {AppConfig.URL}\n\n") # URL kaldırıldı
        f.write("Files: *\n")
        f.write(f"Copyright: 2025 {AppConfig.MAINTAINER}\n")
        f.write(f"License: {AppConfig.LICENSE}\n")
        f.write(f"\nLicense: {AppConfig.LICENSE}\n")
        f.write(" This program is free software: you can redistribute it and/or modify\n")
        f.write(" it under the terms of the GNU General Public License as published by\n")
        f.write(" the Free Software Foundation, either version 3 of the License, or\n")
        f.write(" (at your option) any later version.\n")
        f.write(" .\n")
        f.write(" On Debian systems, the complete text of the GNU General\n")
        f.write(" Public License version 3 can be found in \"/usr/share/common-licenses/GPL-3\".\n")

    # Control File
    installed_size = get_directory_size_kb(build_dir)
    print(f"Hesaplanan Boyut: {installed_size} KB")

    control_lines = [
        f"Package: {app_name}",
        f"Version: {version}",
        "Section: utils",
        "Priority: optional",
        f"Architecture: {target_arch}", #Genelde all iyidir ama talep üzerine parametrik
        f"Depends: {AppConfig.DEPENDENCIES}",
        f"Maintainer: {AppConfig.MAINTAINER}",
        f"Installed-Size: {installed_size}",
        f"Description: {AppConfig.DESCRIPTION}",
        " Bu paket Linux icin GPU surucu yonetim aracidir.",
        " NVIDIA ve AMD kartlari destekler."
    ]
    with open(os.path.join(debian_dir, "control"), "w", encoding="utf-8") as f:
        f.write("\n".join(control_lines) + "\n")

    # Postinst (Geçici olarak devre dışı - GUI Installer uyumluluğu için)
    # postinst_path = os.path.join(debian_dir, "postinst")
    # post_lines = [
    #     "#!/bin/bash",
    #     "set -e",
    #     "",
    #     "# Desktop Update",
    #     "update-desktop-database /usr/share/applications || true",
    #     "gtk-update-icon-cache /usr/share/icons/hicolor || true",
    #     f"echo '{AppConfig.PRETTY_NAME} kurulumu tamamlandi.'"
    # ]
    # with open(postinst_path, "w") as f:
    #     f.write("\n".join(post_lines) + "\n")
    # os.chmod(postinst_path, 0o755)

    # İzinler (Docker vs Host sorunu için)
    if sys.platform.startswith("linux"):
        print("Linux ortamı: root sahipliği ayarlanıyor...")
        subprocess.run(["chown", "-R", "root:root", build_dir], check=False)

    # Paketleme
    print("DEB paketi oluşturuluyor...")
    deb_filename = f"{app_name}_{version}_{target_arch}.deb"
    try:
        subprocess.run(["dpkg-deb", "--build", build_dir, deb_filename], check=True)
        print(f"\n[BASARILI] Paket: {os.path.abspath(deb_filename)}")
        
        # Docker kolaylığı: /app/ dizinine (host mount) kopyala
        # Docker kolaylığı: /app/ dizinine (host mount) kopyala
        if os.path.isdir("/app"):
            try:
                shutil.copy(deb_filename, "/app/")
                subprocess.run(["chown", "1000:1000", os.path.join("/app", deb_filename)], check=False)
                print(f"Paket host dizinine kopyalandı: /app/{deb_filename}")
            except shutil.SameFileError:
                print(f"Paket zaten /app içinde mevcut: {deb_filename}")
            except Exception as e:
                print(f"Kopyalama uyarısı: {e}")

    except FileNotFoundError:
        print("\n[UYARI] 'dpkg-deb' komutu bulunamadi (macOS/Windows). Paket klasörü 'build_deb' içinde hazırdır.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Display Driver App Deb Builder")
    parser.add_argument("--arch", default="all", help="Hedef mimari (amd64, arm64, all). Varsayılan: all")
    args = parser.parse_args()
    
    build_deb(args.arch)
