# Bölüm I: yerel Android derlemesi

`game/` Godot **4.4.1 stable** projesidir. Bu dal ayrı Android paketli (`com.ashenvale.episodeone.preview`) `1.1-dev` önizlemesidir: Android'de Mobile/Vulkan ve uyumlu cihazlar için GLES geri dönüşü, PC'de Forward+ kullanır. İçerik yerel 3B'dir; WebView, hesap, ağ TTS veya sistem konuşma motoru yoktur. Önceki imzalı 1.0.0'ın doğrulaması [proje hafızasında](../braind.md); onun sonuçlarını yeni sürüme atfetmeyin.

### Türkçe ses — yalnızca önceden üretilmiş kayıtlar

- Kanonik konuşmacı ve altyazı: `story/kalkstein-voices.json`. `.av` içinde `!kayıt` yürürken duyulan replik, `$kayıt` karşılıklı konuşmadır. İşitsel ipuçlarının altyazısı, ses kapalıyken de kalır. Kayıtsız satır yalnızca metindir; rastgele sesle doldurulmaz.
- Bu sohbetin ses aracıyla üretilmiş kayıpsız asıllar `story/voice-masters/*.flac` (APK'nın dışında). Oyunda mono 24 kHz Vorbis kullanılır: `game/audio/voices/tr/`. Dosyanın **artist, title ve language** etiketleri rol ve metinle örtüşmelidir. Metin değişirse yeniden kayıt gerekir. `python3 tools/story.py --check` iki kopyayı da denetler.
- Var olan kayıtları yeniden paketlemek veya örnek dinlemeyi almak için: `python3 tools/voice-mix.py --ffmpeg /yol/ffmpeg --preview`. FFmpeg yalnızca kodlama ve seviye ayarı yapar; metinden ses üretmez. Hazır dosyalarla derlemede FFmpeg gerekmez.
- Sistemdeki Godot 4.4.1 ile, ayrı bir test kullanıcı dizininde önce normal grafik sürücüsüyle `godot --editor --path game --import`; sonra `godot --headless --path game --script res://tests/voices_test.gd`. Dört sesin miksere ulaştığını izole kanalda ölçer; atlama/susturma, iki geçit, algılanma, üç eşzamanlı dokunuş arasında sentetik kol düğmesini ve kayıt dönüşünü kontrol eder. Bu test fiziksel kol eşleşmesini sınamaz. `tests/forest_test.gd` çayın iki yolunu, taşkını, kaydı, ocağı ve dükkânların çalışanlarını denetler; `tests/chapter_test.gd` bölümün geri kalanını da yürür. `voice-mix.py` ayrıca 25 Hz çene/dudak eğrilerini kliplerin ses örneklerinden çıkarır. Yüzdeki iki şekil `tools/rig-expression.py` ile donatılmıştır; bunlar fonem çözümlemesi veya yüz yakalama değildir. Başka ağız biçimleri/klipleri olan bir karaktere körlemesine uygulamayın.

## İçerik ve doğrulama

- Ana kaynak `episode-1.md`. `story/episode1.av` oyun uyarlaması; `python3 tools/story.py` çevrimdışı bölüm ve arşiv verilerini üretir. `--check` eski çıktı varsa başarısız olur. `game/data/excursions.json` saha çalışmalarının adımlarını içerir.
- JDK 17, Android SDK (platform-tools ve 16 KiB sayfa hizalamasını destekleyen Build Tools), `xvfb`, Mesa/OpenGL ve Python 3: `bash tools/engine.sh && bash tools/ci-build.sh`. `ANDROID_HOME` ile `JAVA_HOME` ayarlanmalıdır. Editör ve Android şablonu Godot'un resmî 4.4.1 dağıtımından alınır ve dağıtımın SHA-512 listesiyle denetlenir. Önceden yapılandırılmış bir CI hesabına göre yazılan derleme betiği **editör ayar dosyasını yazar**; kişisel editör profilinin yerine ayrı bir `HOME` kullanın.
- `game/tests/chapter_test.gd` başlıktan sona gider; gerçek hareket işleviyle hedeflere erişimi, takip, bulmacalar, büyüler, yanlış yanıt, kısmi kayıt ve devam etmeyi denetler. `PACE_MODEL` yürüyüş simülasyonu ile görülen sözcükleri ayrı raporlar. İnsan oynanış süresi veya fiziksel telefon FPS ölçümü değildir.
- `game/tests/visual.gd` gerçek görünüm alanından **11 PNG** alır: başlık, yatakhane, Lyra, Matilda, sağ önkol, çay, Orfen, Avlu, teras, Edda ve savak. Ortadaki oyun alanı tek renkse veya başlıktaki Latin harflerinin ilerlemesi negatifse test başarısız olur. Edda'nın yüzü veya tabağı altyazının arkasında ya da başka bir karakterin gövdesiyle aynı bakış çizgisindeyse servis kadrajı da testi geçmez. Görüntüleri ayrıca gözle açın; bu eşikler iyi oyunculuk veya doğru kadraj kanıtı değildir. Ayrı bir veri dizininde çalıştırma örneği:

  ```bash
  mkdir -p build/shots build/test-user
  XDG_DATA_HOME="$PWD/build/test-user" SHOT_DIR="$PWD/build/shots" \
    godot --path game --audio-driver Dummy --rendering-method gl_compatibility \
    --fixed-fps 24 --resolution 1280x720 --script res://tests/visual.gd
  ```

- `tests/kalkstein_take.gd` aynı veri izolasyonuyla `--write-movie /mutlak/yol/take.avi --fixed-fps 24` kullanır. Yatak başındaki başlangıç konumlarını kurar; iki repliği oyunun kendisi çalar ve ilerletir. AVI'nin sesi Godot mikserindendir. Örnek: [10,29 sn MP4](../samples/kalkstein-diyalog.mp4); Türkçe replikler videoya sonradan giydirilmedi. Bu **çevrimdışı kare kaydıdır**; filmin kare hızı cihaz FPS'i değildir.

  ```bash
  mkdir -p build/movie/{data,config}
  XDG_DATA_HOME="$PWD/build/movie/data" XDG_CONFIG_HOME="$PWD/build/movie/config" \
    godot --path game --audio-driver Dummy --rendering-method gl_compatibility \
    --resolution 1280x720 --fixed-fps 24 --write-movie "$PWD/build/movie/third-olive.avi" \
    --script res://tests/kalkstein_take.gd
  ```

  Ekran sunucusu ve çalışan bir 3B sürücüsüyle çalıştırın. Günlükte `TAKE_BEGIN` / `TAKE_END` ve `both_lines=true` olmalı; siyah kareyi ya da boş ses kanalını yalnız bu işaretler yakalamaz.

- Kostüm hazırlama (yalnız metre ölçekli bu iskeletlerde): `python3 tools/rig-expression.py` ve Pillow yüklüyken `python3 tools/fit-kalkstein.py`. Paketlenmiş dosyalarda yeniden çalıştırmak değişiklik yapmaz. İkinci araç giysi ağırlıklarını korur; iki çocukta yüz, saç ve konuşma şekillerini birlikte uyarlar. Sağ önkolun çıplak yüzeyini aynı eklem ağırlıklarıyla ayırır; iz gölgede ve hareket halinde kolla kalır. Hazır modellerle oyunu çalıştırırken bu araçlar gerekmez.
- `tools/device-smoke.sh <imzalı-apk>` sürüme göre eski avluya ya da Kalkstein yatakhanesine girer. Android x86_64 emülatörüne **verilen APK'yı değiştirmeden** kurar; yatay menü, ayarlar, dokunma, diyalog, hareket, sürecin kapanması ve kayıttan dönüşü denetler. Bunlar fiziksel ARM telefon veya Bluetooth kol testi yerine geçmez.

## İmza ve yayın

Derleme `build/android/Ashen-Vale-Episode-1.apk` adlı **imzasız** bir ara dosya üretir; indirilecek ürün bu değildir. 1.1-dev için kullanıcının onayladığı hedef GitHub Releases'ta ön sürümdür. Teslim dosyaları **Ashen-Vale-1.1-dev-Android.apk** ve **kalkstein-diyalog.mp4**. Android uygulama kimliği `com.ashenvale.episodeone.preview`, sürüm kodu `10002`. Eski `com.ashenvale.episodeone` uygulamasının sertifikası kullanılmaz; iki uygulama ve kayıtları ayrı kalır.

Önizleme anahtarı yalnız çevrimdışı imzacıdadır; Git'e, Actions'a, sohbet mesajına veya indirilen dosyalara özel anahtar/parola koymayın. Gelecekte aynı önizleme paketinin üzerine kurulum için aynı anahtarın güvenli özel yedeği gerekir. `apksigner sign` çevrimdışı çalışır. `tools/signature_patch.py`, doğrulanmış imzasız pakette zaten bulunan sıkıştırılmış içeriği kopyalar; teslim verisi yalnızca **açık imza**, ZIP başlıkları ve kaynak/sonuç özetleridir. İmza atma yetkisi vermez.

`.github/workflows/preview-delivery.yml` yalnız bu dal, etiket ve paket için çalışır. Başarılı kaynağı ve SHA-256 özetini doğrular; yeniden kurduğu APK'yı `apksigner verify --verbose --print-certs` ile, hizalamayı `zipalign -c -P 16 4` ile denetler. Geçici AVD'ye önce özeti doğrulanmış 1.0.0, sonra imzalı önizleme kurulur. Farklı Android kullanıcı kimlikleri ve gerçek dokunma, görünen sahne, süreci kapatıp devam etme sınanır. Siyah 3B sahne üstünde görünen bir menü geçer not almaz. İki dosya ancak bu kontroller geçerse taslağa eklenir; yeniden indirilip özetleri doğrulanmadan taslak açılmaz. Ön sürüm kararlı `Latest` bağlantısını değiştirmez. Yeni bir sürüm, çıktı veya hedef için yeni yayın onayı gerekir.
