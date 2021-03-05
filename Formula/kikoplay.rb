class Kikoplay < Formula
  desc "NOT ONLY A Full-Featured Danmu Player"
  homepage "https://github.com/Protostars/KikoPlay"
  url "https://github.com/Protostars/KikoPlay/archive/0.7.2.tar.gz"
  sha256 "9560163ab968b8441643724b30a132af0cfab63addf8b0aad88a8b57e07d97d5"
  revision 1

  head do
    url "https://github.com/Protostars/KikoPlay.git"

    resource "script" do
      url "https://github.com/Protostars/KikoPlayScript.git"
    end
  end

  depends_on "aria2"
  depends_on "lua@5.3"
  depends_on "mpv"
  depends_on "protostars/kikoplay/qhttpengine"
  depends_on "qt@5"

  def install
    inreplace "globalobjects.cpp", "if (fileinfoConfig", "if (1 || fileinfoConfig"

    script =  build.head? ? "Script" : "Download/Script"

    inreplace %W[
      LANServer/httpserver.cpp
      #{script}/scriptmanager.cpp
    ] do |s|
      s.gsub! "/usr", "/usr/local"
    end

    libs = %W[
      -L#{Formula["lua@5.3"].lib}
      -L#{Formula["mpv"].lib}
      -L#{Formula["protostars/kikoplay/qhttpengine"].lib}
    ]
    system "#{Formula["qt@5"].bin}/qmake",
           "CONFIG -= app_bundle",
           "LIBS += #{libs * " "}"

    ln_sf Dir[Formula["lua@5.3"].opt_include/"lua/*"], "#{script}/lua/"

    ln_s prefix, "usr"
    ENV["INSTALL_ROOT"] = "."
    system "make", "install"

    if build.head?
      resource("script").stage do
        (share/"kikoplay/script").install Dir["*"]
      end
    end

    mv Dir["KikoPlay*.pdf"] * "", "help.pdf"
    doc.install "help.pdf"
  end
end
