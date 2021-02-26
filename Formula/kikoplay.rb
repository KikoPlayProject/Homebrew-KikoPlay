class Kikoplay < Formula
  desc "NOT ONLY A Full-Featured Danmu Player"
  homepage "https://github.com/Protostars/KikoPlay"
  url "https://github.com/Protostars/KikoPlay/archive/0.7.2.tar.gz"
  sha256 "9560163ab968b8441643724b30a132af0cfab63addf8b0aad88a8b57e07d97d5"
  head "https://github.com/Protostars/KikoPlay.git"

  depends_on "aria2"
  depends_on "lua@5.3"
  depends_on "mpv"
  depends_on "protostars/kikoplay/qhttpengine"
  depends_on "qt"

  def install
    libs = %W[
      -L#{Formula["lua@5.3"].lib}
      -L#{Formula["mpv"].lib}
      -L#{Formula["protostars/kikoplay/qhttpengine"].lib}
    ]
    system "#{Formula["qt"].bin}/qmake",
           "CONFIG -= app_bundle",
           "LIBS += #{libs * " "}"

    ln_sf Dir[Formula["lua@5.3"].opt_include/"lua/*"], "Download/Script/lua/"

    system "make"
    bin.install "KikoPlay"

    mv Dir["KikoPlay*.pdf"] * "", "help.pdf"
    doc.install "help.pdf"
  end
end
