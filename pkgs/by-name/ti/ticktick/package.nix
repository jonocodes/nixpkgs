{
  lib,
  fetchurl,
  stdenv,
  wrapGAppsHook3,
  dpkg,
  autoPatchelfHook,
  glibc,
  gcc-unwrapped,
  nss,
  libdrm,
  libgbm,
  alsa-lib,
  xdg-utils,
  systemd,
}:
let

  throwSystem = throw "Unsupported system: ${stdenv.hostPlatform.system}";

  _version = "6.0.21";

  baseUrl = "https://d2atcrkye2ik4e.cloudfront.net/download";

  srcs = {
    x86_64-linux = fetchurl {
      url = "${baseUrl}/linux/linux_deb_x64/ticktick-${_version}-amd64.deb";
      hash = "sha256-e5N20FL2c6XdkDax0SMGigLuatXKZxb9c53sqQ5XVtM=";
    };
    aarch64-linux = fetchurl {
      url = "${baseUrl}/linux/linux_deb_arm64/ticktick-${_version}-arm64.deb";
      hash = "sha256-6/nzPL+TeEE31S0ngmsUFPZEfWtt4PVAEkMqSa8OpYI=";
    };
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ticktick";
  version = _version;

  src = srcs.${stdenv.hostPlatform.system} or throwSystem;

  nativeBuildInputs = [
    wrapGAppsHook3
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    nss
    glibc
    libdrm
    gcc-unwrapped
    libgbm
    alsa-lib
    xdg-utils
  ];

  # Needed to make the process get past zygote_linux fork()'ing
  runtimeDependencies = [ systemd ];

  unpackPhase = ''
    runHook preUnpack

    mkdir -p "$out/share" "$out/opt/${finalAttrs.pname}" "$out/bin"
    dpkg-deb --fsys-tarfile "$src" | tar --extract --directory="$out"

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    cp -av $out/opt/TickTick/* $out/opt/${finalAttrs.pname}
    cp -av $out/usr/share/* $out/share
    rm -rf $out/usr $out/opt/TickTick
    ln -sf "$out/opt/${finalAttrs.pname}/${finalAttrs.pname}" "$out/bin/${finalAttrs.pname}"

    substituteInPlace "$out/share/applications/${finalAttrs.pname}.desktop" \
      --replace "Exec=/opt/TickTick/ticktick" "Exec=$out/bin/${finalAttrs.pname}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Powerful to-do & task management app with seamless cloud synchronization across all your devices";
    homepage = "https://ticktick.com/home/";
    license = licenses.unfree;
    maintainers = with maintainers; [
      hbjydev
      jonocodes
    ];
    platforms = builtins.attrNames srcs;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
})
