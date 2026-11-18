# Ashen Vale — proje hafızası

Yeni bir oturumda önce bu dosyayı oku. Amaç, oyunla ilgili kararları korumak ve konuşulan fikirleri onaylanmış işlerle karıştırmamak.

## Onay kuralı

- **Kodlamadan önce:** O güncellemede neyin değişeceğini ve neyin teslim edileceğini kısaca anlat. Kullanıcı o kapsam için açıkça onay vermeden kodlamaya başlama. Buna proje iskeleti ve CI iş akışları da dahil. Hikâye konuşmak veya bir fikri beğenmek kodlama onayı değildir.
- **Yayınlamadan önce:** Hangi sürümün, hangi çıktısının, nereye gönderileceğini belirt ve kullanıcıdan açık yayın onayı al. Kodlama onayı yayın izni değildir. Onay olmadan güncellemeyi GitHub’a gönderme, PR açma/birleştirme, APK/EXE paylaşma veya release yayımlama.
- Bir onay yalnızca belirtilen güncelleme ve kapsam için geçerlidir. Kapsam değişirse ya da onay belirsizse dur ve sor.

**Mevcut durum:** Bu adımda yalnızca `Brain.md` oluşturulması istendi. Oyun kodu, build veya yayın için onay yok. Repoda henüz oynanabilir bir sürüm yok. Mevcut [lisans](LICENSE) geçerli.

## Oyunda korunacak hedefler

- **Dünya:** Antik çağda geçen, **dev bir vadi haritasına** sahip açık dünya. GTA, oyuncunun özgürlüğüne; Hogwarts Legacy, keşif atmosferine referans. Hikâye ve karakterler henüz belirlenmedi.
- **Görünüm ve his:** Minecraft Dungeons görsel özen için örnek; dünya **küplerden oluşmayacak**. Doğal hatlı, stilize 3B ortamlar; güçlü sinematikler, ağırlığı hissedilen yürüme/koşma/dönme animasyonları ve tepkisi iyi zamanlanmış dövüş önemli. Hedef fotogerçekçilik değil; en zayıf cihaz uğruna görüntüyü kısmak da değil.
- **Ana platform:** Android’e kurulan gerçek bir **APK**. HTML, tarayıcı demosu veya WebView yok. Dokunmatik kontrolün yanında telefonda Bluetooth ile PS4 kolu (DualShock 4) düşünülüyor.
- **İsteğe bağlı PC sürümü:** Aynı içerik için yerel Windows `.exe` ve daha yüksek grafik ayarları. Referans: Intel Arc B580 Limited Edition, 1440p / 144 Hz monitör; 4K TV veya projektör de kullanılabilir. PC’de hedef yoğun sahnelerde de 60 FPS; **60 bir tavan değil**. Varsayılan VSync kapalı, FPS sınırı yok. Bu hedef henüz cihazda ölçülmedi.

## Henüz karara bağlanmayanlar

- **Motor ve derleme:** GitHub reposu ve onaydan sonra GitHub Actions üzerinden yerel oyun çıktıları isteniyor. Unity 6 LTS + URP önerildi; kesin motor seçimi yapılmadı. CI lisansı, Android araçları ve gerçek cihaz performansı doğrulanmadı.
- **Sıradaki konuşma:** Ana karakter, hikâyenin açılışı ve oyuncunun vadideki ilk amacı. Önceden geçen kül büyüsü, köprü ve tapınak sahneleri yalnızca fikir; kullanıcı seçmeden hikâyenin parçası sayılmaz. Bu tasarım konuşması için kod yazmaya gerek yok.
