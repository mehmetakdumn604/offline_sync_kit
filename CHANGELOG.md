# Değişiklik Günlüğü

## 1.4.0

### WebSocket Desteği ve Gerçek Zamanlı Senkronizasyon
- **WebSocketConnectionManager** eklendi - WebSocket bağlantı yaşam döngüsünü, yeniden bağlanma denemelerini ve durum bildirimlerini yönetir
- **WebSocketNetworkClient** eklendi - Http tabanlı ağ istemcisinin yanında WebSocket tabanlı alternatif sağlar
- **WebSocketConfig** eklendi - WebSocket davranışı için kapsamlı yapılandırma seçenekleri
- **SyncEventMapper** sınıfı eklendi - WebSocket olay adlarını ve SyncEventType numaralandırmasını eşler
- Abonelikler ve kanal dinleme için pub/sub mesajlaşma sistemi

### Özelleştirme Geliştirmeleri
- Özelleştirilebilir mesaj formatı için birden çok mesaj formatlayıcı desteği
- Bağlantı yaşam döngüsü yönetimi ve durum izleme için gelişmiş kancalar
- WebSocket bağlantı işleme için genişletilebilir davranış
- Özelleştirilebilir ping/pong mesajları

### Olay Sistemi İyileştirmeleri
- Senkronizasyon olaylarını izlemek ve dinlemek için genişletilmiş SyncEventType
- İstemci tarafı olay filtreleme ve dönüştürme yetenekleri
- Olay dinleyiciler ve akış oluşturma için gelişmiş destek

## 1.3.0

### Özel Depo Desteği
- Depolama Yardımcı Programları - Özel depo sınıflarını kaydetmek ve kullanmak için yeni API'ler
- UUID Yardımcı Programları - Model tanımlayıcıları oluşturmak için yeni dahili UUID desteği
- Model Fabrikası Geliştirmeleri - Her model türü için tür güvenli fabrika işlevleri 

### Model Fabrikası İşleme
- Model fabrikası kodlaması ve çözme için geliştirilmiş destek
- Seri hale getirilmiş modelleri JSON'dan geri yüklemek için daha iyi doğrulama
- Model oluşturmada çeşitli türler için genişletilmiş destek

### Delta Senkronizasyon İyileştirmeleri
- Delta hesaplama için optimize edilmiş algoritma
- Yalnızca değişen alanları göndermek için ince ayarlanmış senkronizasyon motoru
- Değiştirilmiş alanları izlemek için iyileştirilmiş yöntemler

## 1.2.0

### Çift Yönlü Senkronizasyon
- Sunucudan yerel modelleri güncellemek için sağlam iki yönlü senkronizasyon
- Sunucudan yeni verileri kontrol etmek için akıllı zaman damgası işleme
- Sunucu değişikliklerini yerel modellere entegre etmek için çakışma çözümü

### Performans İyileştirmeleri
- Daha hızlı veri senkronizasyonu için toplu senkronizasyon desteği
- Daha verimli aktarım için optimize edilmiş ağ istekleri
- İyileştirilmiş yerel veritabanı sorguları

### Hata İşleme Geliştirmeleri
- Daha iyi tanılar için daha ayrıntılı hata mesajları
- Geri yükleme mekanizmaları
- API istisnaları için gelişmiş işleme

## 1.1.0

### Gelişmiş Yapılandırma
- Senkronizasyon aralıkları, stratejileri ve davranışı için özelleştirilebilir seçenekler
- Çakışma çözümü için genişletilebilir çerçeve
- Senkronizasyon davranışını özelleştirmek için olay dinleyicileri

### Şifreleme Desteği
- Yerel olarak depolanan veriler için seçimli şifreleme
- Yapılandırılabilir şifreleme anahtarları
- Güvenlik mekanizmaları

## 1.0.0

### İlk Sürüm
- Açık/Kapalı durumlarında çalışan model ile çevrimdışı veri senkronizasyonu
- SQLite tabanlı yerel veritabanı depolama
- Otomatik senkronizasyon yönetimi
- Temel çakışma yönetimi
- REST API entegrasyonu
- Bağlantı izleme
- Yalnızca değiştirilen verileri senkronize etme özelliği
