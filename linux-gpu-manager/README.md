# ro-Control 🎮🚀

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-GPLv3-green.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)
![Status](https://img.shields.io/badge/status-Stable-success.svg)

**ro-Control**, Linux sistemlerindeki grafik sürücüsü ve oyun performans yönetimini demokratikleştiren, son kullanıcı dostu, güçlü bir araçtır. Karmaşık terminal komutlarına son verin; NVIDIA, AMD ve Intel GPU'larınızın gücünü tek tıkla kontrol altına alın.

![Screenshot](https://via.placeholder.com/800x450.png?text=ro-Control+Screenshot)
_(Ekran görüntüsü buraya gelecek)_

## 🌟 Öne Çıkan Özellikler

### 🚀 **Akıllı Sürücü Yönetimi**

- **Otomatik Tespit:** donanımınızı milisaniyeler içinde analiz eder.
- **Tek Tıkla Kurulum:** En stabil veya en yeni sürücüleri (Open Source / Proprietary) sorunsuz kurar.
- **Derin Temizlik (Deep Clean):** Eski sürücü kalıntılarını "nükleer" yöntemlerle temizleyerek çakışmaları önler.

### 🎮 **Oyun Performansı**

- **GameMode Entegrasyonu:** Feral GameMode'u otomatik kurar ve yönetir.
- **Hybrid GPU Switch (MUX):** Laptop kullanıcıları için NVIDIA (Performans), Intel (Güç Tasarrufu) ve Hybrid modları arasında _yeniden başlatma uyarılı_ güvenli geçiş.
- **Canlı Monitör:** GPU sıcaklığı, yükü, VRAM kullanımı ile CPU ve RAM durumunu anlık izleyin.

### 🛠 **Uzman Araçları**

- **Flatpak Onarıcı:** Steam oyunlarının açılmama sorununu çözen tek tuşlu onarım aracı.
- **X11 / Wayland Tespiti:** Hangi görüntü sunucusunda çalıştığınızı anında görün.
- **Repo Optimizasyonu:** İndirme hızlarını artırmak için en yakın yansıyı seçer.

### 🔄 **Akıllı Güncelleme**

- **Otomatik Kontrol:** Uygulama açılışında GitHub üzerindeki yeni sürümleri kontrol eder.
- **Yerinde Güncelleme:** Yeni sürümleri arayüz üzerinden indirip kurar.

## 📦 Kurulum

### Debian / Ubuntu / Mint / Pop!\_OS

En son sürümü [Releases](https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/releases) sayfasından indirebilirsiniz.

**Intel/AMD İşlemcili Sistemler (x86_64/AMD64) İçin:**

```bash
sudo apt install ./ro-control_1.0.0_amd64.deb
```

**ARM İşlemcili Sistemler (Raspberry Pi/ARM64) İçin:**

```bash
sudo apt install ./ro-control_1.0.0_arm64.deb
```

## 🖥 Kullanım

Uygulamayı menüden **ro-Control** adıyla veya terminalden:

```bash
ro-control
```

komutuyla başlatabilirsiniz.

_Not: Sürücü kurma, kaldırma ve sistem onarım işlemleri için `pkexec` aracılığıyla yönetici parolası istenir._

## 🤝 Katkıda Bulunma (Contributing)

Bu proje açık kaynaklıdır ve her türlü katkıya açıktır! Lütfen katkıda bulunmadan önce [CONTRIBUTING.md](CONTRIBUTING.md) dosyasını okuyun.

1.  Bu repoyu Fork'layın.
2.  Yeni bir özellik dalı (branch) oluşturun (`git checkout -b feature/yeniozellik`).
3.  Değişikliklerinizi commit'leyin (`git commit -m 'Yeni özellik eklendi'`).
4.  Dalınızı Push'layın (`git push origin feature/yeniozellik`).
5.  Bir Pull Request (PR) oluşturun.

## 🐛 Hata Bildirimi

Bir hata mı buldunuz? Lütfen [Issues](https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/issues) sekmesini kullanarak bize bildirin. Hata bildiriminde şunları eklemeyi unutmayın:

- Kullandığınız dağıtım ve sürümü
- Ekran kartı modeliniz
- Hatanın ekran görüntüsü veya log çıktısı

## 📜 Lisans

Bu proje **GPL-3.0** lisansı ile lisanslanmıştır. Detaylar için repodaki lisans dosyasına bakabilirsiniz.

---

<div align="center">
  <sub>Sopwit tarafından  ile geliştirildi.</sub>
</div>
