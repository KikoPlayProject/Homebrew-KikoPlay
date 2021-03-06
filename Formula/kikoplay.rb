class Kikoplay < Formula
  desc "NOT ONLY A Full-Featured Danmu Player"
  homepage "https://github.com/Protostars/KikoPlay"
  url "https://github.com/Protostars/KikoPlay/archive/0.7.2.tar.gz"
  sha256 "9560163ab968b8441643724b30a132af0cfab63addf8b0aad88a8b57e07d97d5"
  license "GPL-3.0"
  revision 2

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
    script =  build.head? ? "Script" : "Download/Script"

    # Enable test
    inreplace "res/version.json", /(?<="Version":).*/, %Q("#{version}") if build.head?

    inreplace "main.cpp", "args.pop_front();", <<~EOS
      args.pop_front();
      if(args.at(0) == "-V")
      {
        QFile version(":/res/version.json");
        version.open(QIODevice::ReadOnly);
        QJsonObject curVersionObj = QJsonDocument::fromJson(version.readAll()).object();
        qDebug() << qUtf8Printable(curVersionObj.value("Version").toString());
        exit(0);
      }
    EOS

    # Use relative path ($prefix/bin/..) for instead of /usr
    inreplace %W[
      LANServer/httpserver.cpp
      #{script}/scriptmanager.cpp
    ] do |s|
      s.gsub! '"/usr', 'QCoreApplication::applicationDirPath()+"/..'
    end

    # Force create ~/.config/kikoplay
    inreplace "globalobjects.cpp", "if (fileinfoConfig", "if (1 || fileinfoConfig"

    libs = %W[
      -L#{Formula["lua@5.3"].lib}
      -L#{Formula["mpv"].lib}
      -L#{Formula["protostars/kikoplay/qhttpengine"].lib}
    ]
    system "#{Formula["qt@5"].bin}/qmake",
           "CONFIG -= app_bundle",
           "LIBS += #{libs * " "}"

    # Use packaged Lua headers
    ln_sf Dir[Formula["lua@5.3"].opt_include/"lua/*"], "#{script}/lua/"

    # Strip leading /usr during installation
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

  test do
    assert_match version.to_s, shell_output("#{bin}/KikoPlay -V 2>&1 | tail -n1")
  end
end
