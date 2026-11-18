# Bölüm I: yerel Android derlemesi

`game/` doğrudan Godot **4.4.1 stable** ile açılır. GL Compatibility (OpenGL ES 3), iskeletli GLB karakterler ve gerçek zamanlı 3B sahne kullanır. WebView, sunucu veya hesap yok. Karakterler, yapılar ve sesler APK içindedir; Türkçe sistem anlatımı yalnızca cihazın uygun bir sesi varsa kullanılır.

## İçerik ve doğrulama

- Ana kaynak `episode-1.md`. `story/episode1.av` oyun uyarlaması; `python3 tools/story.py` çevrimdışı bölüm ve arşiv verilerini üretir. `--check` eski çıktı varsa başarısız olur. `game/data/excursions.json` saha çalışmalarının adımlarını içerir.
- JDK 17, Android SDK (platform-tools ve 16 KiB sayfa hizalamasını destekleyen Build Tools), `xvfb`, Mesa/OpenGL ve Python 3: `bash tools/engine.sh && bash tools/ci-build.sh`. `ANDROID_HOME` ile `JAVA_HOME` ayarlanmalıdır. Editör ve Android şablonu Godot'un resmî 4.4.1 dağıtımından alınır ve dağıtımın SHA-512 listesiyle denetlenir. Önceden yapılandırılmış bir CI hesabına göre yazılan derleme betiği **editör ayar dosyasını yazar**; kişisel editör profilinin yerine ayrı bir `HOME` kullanın.
- `game/tests/chapter_test.gd` başlıktan sona gider; gerçek hareket işleviyle hedeflere erişimi, takip, bulmacalar, büyüler, yanlış yanıt, kısmi kayıt ve devam etmeyi denetler. `PACE_MODEL` yürüyüş simülasyonu ile görülen sözcükleri ayrı raporlar. İnsan oynanış süresi veya fiziksel telefon FPS ölçümü değildir.
- `game/tests/visual.gd` gerçek GL görüntüleri alır. `tools/device-smoke.sh <imzalı-apk>` Android x86_64 emülatörüne **verilen APK'yı değiştirmeden** kurar; yatay menü, ayarlar, dokunma, diyalog, hareket, sürecin kapanması ve kayıttan dönüşü denetler. Bunlar fiziksel ARM telefon veya Bluetooth kol testi yerine geçmez.

## İmza ve yayın

Derleme **imzasız** paket üretir. Kullanıcıya verilen dosya `build/android/Ashen-Vale-Episode-1.apk` adını taşıyan **imzalı release** olmalıdır. Özel anahtar Git'e, Actions'a veya derleme çıktısına girmez. `apksigner sign` çevrimdışı çalışır; `apksigner verify --verbose --print-certs` ve `zipalign -c -P 16 4` ile denetlenir. Sadece aynı imzayla güncelleme kurulabildiğinden yayın anahtarı güvenli ve özel yedeklenmelidir.

`tools/signature_patch.py` imzalı dosya ile doğrulanmış imzasız CI paketi arasındaki farkı aktarır; pakette değişmeyen sıkıştırılmış içerik yeniden taşınmaz. Yalnızca **açık imza** ve APK başlıkları Git'te yer alır; imza atma yetkisi vermez. Teslim iş akışı asıl build SHA'sını, tam dosya ve sertifika özetlerini denetler; aynı dosyanın cihaz testinden sonra GitHub Release'e ekler ve **indirme adresinden dosyayı geri indirip** özetini tekrar doğrular. Herhangi bir sonraki güncellemede hem geliştirme hem yayın için yeni kullanıcı onayı gerekir.
