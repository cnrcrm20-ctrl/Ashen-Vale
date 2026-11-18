# Ashen Vale — proje hafızası

Yeni bir oturumda önce bu dosyayı oku. Amaç, oyunla ilgili kararları korumak ve konuşulan fikirleri onaylanmış işlerle karıştırmamak.

## Onay kuralı

- **Kodlamadan önce:** O güncellemede neyin değişeceğini ve neyin teslim edileceğini kısaca anlat. Kullanıcı o kapsam için açıkça onay vermeden kodlamaya başlama. Buna proje iskeleti ve CI iş akışları da dahil. Hikâye konuşmak veya bir fikri beğenmek kodlama onayı değildir.
- **Yayınlamadan önce:** Hangi sürümün, hangi çıktısının, nereye gönderileceğini belirt ve kullanıcıdan açık yayın onayı al. Kodlama onayı yayın izni değildir. Onay olmadan güncellemeyi GitHub’a gönderme, PR açma/birleştirme, APK/EXE paylaşma veya release yayımlama.
- Bir onay yalnızca belirtilen güncelleme ve kapsam için geçerlidir. Kapsam değişirse ya da onay belirsizse dur ve sor.

**Bu teslimin onayı:** Kullanıcı, mevcut `episode-1.md` üzerinden Bölüm I'in kısaltılmadan kodlanmasını, gerçek Android oyunu olarak derlenmesini ve doğrudan GitHub APK bağlantısını açıkça istedi. Bu yalnızca **Üçüncü Zeytin 1.0.0** içindir. Bölüm II, başka güncelleme, Windows sürümü veya `main`e birleştirme izni değildir. [Lisans](LICENSE) geçerli.

## Oyunda korunacak hedefler

- **Dünya:** Antik çağda geçen, **dev bir vadi haritasına** sahip açık dünya. GTA, oyuncunun özgürlüğüne; Hogwarts Legacy, keşif atmosferine referans. İlyan’ın Üçoluk’ta başlayan üç günü ve karakterler `episode-1.md` içinde sabittir. Bu bölümün yedi güzergâhı, bitmiş oyunun dev haritası değildir.
- **Görünüm ve his:** Minecraft Dungeons görsel özen için örnek; dünya **küplerden oluşmayacak**. Doğal hatlı, stilize 3B ortamlar; güçlü sinematikler, ağırlığı hissedilen yürüme/koşma/dönme animasyonları ve tepkisi iyi zamanlanmış dövüş önemli. Hedef fotogerçekçilik değil; en zayıf cihaz uğruna görüntüyü kısmak da değil.
- **Ana platform:** Android’e kurulan gerçek bir **APK**. HTML, tarayıcı demosu veya WebView yok. Dokunmatik kontrolün yanında telefonda Bluetooth ile PS4 kolu (DualShock 4) düşünülüyor.
- **İsteğe bağlı PC sürümü:** Aynı içerik için yerel Windows `.exe` ve daha yüksek grafik ayarları. Referans: Intel Arc B580 Limited Edition, 1440p / 144 Hz monitör; 4K TV veya projektör de kullanılabilir. PC’de hedef yoğun sahnelerde de 60 FPS; **60 bir tavan değil**. Varsayılan VSync kapalı, FPS sınırı yok. Bu hedef henüz cihazda ölçülmedi.

## Bölüm I (Üçüncü Zeytin)

- Yerel Godot 4.4.1 Android release, 64 bit ARM / x86, çevrimdışı. Kaynak `game/`; kanonik metin `episode-1.md`, oyun uyarlaması `story/episode1.av`. Kurulum ve doğrulama için `docs/android-build.md`.
- 13 yaşındaki İlyan gönüllü olarak Tamar’ı izler ve **işaretinden önce** Vadi’ye gitmeyi ister. İşaret sağ önkoldadır. Annesi Belis, babası olağanüstü yetenekli ve zalim büyücü Vadigon. Sarpel’in önyargısı çocuğun insan oluşunadır. İlyan ilk insan büyücüdür. Ortak Avlu’nun nar hattı Ufuk Duvarları değildir.
- 8 dal, toplam 34 büyü; 8 karanlık, her daldan bir tane. Bu bölümde yalnız Fitil, Dipses, Siper, Yel Avucu öğrenilir. Su Eşiği Tamar’ındır. Naret’in sesiyle ilgili karanlık büyü öğretilmez.
- İlk gün kaçış, eşik, konuk kaydı, kandil ve yemek; ikinci gün ders ve eşli talim; üçüncü gün Üçdil. Sonuç: ölçü ile teslim kaydı çelişir; fail ya da sabotaj kanıtlanmaz. İki kayıt ve Mina’nın cevabıyla sefer hazırlanır. Nar hattının ötesine geçilmez.
- 60 görev adımı, dört çok duraklı saha çalışması, üç döndürülebilir güzergâh levhası, 21 isteğe bağlı hatıra. Süreyi doldurmak için diyalog kilidi veya geri sayım yok. Tasarım 45–50 dakika; hızlandırılmış rota + 180 kelime/dakika okuma modeli 32,1 dakika, düşünme/uygulama ayrı. Bu, ölçülmüş insan oynanış süresi ya da telefon FPS testi **değildir**.
- İmzalı ilk sürüm için teslim tarifi `delivery/episode1.json`; yayın durumu GitHub Releases’tan doğrulanır. Yeni bir teslim için yeni ve ayrı onay gerekir.
