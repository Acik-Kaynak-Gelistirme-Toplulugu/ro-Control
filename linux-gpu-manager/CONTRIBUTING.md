# Katkıda Bulunma Rehberi

Öncelikle ro-Control projesine katkıda bulunmak istediğiniz için teşekkür ederiz! Açık kaynak topluluğunun gücüne inanıyoruz ve her türlü desteği takdir ediyoruz.

Aşağıda projemize katkıda bulunurken süreci kolaylaştıracak bazı yönergeler bulunmaktadır.

## Nasıl Katkıda Bulunabilirim?

### 1. Hata Bildirimi (Bug Reporting)

Karşılaştığınız hataları GitHub [Issues](https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control/issues) sayfası üzerinden bildirebilirsiniz. İyi bir hata raporu şunları içermelidir:

- **Net ve açıklayıcı bir başlık.**
- **Adım adım yeniden oluşturma talimatları:** Hatayı tekrar oluşturmak için ne yapmalıyız?
- **Beklenen ve gerçekleşen davranış:** Ne olmasını bekliyordunuz, ne oldu?
- **Ekran görüntüleri veya Loglar:** Hata anına ait görseller veya uygulama logları (`debug.log` veya terminal çıktısı).
- **Sistem Bilgileri:** Dağıtım, GPU modeli, Sürücü sürümü vb.

### 2. Özellik İsteği (Feature Request)

Yeni bir özellik mi istiyorsunuz? Issues bölümünde "Feature Request" etiketiyle bir tartışma başlatın. Fikrinizi, neden gerekli olduğunu ve nasıl çalışması gerektiğini detaylandırın.

### 3. Kod Katkısı (Pull Requests)

Kod göndermeden önce lütfen şu adımları izleyin:

1.  **Fork Edin:** Projeyi kendi hesabınıza fork'layın.
2.  **Branch Açın:** Yapaccağınız değişiklik için açıklayıcı bir dal (branch) oluşturun.
    - `feature/yeni-buton`
    - `fix/kurulum-hatasi`
3.  **Temiz Kod:** Kodunuzun mevcut kod stiline (PEP 8 vb.) uyduğundan emin olun.
4.  **Test Edin:** Yaptığınız değişikliğin mevcut özellikleri bozmadığını test edin.
5.  **Commit Mesajları:** Açıklayıcı commit mesajları yazın.
    - ❌ `fix`
    - ✅ `Fix: Update modülündeki zamanlama hatası giderildi`
6.  **PR Gönderin:** Pull Request açarken yaptığınız değişikliği özetleyin ve ilgili Issue numarasını belirtin.

## Geliştirme Ortamı Kurulumu

Projeyi yerel makinenizde çalıştırmak için:

```bash
# Repoyu klonlayın
git clone https://github.com/Acik-Kaynak-Gelistirme-Toplulugu/ro-Control.git
cd ro-control

# Sanal ortam oluşturun (Önerilen)
python3 -m venv venv
source venv/bin/activate

# Bağımlılıkları yükleyin
pip install -r requirements.txt

# Uygulamayı başlatın
python3 -m src.main
```

## Kodlama Standartları

- **Dil:** Proje dili İngilizce (değişkenler, fonksiyon isimleri) ve Türkçe (yorum satırları, arayüz metinleri) karışımıdır. Ancak yeni kodlarda fonksiyon isimlerinin İngilizce olması tercih edilir.
- **UI:** GTK4 ve LibAdwaita prensiplerine sadık kalın.

Teşekkürler! 🚀
